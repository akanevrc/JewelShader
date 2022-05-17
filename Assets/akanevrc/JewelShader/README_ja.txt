茜式宝石シェーダー（akanevrc_JewelShader）


本製品はUnityのBuilt-inレンダリングパイプライン用シェーダーです。
3Dモデルは付属していません。
VRChatのWindows版での使用に対応しています。


【注意！】
本シェーダーを正常に適用できるメッシュには条件があります。
1. 凸包であること
2. 原点(0, 0, 0)を内包すること

また、本シェーダーはReflection Probe（またはSkybox）を参照するため、
Reflection Probeに映らないオブジェクトは透過されません。


【販売】
URL：https://akanezoranomukou.booth.pm/
販売者：茜（akanevrc）

【作者】
茜（akanevrc）

【検証環境】
Unity 2019.4.31f1

【必須要件】
Windows版 VRChat
（Oculus/Meta Quest版は非対応です！ ご注意ください！）

【利用規約】
同梱の「TermsOfUse_ja.pdf」または「TermsOfUse_en.pdf」を参照してください。
本製品の購入または使用により、本規約に同意したものとみなします。


【概要】
茜式宝石シェーダーは、透明な物質の屈折と反射を再現するシェーダーです。
法線情報をキューブマップにベイクすることで、レイを使わずに1パスで描画できるので高速です。
ハードエッジ、ソフトエッジの両方に対応しています。
補助的な光源で輝かせることができます。
材質の色を指定することができます。
プリズムのような分光を再現することができます。
フォトリアリスティックな見た目になるので、小さいオブジェクトよりも大きいオブジェクトに向いています。


【使用方法】
本シェーダーは、法線情報をキューブマップにベイクし、
マテリアルにそのキューブマップを設定することで正しく動作します。
その手順を説明します。

1. 以下のパスにあるPrefabをシーンに置く。
  Assets/akanevrc/JewelShader/CubemapBaker/CubemapBaker.prefab
2. 以下の入力欄に、シェーダーを適用する予定のメッシュを含むPrefab/GameObjectを設定する。
  「Target mesh Prefab/GameObject」（処理対象のメッシュを含むPrefab/GameObject）
3. 「Bake」（ベイク）ボタンをクリックし、キューブマップの保存先を指定すると、
  キューブマップがPNGファイルとして保存される。
4. 新規マテリアルを作成し、シェーダーを「akanevrc_JewelShader/Jewel」にする。
5. 「Normal Cubemap」（法線キューブマップ）に先ほどのキューブマップを設定する。
6. マテリアルを先ほどのメッシュに適用する。


【CubemapBaker】
マテリアルに使用するキューブマップをベイクするためのスクリプトです。
以下のPrefabをシーンに配置することで使用できます。
  Assets/akanevrc/JewelShader/CubemapBaker/CubemapBaker.prefab

右上の「日本語」（English）ボタンで英語/日本語の切り替えができます。
以下に設定項目を説明します。

「Target mesh Prefab/GameObject」（処理対象のメッシュを含むPrefab/GameObject）
ここに指定したメッシュの法線情報をキューブマップにベイクします。
基本的に、マテリアルを適用する予定のメッシュを指定してください。
前述の通り、このメッシュは条件にあったものにしてください。
（条件に合わなくてもエラーは出ないので、適用自体はできます）
1. 凸包であること
2. 原点(0, 0, 0)を内包すること

「Baked cubemap width」（ベイクされるキューブマップのサイズ）
キューブマップの1面のピクセル幅を指定します。

「Bake」（ベイク）ボタン
設定に従ってキューブマップをベイクします。
クリックするとファイル保存ダイアログが表示されますので、
保存先ファイル名を指定してください。


【akanevrc_JewelShader/Jewel】
宝石のように見えるシェーダーです。
マテリアルに設定することで使用できます。

右上の「日本語」（English）ボタンで英語/日本語の切り替えができます。
以下に設定項目を説明します。

「Normal Cubemap」（法線キューブマップ）
CubemapBakerでベイクしたキューブマップを指定します。

「Refractive Index」（屈折率）
物体の相対屈折率を指定します。

「Light Direction」（光源の向き）
補助的な光源（Directional Light）の向きを指定します。

「Light Power Value」（光源の累乗値）
光源に累乗する値を指定します。
小さいほど範囲が広くなります。

「Light Reflection Ratio」（光源の反射率）
光源の光が物体表面で反射する反射率を指定します。

「Light Color (Intensity)」（光源の色（強さ））
光源の光の強さです。
HDRカラーで指定します。
この光源は明所では明るく、暗所では暗くなることに注意してください。

「Color Attenuation R」（赤の減衰）
「Color Attenuation G」（緑の減衰）
「Color Attenuation B」（青の減衰）
物体の色です。
赤の減衰を強くするとシアンになります。
緑の減衰を強くするとマゼンタになります。
青の減衰を強くするとイエローになります。

「Spectorscopy」（分光）
Noneを指定すると分光しません。
RGBを指定するとプリズムのように分光します。

「Spectrum Refractive Ratio R」（赤の屈折比率）
「Spectrum Refractive Ratio G」（緑の屈折比率）
「Spectrum Refractive Ratio B」（青の屈折比率）
上で指定した屈折率に乗算する値です。
この値を適切にばらけさせることで、分光を表現します。


【更新履歴】
1.0.0 (2022/05/16)
基本機能を実装しました。


【連絡先】
茜
Twitter： @akanevrc
Mail： akanezoranomukou@gmail.com
