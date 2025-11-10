#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Hash function for pseudo-random number generation
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

[[ stitchable ]] float4 particleSparkle(float2 position, float4 bounds, float time) {
    // Normalize position
    float2 uv = position / bounds.zw;
    
    // Create grid of particles
    float2 grid = floor(uv * 20.0);
    float2 cellUV = fract(uv * 20.0) - 0.5;
    
    // Generate unique random seed for each cell
    float seed = hash(grid);
    
    // Particle position within cell (offset by random amount)
    float2 particlePos = cellUV - float2(
        hash(grid + float2(1.0, 0.0)) - 0.5,
        hash(grid + float2(0.0, 1.0)) - 0.5
    ) * 0.8;
    
    // Distance from particle center
    float dist = length(particlePos);
    
    // Animate particle size and opacity
    float particleTime = time * (0.5 + seed * 0.5);
    float size = 0.02 + sin(particleTime * 2.0) * 0.01;
    float opacity = sin(particleTime) * 0.5 + 0.5;
    
    // Create sparkle effect with falloff
    float sparkle = 1.0 - smoothstep(0.0, size, dist);
    sparkle *= opacity;
    
    // Add color variation based on seed
    float hue = seed;
    float3 color = float3(
        0.5 + 0.5 * sin(hue * 6.28 + time),
        0.5 + 0.5 * sin(hue * 6.28 + time + 2.09),
        0.5 + 0.5 * sin(hue * 6.28 + time + 4.18)
    );
    
    // Return particle color with alpha
    return float4(color * sparkle, sparkle * 0.8);
}

