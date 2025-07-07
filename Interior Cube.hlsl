#ifndef DEF_INTERIOR_CUBE
#define DEF_INTERIOR_CUBE

float3 RayToCube(const float3 origin, const float3 direction, const float3 size,
    out float3 positionNear, out float3 positionFar,
    out float3 normalNear, out float3 normalFar)
{
    const float3 n = origin / direction;
    const float3 k = size / abs(direction);
    const float3 t0 = n - k;
    const float3 t1 = k - n;
    const float near = max(max(t0.x, t0.y), t0.z);
    const float far = min(min(t1.x, t1.y), t1.z);

    positionNear = mad(direction, near, origin);
    positionFar = mad(direction, far, origin);

    if (near > far || far < 0.0f) {return direction;}
    normalNear = -step(near.xxx, t0);
    normalFar = step(t1, far.xxx);
    return sign(direction) * (near > 0.0f ? normalNear : normalFar);
}

#endif 
