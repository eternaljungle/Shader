Shader "GPUParticles"
{
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #define PARTICLE_SIZE 10
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            ByteAddressBuffer Particles;
            static float2 quad[] =
            {
                float2(-1.0f, +1.0f), float2(-1.0f, -1.0f), float2(+1.0f, -1.0f),
                float2(+1.0f, -1.0f), float2(+1.0f, +1.0f), float2(-1.0f, +1.0f)
            };

            float4 Vert(const uint vertexID : SV_VertexID) : SV_POSITION
            {
                const uint id = vertexID / 6;
                const uint localVertexID = vertexID % 6;
                float3 position = asfloat(Particles.Load3(mad(id, PARTICLE_SIZE, 0) << 2));
                float4 positionCS = TransformWorldToHClip(position);
                positionCS.xy += quad[localVertexID] * 0.5f;
                return positionCS;
            }

            half4 Frag(const float4 positionCS : SV_POSITION) : SV_TARGET
            {
                return half4(1.0h, 0.0h, 0.5h, 1.0h);
            }
            ENDHLSL
        }
    }
}