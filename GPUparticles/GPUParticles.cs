using UnityEngine;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using static Unity.Mathematics.math;

namespace GPUParticles
{
    public struct SphereVolume
    {
        [SerializeField] public float3 position;
        [SerializeField] public float radius;
    }


    public struct Particle
    {
        public static readonly int Size = Marshal.SizeOf<Particle>();

        public float3 Position;
        public float3 Velocity;
        public float3 Acceleration;
        public float intertia;
    }

    public struct Constants
    {
        public static readonly int Size = Marshal.SizeOf<Constants>();
        public uint Capacity;
        public float3 SpherePosition;
        public float SphereRadius;
    }

    public class GPUParticles : MonoBehaviour
    {
        [SerializeField] private ComputeShader tick;
        [SerializeField] private uint capacity;
        [SerializeField] private float3 initPosition;
        [SerializeField] private string particlesBufferName;
        [SerializeField] private string kernelNameInit;
        [SerializeField] private string kernelNameTick;
        [SerializeField] private Material material;
        [SerializeField] private SphereVolume initVolume;

        private GraphicsBuffer _particlesBuffer;
        private GraphicsBuffer _constantsBuffer;
        private ComputeShader _tickInstance;
        private int _kernelIndex;
        private readonly Constants[] _constants = new Constants[1];
        private RenderParams _renderParams;
        private int _threadGroupX;


        private void OnValidate() => Init();
        private void OnEnable() => Init();
        private void Update() => Tick();
        private void OnDisable() => Dispose();

        private void Init()
        {
            if (!tick) return;
            if (0 == capacity) return;
            if (string.IsNullOrEmpty(kernelNameTick)) return;
            if (string.IsNullOrEmpty(kernelNameInit)) return;
            if (string.IsNullOrEmpty(particlesBufferName)) return;

            if (null == _particlesBuffer) _particlesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, (int)capacity, Particle.Size);
            else if (!_particlesBuffer.IsValid()) _particlesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, (int)capacity, Particle.Size);
            else if (_particlesBuffer.count != capacity)
            {
                _particlesBuffer.Dispose();
                _particlesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, (int)capacity, Particle.Size);

            }
            
            if (null == _constantsBuffer) _constantsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, 1, Constants.Size);
            else if (!_constantsBuffer.IsValid()) _constantsBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Raw, 1, Constants.Size);

            _constants[0].Capacity = capacity;
            _constants[0].SpherePosition = initVolume.position;
            _constants[0].SphereRadius = initVolume.radius;
            _constantsBuffer.SetData(_constants);

            _tickInstance = Instantiate(tick);
            _kernelIndex = _tickInstance.FindKernel(kernelNameTick);
            _tickInstance.SetBuffer(_kernelIndex, particlesBufferName, _particlesBuffer);
            _tickInstance.SetConstantBuffer(nameof(Constants), _constantsBuffer, 0, Constants.Size);

            if (material)
            {
                _renderParams = new RenderParams(material) { matProps = new MaterialPropertyBlock() };
                _renderParams.matProps.SetBuffer(particlesBufferName, _particlesBuffer);
            }

            _threadGroupX = (int)ceil(capacity / 64.0f);
            var kernelInit = _tickInstance.FindKernel(kernelNameInit);
            _tickInstance.SetBuffer(kernelInit, particlesBufferName, _particlesBuffer);
            _tickInstance.Dispatch(kernelInit, _threadGroupX, 1, 1);
        }

        private void Tick()
        {
            _tickInstance?.Dispatch(_kernelIndex, _threadGroupX, 1, 1);
            if (material) Graphics.RenderPrimitives(_renderParams, MeshTopology.Triangles, (int)capacity * 6);
        }


        private void Dispose()
        {
            if (_tickInstance)
            {
                if (Application.isPlaying) Destroy(_tickInstance);
                else DestroyImmediate(_tickInstance);
            }
            _particlesBuffer?.Dispose();
            _constantsBuffer?.Dispose();
        }
    }
    
}

