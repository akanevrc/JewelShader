using UnityEditor;
using UnityEngine;

namespace akanevrc.JewelShader
{
    [CustomEditor(typeof(CubemapBaker))]
    public class CubemapBakerEditor : Editor
    {
        private SerializedProperty meshPrefab;
        private SerializedProperty cameraPrefab;
        private SerializedProperty width;

        private void OnEnable()
        {
            meshPrefab   = serializedObject.FindProperty(nameof(meshPrefab));
            cameraPrefab = serializedObject.FindProperty(nameof(cameraPrefab));
            width        = serializedObject.FindProperty(nameof(width));
        }

        public override void OnInspectorGUI()
        {
            var baker = (CubemapBaker)target;

            serializedObject.Update();
            
            EditorGUILayout.PropertyField(meshPrefab  , new GUIContent("Target Mesh Prefab/GameObject"));
            EditorGUILayout.PropertyField(cameraPrefab, new GUIContent("Baker Camera Prefab/GameObject"));
            EditorGUILayout.PropertyField(width       , new GUIContent("Baked Cubemap Width"));

            EditorGUILayout.Space();

            if (GUILayout.Button("Bake"))
            {
                var path = EditorUtility.SaveFilePanelInProject
                (
                    "Save Cubemap Texture",
                    "JewelShader_Cubemap.png",
                    "png",
                    "Enter a name of new cubemap texture file."
                );

                if (!string.IsNullOrEmpty(path))
                {
                    baker.Bake(path);
                }
            }

            serializedObject.ApplyModifiedProperties();
        }
    }
}
