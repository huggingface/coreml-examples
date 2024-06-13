#include <metal_stdlib>
using namespace metal;

float3 hue2rgb(float hue) {
    float r = fabs(hue * 6.0 - 3.0) - 1.0;
    float g = 2.0 - fabs(hue * 6.0 - 2.0);
    float b = 2.0 - fabs(hue * 6.0 - 4.0);
    return saturate(float3(r, g, b));
}

kernel void SemanticMapToColor(texture2d<uint, access::read> semantic_map [[ texture(0) ]],
                               texture2d<float, access::write> image [[ texture(1) ]],
                               const device uint &n_classes [[ buffer(0) ]],
                               uint2 gid [[thread_position_in_grid]]) {
    uint class_id = semantic_map.read(gid).r;
    float hue = float(class_id) / float(n_classes);
    float3 rgb = hue2rgb(hue);
    image.write(float4(rgb, 1.0), gid);
}
