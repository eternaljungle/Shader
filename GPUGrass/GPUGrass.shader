Shader "GPU Grass"
{
    Properties
    {
        Position ("Position", Vector) = (0, 0, 0)
    }
    SubShader
    {
        ZWrite On
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag 
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

            cbuffer UnityPerMaterial
            {
                float3 Position;
            }

            #include "./GPUGrassCommon.hlsl"   

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
                const Grass grass = LoadGrass(bladeID);

                float4 vertexAttribute = grassMesh[localVertex];
                vertexAttribute.xy *= grass.scale;

                vertexAttribute.z += pow(vertexAttribute.w, 3.0f) * grass.bend;
                
                float s = sin(grass.rotation);
                float c = cos(grass.rotation);
                float2x2 rotationMatrix = float2x2(s, c, -c, s);
                vertexAttribute.xz = mul(rotationMatrix, vertexAttribute.xz);

                Varyings output;
                output.positionCS = TransformWorldToHClip(Position + grass.position + vertexAttribute.xyz);
                output.color = lerp(UnPackColor(grass.colors.x), UnPackColor(grass.colors.y), vertexAttribute.w); 
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
