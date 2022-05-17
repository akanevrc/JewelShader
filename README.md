# akanevrc_JewelShader

## Abstraction

茜式宝石シェーダーは、透明な物質の屈折と反射を再現するシェーダーです。
法線情報をキューブマップにベイクすることで、レイを使わずに1パスで描画できるので高速です。
ハードエッジ、ソフトエッジの両方に対応しています。
補助的な光源で輝かせることができます。
材質の色を指定することができます。
プリズムのような分光を再現することができます。
フォトリアリスティックな見た目になるので、小さいオブジェクトよりも大きいオブジェクトに向いています。

akanevrc_JewelShader is a shader that reproduces the refraction and reflection of transparent substances.
This shader is fast because draw in 1 pass without using rays by baking normal data to a cubemap.
Both hard edge and soft edge supported.
The color of the object can be specified.
It is possible to reproduce a prism-like spectrum.
It gives a photorealistic look and is better suited for larger objects than smaller ones.
