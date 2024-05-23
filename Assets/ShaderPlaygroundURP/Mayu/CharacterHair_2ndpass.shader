Shader "Character/Hair_2ndpass"
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
            // パスの用途はLightModeで指定
            // 他にはShadowCasterやDepthOnlyなどがある
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
                half3 viewWS : VIEW_WS;
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
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewWS = normalize(GetWorldSpaceViewDir(positionWS));
                return OUT;
            }

            // HLSLPROGRAMの場合、fixed4は使えない
            half4 frag(Varyings IN) : SV_Target
            {
                half4 col = tex2D(_BaseMap, IN.uv) * _BaseColor;
                half3 forward = half3(0, 0, 1);// UNITY_MATRIX_M._m02_m12_m22;
                col.a = 1 - clamp(dot(forward, IN.viewWS), 0, 1);
                return col;
            }
            ENDHLSL
        }
    }
}