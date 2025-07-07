#ifndef DEF_GPU_GRASS_COMMON
#define DEF_GPU_GRASS_COMMON

#define GRASS_BUFFER_SIZE 9
#define VERTEX_PER_BLADE 15     

struct Grass
{
   float3 position;
   float rotation;
   float2 scale;
   float bend;
   uint2 colors;
};

RWByteAddressBuffer GrassBufferStore;
void StoreGrass(Grass grass, uint id)
{                               
    GrassBufferStore.Store4(mad(id, GRASS_BUFFER_SIZE, 0) << 2, asuint(float4(grass.position, grass.rotation)));
    GrassBufferStore.Store2(mad(id, GRASS_BUFFER_SIZE, 4) << 2, asuint(grass.scale));
    GrassBufferStore.Store(mad(id, GRASS_BUFFER_SIZE, 6) << 2, asuint(grass.bend));
    GrassBufferStore.Store2(mad(id, GRASS_BUFFER_SIZE, 7) << 2, asuint(grass.colors));  
}

ByteAddressBuffer GrassBufferLoad;
Grass LoadGrass(uint id)
{
   Grass grass;
   grass.position = asfloat(GrassBufferLoad.Load3(mad(id, GRASS_BUFFER_SIZE, 0) << 2));
   grass.rotation = asfloat(GrassBufferLoad.Load(mad(id, GRASS_BUFFER_SIZE, 3) << 2));
   grass.scale = asfloat(GrassBufferLoad.Load2(mad(id, GRASS_BUFFER_SIZE, 4) << 2));
   grass.bend = asfloat(GrassBufferLoad.Load(mad(id, GRASS_BUFFER_SIZE, 6) << 2));
   grass.colors = asuint(GrassBufferLoad.Load2(mad(id, GRASS_BUFFER_SIZE, 7) << 2));
   return grass;
}

uint PackColor(float4 color)                                                                       
{                                                                                                  
   const uint r = uint(saturate(color.x) * 255.0f) << 24;
   const uint g = uint(saturate(color.y) * 255.0f) << 16;
   const uint b = uint(saturate(color.z) * 255.0f) << 8;
   const uint a = uint(saturate(color.w) * 255.0f) << 0;
   return uint(r | g | b | a);
}                                                                                              

float4 UnPackColor(uint color)
{
return float4(color >> 24 &0xFF, color >> 16 & 0xFF, color >> 8 & 0xFF, color & 0xFF) / 255.0f;
}
     
#endif                                                                                        
