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
                float2 uv0 : TEXCOORD0;
                float3 normal : NORMAL;
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
                half4 color = 0;
                const int sliceCount = 32;
                float frame = input.frame;

                for (int i = 0; i < sliceCount; ++i)
                 {
                    float z = float(i) / sliceCount;
                    half4 sampled = _CachedVolumeCloud.Sample(sampler_CachedVolumeCloud, float3(input.uv0.xy, frame + z));
                    sampled.rgb *= 1.5;
                    sampled.a *= 2.0;
                    color += sampled;
                 }
                
                color *= 50.0;
                color /= sliceCount;

                float2 uv = input.uv0;
                float2 d = abs(uv - 0.5);  // 중심에서의 거리
                float edge = max(d.x, d.y); // 가장자리 거리

                float border = 0.05;         // 감쇠가 시작되는 거리
                float edgeFalloff = saturate((0.5 - edge - border) / (0.5 - border));
                edgeFalloff = pow(edgeFalloff, 2.5); // 지수로 감쇠 강도 조절

                color.rgb *= edgeFalloff;
                color.a   *= edgeFalloff;

                return color;
            }
            
            ENDHLSL
        }
    }
}
