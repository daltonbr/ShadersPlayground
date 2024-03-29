﻿Shader "Custom/Water"
{
    Properties
    {
        // color of the water
        _Color("Color", Color) = (0.0, 0.0, 0.7, 0.7)
        // color of the edge effect
        _EdgeColor("Edge Color", Color) = (0.8, 0.8, 1, 0.7)
        // width of the edge effect
        _DepthFactor("Depth Factor", float) = 0.5
    }
SubShader
{
Pass
{

CGPROGRAM
float4 _Color;
float4 _EdgeColor;
float _DepthFactor;

// required to use ComputeScreenPos()
#include "UnityCG.cginc"

#pragma vertex vert
#pragma fragment frag

// Unity built-in - NOT required in Properties
sampler2D _CameraDepthTexture;

struct vertexInput
{
    float4 vertex : POSITION;
};

struct vertexOutput
{
    float4 pos : SV_POSITION;
    float4 screenPos : TEXCOORD1;
};

vertexOutput vert(vertexInput input)
{
    vertexOutput output;
    
    // convert obj-space position to camera clip space
    output.pos = UnityObjectToClipPos(input.vertex);
    
    // compute depth (screenPos is a float4)
    output.screenPos = ComputeScreenPos(output.pos);
    
    return output;
}

//float4 frag(vertexOutput input) : COLOR
//{
//  // sample camera depth texture
//  float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
//  float depth = Linear01Depth(depthSample).r;
//  // Because the camera depth texture returns a value between 0-1,
//  // we can use that value to create a grayscale color
//  // to test the value output.
//  float4 foamLine = float4(depth, depth, depth, 1);
//  return foamLine;
//}

float4 frag(vertexOutput input) : COLOR
{
    // Sample depth, just the red component.
    //#define SAMPLE_DEPTH_TEXTURE_PROJ(sampler, uv) (tex2Dproj(sampler, uv).r)
    float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(input.screenPos));
  
    /*
    // Z buffer to linear 0..1 depth
    inline float Linear01Depth( float z )
    {
        return 1.0 / (_ZBufferParams.x * z + _ZBufferParams.y);
    }
    // Z buffer to linear depth
    inline float LinearEyeDepth( float z )
    {
        return 1.0 / (_ZBufferParams.z * z + _ZBufferParams.w);
    }
    */
    float depth = LinearEyeDepth(depthSample).r;

    // apply the DepthFactor to be able to tune at what depth values
    // the foam line actually starts
    float foamLine = 1 - saturate(_DepthFactor * (depth - input.screenPos.w));

    // multiply the edge color by the foam factor to get the edge,
    // then add that to the color of the water
    float4 col = _Color + foamLine * _EdgeColor;
    return col;
    
}

  ENDCG
}}}
