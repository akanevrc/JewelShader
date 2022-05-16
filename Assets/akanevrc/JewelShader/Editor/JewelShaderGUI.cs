using System;
using UnityEditor;
using UnityEngine;

namespace akanevrc.JewelShader.Editor
{
    public class JewelShaderGUI : ShaderGUI
    {
        public enum SpectroscopyKeyword
        {
            _SPECTROSCOPY_NONE = 0,
            _SPECTROSCOPY_RGB = 1
        }

        private class I18n
        {
            private static string GetText(string language, string enText, string jaText)
            {
                switch (language)
                {
                    case "en":
                        return enText;
                    case "ja":
                        return jaText;
                    default:
                        throw new NotSupportedException();
                }
            }

            public static string GetLanguageButtonLabel(string language)
            {
                return GetText(language, "日本語", "English");
            }

            public static string GetJewelShaderTitle(string language)
            {
                return GetText(language, "akanevrc_JewelShader", "茜式宝石シェーダー (akanevrc_JewelShader)");
            }

            public static string GetNormalCubeLabel(string language)
            {
                return GetText(language, "Normal Cubemap", "法線キューブマップ");
            }

            public static string GetRefractiveLabel(string language)
            {
                return GetText(language, "Refractive Index", "屈折率");
            }

            public static string GetLightDirLabel(string language)
            {
                return GetText(language, "Light Direction", "光源の向き");
            }

            public static string GetLightPowerLabel(string language)
            {
                return GetText(language, "Light Power Value", "光源の累乗値");
            }

            public static string GetLightReflectionLabel(string language)
            {
                return GetText(language, "Light Reflection Ratio", "光源の反射率");
            }

            public static string GetLightIntensityLabel(string language)
            {
                return GetText(language, "Light Color (Intensity)", "光源の色（強さ）");
            }

            public static string GetColorAttenuationRLabel(string language)
            {
                return GetText(language, "Color Attenuation R", "赤の減衰");
            }

            public static string GetColorAttenuationGLabel(string language)
            {
                return GetText(language, "Color Attenuation G", "緑の減衰");
            }

            public static string GetColorAttenuationBLabel(string language)
            {
                return GetText(language, "Color Attenuation B", "青の減衰");
            }

            public static string GetSpectroscopyLabel(string language)
            {
                return GetText(language, "Spectorscopy", "分光");
            }

            public static string GetSpectrumRefractiveRLabel(string language)
            {
                return GetText(language, "Spectrum Refractive Ratio R", "赤の屈折比率");
            }

            public static string GetSpectrumRefractiveGLabel(string language)
            {
                return GetText(language, "Spectrum Refractive Ratio G", "緑の屈折比率");
            }

            public static string GetSpectrumRefractiveBLabel(string language)
            {
                return GetText(language, "Spectrum Refractive Ratio B", "青の屈折比率");
            }
        }

        private static string language = "en";

        private MaterialProperty _NormalCube;
        private MaterialProperty _Refractive;
        private MaterialProperty _LightDir;
        private MaterialProperty _LightPower;
        private MaterialProperty _LightReflection;
        private MaterialProperty _LightIntensity;
        private MaterialProperty _ColorAttenuationR;
        private MaterialProperty _ColorAttenuationG;
        private MaterialProperty _ColorAttenuationB;
        private MaterialProperty _Spectroscopy;
        private MaterialProperty _SpectrumRefractiveR;
        private MaterialProperty _SpectrumRefractiveG;
        private MaterialProperty _SpectrumRefractiveB;
        private MaterialProperty _Centroid;
        private MaterialProperty _ReflectionCount;
        private MaterialProperty _MainTex;
        private MaterialProperty _Color;

        private void FindProperties(MaterialProperty[] props)
        {
            _NormalCube          = ShaderGUI.FindProperty("_NormalCube"         , props);
            _Refractive          = ShaderGUI.FindProperty("_Refractive"         , props);
            _LightDir            = ShaderGUI.FindProperty("_LightDir"           , props);
            _LightPower          = ShaderGUI.FindProperty("_LightPower"         , props);
            _LightReflection     = ShaderGUI.FindProperty("_LightReflection"    , props);
            _LightIntensity      = ShaderGUI.FindProperty("_LightIntensity"     , props);
            _ColorAttenuationR   = ShaderGUI.FindProperty("_ColorAttenuationR"  , props);
            _ColorAttenuationG   = ShaderGUI.FindProperty("_ColorAttenuationG"  , props);
            _ColorAttenuationB   = ShaderGUI.FindProperty("_ColorAttenuationB"  , props);
            _Spectroscopy        = ShaderGUI.FindProperty("_Spectroscopy"       , props);
            _SpectrumRefractiveR = ShaderGUI.FindProperty("_SpectrumRefractiveR", props);
            _SpectrumRefractiveG = ShaderGUI.FindProperty("_SpectrumRefractiveG", props);
            _SpectrumRefractiveB = ShaderGUI.FindProperty("_SpectrumRefractiveB", props);
            _Centroid            = ShaderGUI.FindProperty("_Centroid"           , props);
            _ReflectionCount     = ShaderGUI.FindProperty("_ReflectionCount"    , props);
            _MainTex             = ShaderGUI.FindProperty("_MainTex"            , props);
            _Color               = ShaderGUI.FindProperty("_Color"              , props);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            var material = (Material)materialEditor.target;
            FindProperties(props);

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(I18n.GetJewelShaderTitle(JewelShaderGUI.language), EditorStyles.boldLabel);
            if (GUILayout.Button(I18n.GetLanguageButtonLabel(JewelShaderGUI.language))) ToggleLanguage();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUI.BeginChangeCheck();

            materialEditor.TextureProperty(_NormalCube, I18n.GetNormalCubeLabel(JewelShaderGUI.language));
            EditorGUILayout.Space();

            materialEditor.RangeProperty(_Refractive, I18n.GetRefractiveLabel(JewelShaderGUI.language));
            EditorGUILayout.Space();

            materialEditor.VectorProperty(_LightDir       , I18n.GetLightDirLabel       (JewelShaderGUI.language));
            materialEditor.RangeProperty (_LightPower     , I18n.GetLightPowerLabel     (JewelShaderGUI.language));
            materialEditor.RangeProperty (_LightReflection, I18n.GetLightReflectionLabel(JewelShaderGUI.language));
            materialEditor.ColorProperty (_LightIntensity , I18n.GetLightIntensityLabel (JewelShaderGUI.language));
            EditorGUILayout.Space();

            materialEditor.RangeProperty(_ColorAttenuationR, I18n.GetColorAttenuationRLabel(JewelShaderGUI.language));
            materialEditor.RangeProperty(_ColorAttenuationG, I18n.GetColorAttenuationGLabel(JewelShaderGUI.language));
            materialEditor.RangeProperty(_ColorAttenuationB, I18n.GetColorAttenuationBLabel(JewelShaderGUI.language));
            EditorGUILayout.Space();

            var oldSpectroscopy = (SpectroscopyKeyword)Mathf.RoundToInt(_Spectroscopy.floatValue);
            var newSpectroscopy = (SpectroscopyKeyword)EditorGUILayout.EnumPopup(I18n.GetSpectroscopyLabel(JewelShaderGUI.language), oldSpectroscopy);
            _Spectroscopy.floatValue = (float)newSpectroscopy;
            if (newSpectroscopy != oldSpectroscopy) SetKeyword(material, newSpectroscopy);
            EditorGUILayout.Space();

            materialEditor.RangeProperty(_SpectrumRefractiveR, I18n.GetSpectrumRefractiveRLabel(JewelShaderGUI.language));
            materialEditor.RangeProperty(_SpectrumRefractiveG, I18n.GetSpectrumRefractiveGLabel(JewelShaderGUI.language));
            materialEditor.RangeProperty(_SpectrumRefractiveB, I18n.GetSpectrumRefractiveBLabel(JewelShaderGUI.language));

            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.PropertiesChanged();
            }
        }

        private void ToggleLanguage()
        {
            if (JewelShaderGUI.language == "en")
            {
                JewelShaderGUI.language = "ja";
            }
            else
            {
                JewelShaderGUI.language = "en";
            }
        }

        private void SetKeyword<T>(Material material, T keyword) where T : Enum
        {
            foreach (var name in Enum.GetNames(typeof(T)))
            {
                if (name == Enum.GetName(typeof(T), keyword))
                {
                    material.EnableKeyword(name);
                }
                else
                {
                    material.DisableKeyword(name);
                }
            }
        }
    }
}
