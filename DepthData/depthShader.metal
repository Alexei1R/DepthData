//
//  depthShader.metal
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex data for a full-screen quad
struct Vertex {
    float2 position;
    float2 texCoord;
};

vertex VertexOut texture_vertex_shader(uint vertexID [[vertex_id]],
                                     constant Vertex *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID].position, 0.0, 1.0);
    out.texCoord = vertices[vertexID].texCoord;
    return out;
}

fragment float4 texture_fragment_shader(VertexOut in [[stage_in]],
                                      texture2d<float> depthTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float depth = depthTexture.sample(textureSampler, in.texCoord).r;
    
    // Normalize depth values for visualization
    // You might need to adjust these values based on your depth range
    float normalizedDepth = 1.0 - (depth / 5.0); // Assuming max depth of 5 meters
    
    return float4(normalizedDepth, normalizedDepth, normalizedDepth, 1.0);
}
