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
                    "Use this GameObject to bake a Cubemap for JewelShader.",
                    "このGameObjectは、宝石シェーダー用キューブマップをベイクするために使用します。"
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

        public SerializedProperty cameraPrefab;
        public SerializedProperty meshPrefab;
        public SerializedProperty width;
        public SerializedProperty language;

        private string errorMessage = "";
        private bool errorIsCritical = false;

        [SerializeField]
        private bool hiddenConfigFoldout = false;

        private void OnEnable()
        {
            this.cameraPrefab = this.serializedObject.FindProperty(nameof(this.cameraPrefab));
            this.meshPrefab   = this.serializedObject.FindProperty(nameof(this.meshPrefab));
            this.width        = this.serializedObject.FindProperty(nameof(this.width));
            this.language     = this.serializedObject.FindProperty(nameof(this.language));
        }

        public override void OnInspectorGUI()
        {
            var baker = (CubemapBaker)this.target;
            var lang  = this.language.stringValue;

            this.serializedObject.Update();

            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(I18n.GetCubemapBakerTitle(lang), EditorStyles.boldLabel);
            if (GUILayout.Button(I18n.GetLanguageButtonLabel(lang))) ToggleLanguage();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUILayout.HelpBox(I18n.GetCubemapBakerDescription(lang), MessageType.Info);
            EditorGUILayout.Space();

            EditorGUILayout.LabelField(I18n.GetMeshPrefabLabel(lang));
            EditorGUILayout.PropertyField(this.meshPrefab, new GUIContent());
            EditorGUILayout.Space();

            EditorGUILayout.LabelField(I18n.GetWidthLabel(lang));
            EditorGUILayout.PropertyField(this.width, new GUIContent());
            EditorGUILayout.Space();

            this.hiddenConfigFoldout = EditorGUILayout.Foldout(this.hiddenConfigFoldout, I18n.GetHiddenConfigFoldout(lang));
            if (this.hiddenConfigFoldout)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.LabelField(I18n.GetCameraPrefabLabel(lang));
                EditorGUILayout.PropertyField(this.cameraPrefab, new GUIContent());
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.Space();

            if (GUILayout.Button(I18n.GetBakeButtonLabel(lang)))
            {
                if (Validate())
                {
                    var meshObj = (GameObject)this.meshPrefab.objectReferenceValue;

                    var path = EditorUtility.SaveFilePanelInProject
                    (
                        I18n.GetSaveFilePanelTitle(lang),
                        $"JewelShader_Cubemap_{meshObj?.name}.png",
                        "png",
                        I18n.GetSaveFilePanelMessage(lang)
                    );

                    if (!string.IsNullOrEmpty(path))
                    {
                        baker.Bake(path);
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
            if (this.language.stringValue == "en")
            {
                this.language.stringValue = "ja";
            }
            else
            {
                this.language.stringValue = "en";
            }
        }

        private bool Validate()
        {
            var cameraObj = this.cameraPrefab.objectReferenceValue;
            var meshObj   = this.meshPrefab  .objectReferenceValue;
            var widthVal  = this.width.intValue;
            var lang      = this.language.stringValue;

            if (cameraObj == null)
            {
                this.errorMessage = I18n.GetNullMessageOfCameraPrefab(lang);
                return false;
            }
            else if (meshObj == null)
            {
                this.errorMessage = I18n.GetNullMessageOfMeshPrefab(lang);
                return false;
            }
            else if (widthVal <= 0)
            {
                this.errorMessage = I18n.GetOutOfRangeMessageOfWidth(lang);
                return false;
            }

            this.errorMessage = "";
            return true;
        }
    }
}
