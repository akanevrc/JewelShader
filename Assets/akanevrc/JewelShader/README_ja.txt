茜式宝石シェーダー（akanevrc_JewelShader）


本製品はUnityのBuilt-inレンダリングパイプライン用シェーダーです。
3Dモデルは付属していません。
VRChatのWindows版での使用に対応しています。
（VRChat以外の用途にも全く問題なく使用できます）


【注意！】
本シェーダーを正常に適用できるメッシュには条件があります。
条件：指定した中心座標を原点とする極座標系においてメッシュが連続であること

また、本シェーダーはReflection Probe（またはSkybox）を参照するため、
Reflection Probeに映らないオブジェクトは透過されません。


【販売】
URL：https://akanezoranomukou.booth.pm/
販売者：茜（akanevrc）

【作者】
茜（akanevrc）

【検証環境】
Unity 2019.4.31f1

【VRChat要件】
Windows版 VRChat
（Oculus/Meta Quest版は非対応です！ ご注意ください！）

【利用規約】
同梱の「TermsOfUse_○○License_ja.pdf」または「TermsOfUse_○○License_en.pdf」を参照してください。
本製品の購入または使用により、本規約に同意したものとみなします。
ライセンスに関する簡易的な説明は、「README_about_licenses_ja.txt」または「README_about_licenses_en.txt」を参照してください。


【概要】
茜式宝石シェーダーは、透明な物質の屈折と反射を再現するシェーダーです。
法線情報をキューブマップにベイクすることで、レイを使わずに1パスで描画できるので非常に高速です。
ハードエッジ、ソフトエッジの両方に対応しています。
補助的な光源で輝かせることができます。
材質の色を指定することができます。
プリズムのような分光を再現することができます。
フォトリアリスティックな見た目になるので、小さいオブジェクトよりも大きいオブジェクトに向いています。


【使用方法】
本シェーダーは、法線情報をキューブマップにベイクし、
生成されたマテリアルを対象のメッシュに適用することで正しく動作します。
その手順を説明します。

1. 以下のパスにあるPrefabをシーンに置く。
  Assets/akanevrc/JewelShader/CubemapBaker/CubemapBaker.prefab
2. 以下の入力欄に、シェーダーを適用する予定のメッシュを含むPrefab/GameObjectを設定する。
  「Target mesh Prefab/GameObject」（処理対象のメッシュを含むPrefab/GameObject）
3. 「Bake」（ベイク）ボタンをクリックし、キューブマップの保存先とマテリアルの保存先を指定すると、
  PNG形式のキューブマップと、それを適用済みのマテリアルが保存される。
4. マテリアルを先ほどのメッシュに適用する。


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
条件：指定した中心座標を原点とする極座標系においてメッシュが連続であること

「Specify centroid manually」（中心座標を手動で指定）
チェック無しの状態では、中心座標をメッシュ情報から自動算出します。
チェック有りの状態では、中心座標を任意の値に指定できます。

「Centroid position」（中心座標）
中心座標を手動で指定するチェック有りの場合に、中心座標を指定します。

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
この項目は、CubemapBakerがベイク時に自動で設定します。

「Centroid Position」（中心座標）
法線ベイクの中心座標です。
この項目は、CubemapBakerがベイク時に自動で設定します。

「Refractive Index」（屈折率）
物体の屈折率を指定します。
目安として、1.3なら氷、1.5ならガラス、1.7ならサファイア、2.4ならダイヤです。

「Light Source 1 - 4」（光源 1～4）
補助的な光源（Directional Light）です。
矢印をクリックして展開し、下記のパラメータを設定できます。

    「Direction」（向き）
    光源の向きを指定します。

    「Power Value」（累乗値）
    光源に累乗する値を指定します。
    小さいほど範囲が広くなります。

    「Reflection Ratio」（反射率）
    光源の光が物体表面で反射する反射率を指定します。

    「Color (Intensity)」（色（強さ））
    光源の光の強さです。
    HDRカラーで指定します。

    「Multiplication Factor」（乗算係数）
    光源の影響の仕方が加算的か乗算的かを決定する係数です。
    この値が大きいと、明所では明るく、暗所では暗くなります。
    この値が小さいと、明所でも暗所でも明るくなります。

    「Weight Factor」（重み係数）
    光源の明るさに乗じる係数です。
    1なら明るい光となります。
    0なら光源は無効化されます。
    -1なら照らされた部分が暗くなる光となります。

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
1.1.0 (2022/05/20)
光源の機能と個数を追加しました。
シェーダープロパティの初期値を変更しました。

1.0.0 (2022/05/16)
基本機能を実装しました。


【連絡先】
茜
Twitter： @akanevrc
Mail： akanezoranomukou@gmail.com
