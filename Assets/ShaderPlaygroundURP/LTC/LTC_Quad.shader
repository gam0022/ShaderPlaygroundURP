Shader "LTC/Quad"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _LightColor ("Light Color", Color) = (1, 1, 1, 1)
        _DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _LTC1 ("LTC1", 2D) = "white" {}
        _LTC2 ("LTC2", 2D) = "white" {}
        _TwoSided("Two Sided", Range(0, 1)) = 1
        _ClipLess ("Clip Less", Range(0, 1)) = 0
        _Roughness ("Roughness", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "Queue" = "Geometry"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define LUT_SIZE 64.0
            #define LUT_SCALE 0.984375 // (LUT_SIZE - 1.0)/LUT_SIZE;
            #define LUT_BIAS  0.0078125 // 0.5 / LUT_SIZE;

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : POSITION_WS;
                float2 uv : TEXCOORD0;
                half3 normalWS : NORMAL_WS;
                half3 viewWS : VIEW_WS;
            };

            sampler2D _BaseMap;
            sampler2D _LTC1;
            sampler2D _LTC2;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;

            half4 _LightColor;
            half4 _DiffuseColor;
            half4 _SpecularColor;

            float _TwoSided;
            float _ClipLess;
            float _Roughness;
            CBUFFER_END

            float4 _QuadPoints[4];

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.normalWS = TransformObjectToWorldDir(input.normal);
                output.viewWS = normalize(GetWorldSpaceViewDir(output.positionWS));
                return output;
            }

            float3 IntegrateEdgeVec(float3 v1, float3 v2)
            {
                float x = dot(v1, v2);
                float y = abs(x);

                float a = 0.8543985 + (0.4965155 + 0.0145206*y)*y;
                float b = 3.4175940 + (4.1616724 + y)*y;
                float v = a / b;

                float theta_sintheta = (x > 0.0) ? v : 0.5*rsqrt(max(1.0 - x*x, 1e-7)) - v;

                return cross(v1, v2)*theta_sintheta;
            }

            float IntegrateEdge(float3 v1, float3 v2)
            {
                return IntegrateEdgeVec(v1, v2).z;
            }

            void ClipQuadToHorizon(inout float3 L[5], out int n)
            {
                // detect clipping config
                int config = 0;
                if (L[0].z > 0.0) config += 1;
                if (L[1].z > 0.0) config += 2;
                if (L[2].z > 0.0) config += 4;
                if (L[3].z > 0.0) config += 8;

                // clip
                n = 0;

                if (config == 0)
                {
                    // clip all
                }
                else if (config == 1) // V1 clip V2 V3 V4
                {
                    n = 3;
                    L[1] = -L[1].z * L[0] + L[0].z * L[1];
                    L[2] = -L[3].z * L[0] + L[0].z * L[3];
                }
                else if (config == 2) // V2 clip V1 V3 V4
                {
                    n = 3;
                    L[0] = -L[0].z * L[1] + L[1].z * L[0];
                    L[2] = -L[2].z * L[1] + L[1].z * L[2];
                }
                else if (config == 3) // V1 V2 clip V3 V4
                {
                    n = 4;
                    L[2] = -L[2].z * L[1] + L[1].z * L[2];
                    L[3] = -L[3].z * L[0] + L[0].z * L[3];
                }
                else if (config == 4) // V3 clip V1 V2 V4
                {
                    n = 3;
                    L[0] = -L[3].z * L[2] + L[2].z * L[3];
                    L[1] = -L[1].z * L[2] + L[2].z * L[1];
                }
                else if (config == 5) // V1 V3 clip V2 V4) impossible
                {
                    n = 0;
                }
                else if (config == 6) // V2 V3 clip V1 V4
                {
                    n = 4;
                    L[0] = -L[0].z * L[1] + L[1].z * L[0];
                    L[3] = -L[3].z * L[2] + L[2].z * L[3];
                }
                else if (config == 7) // V1 V2 V3 clip V4
                {
                    n = 5;
                    L[4] = -L[3].z * L[0] + L[0].z * L[3];
                    L[3] = -L[3].z * L[2] + L[2].z * L[3];
                }
                else if (config == 8) // V4 clip V1 V2 V3
                {
                    n = 3;
                    L[0] = -L[0].z * L[3] + L[3].z * L[0];
                    L[1] = -L[2].z * L[3] + L[3].z * L[2];
                    L[2] =  L[3];
                }
                else if (config == 9) // V1 V4 clip V2 V3
                {
                    n = 4;
                    L[1] = -L[1].z * L[0] + L[0].z * L[1];
                    L[2] = -L[2].z * L[3] + L[3].z * L[2];
                }
                else if (config == 10) // V2 V4 clip V1 V3) impossible
                {
                    n = 0;
                }
                else if (config == 11) // V1 V2 V4 clip V3
                {
                    n = 5;
                    L[4] = L[3];
                    L[3] = -L[2].z * L[3] + L[3].z * L[2];
                    L[2] = -L[2].z * L[1] + L[1].z * L[2];
                }
                else if (config == 12) // V3 V4 clip V1 V2
                {
                    n = 4;
                    L[1] = -L[1].z * L[2] + L[2].z * L[1];
                    L[0] = -L[0].z * L[3] + L[3].z * L[0];
                }
                else if (config == 13) // V1 V3 V4 clip V2
                {
                    n = 5;
                    L[4] = L[3];
                    L[3] = L[2];
                    L[2] = -L[1].z * L[2] + L[2].z * L[1];
                    L[1] = -L[1].z * L[0] + L[0].z * L[1];
                }
                else if (config == 14) // V2 V3 V4 clip V1
                {
                    n = 5;
                    L[4] = -L[0].z * L[3] + L[3].z * L[0];
                    L[0] = -L[0].z * L[1] + L[1].z * L[0];
                }
                else if (config == 15) // V1 V2 V3 V4
                {
                    n = 4;
                }

                if (n == 3)
                    L[3] = L[0];
                if (n == 4)
                    L[4] = L[0];
            }


            float3 LTC_Evaluate(
                float3 N, float3 V, float3 P, float3x3 Minv, float3 points[4], bool twoSided)
            {
                // construct orthonormal basis around N
                float3 T1, T2;
                T1 = normalize(V - N*dot(V, N));
                T2 = cross(N, T1);

                // rotate area light in (T1, T2, N) basis
                Minv = mul(transpose(float3x3(T1, T2, N)), Minv);

                // polygon (allocate 5 vertices for clipping)
                float3 L[5];
                L[0] = mul(points[0] - P, Minv);
                L[1] = mul(points[1] - P, Minv);
                L[2] = mul(points[2] - P, Minv);
                L[3] = mul(points[3] - P, Minv);
                L[4] = (1).xxx;

                // integrate
                float sum = 0.0;

                if (_ClipLess)
                {
                    float3 dir = points[0].xyz - P;
                    float3 lightNormal = cross(points[1] - points[0], points[3] - points[0]);
                    bool behind = (dot(dir, lightNormal) < 0.0);

                    L[0] = normalize(L[0]);
                    L[1] = normalize(L[1]);
                    L[2] = normalize(L[2]);
                    L[3] = normalize(L[3]);

                    float3 vsum = (0.0).xxx;

                    vsum += IntegrateEdgeVec(L[0], L[1]);
                    vsum += IntegrateEdgeVec(L[1], L[2]);
                    vsum += IntegrateEdgeVec(L[2], L[3]);
                    vsum += IntegrateEdgeVec(L[3], L[0]);

                    float len = length(vsum);
                    float z = vsum.z/len;

                    if (behind)
                        z = -z;

                    float2 uv = float2(z*0.5 + 0.5, len);
                    uv = uv*LUT_SCALE + LUT_BIAS;

                    float scale = tex2D(_LTC2, uv).w;

                    sum = len*scale;

                    if (behind && !twoSided)
                        sum = 0.0;
                }
                else
                {
                    int n;
                    ClipQuadToHorizon(L, n);

                    if (n == 0)
                        return float3(0, 0, 0);
                    // project onto sphere
                    L[0] = normalize(L[0]);
                    L[1] = normalize(L[1]);
                    L[2] = normalize(L[2]);
                    L[3] = normalize(L[3]);
                    L[4] = normalize(L[4]);

                    // integrate
                    sum += IntegrateEdge(L[0], L[1]);
                    sum += IntegrateEdge(L[1], L[2]);
                    sum += IntegrateEdge(L[2], L[3]);
                    if (n >= 4)
                        sum += IntegrateEdge(L[3], L[4]);
                    if (n == 5)
                        sum += IntegrateEdge(L[4], L[0]);

                    sum = twoSided ? abs(sum) : max(0.0, sum);
                }

                float3 Lo_i = float3(sum, sum, sum);

                return Lo_i;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // return tex2D(_LTC1, input.uv) * _BaseColor;
                float3 lcol = _LightColor.rgb;
                float3 dcol = _DiffuseColor.rgb;
                float3 scol = _SpecularColor.rgb;

                float3 pos = input.positionWS;
                float3 N = input.normalWS;
                float3 V = GetWorldSpaceNormalizeViewDir(pos);

                float ndotv = saturate(dot(N, V));
                float2 uv = float2(_Roughness, sqrt(1.0 - ndotv));
                uv = uv * LUT_SCALE + LUT_BIAS;

                float4 t1 = tex2D(_LTC1, uv);
                float4 t2 = tex2D(_LTC2, uv);

                float3x3 Minv = float3x3(
                    float3(t1.x, 0, t1.y),
                    float3(  0,  1,    0),
                    float3(t1.z, 0, t1.w)
                );

                float3x3 Midentify = float3x3(
                    float3(1, 0, 0),
                    float3(0, 1, 0),
                    float3(0, 0, 1)
                );

                float3 points[4];
                points[0] = _QuadPoints[0].xyz;
                points[1] = _QuadPoints[1].xyz;
                points[2] = _QuadPoints[2].xyz;
                points[3] = _QuadPoints[3].xyz;

                float3 spec = LTC_Evaluate(N, V, pos, Minv, points, _TwoSided);
                // BRDF shadowing and Fresnel
                spec *= scol*t2.x + (1.0 - scol)*t2.y;

                float3 diff = LTC_Evaluate(N, V, pos, Midentify, points, _TwoSided);

                float3 col = lcol*(spec + dcol*diff);
                // return half4(_Roughness, 0, 0, 1);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}