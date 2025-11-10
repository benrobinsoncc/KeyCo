#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] float4 geometricPattern(float2 position, float4 bounds, float time) {
    // Normalize position
    float2 uv = position / bounds.zw;
    
    // Create animated grid pattern
    float gridSize = 8.0;
    float2 gridUV = fract(uv * gridSize);
    
    // Animate grid with time
    float gridOffset = time * 0.2;
    float2 gridCoord = (uv + gridOffset) * gridSize;
    
    // Create wave distortion
    float waveX = sin(time * 0.5 + uv.y * 6.28) * 0.02;
    float waveY = cos(time * 0.4 + uv.x * 6.28) * 0.02;
    float2 distortedUV = uv + float2(waveX, waveY);
    
    // Grid lines with smooth falloff
    float2 gridLines = abs(fract(distortedUV * gridSize) - 0.5);
    float gridLine = smoothstep(0.0, 0.1, min(gridLines.x, gridLines.y));
    
    // Subtle pattern overlay (don't overpower)
    float pattern = gridLine * 0.15;
    
    // Add subtle color variation
    float colorShift = sin(time * 0.3 + uv.x * 2.0 + uv.y * 2.0) * 0.1;
    
    // Return subtle pattern overlay
    return float4(pattern + colorShift * 0.05, pattern + colorShift * 0.05, pattern + colorShift * 0.1, pattern);
}

