Shader "Character/Stencil/Hair_2ndpass"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags
        {
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

            Stencil {
                Ref 2
                Comp Equal
                Pass Keep
                ZFail Keep
            }

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
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.viewWS = normalize(GetWorldSpaceViewDir(positionWS));
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 col = tex2D(_BaseMap, input.uv) * _BaseColor;
                half3 forward = half3(0, 0, 1);// UNITY_MATRIX_M._m02_m12_m22;
                col.a = clamp(1 - clamp(pow(saturate(dot(forward, input.viewWS)), 2), 0, 1), 0.3, 1);
                return col;
            }
            ENDHLSL
        }
    }
}