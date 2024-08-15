# Unity ShaderPlaygroundURP

[WebGL Demo](https://gam0022.net/ShaderPlaygroundURP/)

## InkShader

[![ink-shader.gif](imgs/ink-shader.gif)](imgs/ink-shader.gif)

[![ink-shader-color.gif](imgs/ink-shader-color.gif)](imgs/ink-shader-color.gif)

[![ink-shader-threshold.gif](imgs/ink-shader-threshold.gif)](imgs/ink-shader-threshold.gif)

- シーン
    - [Assets/ShaderPlaygroundURP/InkShader/InkNoise.unity](https://github.com/gam0022/ShaderPlaygroundURP/blob/main/Assets/ShaderPlaygroundURP/InkShader/InkNoise.unity)
- 解説記事
    - [UnityのShaderGraphでインクシェーダーを作る | gam0022.net](https://gam0022.net/blog/2022/12/25/unity-ink-shader/)

## Mayu Shader

[![mayu.gif](imgs/mayu.gif)](imgs/mayu.gif)

学園アイドルマスターの眉毛シェーダー（正面から見ると眉毛が前髪より手前に、横顔に近づくと眉毛がフェードアウトする処理）を再現する試みです。

- シーン
    - [Assets/ShaderPlaygroundURP/Mayu/MayuDepthOffset.unity](https://github.com/gam0022/ShaderPlaygroundURP/blob/main/Assets/ShaderPlaygroundURP/Mayu/MayuDepthOffset.unity)
- 解説記事
    - [学園アイドルマスターの眉毛のShaderをUnityで再現してみた | gam0022.net](https://gam0022.net/blog/2024/05/29/gakumasu-mayuge-shader/)

UnityちゃんシリーズのSDトーコちゃんの3Dモデルを使わせていただきました。

## LTC（Linearly Transformed Cosines）によるエリアライト

Eric HeitzさんがSIGGRAPH 2016で発表したエリアライトをリアルタイムに計算する手法をURP上で実装しました。

[![LTC_roughness.gif](imgs/LTC_roughness.gif)](imgs/LTC_roughness.gif)

[![LTC_scale_x.gif](imgs/LTC_scale_x.gif)](imgs/LTC_scale_x.gif)

[![LTC_rotate_y.gif](imgs/LTC_rotate_y.gif)](imgs/LTC_rotate_y.gif)

[![LTC_rotate_x.gif](imgs/LTC_rotate_x.gif)](imgs/LTC_rotate_x.gif)

- 論文著者のページ
  - [Real-Time Polygonal-Light Shading with Linearly Transformed Cosines | Eric Heitz's Research Page](https://eheitzresearch.wordpress.com/415-2/)
- 解説スライド
  - [LTC（Linearly Transformed Cosines）によるエリアライトのUnity URP実装 | ゆるゆるシェーダー交流会](https://docs.google.com/presentation/d/1OAey5wGU7BIKw7YOpILKz-Ymqv-jysgFeWpvJVVdXm0/edit?usp=sharing)

# License

ソースコードはMITライセンスとしますが、アセットについてはプロジェクトファイル内にあるLicenseファイルにしたがってください。

- Unity Chan: © Unity Technologies Japan/UCL

シェーダーやソースコードを参考にした場合は、必ずクレジットをお願いします。