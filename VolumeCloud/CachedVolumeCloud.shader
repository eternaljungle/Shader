Shader "Cached Volume Cloud"
{
    Properties
    {
        _CachedVolumeCloud ("Cached Volume Cloud", 2DArray) = "white"{}
        _Frames ("Frames", Integer) = 32
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }
        Blend SrcAlpha One
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float3 position : POSITION;
                float uv0 : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float frame : TEXCOORD1;
            };

            cbuffer UnityPerMaterial
            {
                int _Frames;
            }

            Varyings Vert(const Attribute input)
            {
                const float3 view = GetViewForwardDir();
                const float angle = atan2(view.x, view.z) + PI;
                const float frame = frac(angle / TWO_PI - 0.25f)* _Frames;
                
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.position);
                output.uv0 = input.uv0;
                output.frame = frame;
                return output;
            }

            Texture2DArray _CachedVolumeCloud;
            SamplerState sampler_CachedVolumeCloud;

            half4 Frag(const Varyings input) : SV_TARGET
            {
                const half4 cached = _CachedVolumeCloud.Sample(sampler_CachedVolumeCloud, float3(input.uv0.xy, input.frame));
                return cached;
            }
            
            ENDHLSL
        }
    }
}