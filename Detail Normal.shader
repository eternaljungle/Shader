Shader "Detail Normal"
{
    Properties
    {
        _BaseColor ("Color", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _DetailNormal ("Detail Normal", 2D) = "bump" {}
        _UVScale ("UV Scale", Float) = 1.0
        _DetailNormalScale("Detail Normal Scale", Float) = 1.0

        [Toggle(USE_DETAIL_NORMAL)] _UseDetailNormal ("use", float) = 0.0 
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #pragma shader_feature_fragment _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma shader_feature_fragment _SHADOWS_SOFT _SHADOWS_SOFT_HIGH _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_LOW
            #pragma shader_feature_fragment USE_DETAIL_NORMAL

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"


            struct Attribute
            {
                float3 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 position : TEXCOORD2;

            };

            cbuffer UnityPerMaterial
            {
                float _DetailNormalScale;
                float _UVScale;
            }

            Varyings Vert(const Attribute input)
            {
                float3 position = TransformObjectToWorld(input.position);
                float3 normal = TransformObjectToWorldNormal(input.normal);

                Varyings output;
                output.positionCS = TransformWorldToHClip(position);
                output.normal = normal;
                output.tangent = float4(TransformObjectToWorldDir(input.tangent.xyz), sign(input.tangent.w));
                output.uv0 = input.uv * _UVScale;
                output.uv1 = input.uv * _DetailNormalScale;
                output.position = position;
                return output;
              
            }

            //낮은 텍스쳐의 밀도를 높이기
            Texture2D _BaseColor;
            Texture2D _Normal;
            Texture2D _DetailNormal;

            SamplerState sampler_BaseColor;
            SamplerState sampler_Normal;
            SamplerState sampler_DetailNormal;

            half4 Frag(const Varyings input) : SV_TARGET
            {
                const float3 vertexNormal = normalize(input.normal);

                const half4 baseColor = _BaseColor.Sample(sampler_BaseColor, input.uv0);
                const half4 packedNormal = _Normal.Sample(sampler_Normal, input.uv0);
                const half3 unpackedNormal = UnpackNormal(packedNormal);

                #if defined(USE_DETAIL_NORMAL)
                const half4 packedDetailNormal = _DetailNormal.Sample(sampler_DetailNormal, input.uv1);
                const half4 unpackedDetailNormal = packedDetailNormal * 2.0f - 1.0f;
                const float3 normal = BlendNormalRNM(unpackedDetailNormal.xyz, unpackedNormal);

                #else
                const float3 normal = unpackedNormal;
                #endif


                float4 shadowCoord = TransformWorldToShadowCoord(input.position);
                Light mainLight = GetMainLight(shadowCoord);

                const float3 tangent = input.tangent.xyz;
                const float3 bitangent = cross(tangent, vertexNormal) * input.tangent.w * GetOddNegativeScale();
                const float3x3 tangentToWorld = float3x3(tangent, bitangent, vertexNormal);
                const float3 worldNormal = TransformTangentToWorldDir(normal, tangentToWorld,true);


                const float attenuation = max(0.0f, dot(mainLight.direction, normal)) * mainLight.shadowAttenuation;
                const half3 directLight = mainLight.color * attenuation * baseColor;
                const half3 indirectLight = SampleSH(normal) * baseColor;
                return half4(directLight + indirectLight, 1.0h);

            }
            ENDHLSL
        }
    }
}
