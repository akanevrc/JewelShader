using System;
using UnityEditor;
using UnityEngine;

namespace akanevrc.JewelShader.Editor
{
    [CustomEditor(typeof(CubemapBaker))]
    public class CubemapBakerEditor : UnityEditor.Editor
    {
        private static class I18n
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

            public static string GetCubemapBakerTitle(string language)
            {
                return GetText(language, "Cubemap Baker", "キューブマップベイカー (Cubemap Baker)");
            }

            public static string GetCubemapBakerDescription(string language)
            {
                return GetText
                (
                    language,
                    "Use this GameObject to bake a Cubemap for akanevrc_JewelShader.",
                    "このGameObjectは、茜式宝石シェーダー用キューブマップをベイクするために使用します。"
                );
            }

            public static string GetHiddenConfigFoldout(string language)
            {
                return GetText(language, "Hidden configs", "非表示の設定");
            }

            public static string GetCameraPrefabLabel(string language)
            {
                return GetText(language, "Baker camera Prefab/GameObject", "ベイク用カメラのPrefab/GameObject");
            }

            public static string GetMeshPrefabLabel(string language)
            {
                return GetText(language, "Target mesh Prefab/GameObject", "処理対象のメッシュを含むPrefab/GameObject");
            }

            public static string GetWidthLabel(string language)
            {
                return GetText(language, "Baked cubemap width", "ベイクされるキューブマップのサイズ");
            }

            public static string GetBakeButtonLabel(string language)
            {
                return GetText(language, "Bake", "ベイク");
            }

            public static string GetSaveFilePanelTitle(string language)
            {
                return GetText(language, "Save cubemap texture", "キューブマップテクスチャの保存");
            }

            public static string GetSaveFilePanelMessage(string language)
            {
                return GetText(language, "Enter a name of new cubemap texture file.", "キューブマップテクスチャファイルの名前を入力");
            }

            public static string GetNullMessageOfCameraPrefab(string language)
            {
                return GetText(language, "Enter camera Prefab/GameObject", "カメラPrefab/GameObjectを指定してください");
            }

            public static string GetNullMessageOfMeshPrefab(string language)
            {
                return GetText(language, "Enter mesh Prefab/GameObject", "メッシュを含むPrefab/GameObjectを指定してください");
            }

            public static string GetOutOfRangeMessageOfWidth(string language)
            {
                return GetText(language, "Width must be 1 or above", "サイズは1以上にしてください");
            }
        }

        private static string language = "en";

        private SerializedProperty cameraPrefab;
        private SerializedProperty meshPrefab;
        private SerializedProperty width;

        private string errorMessage = "";
        private bool errorIsCritical = false;

        private bool hiddenConfigFoldout = false;

        private void OnEnable()
        {
            this.cameraPrefab = this.serializedObject.FindProperty(nameof(this.cameraPrefab));
            this.meshPrefab   = this.serializedObject.FindProperty(nameof(this.meshPrefab));
            this.width        = this.serializedObject.FindProperty(nameof(this.width));
        }

        public override void OnInspectorGUI()
        {
            var baker = (CubemapBaker)this.target;

            this.serializedObject.Update();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(I18n.GetCubemapBakerTitle(CubemapBakerEditor.language), EditorStyles.boldLabel);
            if (GUILayout.Button(I18n.GetLanguageButtonLabel(CubemapBakerEditor.language))) ToggleLanguage();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUILayout.HelpBox(I18n.GetCubemapBakerDescription(CubemapBakerEditor.language), MessageType.Info);
            EditorGUILayout.Space();

            EditorGUILayout.LabelField(I18n.GetMeshPrefabLabel(CubemapBakerEditor.language));
            EditorGUILayout.PropertyField(this.meshPrefab, new GUIContent());
            EditorGUILayout.Space();

            EditorGUILayout.LabelField(I18n.GetWidthLabel(CubemapBakerEditor.language));
            EditorGUILayout.PropertyField(this.width, new GUIContent());
            EditorGUILayout.Space();

            this.hiddenConfigFoldout = EditorGUILayout.Foldout(this.hiddenConfigFoldout, I18n.GetHiddenConfigFoldout(CubemapBakerEditor.language));
            if (this.hiddenConfigFoldout)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.LabelField(I18n.GetCameraPrefabLabel(CubemapBakerEditor.language));
                EditorGUILayout.PropertyField(this.cameraPrefab, new GUIContent());
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.Space();

            if (GUILayout.Button(I18n.GetBakeButtonLabel(CubemapBakerEditor.language)))
            {
                if (Validate())
                {
                    var meshObj = (GameObject)this.meshPrefab.objectReferenceValue;

                    var path = EditorUtility.SaveFilePanelInProject
                    (
                        I18n.GetSaveFilePanelTitle(CubemapBakerEditor.language),
                        $"JewelShader_Cubemap_{meshObj?.name}.png",
                        "png",
                        I18n.GetSaveFilePanelMessage(CubemapBakerEditor.language)
                    );

                    if (!string.IsNullOrEmpty(path))
                    {
                        baker.Bake(path);
                        Debug.Log("Bake succeeded");
                    }
                }
            }

            if (!string.IsNullOrEmpty(this.errorMessage))
            {
                EditorGUILayout.HelpBox(this.errorMessage, this.errorIsCritical ? MessageType.Error : MessageType.Warning);
            }

            this.serializedObject.ApplyModifiedProperties();
        }

        private void ToggleLanguage()
        {
            if (CubemapBakerEditor.language == "en")
            {
                CubemapBakerEditor.language = "ja";
            }
            else
            {
                CubemapBakerEditor.language = "en";
            }
        }

        private bool Validate()
        {
            var cameraObj = this.cameraPrefab.objectReferenceValue;
            var meshObj   = this.meshPrefab  .objectReferenceValue;
            var widthVal  = this.width.intValue;

            if (cameraObj == null)
            {
                this.errorMessage = I18n.GetNullMessageOfCameraPrefab(CubemapBakerEditor.language);
                return false;
            }
            else if (meshObj == null)
            {
                this.errorMessage = I18n.GetNullMessageOfMeshPrefab(CubemapBakerEditor.language);
                return false;
            }
            else if (widthVal <= 0)
            {
                this.errorMessage = I18n.GetOutOfRangeMessageOfWidth(CubemapBakerEditor.language);
                return false;
            }

            this.errorMessage = "";
            return true;
        }
    }
}
