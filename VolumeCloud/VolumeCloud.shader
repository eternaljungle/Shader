Shader "Custom/Volume Cloud"
{
    SubShader
    {
        Pass
        {
         HLSLPROGRAM
         #pragma vertex Vert
         #pragma fragment Frag

         #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

         struct Attribute
         {
            float4 position : POSITION;

         };

         struct Varyings
         {
            float4 positionCS : SV_POSITION;
            float3 position : TEXCOORD0;
         };

         struct Ray
         {
            float3 origin;
            float3 direction;
         };

         Varyings Vert(Attribute input)
         {
            const float3 position = TransformObjectToWorld(input.position);
            
            Varyings output;
            output.positionCS = TransformWorldToHClip(position);
            output.position = position;

            return output;

         }

         Ray GetViewRay(const float3 position)
         {
            const float3 view = -GetWorldSpaceViewDir(position);
            Ray ray;
            ray.origin = position;
            ray.direction = normalize(view);
            return ray;
         }

         float DistanceToSphere(const float3 p, const float3 center, const float radius)
         {
            return distance(p, center) - radius;
         }

         float DistanceToCube(const float3 p, const float3 center, const float3 extent)
         {
            const float3 q = abs(p - center) - extent;
            return length(max(q.xyz, 0.0f)) + min(max(max(q.x, q.y), q.z), 0.0f);
         }
         
         float SDFVolume(float3 p)
         {
            const float ds = DistanceToSphere(p, float3(-0.2f, 0.0f, 0.0f), 0.4f);
            const float dc = DistanceToCube(p, float3(0.2f, 0.0f, 0.0f), float3(0.3f, 0.2f, 0.3f));
            return min(ds, dc);
         }

         float RayMarch(Ray ray)
         {
            float3 p = ray.origin;
            float t = 0.0f;
            for (int i = 0; i < 48; ++i)
            {
               float3 p = mad(ray.direction, t, ray.origin);
               float d = SDFVolume(p);
               if (d < 0.001f || t > 1000.0f) break;
               t += d;
            }
            return t;
         }

         float VolumeMarch(Ray ray)
         {
            float t = 0.0f;
            float acc = 0.0f;
            for (int i = 0; i < 128; ++i)
            {
               float3 p = mad(ray.direction, t, ray.origin);
               float d = SDFVolume(p);
               if (d < 0.0f) { acc += 0.01f; }

               t += 0.01f;
            }

            return acc;
         }

         float3 GetNormal(const float3 p)
         {
            const float2 epsilon = float2(0.001f, 0.0f);
            const float3 n = SDFVolume(p) - float3(
               SDFVolume(p - epsilon.xyy),
               SDFVolume(p - epsilon.yxy),
               SDFVolume(p - epsilon.yyx)
               );
               return normalize(n);
         }
         
         half4 Frag(Varyings input) : SV_TARGET
         {
            Ray ray = GetViewRay(input.position);
            const float t = VolumeMarch(ray);
            return half4(t, t, t, 1.0h);
         }
         ENDHLSL
        }
    }
}
