Shader "Character/DepthOffset/Mayu"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _DepthOffset ("Depth Offset", Float) = 0.1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                half3 viewWS : VIEW_WS;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            float _DepthOffset;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;

                // View空間上でDepth Offset
                // https://zhuanlan.zhihu.com/p/696515379
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 positionVS = mul(UNITY_MATRIX_V, float4(positionWS, 1.0)).xyz;

                // View空間上でDepth Offset
                positionVS.z += _DepthOffset;

                float4 positionHCS = TransformWViewToHClip(positionVS);
                float depth = positionHCS.z / positionHCS.w;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                // クリッピング空間上でオフセットされた深度を適用
                output.positionHCS.z = depth * output.positionHCS.w;

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.viewWS = normalize(GetWorldSpaceViewDir(positionWS));
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 col = tex2D(_BaseMap, input.uv) * _BaseColor;
                half3 forward = half3(0, 0, 1);// UNITY_MATRIX_M._m02_m12_m22;
                col.a = clamp(pow(saturate(dot(forward, input.viewWS)), 2), 0, 0.7);
                return col;
            }
            ENDHLSL
        }
    }
}