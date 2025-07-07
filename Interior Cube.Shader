Shader "Interior Cube"
{
    Properties
    {
        _InteriorCubemap ("Interior Cubemap", Cube) = "white" {}
        _Size ("Size", Vector) = (1, 1, 1)
        _Tiles("Tiles", Vector) = (1, 1, 1, 0)
    }
    SubShader
    {
        Pass
        {
            Cull Front
            
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./InterialCube.hlsl"

            struct Attribute
            {
                float3 position : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 position : TEXCOORD0;
                float3 view : TEXCOORD1;
            };

            cbuffer UnityPerMaterial
            {
                float3 _Size;
                float3 _Tiles;
            }

            Varyings Vert(const Attribute input)
            {
                const float3 position = TransformObjectToWorld(input.position);
                const float3 view = TransformWorldToObject(-GetWorldSpaceViewDir(position));
                
                Varyings output;
                output.positionCS = TransformWorldToHClip(position);
                output.position = input.position;
                output.view = view;
                return output;
            }

            TextureCube _InteriorCubemap;
            SamplerState sampler_InteriorCubemap;

            half4 Frag(const Varyings input) : SV_TARGET
            {
                float3 position = input.position * _Tiles;
                float3 view = input.view;
                const float3 coord = floor(position);
                const float r = GenerateHashedRandomFloat(asuint(coord));
                const float angle = floor(r * 4.0f * HALF_PI + 0.5f);
                const float s = sin (angle);
                const float c = cos (angle);
                position.xz = mul(float2x2(c, s, -s, c), position.xz);
                view.xz = mul(float2x2(c, s, -s, c), view.xz);
                const float3 origin = fmod(fmod(position, _Size.xyz) + _Size.xyz, _Size.xyz);

                const Light mainLight = GetMainLight();
                float3 pn, pf, nn, nf;
                float3 normal = RayToCube(origin, input.view, _Size, pn, pf, nn, nf);
                normal.xz = mul(float2x2(c, -s, s, c), normal.xz);
                const float halflambert = mad(dot(mainLight.direction, -normal), 0.5f, 0.5f);

                const half3 color = _InteriorCubemap.Sample(sampler_InteriorCubemap, pf) *halflambert;
                return half4(color.xyz, 1.0h);
            }
            ENDHLSL
        }

    }
}
