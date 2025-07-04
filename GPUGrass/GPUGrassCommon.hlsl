#ifndef DEF_GPU_GRASS_COMMON
#define DEF_GPU_GRASS_COMMON

#define VERTEX_PER_BLADE 15                                                                        
#define GRASS_BUFFER_SIZE 9                                                                        
                                                                                                   
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