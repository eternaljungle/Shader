using UnityEngine;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using static Unity.Mathematics.math;


namespace GPUGrass
{
    public struct Constants
    {
        public static readonly int Size = Marshal.SizeOf<Constants>();
        
        public float4 RootColor;
        public float4 TopColor;
        public float4 ScaleParam;
        public uint Capacity;
        public float ScatterRange;
    }
    
    public struct Grass
{
    public static readonly int Size = Marshal.SizeOf<Grass>();

    public float3 Position;
    public float Rotation;
    public float2 Scale;
    public float Bend;
    public uint2 ColorParams;
}

    [ExecuteAlways]
    public class GPUGrass : MonoBehaviour
    {
        private const int MaxCapacity = 10000;
        private static readonly int GrassBufferStore = Shader.PropertyToID("GrassBufferStore");
                private static readonly int GrassBufferLoad = Shader.PropertyToID("GrassBufferLoad");
        private static readonly int CommandBuffer = Shader.PropertyToID("CommandBuffer");
        private static readonly int ConstantsProperty = Shader.PropertyToID("Constants");

        [SerializeField] private ComputeShader compute;
        [SerializeField][Range(0, MaxCapacity)]
        private int capacity;

        [SerializeField][Range(10.0f, 32.0f)] private float scatterRange;
        [SerializeField] private float2 xScalePram;
        [SerializeField] private float2 yScalePram;
        [SerializeField] private Color rootColor;
        [SerializeField] private Color topColor;
        
        [SerializeField] private Material renderMaterial;

        private ComputeShader _compute;
        private GraphicsBuffer _constBuffer;
        private GraphicsBuffer _grassBuffer;
        private GraphicsBuffer _commandBuffer;
        private RenderParams _renderParams;
        private int _tickKernelIndex;
        private int _threadGroupCount;

        private readonly Constants[] _constants = new Constants[1];

        private void OnValidate()
        {
            capacity = clamp(capacity, 0, MaxCapacity);
            Init();
        } 

        private void OnEnable() => Init();
        private void OnDisable() => Dispose();

        private void Update()
        {
            if (Application.isPlaying) Tick();

        }

#if UNITY_EDITOR
        private void UpdateEditor()
        {
            if (!Application.isPlaying) Tick();
        }
#endif

        private void Init()
        {
            if (capacity <= 0)
            {
                Dispose();
                return;
            }

            if (!compute) return;

            _compute = Instantiate(compute);

            if (null == _constBuffer || !_constBuffer.IsValid()) _constBuffer = NewConstantsBuffer();
            else if (_constBuffer.stride != Constants.Size)
            {
                _constBuffer.Dispose();
                _constBuffer = NewConstantsBuffer();
            }

            if (null == _grassBuffer || !_grassBuffer.IsValid()) _grassBuffer = NewGrassBuffer();
                else if (_grassBuffer.count != capacity || _grassBuffer.stride != Grass.Size)
                {
                    _grassBuffer.Dispose();
                    _grassBuffer = NewGrassBuffer();
                }

            if (null == _commandBuffer || !_commandBuffer.IsValid()) _commandBuffer = NewCommandBuffer();

            _constants[0].RootColor = float4(rootColor.r, rootColor.g, rootColor.b, rootColor.a);
            _constants[0].TopColor = float4(topColor.r, topColor.g, topColor.b, topColor.a);
            _constants[0].ScaleParam = float4(xScalePram, yScalePram);
            _constants[0].Capacity = (uint)capacity;
            _constants[0].ScatterRange = scatterRange;
            _constBuffer.SetData(_constants);
            _compute.SetConstantBuffer(ConstantsProperty, _constBuffer, 0, Constants.Size);

            var initKernelIndex = compute.FindKernel("Init");
            _compute.SetBuffer(initKernelIndex, GrassBufferStore, _grassBuffer);
            _compute.SetBuffer(initKernelIndex, CommandBuffer, _commandBuffer);
            _compute.Dispatch(initKernelIndex, 1, 1, 1);

            _tickKernelIndex = compute.FindKernel("Tick");
            _compute.SetBuffer(_tickKernelIndex, GrassBufferStore, _grassBuffer);
            _compute.SetBuffer(_tickKernelIndex, CommandBuffer, _commandBuffer);
            _threadGroupCount = (int)ceil(capacity / 64.0f);

            if (renderMaterial)
            {
                _renderParams = new RenderParams(renderMaterial) { matProps = new MaterialPropertyBlock() };
                _renderParams.matProps.SetBuffer(GrassBufferLoad, _grassBuffer);
            }

#if UNITY_EDITOR
                UnityEditor.EditorApplication.update -= UpdateEditor;
            UnityEditor.EditorApplication.update += UpdateEditor;
#endif
        }

        private GraphicsBuffer NewConstantsBuffer() => new(GraphicsBuffer.Target.Constant, 1, Constants.Size);
        private GraphicsBuffer NewGrassBuffer() => new(GraphicsBuffer.Target.Raw, capacity, Grass.Size);
        private GraphicsBuffer NewCommandBuffer() => new(GraphicsBuffer.Target.IndirectArguments | GraphicsBuffer.Target.Raw, 1,  GraphicsBuffer.IndirectDrawArgs.size);

        private void Dispose()
        {
            if (Application.isPlaying) Destroy(_compute);
            else DestroyImmediate(_compute);
            _grassBuffer?.Dispose();
            _commandBuffer?.Dispose();

#if UNITY_EDITOR
            UnityEditor.EditorApplication.update -= UpdateEditor;
#endif
        }

        private void Tick()
        {
            if (!_compute) return;
            _compute.Dispatch(_tickKernelIndex, _threadGroupCount, 1, 1);
            if (renderMaterial)
            {
                _renderParams.worldBounds = new Bounds(transform.position, Vector3.one * 100.0f);
                _renderParams.matProps.SetVector("Position", transform.position);
                Graphics.RenderPrimitivesIndirect(_renderParams, MeshTopology.Triangles, _commandBuffer);
            }

        }
    }
}
