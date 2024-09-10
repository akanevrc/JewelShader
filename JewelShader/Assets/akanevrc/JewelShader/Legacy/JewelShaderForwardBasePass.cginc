#ifndef TANA_GH_JEWEL_LEGACY_FORWARD_BASE_PASS_INCLUDED
#define TANA_GH_JEWEL_LEGACY_FORWARD_BASE_PASS_INCLUDED

#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float3 normalOS : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 viewDirWS : TEXCOORD2;
    float3 centerWS : TEXCOORD3;
    UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert(appdata v)
{
    v2f o = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.positionWS = mul(unity_ObjectToWorld, float4(v.vertex.xyz / v.vertex.w, 1));
    o.normalWS = UnityObjectToWorldNormal(v.normalOS);
    o.viewDirWS = normalize(UnityWorldSpaceViewDir(o.positionWS.xyz));
    o.centerWS = mul(unity_ObjectToWorld, float4(_Centroid.xyz / _Centroid.w, 1));
    UNITY_TRANSFER_FOG(o, o.vertex);
    return o;
}

float3 boxProjection(float3 dir, float3 worldPos, float4 probePos, float3 boxMin, float3 boxMax)
{
#if UNITY_SPECCUBE_BOX_PROJECTION
    if (probePos.w > 0)
    {
        float3 magnitudes = ((dir > 0 ? boxMax : boxMin) - worldPos) / dir;
        float magnitude = min(min(magnitudes.x, magnitudes.y), magnitudes.z);
        dir = dir * magnitude + (worldPos - probePos);
    }
#endif
    return dir;
}

half4 probeColor(float3 dir, float3 pos)
{
    half3 dirProbe0 = boxProjection(dir, pos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    half3 dirProbe1 = boxProjection(dir, pos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

    half4 colProbe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, dirProbe0, 0);
    colProbe0.rgb = DecodeHDR(colProbe0, unity_SpecCube0_HDR);

    half4 colProbe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, dirProbe1, 0);
    colProbe1.rgb = DecodeHDR(colProbe1, unity_SpecCube1_HDR);

    return lerp(colProbe1, colProbe0, unity_SpecCube0_BoxMin.w);
}

#define DECL_APPLY_LIGHT(i)\
half4 applyLight_##i(half4 color, float3 dir, half lightReflection)\
{\
    half3 lightColor = pow(saturate(dot(dir, _LightDir_##i.xyz)), _LightPower_##i) * _LightIntensity_##i.xyz * lightReflection * _LightWeight_##i;\
    return half4(max(color.xyz * color.w * (1 + lightColor * _LightMultiFactor_##i) + lightColor * (1 - _LightMultiFactor_##i), half3(0, 0, 0)), 1);\
}

DECL_APPLY_LIGHT(1)
DECL_APPLY_LIGHT(2)
DECL_APPLY_LIGHT(3)
DECL_APPLY_LIGHT(4)

half fresnel(float3 dirIn, float3 normal, half refractive)
{
    half f0 = pow((refractive - 1) / (refractive + 1), 2);
    return f0 + (1 - f0) * pow(1 - dot(-dirIn, normal), 5);
}

float3 refractDir(float3 dirIn, float3 normal, half invRefractive)
{
    float cosView = dot(-dirIn, normal);
    float sinIn = sqrt(saturate(1 - pow(cosView, 2))) * invRefractive;
    float cosIn = sqrt(saturate(1 - pow(sinIn  , 2)));
    float3 dir = (cosView * normal + dirIn) * invRefractive - cosIn * normal;
    return dot(dir, dir) < 0.000001 ? float3(0, 0, 0) : normalize(dir);
}

half4 iterate
(
    float3 posIn,
    float3 dirIn,
    half refractive,
    float3 center,
    out float3 posRef,
    out float3 dirRef,
    inout half fr,
    inout float len,
    bool isFinal
)
{
    float3 c = center - posIn;
    float3 cRef = normalize(dot(c, dirIn) * 2 * dirIn - c);
    half4 tex = UNITY_SAMPLE_TEXCUBE_LOD(_NormalCube, mul(unity_WorldToObject, cRef), 0);
    float3 n = normalize(-mul(unity_ObjectToWorld, float4((tex.xyz - 0.5) * 2, 1)).xyz);
    float3 dirOut = refractDir(dirIn, n, refractive);

    posRef = center + cRef;
    dirRef = reflect(dirIn, n);
    len = len + distance(posRef, posIn);

    half4 col = length(dirOut) == 0 ? half4(0, 0, 0, 1) : probeColor(dirOut, posIn);
    col = applyLight_1(col, dirOut, 1);
    col = applyLight_2(col, dirOut, 1);
    col = applyLight_3(col, dirOut, 1);
    col = applyLight_4(col, dirOut, 1);
    col = half4(col.xyz * exp(-len * half3(_ColorAttenuationR, _ColorAttenuationG, _ColorAttenuationB)), 1);

    half tmpfr = fr;
    fr = fr * fresnel(dirIn, n, 1 / refractive);
    return half4(col.xyz * (isFinal ? tmpfr : max(tmpfr - fr, 0)), col.w);
}

float4 iterateAll
(
    float3 posIn,
    float3 dirIn,
    half refractive,
    float3 center,
    half fr
)
{
    float3 posRef, dirRef;
    half4 ite, col = half4(0, 0, 0, 0);
    float len = 0;
    for (uint j = 0; j < _ReflectionCount; j++)
    {
        ite = iterate(posIn, dirIn, refractive, center, posRef, dirRef, fr, len, false);
        col = half4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
        posIn = posRef;
        dirIn = dirRef;
    }
    ite = iterate(posIn, dirIn, refractive, center, posRef, dirRef, fr, len, true);
    return half4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
}

fixed4 frag(v2f i) : SV_Target
{
    float3 posIn = i.positionWS;

#ifdef _SPECTROSCOPY_NONE
    float3 dirIn = refractDir(-i.viewDirWS, i.normalWS, 1 / _Refractive);
#elif _SPECTROSCOPY_RGB
    float3 dirInR = refractDir(-i.viewDirWS, i.normalWS, 1 / (_Refractive * _SpectrumRefractiveR));
    float3 dirInG = refractDir(-i.viewDirWS, i.normalWS, 1 / (_Refractive * _SpectrumRefractiveG));
    float3 dirInB = refractDir(-i.viewDirWS, i.normalWS, 1 / (_Refractive * _SpectrumRefractiveB));
#endif

    half fr = 1 - fresnel(-i.viewDirWS, i.normalWS, _Refractive);
    float3 dirOut = reflect(-i.viewDirWS, i.normalWS);
    half4 color = probeColor(dirOut, posIn);
    color = half4(color.xyz * (1 - fr), color.w);
    color = applyLight_1(color, dirOut, _LightReflection_1);
    color = applyLight_2(color, dirOut, _LightReflection_2);
    color = applyLight_3(color, dirOut, _LightReflection_3);
    color = applyLight_4(color, dirOut, _LightReflection_4);

#ifdef _SPECTROSCOPY_NONE
    half4 w = iterateAll(posIn, dirIn, _Refractive, i.centerWS, fr);
    color = half4(color.xyz * color.w + w.xyz * w.w, 1 - (1 - color.w) * (1 - w.w));
#elif _SPECTROSCOPY_RGB
    half4 r = iterateAll(posIn, dirInR, _Refractive * _SpectrumRefractiveR, i.centerWS, fr);
    half4 g = iterateAll(posIn, dirInG, _Refractive * _SpectrumRefractiveG, i.centerWS, fr);
    half4 b = iterateAll(posIn, dirInB, _Refractive * _SpectrumRefractiveB, i.centerWS, fr);
    color =
        half4
        (
            color.x * color.w + r.x * r.w,
            color.y * color.w + g.y * g.w,
            color.z * color.w + b.z * b.w,
            1 - (1 - color.w) * (1 - r.w) * (1 - g.w) * (1 - b.w)
        );
#endif

    UNITY_APPLY_FOG(i.fogCoord, color);
    color.a = 1;
    return color;
}

#endif // TANA_GH_JEWEL_LEGACY_FORWARD_PASS_INCLUDED
