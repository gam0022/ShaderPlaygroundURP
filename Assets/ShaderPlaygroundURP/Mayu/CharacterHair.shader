Shader "Character/Hair"
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
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            // パスの用途はLightModeで指定
            // 他にはShadowCasterやDepthOnlyなどがある
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil {
                Ref 2
                Comp NotEqual
                Pass Keep
                ZFail Keep
            }

            // URPの場合はCGPROGRAMではなくHLSLPROGRAMを使う
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Core.hlslをインクルードする
            // よく使われるHLSLのマクロや関数が定義されている
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                // OSはObject Spaceの略
                // 変数名は何でもいいがURPでは座標の変数名にこのようにSuffixを付けるのが一般的
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _BaseMap;

            // SRP Batcherによるバッチングを効かせたい場合にはCBUFFERブロック内に変数を記述する
            // 詳しくは → https://light11.hatenadiary.com/entry/2021/07/15/201733
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 旧パイプラインではUnityObjectToClipPosだったのがURPではTransformObjectToHClipに
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // HLSLPROGRAMの場合、fixed4は使えない
            half4 frag(Varyings IN) : SV_Target
            {
                return tex2D(_BaseMap, IN.uv) * _BaseColor;
            }
            ENDHLSL
        }
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
            // パスの用途はLightModeで指定
            // 他にはShadowCasterやDepthOnlyなどがある
            Tags
            {
                "LightMode" = "HairTransparent"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always

            Stencil {
                Ref 2
                Comp Equal
                Pass Keep
                ZFail Keep
            }

            // URPの場合はCGPROGRAMではなくHLSLPROGRAMを使う
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Core.hlslをインクルードする
            // よく使われるHLSLのマクロや関数が定義されている
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                // OSはObject Spaceの略
                // 変数名は何でもいいがURPでは座標の変数名にこのようにSuffixを付けるのが一般的
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _BaseMap;

            // SRP Batcherによるバッチングを効かせたい場合にはCBUFFERブロック内に変数を記述する
            // 詳しくは → https://light11.hatenadiary.com/entry/2021/07/15/201733
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 旧パイプラインではUnityObjectToClipPosだったのがURPではTransformObjectToHClipに
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // HLSLPROGRAMの場合、fixed4は使えない
            half4 frag(Varyings IN) : SV_Target
            {
                half4 col = tex2D(_BaseMap, IN.uv) * _BaseColor;
                col.a = 0.9;
                return col;
            }
            ENDHLSL
        }
    }
}