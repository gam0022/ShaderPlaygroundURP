Shader "Character/Common/Outline"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)

        _OutlineColor ("Color", color) = (0.2, 0.2, 0.2, 1.0)
        _OutlineWidthBase ("Width Base", float) = 1
        _OutlineCorrectionDistance ("Correction Distance", float) = 0.9
        _OutlineCorrectionRate ("Correction Rate", range(0,1)) = 0.5
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

            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _OutlineColor;
            float _OutlineWidthBase;
            float _OutlineCorrectionDistance;
            float _OutlineCorrectionRate;
            CBUFFER_END

            // アウトラインの幅[m]
            #define _OUTLINE_WIDTH_BASE _OutlineWidthBase * 0.001

            // Z方向の押し込み量[m]
            #define _OUTLINE_SHOVE_BASE 0.0007

            // 任意エッジのアウトラインの幅の比率。0.0〜1.0の範囲で指定
            #define _EDGE_WIDTH_RATE 0.1

            // 近影とみなす距離[m]
            // カメラとの距離がこれ未満ならアウトライン幅を常に一定を保つ
            #define _OUTLINE_CORRECTION_DISTANCE _OutlineCorrectionDistance

            // 遠影（カメラとの距離が _OUTLINE_CORRECTION_DISTANCE 以降）のときの補正率
            //
            // 0.0〜1.0の範囲で指定。大きいほど補正が強い
            //   0.0: 補正が完全に無効になる（遠ざかるほど細くなる）
            //   1.0: 遠ざかってもアウトライン幅を一定に保つ（近影時と完全に同じ補正率を維持する）
            #define _OUTLINE_CORRECTION_RATE _OutlineCorrectionRate

            // 画面奥方向への押し込み計算
            inline void ShoveOutlineDepth(inout float depth, float shoveVal)
            {
                #if defined(UNITY_REVERSED_Z)
                depth -= _OUTLINE_SHOVE_BASE * (1.0 - shoveVal);
                #else
                depth += _OUTLINE_SHOVE_BASE * (1.0 - shoveVal);
                #endif
            }

            // 法線方向によるポリゴンの押し出しによるアウトラインのための頂点計算
            // 距離やFOVに応じた補正あり
            //
            // 頂点カラー
            // ・R: アウトラインの幅
            // ・G: 画面奥方向への押し込み量
            // ・B: 任意エッジへのアウトラインの幅
            float4 OutlineVertexPosition(Attributes v)
            {
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float4 position    = TransformWorldToHClip(positionWS);
                float3 viewNnormal   = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, normalize(v.normalOS)));
                float2 offset = mul((float2x2)UNITY_MATRIX_P, viewNnormal.xy);

                // アウトライン幅の補正スケール（デフォルトでは補正OFF）
                float correction = 1.0;

                if (UNITY_MATRIX_P._m33 == 0.0)
                {
                    // 透視投影時のアウトライン幅の補正

                    // View空間上で距離を計算する
                    // プロジェクション空間は非線形なので、View空間を用いる
                    float3 positionVS = mul(UNITY_MATRIX_V, float4(positionWS, 1.0)).xyz;
                    float distanceCorrection = max(0.0, -positionVS.z);

                    // プロジェクション変換行列の要素を利用してFoVの影響を打ち消す
                    // _m00 = 1 / tan(FoV/2) * H / W
                    // _m11 = 1 / tan(FoV/2)
                    // http://marupeke296.com/DXG_No70_perspective.html

                    // FoV30°を補正なしの基準値にする
                    float tan15 = 0.26794919243;// tan(30/2)

                    // NOTE: iOSなどの一部のプラットフォームでは、UNITY_MATRIX_P._m11 がマイナスになるので、absをつける
                    float fovCorrection = abs(UNITY_MATRIX_P._m11) * tan15;

                    // 画面分割のトリミングでアウトラインが太く見えるので、補正する
                    // float resolutionCorrection = saturate(_RenderTextureResolution.y / _ScreenParams.y);
                    float resolutionCorrection = 1.0;

                    // NOTE: _m11 からFoVを計算すれば、アスペクト比を渡す必要がなくなる
                    // NOTE: fovCorrection = UNITY_MATRIX_P._m11 * tan15;
                    // NOTE: しかし、iPhone上では _m11 から計算すると、アウトラインが表示されなくなることを確認した
                    // TODO: iPhone上の _m11 の値について調査

                    // 距離とFoVを合成したキャラクターとカメラの距離。スクリーン上でどの大きさで見えるかを基準とした値
                    correction = distanceCorrection * resolutionCorrection / fovCorrection;

                    if (correction < _OUTLINE_CORRECTION_DISTANCE)
                    {
                        // 近影時のアウトライン幅の補正
                        correction = correction / _OUTLINE_CORRECTION_DISTANCE;
                    }
                    else
                    {
                        // 遠影時のアウトライン幅の補正
                        correction = correction * _OUTLINE_CORRECTION_RATE / _OUTLINE_CORRECTION_DISTANCE + 1.0 - _OUTLINE_CORRECTION_RATE;
                    }
                }
                else
                {
                    // 平行投影時にはアウトライン幅を0にする（アウトラインを非表示）
                    correction = 0.0;
                }

                // 頂点カラーRで太さ調整する
                position.xy += offset * _OUTLINE_WIDTH_BASE * v.color.r * correction;

                // 頂点カラーのGで押し込み量を調整する
                // ShoveOutlineDepth(position.z, v.color.g);
                ShoveOutlineDepth(position.z, 0.8);

                return position;
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = OutlineVertexPosition(input);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                return tex2D(_BaseMap, input.uv) * _BaseColor * _OutlineColor;
            }
            ENDHLSL
        }
    }
}