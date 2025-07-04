Shader "GPU Grass"
{
    SubShader
    {
        ZWrite On
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "./GPUGrassCommon.hlsl"    
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                uint vertexID : SV_VertexID;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 color : COLOR;

            };

            ByteAddressBuffer GrassBuffer;

            static float4 grassMesh[VERTEX_PER_BLADE] =
            {
                float4(-1.0f, +0.0f, +0.0f, 0.00f), float4(-0.9f, +1.0f, +0.0f, 0.33f), float4(+0.9f, +1.0f, +0.0f, 0.33f),
                float4(+0.9f, +1.0f, +0.0f, 0.33f), float4(+1.0f, +0.0f, +0.0f, 0.00f), float4(-1.0f, +0.0f, +0.0f, 0.00f),

                 float4(-0.9f, +1.0f, +0.0f, 0.33f), float4(-0.6f, +2.0f, +0.0f, 0.67f), float4(+0.6f, +2.0f, +0.0f, 0.67f),
                 float4(+0.6f, +2.0f, +0.0f, 0.67f), float4(+0.9f, +1.0f, +0.0f, 0.33f), float4(-0.9f, +1.0f, +0.0f, 0.33f),

                 float4(-0.6f, +2.0f, +0.0f, 0.67f), float4(+0.0f, +3.0f, +0.0f, 1.00f), float4(+0.6f, +2.0f, +0.0f, 0.67f),
            };

            Varyings Vert(const Attribute input)
            {
                const uint globalVertexID = input.vertexID;
                const uint bladeID = uint(floor(globalVertexID / VERTEX_PER_BLADE));
                const uint localVertex = globalVertexID % VERTEX_PER_BLADE;
                const float4 bladePositionRotation = asfloat(GrassBuffer.Load4(mad(bladeID, GRASS_BUFFER_SIZE, 0) << 2));
                const float2 bladeScale = asfloat(GrassBuffer.Load2(mad(bladeID, GRASS_BUFFER_SIZE, 4) << 2));
                const float bladeBend = asfloat(GrassBuffer.Load(mad(bladeID, GRASS_BUFFER_SIZE, 5) << 2));
                const uint2 bladeColors = asuint(GrassBuffer.Load2(mad(bladeID, GRASS_BUFFER_SIZE, 7) << 2));
                
                const float3 bladePosition = bladePositionRotation.xyz;
                const float bladeRotaion = bladePositionRotation.w;

                float4 vertexAttribute = grassMesh[localVertex];
                vertexAttribute.xy *= bladeScale.xy;

                vertexAttribute.z += pow(vertexAttribute.w, 3.0f) * bladeBend;
                
                float s = sin(bladeRotaion);
                float c = cos(bladeRotaion);
                float2x2 rotationMatrix = float2x2(s, c, -c, s);
                vertexAttribute.xz = mul(rotationMatrix, vertexAttribute.xz);

                Varyings output;
                output.positionCS = TransformWorldToHClip(bladePosition.xyz + vertexAttribute.xyz);
                output.color = lerp(UnPackColor(bladeColors.x), UnPackColor(bladeColors.y), vertexAttribute.w); 
                return output;
            }

            half4 Frag(const Varyings input) : SV_TARGET
            {
                return half4(input.color.xyz, 1.0f);
            }
            ENDHLSL
        }
    }
}