//Vertex Shader
struct PSInput
{
    float4 position : SV_POSITION;
    float3 color : COLOR;
    float life : PSIZE0;
    float size : PSIZE1;
};

struct Particle
{
    float3 position;
    float3 velocity;
    float life;
    float size;
};

StructuredBuffer<Particle> particles : register(t0);

// VSInput이 없이 vertexID만 사용
PSInput main(uint vertexID : SV_VertexID)
{
    const float fadeLife = 0.5f;
    
    Particle p = particles[vertexID];
    
    PSInput output;
    
    output.position = float4(p.position.xyz, 1.0);
    
    float3 color1 = float3(1.0f, 0.5f, 0.2);
    float3 color2 = float3(1.0f, 0.3f, 0);
    
    float3 tempColor = lerp(color2, color1, pow(saturate(p.life / 1.0f), 2.0));
    
    output.color = tempColor * saturate(p.life / fadeLife);

    output.life = p.life;
    output.size = p.size;

    return output;
}

//Pixel Shader
Texture2D spriteTex : register(t0);
SamplerState linearWrapSampler : register(s1);

struct PixelShaderInput
{
    float4 pos : SV_POSITION; // not POSITION
    float2 texCoord : TEXCOORD;
    float3 color : COLOR;
    uint primID : SV_PrimitiveID;
};

float smootherstep(float x, float edge0 = 0.0f, float edge1 = 1.0f)
{
  // Scale, and clamp x to 0..1 range
    x = clamp((x - edge0) / (edge1 - edge0), 0, 1);

    return x * x * x * (3 * x * (2 * x - 5) + 10.0f);
}

float4 main(PixelShaderInput input) : SV_TARGET
{
    //float dist = length(float2(0.5, 0.5) - input.texCoord) * 2;
    //float scale = smootherstep(1 - dist);
    //return float4(input.color.rgb * scale, 1);
    
    float2 uv = input.texCoord;
    if (input.primID % 4 == 0 || input.primID % 4 == 2)
    {
        uv.x -= 0.5;
        uv.x = -uv.x;
        uv.x += 0.5;
    }
    if (input.primID % 4 == 1 || input.primID % 4 == 2)
    {
        uv.y -= 0.5;
        uv.y = -uv.y;
        uv.y += 0.5;
    }
    
    float4 sprite = spriteTex.Sample(linearWrapSampler, uv);

    return float4(input.color.rgb * sprite.rgb * sprite.a * 0.5, 1);
}

