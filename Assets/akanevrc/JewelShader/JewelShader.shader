Shader "JewelShader/Jewel"
{
    Properties
    {
        _NormalCube          ("Normal Cubemap"  , Cube            ) = "bump" {}
        _Refractive          ("Refractive Index", Range(1, 5)     ) = 1
        _LightDir            ("Light Direction" , Vector          ) = (0, 1, 0, 1)
        _LightPower          ("Light Power"     , Range(0.01, 100)) = 10
        _LightReflection     ("Light Reflection", Range(0, 1)     ) = 0.01
        [HDR] _LightIntensity("Light Color"     , Color           ) = (20, 20, 20, 1)

        _ColorAttenuationR("Color Attenuation R", Range(0, 1)) = 0
        _ColorAttenuationG("Color Attenuation G", Range(0, 1)) = 0
        _ColorAttenuationB("Color Attenuation B", Range(0, 1)) = 0

        [KeywordEnum(None, RGB)] _Spectroscopy("Spectroscopy", Float) = 0
        _SpectrumRefractiveR("_Spectrum Refractive R", Range(1, 2)) = 1
        _SpectrumRefractiveG("_Spectrum Refractive G", Range(1, 2)) = 1.04
        _SpectrumRefractiveB("_Spectrum Refractive B", Range(1, 2)) = 1.08

        [HideInInspector] _Centroid       ("Centroid Position", Vector) = (0, 0, 0, 1)
        [HideInInspector] _ReflectionCount("Reflection Count" , Int   ) = 2

        [HideInInspector] _MainTex("Main Texture", 2D   ) = "white" {}
        [HideInInspector] _Color  ("Color"       , Color) = (1, 1, 1, 0.5)
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" "VRCFallback"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _SPECTROSCOPY_NONE _SPECTROSCOPY_RGB

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float3 normal   : NORMAL;
                float3 worldPos : TEXCOORD0;
                float3 viewDir  : TEXCOORD1;
                float3 center   : TEXCOORD2;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_TEXCUBE(_NormalCube);
            float  _Refractive;
            float4 _LightDir;
            float  _LightPower;
            float  _LightReflection;
            float4 _LightIntensity;
            float  _ColorAttenuationR;
            float  _ColorAttenuationG;
            float  _ColorAttenuationB;
            float  _SpectrumRefractiveR;
            float  _SpectrumRefractiveG;
            float  _SpectrumRefractiveB;
            float4 _Centroid;
            int    _ReflectionCount;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex   = UnityObjectToClipPos(v.vertex);
                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz / v.vertex.w, 1));
                o.viewDir  = normalize(UnityWorldSpaceViewDir(o.worldPos.xyz));
                o.center   = mul(unity_ObjectToWorld, _Centroid);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float3 boxProjection(float3 dir, float3 worldPos, float4 probePos, float3 boxMin, float3 boxMax)
            {
#if UNITY_SPECCUBE_BOX_PROJECTION
                if (probePos.w > 0) {
                    float3 magnitudes = ((dir > 0 ? boxMax : boxMin) - worldPos) / dir;
                    float  magnitude  = min(min(magnitudes.x, magnitudes.y), magnitudes.z);
                    dir = dir * magnitude + (worldPos - probePos);
                }
#endif
                return dir;
            }

            float4 probeColor(float3 dir, float3 pos)
            {
                half3 dirProbe0 = boxProjection(dir, pos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                half3 dirProbe1 = boxProjection(dir, pos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

                half4 colProbe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, dirProbe0, 0);
                colProbe0.rgb = DecodeHDR(colProbe0, unity_SpecCube0_HDR);

                half4 colProbe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, dirProbe1, 0);
                colProbe1.rgb = DecodeHDR(colProbe1, unity_SpecCube1_HDR);

                return lerp(colProbe1, colProbe0, unity_SpecCube0_BoxMin.w);
            }

            float4 light(float3 dir, float3 lightDir)
            {
                return float4(pow(saturate(dot(dir, lightDir)), _LightPower) * _LightIntensity.xyz, 1);
            }

            float fresnel(float3 dirIn, float3 normal, float refractive)
            {
                float f0 = pow((refractive - 1) / (refractive + 1), 2);
                return f0 + (1 - f0) * pow(1 - dot(-dirIn, normal), 5);
            }

            float3 refractDir(float3 dirIn, float3 normal, float invRefractive)
            {
                float cosView = dot(-dirIn, normal);
                float sinIn   = sqrt(saturate(1 - pow(cosView, 2))) * invRefractive;
                float cosIn   = sqrt(saturate(1 - pow(sinIn  , 2)));
                return normalize((cosView * normal + dirIn) * invRefractive - cosIn * normal);
            }

            float4 iterate
            (
                float3 posIn,
                float3 dirIn,
                float3 refractive,
                float3 center,
                float3 lightDir,
                out float3 posRef,
                out float3 dirRef,
                inout float fr,
                inout float len,
                bool isFinal
            )
            {
                float3 c      = center - posIn;
                float3 cRef   = normalize(dot(c, dirIn) * 2 * dirIn - c);
                fixed4 tex    = UNITY_SAMPLE_TEXCUBE_LOD(_NormalCube, mul(unity_WorldToObject, cRef), 0);
                float3 n      = -normalize(mul(unity_ObjectToWorld, (float3(tex.xyz) - 0.5) * 2));
                float3 dirOut = refractDir(dirIn, n, refractive);

                posRef = center + cRef;
                dirRef = reflect(dirIn, n);
                len    = len + distance(posRef, posIn);

                float4 col = length(dirOut) == 0 ? float4(0, 0, 0, 0) : probeColor(dirOut, posIn);
                col = float4(col.xyz * col.w + light(dirOut, lightDir).xyz, 1);
                col = float4(col.xyz * float3(exp(-len * _ColorAttenuationR), exp(-len * _ColorAttenuationG), exp(-len * _ColorAttenuationB)), 1);

                float tmpfr = fr;
                fr = fr * fresnel(dirIn, n, 1 / refractive);
                return float4(col.xyz * (isFinal ? tmpfr : tmpfr - fr), col.w);
            }

            float4 iterateAll
            (
                float3 posIn,
                float3 dirIn,
                float3 refractive,
                float3 center,
                float3 lightDir,
                float  fr
            )
            {
                float3 posRef, dirRef;
                float4 ite, col = float4(0, 0, 0, 0);
                float  len = 0;
                int    j;
                for (j = 0; j < _ReflectionCount; ++j)
                {
                    ite   = iterate(posIn, dirIn, refractive, center, lightDir, posRef, dirRef, fr, len, false);
                    col   = float4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
                    posIn = posRef;
                    dirIn = dirRef;
                }
                ite = iterate(posIn, dirIn, refractive, center, lightDir, posRef, dirRef, fr, len, true);
                return float4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 posIn    = i.worldPos;
                float3 lightDir = normalize(_LightDir.xyz);

#ifdef _SPECTROSCOPY_NONE
                float3 dirIn = refractDir(-i.viewDir, i.normal, 1 / _Refractive);
#elif _SPECTROSCOPY_RGB
                float3 dirInR = refractDir(-i.viewDir, i.normal, 1 / (_Refractive * _SpectrumRefractiveR));
                float3 dirInG = refractDir(-i.viewDir, i.normal, 1 / (_Refractive * _SpectrumRefractiveG));
                float3 dirInB = refractDir(-i.viewDir, i.normal, 1 / (_Refractive * _SpectrumRefractiveB));
#endif

                float  fr     = 1 - fresnel(-i.viewDir, i.normal, _Refractive);
                float3 dirOut = reflect(-i.viewDir, i.normal);
                float4 col    = probeColor(dirOut, posIn);
                col = float4(col.xyz * (1 - fr), col.w);
                col = float4(col.xyz * col.w + light(dirOut, lightDir).xyz * _LightReflection, 1);

#ifdef _SPECTROSCOPY_NONE
                float4 w = iterateAll(posIn, dirIn, _Refractive, i.center, lightDir, fr);
                col = float4(col.xyz * col.w + w.xyz * w.w, 1 - (1 - col.w) * (1 - w.w));
#elif _SPECTROSCOPY_RGB
                float4 r = iterateAll(posIn, dirInR, _Refractive * _SpectrumRefractiveR, i.center, lightDir, fr);
                float4 g = iterateAll(posIn, dirInG, _Refractive * _SpectrumRefractiveG, i.center, lightDir, fr);
                float4 b = iterateAll(posIn, dirInB, _Refractive * _SpectrumRefractiveB, i.center, lightDir, fr);
                col = float4
                (
                    col.x * col.w + r.x * r.w,
                    col.y * col.w + g.y * g.w,
                    col.z * col.w + b.z * b.w,
                    1 - (1 - col.w) * (1 - r.w) * (1 - g.w) * (1 - b.w)
                );
#endif

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
    Fallback "Legacy Shaders/Transparent/Diffuse"
}
