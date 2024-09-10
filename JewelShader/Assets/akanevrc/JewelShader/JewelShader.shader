Shader "akanevrc_JewelShader/Jewel"
{
    Properties
    {
        [NoScaleOffset] _NormalCube("Normal Cubemap", Cube) = "bump" {}
        _Centroid("Centroid Position", Vector) = (0, 0, 0, 1)
        _Refractive("Refractive Index" , Range(1, 5)) = 2.4

        _LightDir_1("Light 1 Direction", Vector) = (0, 1, 0, 0)
        _LightPower_1("Light 1 Power", Range(0.01, 100)) = 10
        _LightReflection_1("Light 1 Reflection", Range(0, 1)) = 0.01
        [HDR] _LightIntensity_1("Light 1 Color", Color) = (40, 40, 40, 1)
        _LightMultiFactor_1("Light 1 Multiplication Factor", Range(0, 1)) = 0.8
        _LightWeight_1("Light 1 Weight", Range(-1, 1)) = 1

        _LightDir_2("Light 2 Direction", Vector) = (0, 1, 0, 0)
        _LightPower_2("Light 2 Power", Range(0.01, 100)) = 3
        _LightReflection_2("Light 2 Reflection", Range(0, 1)) = 0.01
        [HDR] _LightIntensity_2("Light 2 Color", Color) = (0.8, 0.8, 0.8, 1)
        _LightMultiFactor_2("Light 2 Multiplication Factor", Range(0, 1)) = 0.5
        _LightWeight_2("Light 2 Weight", Range(-1, 1)) = -1

        _LightDir_3("Light 3 Direction", Vector) = (0, -1, 0, 0)
        _LightPower_3("Light 3 Power", Range(0.01, 100)) = 3
        _LightReflection_3("Light 3 Reflection", Range(0, 1)) = 0.01
        [HDR] _LightIntensity_3("Light 3 Color", Color) = (0.8, 0.8, 0.8, 1)
        _LightMultiFactor_3("Light 3 Multiplication Factor", Range(0, 1)) = 0.5
        _LightWeight_3("Light 3 Weight", Range(-1, 1)) = 1

        _LightDir_4("Light 4 Direction", Vector) = (0, 1, 0, 0)
        _LightPower_4("Light 4 Power", Range(0.01, 100)) = 10
        _LightReflection_4("Light 4 Reflection", Range(0, 1)) = 0.01
        [HDR] _LightIntensity_4("Light 4 Color", Color) = (1, 1, 1, 1)
        _LightMultiFactor_4("Light 4 Multiplication Factor", Range(0, 1)) = 0.8
        _LightWeight_4("Light 4 Weight", Range(-1, 1)) = 0

        _ColorAttenuationR("Color Attenuation R", Range(0, 1)) = 0
        _ColorAttenuationG("Color Attenuation G", Range(0, 1)) = 0
        _ColorAttenuationB("Color Attenuation B", Range(0, 1)) = 0

        [KeywordEnum(None, RGB)] _Spectroscopy("Spectroscopy", Float) = 1
        _SpectrumRefractiveR("Spectrum Refractive R", Range(1, 2)) = 1
        _SpectrumRefractiveG("Spectrum Refractive G", Range(1, 2)) = 1.04
        _SpectrumRefractiveB("Spectrum Refractive B", Range(1, 2)) = 1.08

        [HideInInspector] _ReflectionCount("Reflection Count", Int) = 2

        [HideInInspector] _MainTex("Main Texture", 2D) = "white" {}
        [HideInInspector] _Color  ("Color", Color) = (1, 1, 1, 0.5)
    }

    SubShader
    {
        PackageRequirements
        {
             "com.unity.render-pipelines.universal": "10.5.0"
        }    
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer

            #pragma multi_compile _SPECTROSCOPY_NONE _SPECTROSCOPY_RGB

            #include "./URP/JewelShaderInput.hlsl"
            #include "./URP/JewelShaderForwardLitPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma multi_compile_instancing

            #include "./URP/JewelShaderInput.hlsl"
            #include "./URP/JewelShaderShadowCasterPass.hlsl"
            ENDHLSL
        }
    }

    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderType"="Opaque"
            "VRCFallback"="Mobile/Diffuse"
        }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="ForwardBase"
            }
            Cull Back

            CGPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog

            #pragma multi_compile _SPECTROSCOPY_NONE _SPECTROSCOPY_RGB

            #include "./Legacy/JewelShaderInput.cginc"
            #include "./Legacy/JewelShaderForwardBasePass.cginc"
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Off

            CGPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_shadowcaster

            #include "./Legacy/JewelShaderInput.cginc"
            #include "./Legacy/JewelShaderShadowCasterPass.cginc"
            ENDCG
        }
    }
    CustomEditor "akanevrc.JewelShader.Editor.JewelShaderGUI"
}
