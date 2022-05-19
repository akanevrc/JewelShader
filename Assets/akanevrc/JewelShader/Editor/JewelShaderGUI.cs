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
            public static string language = "en";

            private static string GetText(string enText, string jaText)
            {
                switch (I18n.language)
                {
                    case "en":
                        return enText;
                    case "ja":
                        return jaText;
                    default:
                        throw new NotSupportedException();
                }
            }

            public static string GetLanguageButtonLabel()
            {
                return GetText("日本語", "English");
            }

            public static string GetJewelShaderTitle()
            {
                return GetText("akanevrc_JewelShader", "茜式宝石シェーダー (akanevrc_JewelShader)");
            }

            public static string GetNormalCubeLabel()
            {
                return GetText("Normal Cubemap", "法線キューブマップ");
            }

            public static string GetCentroidLabel()
            {
                return GetText("Centroid Position", "中心座標");
            }

            public static string GetRefractiveLabel()
            {
                return GetText("Refractive Index", "屈折率");
            }

            public static string GetLightFoldoutLabel(int index)
            {
                return GetText($"Light Source {index + 1}", $"光源 {index + 1}");
            }

            public static string GetLightDirLabel()
            {
                return GetText("Direction", "向き");
            }

            public static string GetLightPowerLabel()
            {
                return GetText("Power Value", "累乗値");
            }

            public static string GetLightReflectionLabel()
            {
                return GetText("Reflection Ratio", "反射率");
            }

            public static string GetLightIntensityLabel()
            {
                return GetText("Color (Intensity)", "色（強さ）");
            }

            public static string GetLightMultiFactorLabel()
            {
                return GetText("Multiplication Factor", "乗算係数");
            }

            public static string GetLightWeightLabel()
            {
                return GetText("Weight Factor", "重み係数");
            }

            public static string GetColorAttenuationRLabel()
            {
                return GetText("Color Attenuation R", "赤の減衰");
            }

            public static string GetColorAttenuationGLabel()
            {
                return GetText("Color Attenuation G", "緑の減衰");
            }

            public static string GetColorAttenuationBLabel()
            {
                return GetText("Color Attenuation B", "青の減衰");
            }

            public static string GetSpectroscopyLabel()
            {
                return GetText("Spectorscopy", "分光");
            }

            public static string GetSpectrumRefractiveRLabel()
            {
                return GetText("Spectrum Refractive Ratio R", "赤の屈折比率");
            }

            public static string GetSpectrumRefractiveGLabel()
            {
                return GetText("Spectrum Refractive Ratio G", "緑の屈折比率");
            }

            public static string GetSpectrumRefractiveBLabel()
            {
                return GetText("Spectrum Refractive Ratio B", "青の屈折比率");
            }
        }

        private static bool[] lightFoldouts = new bool[] { false, false, false, false };

        private MaterialProperty _NormalCube;
        private MaterialProperty _Centroid;
        private MaterialProperty _Refractive;
        private MaterialProperty[] _LightDirs;
        private MaterialProperty[] _LightPowers;
        private MaterialProperty[] _LightReflections;
        private MaterialProperty[] _LightIntensitys;
        private MaterialProperty[] _LightMultiFactors;
        private MaterialProperty[] _LightWeights;
        private MaterialProperty _ColorAttenuationR;
        private MaterialProperty _ColorAttenuationG;
        private MaterialProperty _ColorAttenuationB;
        private MaterialProperty _Spectroscopy;
        private MaterialProperty _SpectrumRefractiveR;
        private MaterialProperty _SpectrumRefractiveG;
        private MaterialProperty _SpectrumRefractiveB;
        private MaterialProperty _ReflectionCount;
        private MaterialProperty _MainTex;
        private MaterialProperty _Color;

        private void FindProperties(MaterialProperty[] props)
        {
            _NormalCube          = ShaderGUI.FindProperty("_NormalCube"         , props);
            _Centroid            = ShaderGUI.FindProperty("_Centroid"           , props);
            _Refractive          = ShaderGUI.FindProperty("_Refractive"         , props);
            _ColorAttenuationR   = ShaderGUI.FindProperty("_ColorAttenuationR"  , props);
            _ColorAttenuationG   = ShaderGUI.FindProperty("_ColorAttenuationG"  , props);
            _ColorAttenuationB   = ShaderGUI.FindProperty("_ColorAttenuationB"  , props);
            _Spectroscopy        = ShaderGUI.FindProperty("_Spectroscopy"       , props);
            _SpectrumRefractiveR = ShaderGUI.FindProperty("_SpectrumRefractiveR", props);
            _SpectrumRefractiveG = ShaderGUI.FindProperty("_SpectrumRefractiveG", props);
            _SpectrumRefractiveB = ShaderGUI.FindProperty("_SpectrumRefractiveB", props);
            _ReflectionCount     = ShaderGUI.FindProperty("_ReflectionCount"    , props);
            _MainTex             = ShaderGUI.FindProperty("_MainTex"            , props);
            _Color               = ShaderGUI.FindProperty("_Color"              , props);

            _LightDirs = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightDir_1", props),
                ShaderGUI.FindProperty("_LightDir_2", props),
                ShaderGUI.FindProperty("_LightDir_3", props),
                ShaderGUI.FindProperty("_LightDir_4", props)
            };
            _LightPowers = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightPower_1", props),
                ShaderGUI.FindProperty("_LightPower_2", props),
                ShaderGUI.FindProperty("_LightPower_3", props),
                ShaderGUI.FindProperty("_LightPower_4", props)
            };
            _LightReflections = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightReflection_1", props),
                ShaderGUI.FindProperty("_LightReflection_2", props),
                ShaderGUI.FindProperty("_LightReflection_3", props),
                ShaderGUI.FindProperty("_LightReflection_4", props)
            };
            _LightIntensitys = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightIntensity_1", props),
                ShaderGUI.FindProperty("_LightIntensity_2", props),
                ShaderGUI.FindProperty("_LightIntensity_3", props),
                ShaderGUI.FindProperty("_LightIntensity_4", props)
            };
            _LightMultiFactors = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightMultiFactor_1", props),
                ShaderGUI.FindProperty("_LightMultiFactor_2", props),
                ShaderGUI.FindProperty("_LightMultiFactor_3", props),
                ShaderGUI.FindProperty("_LightMultiFactor_4", props)
            };
            _LightWeights = new MaterialProperty[]
            {
                ShaderGUI.FindProperty("_LightWeight_1", props),
                ShaderGUI.FindProperty("_LightWeight_2", props),
                ShaderGUI.FindProperty("_LightWeight_3", props),
                ShaderGUI.FindProperty("_LightWeight_4", props)
            };
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            var material = (Material)materialEditor.target;
            FindProperties(props);

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(I18n.GetJewelShaderTitle(), EditorStyles.boldLabel);
            if (GUILayout.Button(I18n.GetLanguageButtonLabel())) ToggleLanguage();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUI.BeginChangeCheck();

            materialEditor.TextureProperty(_NormalCube, I18n.GetNormalCubeLabel());
            materialEditor.VectorProperty (_Centroid  , I18n.GetCentroidLabel  ());
            EditorGUILayout.Space();

            materialEditor.RangeProperty(_Refractive, I18n.GetRefractiveLabel());
            EditorGUILayout.Space();

            for (var i = 0; i < _LightDirs.Length; i++)
            {
                LightPropertyes(materialEditor, i);
                EditorGUILayout.Space();
            }

            materialEditor.RangeProperty(_ColorAttenuationR, I18n.GetColorAttenuationRLabel());
            materialEditor.RangeProperty(_ColorAttenuationG, I18n.GetColorAttenuationGLabel());
            materialEditor.RangeProperty(_ColorAttenuationB, I18n.GetColorAttenuationBLabel());
            EditorGUILayout.Space();

            var oldSpectroscopy = (SpectroscopyKeyword)Mathf.RoundToInt(_Spectroscopy.floatValue);
            var newSpectroscopy = (SpectroscopyKeyword)EditorGUILayout.EnumPopup(I18n.GetSpectroscopyLabel(), oldSpectroscopy);
            _Spectroscopy.floatValue = (float)newSpectroscopy;
            if (newSpectroscopy != oldSpectroscopy) SetKeyword(material, newSpectroscopy);
            EditorGUILayout.Space();

            materialEditor.RangeProperty(_SpectrumRefractiveR, I18n.GetSpectrumRefractiveRLabel());
            materialEditor.RangeProperty(_SpectrumRefractiveG, I18n.GetSpectrumRefractiveGLabel());
            materialEditor.RangeProperty(_SpectrumRefractiveB, I18n.GetSpectrumRefractiveBLabel());

            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.PropertiesChanged();
            }
        }

        private void LightPropertyes(MaterialEditor materialEditor, int index)
        {
            JewelShaderGUI.lightFoldouts[index] =
                EditorGUILayout.Foldout(JewelShaderGUI.lightFoldouts[index], I18n.GetLightFoldoutLabel(index));
            if (JewelShaderGUI.lightFoldouts[index])
            {
                EditorGUI.indentLevel++;
                materialEditor.VectorProperty(_LightDirs        [index], I18n.GetLightDirLabel        ());
                materialEditor.RangeProperty (_LightPowers      [index], I18n.GetLightPowerLabel      ());
                materialEditor.RangeProperty (_LightReflections [index], I18n.GetLightReflectionLabel ());
                materialEditor.ColorProperty (_LightIntensitys  [index], I18n.GetLightIntensityLabel  ());
                materialEditor.RangeProperty (_LightMultiFactors[index], I18n.GetLightMultiFactorLabel());
                materialEditor.RangeProperty (_LightWeights     [index], I18n.GetLightWeightLabel     ());
                EditorGUI.indentLevel--;
            }
        }

        private void ToggleLanguage()
        {
            if (I18n.language == "en")
            {
                I18n.language = "ja";
            }
            else
            {
                I18n.language = "en";
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
