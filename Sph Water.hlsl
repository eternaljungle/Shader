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
    float3 force;
    float density;
    float pressure;
    
    float3 color;
    float life;
    float size;
};


StructuredBuffer<Particle> particles : register(t0);

// VSInput이 없이 vertexID만 사용
PSInput main(uint vertexID : SV_VertexID)
{
    const float fadeLife = 0.2f;
    
    Particle p = particles[vertexID];
    
    PSInput output;
    
    output.position = float4(p.position.xyz, 1.0);
    output.color = p.color * saturate(p.life / fadeLife);
    output.life = p.life;
    output.size = p.size;

    return output;
}

//Pixel Shader
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

float CubicSpline(const float q)
{
    float coeff = 3.0f / (2.0f * 3.141592f);

    if (q < 1.0f)
        return coeff * (2.0f / 3.0f - q * q + 0.5f * q * q * q);
    else if (q < 2.0f)
        return coeff * pow(2.0f - q, 3.0f) / 6.0f;
    else // q >= 2.0f
        return 0.0f;
}

float4 main(PixelShaderInput input) : SV_TARGET
{
    float dist = length(float2(0.5, 0.5) - input.texCoord) * 2;
    
    // if (dist < 0.5)
    //     return float4(1, 1, 1, 1);
    
    float scale = CubicSpline(dist * 2);
    return float4(input.color.rgb * scale, 1);
}

