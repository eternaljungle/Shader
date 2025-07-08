using static Unity.Mathematics.math;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;
using System.Runtime.InteropServices;

namespace VolumeCloud.Editor
{
    public class VolumeCloudCache : EditorWindow
    {
        private static readonly int ConstsProperty = Shader.PropertyToID("Consts");
        private static readonly int BufferProperty = Shader.PropertyToID("buffer");
        private static readonly int AngleProperty = Shader.PropertyToID("Angle");
            
        private struct Consts
        {
            public uint Resolution { get; set; }
        }
        
        [MenuItem("Tools/Volume Cloud Cache")]
        private static void OpenWindow() => CreateWindow<VolumeCloudCache>().Show();
        
        [SerializeField] private ComputeShader computeShader;
        [SerializeField] private int resolution;
        [SerializeField] private int frames;
        
        private void OnGUI()
        {
            computeShader = (ComputeShader)EditorGUILayout.ObjectField(computeShader, typeof(ComputeShader), false);
            resolution = EditorGUILayout.IntField("Resolution", resolution);
            resolution = clamp(resolution, 4, 1024);
            frames = EditorGUILayout.IntField("Frames", frames);
            frames = clamp(frames, 1, 64);
            if (GUILayout.Button("DO")) Do();
        }

        private void Do()
        {
            if (!computeShader) return;
            if (resolution < 4) return;
            if (frames < 1) return;
            
            var path = EditorUtility.SaveFilePanelInProject("Volume Cloud Cache", "VolumeCloudCache.asset", "asset", "");
            if (string.IsNullOrEmpty(path)) return;

            var asset = new Texture2DArray(resolution, resolution, frames, GraphicsFormat.B8G8R8A8_SRGB, TextureCreationFlags.MipChain);
            
            using var constsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Constant, 1, Marshal.SizeOf<Consts>());
            constsBuffer.SetData(new Consts[] { new() {Resolution = (uint)resolution } });
            computeShader.SetConstantBuffer(ConstsProperty, constsBuffer, 0, constsBuffer.stride);
            var kernel = computeShader.FindKernel("VolumeCloud");
            for (var i = 0; i < frames; ++i)
            { 
                using var buffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, resolution * resolution, sizeof(uint));
                var t = (int)ceil(resolution / 8.0f);
                
                computeShader.SetFloat(AngleProperty,(float)i / frames * PI2);
                computeShader.SetBuffer(kernel, BufferProperty, buffer);
                computeShader.Dispatch(kernel, t, t, 1);

                var req = AsyncGPUReadback.Request(buffer);
                req.WaitForCompletion();
                asset.SetPixelData(req.GetData<uint>(), 0, i);

            }
            asset.Apply(true, false);
            AssetDatabase.CreateAsset(asset, path);
        }
    }
}