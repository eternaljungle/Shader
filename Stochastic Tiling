shader "Stochastic Tiling"
{
    Properties
    {
        _BaseColor("Base Color", 2D) = "white" {}
        _UVScale ("UV Scale", Float) = 1.0
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float3 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;

            };

            cbuffer UnityPerMaterial
            {
                float _UVScale;
            }

            Varyings Vert(Attributes input)
            {
                float3 position = TransformObjectToWorld(input.position);

                Varyings output;
                output.positionCS = TransformWorldToHClip(position);
                output.uv0 = position.xz * _UVScale;
                return output;

            }
            
            Texture2D _BaseColor;
            SamplerState sampler_BaseColor;

            half4 Frag(Varyings input) : SV_TARGET
            {
                float2 uv = input.uv0.xy;
                float2 coord = floor(uv);
                float2 jiter = float2(GenerateHashedRandomFloat(~asuint(coord.x)), GenerateHashedRandomFloat(asuint(coord.y) ^ ~asuint(coord.x)));

                float4 sc;
                sincos(jiter.xy * TWO_PI, sc.xy, sc.zw);
                float2x2 rotationX = float2x2(sc.x, sc.z, -sc.z, sc.x);
                float2x2 rotationZ = float2x2(sc.y, sc.w, -sc.w, sc.y);
                uv = mul(rotationX, uv);
                uv = mul(rotationZ, uv);

                half4 baseColor = _BaseColor.Sample(sampler_BaseColor, input.uv0.xy);
                return baseColor;

            }
;
            ENDHLSL
        }
    }
}
