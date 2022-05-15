using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace akanevrc.JewelShader
{
    [ExecuteInEditMode]
    public class CubemapBaker : MonoBehaviour
    {
        private static readonly string shaderName = "JewelShader/CubemapBaker";

        public GameObject cameraPrefab;
        public GameObject meshPrefab;
        public int width = 256;
        public string language = "en";

#if UNITY_EDITOR
        public void Bake(string filePath)
        {
            var activeObjects = UnactivateAll();

            var destroyables = new Stack<UnityEngine.Object>();
            try
            {
                var meshObj = Instantiate(this.meshPrefab);
                meshObj.SetActive(true);
                destroyables.Push(meshObj);

                var cameraObj = Instantiate(this.cameraPrefab);
                cameraObj.SetActive(true);
                destroyables.Push(cameraObj);

                var renderer = meshObj.GetComponent<Renderer>();
                var mesh     = renderer is MeshRenderer ? meshObj.GetComponent<MeshFilter>().sharedMesh : renderer is SkinnedMeshRenderer smr ? smr.sharedMesh : null;
                var camera   = cameraObj.GetComponent<Camera>();

                InitCamera(camera);

                var bakerMaterial = new Material(Shader.Find(CubemapBaker.shaderName));
                destroyables.Push(bakerMaterial);
                InitBakerMaterial(bakerMaterial, renderer);

                var cubemap = new Cubemap(this.width, GraphicsFormat.R8G8B8A8_UNorm, TextureCreationFlags.None);
                destroyables.Push(cubemap);
                InitCubemap(cubemap);

                Render(renderer, camera, bakerMaterial, cubemap);
                SaveTexture(cubemap, filePath);
                SaveImporter(filePath);
            }
            finally
            {
                foreach (var obj in destroyables) DestroyImmediate(obj);
                ActivateAll(activeObjects);
            }
        }

        private IEnumerable<GameObject> UnactivateAll()
        {
            var objs =
                Resources.FindObjectsOfTypeAll<GameObject>()
                .Where(x => x != this && x.transform.parent == null && x.activeSelf)
                .ToArray();
            foreach (var obj in objs) obj.SetActive(false);
            return objs;
        }

        private void ActivateAll(IEnumerable<GameObject> objs)
        {
            foreach (var obj in objs) obj.SetActive(true);
        }

        private void InitCamera(Camera camera)
        {
            camera.transform.position = Vector3.zero;
            camera.transform.rotation = Quaternion.identity;
        }

        private void InitBakerMaterial(Material material, Renderer renderer)
        {
        }

        private void InitCubemap(Cubemap cubemap)
        {
            cubemap.wrapMode   = TextureWrapMode.Clamp;
            cubemap.filterMode = FilterMode.Bilinear;
            cubemap.anisoLevel = 0;
        }

        private void Render(Renderer renderer, Camera camera, Material bakerMaterial, Cubemap cubemap)
        {
            var oldRotation = renderer.transform.rotation;
            var oldMaterial = renderer.sharedMaterial;
            renderer.transform.rotation = Quaternion.identity;
            renderer.sharedMaterial     = bakerMaterial;

            camera.RenderToCubemap(cubemap);

            renderer.transform.rotation = oldRotation;
            renderer.sharedMaterial     = oldMaterial;
        }

        private void SaveTexture(Cubemap cubemap, string filePath)
        {
            var tmp = new Texture2D(this.width, this.width * 6, GraphicsFormat.R8G8B8A8_UNorm, TextureCreationFlags.None);
            try
            {
                tmp.SetPixels(GetPixels(cubemap));
                var bytes = tmp.EncodeToPNG();
                File.WriteAllBytes(filePath, bytes);
                AssetDatabase.Refresh();
            }
            finally
            {
                DestroyImmediate(tmp);
            }
        }

        private Color[] GetPixels(Cubemap cubemap)
        {
            var pixels = new CubemapFace[]
            {
                CubemapFace.PositiveX,
                CubemapFace.NegativeX,
                CubemapFace.PositiveY,
                CubemapFace.NegativeY,
                CubemapFace.PositiveZ,
                CubemapFace.NegativeZ
            }
            .SelectMany(x => cubemap.GetPixels(x))
            .ToArray();

            return
                IterLines(pixels)
                .Reverse()
                .SelectMany(x => x)
                .ToArray();
        }

        private IEnumerable<IEnumerable<Color>> IterLines(Color[] pixels)
        {
            foreach (var x in Enumerable.Range(0, width * 6).Select(x => x * width))
            {
                var arr = new Color[width];
                for (var i = 0; i < arr.Length; i++)
                {
                    arr[i] = pixels[x + i];
                }
                yield return arr;
            }
        }

        private void SaveImporter(string filePath)
        {
            var importer = (TextureImporter)AssetImporter.GetAtPath(filePath);

            var settings = new TextureImporterSettings()
            {
                textureType             = TextureImporterType.Default,
                textureShape            = TextureImporterShape.TextureCube,
                cubemapConvolution      = TextureImporterCubemapConvolution.None,
                sRGBTexture             = false,
                alphaSource             = TextureImporterAlphaSource.FromInput,
                alphaIsTransparency     = false,
                npotScale               = TextureImporterNPOTScale.ToNearest,
                readable                = false,
                streamingMipmaps        = false,
                mipmapEnabled           = false,
                borderMipmap            = false,
                mipmapFilter            = TextureImporterMipFilter.BoxFilter,
                mipMapsPreserveCoverage = false,
                fadeOut                 = false,
                wrapMode                = TextureWrapMode.Clamp,
                filterMode              = FilterMode.Bilinear,
                aniso                   = 0
            };
            importer.SetTextureSettings(settings);

            var platformSettings = new TextureImporterPlatformSettings()
            {
                maxTextureSize  = 2048,
                resizeAlgorithm = TextureResizeAlgorithm.Mitchell,
                format          = TextureImporterFormat.RGBA32
            };
            importer.SetPlatformTextureSettings(platformSettings);

            importer.SaveAndReimport();
        }
#endif
    }
}
