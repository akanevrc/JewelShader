#ifndef TANA_GH_JEWEL_UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define TANA_GH_JEWEL_UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#if defined(LOD_FADE_CROSSFADE)
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 staticLightmapUV : TEXCOORD1;
    float2 dynamicLightmapUV : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 viewDirWS : TEXCOORD2;
    float3 centerWS : TEXCOORD3;

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight : TEXCOORD4; // x: fogFactor, yzw: vertex light
#else
    half fogFactor : TEXCOORD4;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD5;
#endif

    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 6);
#ifdef DYNAMICLIGHTMAP_ON
    float2 dynamicLightmapUV : TEXCOORD7;
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

inline void InitializeSurfaceData(out SurfaceData outSurfaceData)
{
    outSurfaceData.alpha = 1.0;
    outSurfaceData.albedo = half3(1.0, 1.0, 1.0);
    outSurfaceData.metallic = 1;
    outSurfaceData.specular = half3(1.0, 1.0, 1.0);
    outSurfaceData.smoothness = 1;
    outSurfaceData.normalTS = half3(0.0, 0.0, 1.0);
    outSurfaceData.occlusion = 1.0;
    outSurfaceData.emission = half3(0.0, 0.0, 0.0);
    outSurfaceData.clearCoatMask = 0.0;
    outSurfaceData.clearCoatSmoothness = 1.0;
}

inline void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(input.normalWS);
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#else
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

#if defined(DEBUG_DISPLAY)
#if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
#endif
#if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
#else
    inputData.vertexSH = input.vertexSH;
#endif
#endif
}

Varyings vert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.normalWS = NormalizeNormalPerPixel(normalInput.normalWS);
    output.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    output.centerWS = mul(unity_ObjectToWorld, float4(_Centroid.xyz / _Centroid.w, 1)).xyz;
    output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
#ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    return output;
}

half4 GIColor(float3 dir, float3 pos, InputData inputData, SurfaceData surfaceData)
{
    inputData.positionWS = pos;
    inputData.normalWS = dir;
    inputData.viewDirectionWS = dir;

    bool specularHighlightsOff = false;

    BRDFData brdfData;
    InitializeBRDFData(surfaceData, brdfData);

#if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
#endif

    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    lightingData.giColor =
        GlobalIllumination
        (
            brdfData,
            brdfDataClearCoat,
            surfaceData.clearCoatMask,
            inputData.bakedGI,
            aoFactor.indirectAmbientOcclusion,
            inputData.positionWS,
            inputData.normalWS,
            inputData.viewDirectionWS,
            inputData.normalizedScreenSpaceUV
        );
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor =
            LightingPhysicallyBased
            (
                brdfData,
                brdfDataClearCoat,
                mainLight,
                inputData.normalWS,
                inputData.viewDirectionWS,
                surfaceData.clearCoatMask,
                specularHighlightsOff
            );
    }

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor +=
                LightingPhysicallyBased
                (
                    brdfData,
                    brdfDataClearCoat,
                    light,
                    inputData.normalWS,
                    inputData.viewDirectionWS,
                    surfaceData.clearCoatMask,
                    specularHighlightsOff
                );
        }
    }
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor +=
                LightingPhysicallyBased
                (
                    brdfData,
                    brdfDataClearCoat,
                    light,
                    inputData.normalWS,
                    inputData.viewDirectionWS,
                    surfaceData.clearCoatMask,
                    specularHighlightsOff
                );
        }
    LIGHT_LOOP_END
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
#endif

#if REAL_IS_HALF
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
#else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
#endif
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
    InputData inputData,
    SurfaceData surfaceData,
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
    half4 tex = _NormalCube.Sample(sampler_NormalCube, mul(unity_WorldToObject, float4(cRef, 1)).xyz);
    float3 n = normalize(-mul(unity_ObjectToWorld, float4((tex.xyz - 0.5) * 2, 1)).xyz);
    float3 dirOut = refractDir(dirIn, n, refractive);

    posRef = center + cRef;
    dirRef = reflect(dirIn, n);
    len = len + distance(posRef, posIn);

    half4 col = length(dirOut) == 0 ? half4(0, 0, 0, 1) : GIColor(dirOut, posIn, inputData, surfaceData);
    col = applyLight_1(col, dirOut, 1);
    col = applyLight_2(col, dirOut, 1);
    col = applyLight_3(col, dirOut, 1);
    col = applyLight_4(col, dirOut, 1);
    col = half4(col.xyz * exp(-len * half3(_ColorAttenuationR, _ColorAttenuationG, _ColorAttenuationB)), 1);

    half tmpfr = fr;
    fr = fr * fresnel(dirIn, n, 1 / refractive);
    return half4(col.xyz * (isFinal ? tmpfr : max(tmpfr - fr, 0)), col.w);
}

half4 iterateAll
(
    InputData inputData,
    SurfaceData surfaceData,
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
        ite = iterate(inputData, surfaceData, posIn, dirIn, refractive, center, posRef, dirRef, fr, len, false);
        col = half4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
        posIn = posRef;
        dirIn = dirRef;
    }
    ite = iterate(inputData, surfaceData, posIn, dirIn, refractive, center, posRef, dirRef, fr, len, true);
    return half4(col.xyz * col.w + ite.xyz * ite.w, 1 - (1 - col.w) * (1 - ite.w));
}

void frag
(
    Varyings input,
    out half4 outColor : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
#endif
)
{
    SurfaceData surfaceData;
    InitializeSurfaceData(surfaceData);

#ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
#endif

    InputData inputData;
    InitializeInputData(input, half3(0, 0, 1), inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

#ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
#endif

    float3 posIn = input.positionWS;

#ifdef _SPECTROSCOPY_NONE
    float3 dirIn = refractDir(-input.viewDirWS, input.normalWS, 1 / _Refractive);
#elif _SPECTROSCOPY_RGB
    float3 dirInR = refractDir(-input.viewDirWS, input.normalWS, 1 / (_Refractive * _SpectrumRefractiveR));
    float3 dirInG = refractDir(-input.viewDirWS, input.normalWS, 1 / (_Refractive * _SpectrumRefractiveG));
    float3 dirInB = refractDir(-input.viewDirWS, input.normalWS, 1 / (_Refractive * _SpectrumRefractiveB));
#endif

    half fr = 1 - fresnel(-input.viewDirWS, input.normalWS, _Refractive);
    float3 dirOut = reflect(-input.viewDirWS, input.normalWS);
    half4 color = GIColor(dirOut, posIn, inputData, surfaceData);
    color = half4(color.xyz * (1 - fr), color.w);
    color = applyLight_1(color, dirOut, _LightReflection_1);
    color = applyLight_2(color, dirOut, _LightReflection_2);
    color = applyLight_3(color, dirOut, _LightReflection_3);
    color = applyLight_4(color, dirOut, _LightReflection_4);

#ifdef _SPECTROSCOPY_NONE
    half4 w = iterateAll(inputData, surfaceData, posIn, dirIn, _Refractive, input.centerWS, fr);
    color = half4(color.xyz * color.w + w.xyz * w.w, 1 - (1 - color.w) * (1 - w.w));
#elif _SPECTROSCOPY_RGB
    half4 r = iterateAll(inputData, surfaceData, posIn, dirInR, _Refractive * _SpectrumRefractiveR, input.centerWS, fr);
    half4 g = iterateAll(inputData, surfaceData, posIn, dirInG, _Refractive * _SpectrumRefractiveG, input.centerWS, fr);
    half4 b = iterateAll(inputData, surfaceData, posIn, dirInB, _Refractive * _SpectrumRefractiveB, input.centerWS, fr);
    color =
        half4
        (
            color.x * color.w + r.x * r.w,
            color.y * color.w + g.y * g.w,
            color.z * color.w + b.z * b.w,
            1 - (1 - color.w) * (1 - r.w) * (1 - g.w) * (1 - b.w)
        );
#endif

    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = 1;

    outColor = color;

#ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
#endif
}

#endif // TANA_GH_JEWEL_UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
