shader "Stochastic Tiling"
{
    Properties
    {
        _BaseColor ("Base Color", 2D) = "white" {}
        [Normal] _Normal ("Normal", 2D) = "bump" {}
        _UVScale ("UV Scale", Float) = 1.0
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
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
                output.positionCS = TransformWorldToHClip(position); //Clip space
                output.uv0 = input.uv0.xy * _UVScale;
                output.normal = TransformObjectToWorldNormal(input.normal);
                output.tangent = float4(TransformObjectToWorldDir(input.tangent.xyz), sign(input.tangent.w));
                return output;

            }
            
            Texture2D _BaseColor;
            Texture2D _Normal;
            SamplerState sampler_BaseColor;
            SamplerState sampler_Normal;

            half4 Frag(Varyings input) : SV_TARGET
            {
                float2 uv = input.uv0.xy;
                float2 coord = floor(uv);

                //Pseudo-Random 회전값 생성
                float2 jiter = float2(GenerateHashedRandomFloat(~asuint(coord.x)), GenerateHashedRandomFloat(asuint(coord.y) ^ ~asuint(coord.x)));
                //회전행렬 생성
                float4 sc;
                sincos(jiter.xy * TWO_PI, sc.xy, sc.zw);
                float2x2 rotationX = float2x2(sc.x, sc.z, -sc.z, sc.x);
                float2x2 rotationZ = float2x2(sc.y, sc.w, -sc.w, sc.y);
                uv = mul(rotationX, uv);
                uv = mul(rotationZ, uv);
                
                //노멀값 변환 (tangent space -> world space로)
                float3 normal = input.normal;
                float3 tangent = input. tangent.xyz;
                float3 bitangent = cross(normal, tangent) * sign(input.tangent.w) * GetOddNegativeScale(); //normal이 뒤집히지 않도록
                float3x3 lookAt = float3x3(tangent, bitangent, normal);

                half4 baseColor = _BaseColor.Sample(sampler_BaseColor, uv);
                half3 normalTS = UnpackNormal(_Normal.Sample(sampler_Normal, uv)); //tangent space normal
                normal = mul(lookAt, normalTS);

                Light mainLight = GetMainLight();
                float lambert = dot(-mainLight.direction, normal);

                return half4(baseColor.xyz * lambert, 1.0h);
            }
            ENDHLSL
        }
    }
}
