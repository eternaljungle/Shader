//Compute Shader

struct Particle
{
    float3 pos;
    float3 color;
};

static float dt = 1 / 60.0; // ConstBuffer로 받아올 수 있음

//StructuredBuffer<Particle> inputParticles : register(t0);
RWStructuredBuffer<Particle> outputParticles : register(u0);

[numthreads(256, 1, 1)]
void main(int3 gID : SV_GroupID, int3 gtID : SV_GroupThreadID,
          uint3 dtID : SV_DispatchThreadID)
{
    Particle p = outputParticles[dtID.x]; // Read
    
    float3 velocity = float3(-p.pos.y, p.pos.x, 0.0);
    p.pos += velocity * dt;
    
    outputParticles[dtID.x].pos = p.pos; // Write
}

//Vertex Shader
struct PSInput
{
    float4 position : SV_POSITION;
    float3 color : COLOR;
};

struct Particle
{
    float3 position;
    float3 color;
};

StructuredBuffer<Particle> particles : register(t0);

// VSInput이 없이 vertexID만 사용
PSInput main(uint vertexID : SV_VertexID)
{
    Particle p = particles[vertexID];
    
    PSInput output;
    
    output.position = float4(p.position.xyz, 1.0);
    
    output.color = p.color;

    return output;
}

//Pixel Shader
struct PSInput
{
    float4 position : SV_POSITION;
    float3 color : COLOR;
};

float4 main(PSInput input) : SV_TARGET
{
    return float4(input.color.rgb, 1.0);
}
