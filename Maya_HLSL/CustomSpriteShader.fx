//-
// Copyright 2016 Autodesk, Inc.  All rights reserved.
//
// Use of this software is subject to the terms of the Autodesk license agreement
// provided at the time of installation or download, or which otherwise
// accompanies this software in either electronic or hard copy form.
//+

//
// This is a simple effect for particle sprites.
//

Texture2D map
<
	string UIName = "Sprite Texture";
	string UIWidget = "FilePicker";
	string ResourceType = "2D";
	string ResourceName = "";
>;

SamplerState SAMP_MMMLWWW
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
	AddressW = WRAP;
};

RasterizerState RAST_FS
{
	CullMode = FRONT;
	FillMode = SOLID;
};

// Uniform
extern float4x4 WorldIT : worldinversetranspose;
extern float4x4 World : world;
extern float4x4 WorldViewProj : worldviewprojection;
extern float4x4 Projection : projection;
extern float4x4 ProjectionInverse : projectioninverse;
extern float4x4 ViewProjectionInverse : viewprojectioninverse;
extern float4x4 ViewInverse : viewinverse;

// -------------------------------------- ShaderVertex --------------------------------------
struct vertexInS
{
	float3 Pm : POSITION;
	float3 Nm : NORMAL;
	float4 sprite : spritePP;
	float2 UV : TEXCOORD1;
};

struct vertOutS
{
	float3 Nw : TEXCOORD0;
	float3 Vw : TEXCOORD1;
	float2 UV : TEXCOORD2;
	float3 Pw : TEXCOORD4;
	float4 sprite : TEXCOORD5;
	float4 Pc : SV_Position;
};

vertOutS ShaderVertex( vertexInS inputs )
{
	vertOutS outputs;
	outputs.Pw = mul( float4(inputs.Pm, 1.0), World ).xyz;
	float3 worldCameraPosition = ViewInverse._41_42_43;
	outputs.Vw = worldCameraPosition - outputs.Pw;
	outputs.Nw = mul( float4(inputs.Nm, 0.0), WorldIT ).xyz;
	outputs.Pc = mul( float4(inputs.Pm, 1.0), WorldViewProj );
	outputs.UV = inputs.UV;
	outputs.sprite = inputs.sprite;
	return outputs;
}


// -------------------------------------- ShaderGeometry --------------------------------------
struct geometryInS
{
	float3 Nw : TEXCOORD0;
	float3 Vw : TEXCOORD1;
	float2 UV : TEXCOORD2;
	float3 Pw : TEXCOORD4;
	float4 sprite : TEXCOORD5;
	float4 Pc : SV_Position;
};

static const float2 cQuadPoints[4] = {
	float2(  0.5f,  0.5f ),
	float2( -0.5f,  0.5f ),
	float2(  0.5f, -0.5f ),
	float2( -0.5f, -0.5f ) };

void point2ViewAlignedTexturedQuad( geometryInS inputs[1],
									float4x4 projection,
									float4x4 projectionInverse,
									float4x4 viewProjInverse,
									float3 cameraPosition,
									inout TriangleStream<geometryInS> outStream )
{
	geometryInS outS = inputs[0];
	float2 spriteScale = outS.sprite.xy;
	float  spriteTwist = radians( -outS.sprite.z );

	float3 Cz = normalize( mul( outS.Pc, projectionInverse ).xyz );
	float3 Cy = float3( 0.0f, 1.0f, 0.0f );
	float3 Cx = normalize( cross( Cz, Cy ) );
	Cy = normalize( cross( Cx, Cz ) );

	// Rotate around Cz axis with specified twisting angle.
	float sinTheta = sin( spriteTwist * 0.5f );
	float cosTheta = cos( spriteTwist * 0.5f );;
	float4 q = float4( Cz * sinTheta, cosTheta );
	float4x4 qq = float4x4( q.x * q, q.y * q, q.z * q, q.w * q );
	float4x4 rot = float4x4(
		1-2*(qq._22+qq._33), 2*(qq._12+qq._34), 2*(qq._13-qq._24), 0,
		2*(qq._12-qq._34), 1-2*(qq._11+qq._33), 2*(qq._23+qq._14), 0,
		2*(qq._13+qq._24), 2*(qq._23-qq._14), 1-2*(qq._11+qq._22), 0,
		0, 0, 0, 1 );

	float4x4 tm = mul( rot, projection );
	float4 Cxc = mul( float4( Cx, 0.0f ), tm );
	float4 Cyc = mul( float4( Cy, 0.0f ), tm );

	outS.Nw = outS.Vw;

	float2 halfPixel = float2( 0.5f, 0.5f );

	[unroll] for( int i = 0; i < 4; ++i )
	{
		float2 scale = spriteScale * cQuadPoints[i];
		outS.Pc = inputs[0].Pc + Cxc * scale.x + Cyc * scale.y;
		outS.Pw = mul( outS.Pc, viewProjInverse );
		outS.Vw = cameraPosition - mul( outS.Pc, viewProjInverse ).xyz;
		outS.UV = cQuadPoints[i] + halfPixel;
		outStream.Append( outS );
	}
	outStream.RestartStrip();
}

[maxvertexcount( 4 )]
void ShaderGeometry( point geometryInS  inputs[ 1 ] : SV_PATCH, inout TriangleStream <geometryInS> outStream )
{
	point2ViewAlignedTexturedQuad( inputs, Projection, ProjectionInverse, ViewProjectionInverse, ViewInverse._41_42_43, outStream );
}


// -------------------------------------- ShaderPixel --------------------------------------
struct fragInS
{
	float3 Nw : TEXCOORD0;
	float3 Vw : TEXCOORD1;
	float2 UV : TEXCOORD2;
};

float4 ShaderPixel(fragInS IN) : SV_Target
{
	float4 color = map.Sample(SAMP_MMMLWWW, IN.UV);
	return float4(color.rgb, 1.0) * color.a;
}


// -------------------------------------- technique11 Main ---------------------------------------
technique11 Main
<
	int isTransparent = 1;
>
{
	pass P0
	{
		SetRasterizerState(RAST_FS);
		SetVertexShader(CompileShader(vs_4_0, ShaderVertex()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_4_0, ShaderGeometry()));
		SetPixelShader(CompileShader(ps_4_0, ShaderPixel()));
	}
}
