//**************************************************************************/
// Copyright 2011 Autodesk, Inc.  
// All rights reserved.
// Use of this software is subject to the terms of the Autodesk license 
// agreement provided at the time of installation or download, or which 
// otherwise accompanies this software in either electronic or hard copy form.   
//**************************************************************************/

// Simple phong shader with shadow map support based on the phong shader without shadow maps support.

/******* Lighting Macros *******/
/** To use "Object-Space" lighting definitions, change these two macros: **/
#define LIGHT_COORDS "World"
// #define OBJECT_SPACE_LIGHTS /* Define if LIGHT_COORDS is "Object" */

float4x4 WorldXf : World;
float4x4 WorldITXf : WorldInverseTranspose;
float4x4 WvpXf : WorldViewProjection;
float4x4 ViewIXf : ViewInverse;

float3 gLight0Dir : DIRECTION <
    string Object = "DirectionalLight0";
    string UIName =  "Lamp 0 Direction";
    string Space = (LIGHT_COORDS);
> = {0.7f,-0.7f,-0.7f};

float3 gLight0Color : SPECULAR <
    string Object = "DirectionalLight0";
    string UIName =  "Lamp 0 Color";
    string UIWidget = "Color";
> = {1.0f,1.0f,1.0f};


Texture2D gLight0ShadowMapTex : SHADOWMAP
<
    string UIName = "Shadow Map";
>;

// Shadow map sampler.
sampler2D gLight0ShadowMapSamp : SHADOWMAPSAMPLER
{
	Texture = <gLight0ShadowMapTex>;
};

// Shadow map transformation, i.e. the view-projection transformation of the light.
float4x4 gLight0ShadowMapXf : SHADOWMAPMATRIX
<
    string UIName = "Shadow Map Transformation";
>;

bool gLight0ShadowOn : ShadowFlag
<
	string SasUiLabel = "Light shadow flag";
> = false;

float3 gLight0ShadowColor : ShadowColor
<
	string SasUiLabel = "Light shadow color";
> = {0.07f,0.07f,0.07f};

float gLight0Bias : ShadowMapBias
<
> = {0.001f};


float3 gLightAmbiColor : AMBIENT = {0.07f,0.07f,0.07f};

float3 gSurfaceColor : DIFFUSE = {0.0f,0.0f,1.0f};
float gKd = 0.9f;
float gKs = 0.4f;
float gSpecExpon = 30.0f;
float3 avgXYZ = {0.3333,0.3334,0.3333};

struct appdata
{
	float3 Position	: POSITION;
	float3 Normal	: NORMAL;
};

struct vertexOutput
{
	float4 HPosition	: POSITION;
	float3 LightVec		: TEXCOORD1;
	float3 WorldNormal	: TEXCOORD2;
	float3 WorldPos		: TEXCOORD3;
	float3 WorldView	: TEXCOORD5;
};

vertexOutput std_d_VS(
	appdata IN,
	uniform float4x4 WorldITXf,
	uniform float4x4 WorldXf,
	uniform float4x4 ViewIXf,
	uniform float4x4 WvpXf,
	uniform float3 LampDir)
{
	vertexOutput OUT = (vertexOutput)0;
	OUT.WorldNormal = mul(float4(IN.Normal,0.0f),WorldITXf).xyz;
	float4 Po = float4(IN.Position.xyz,1.0f); // homogeneous location coordinates
	float4 Pw = mul(Po,WorldXf);	// convert to "world" space
	OUT.LightVec = -normalize(LampDir);
	OUT.WorldView = normalize(ViewIXf[3].xyz - Pw.xyz);
	OUT.WorldPos = Pw.xyz;
	OUT.HPosition = mul(Po,WvpXf);
	return OUT;
}

void phong(
	vertexOutput IN,
	uniform float Kd,
	uniform float Ks,
	uniform float SpecExpon,
	float3 LightColor,
	uniform float3 AmbiColor,
	out float3 DiffuseContrib,
	out float3 SpecularContrib)
{
	float3 Ln = normalize(IN.LightVec.xyz);
	float3 Nn = normalize(IN.WorldNormal);
	float3 Vn = normalize(IN.WorldView);
	float3 Hn = normalize(Vn + Ln);
	float hdn = dot(Hn,Nn);
	float ldn = dot(Ln,Nn);
	float4 litV = lit(ldn,hdn,SpecExpon);

	// Shadowing code
	float lightGain = 1.0f;
	if( gLight0ShadowOn )
	{
		
		float4 Pndc = mul( float4(IN.WorldPos,1.0) ,  gLight0ShadowMapXf); 
		Pndc.xyz /= Pndc.w; 
		if ( Pndc.x > -1.0f && Pndc.x < 1.0f && Pndc.y  > -1.0f   
			&& Pndc.y <  1.0f && Pndc.z >  0.0f && Pndc.z <  1.0f ) 
		{ 
			float2 uv = 0.5f * Pndc.xy + 0.5f; 
			uv = float2(uv.x,(1.0-uv.y)); //flipping y for DX support
			float z = Pndc.z - gLight0Bias / Pndc.w; 
			float val = z - tex2D(gLight0ShadowMapSamp, uv ).x;  
			lightGain = (val >= 0.0f)? 0.0f : 1.0f;  
			
		
		} 
	}
		
	ldn = litV.y * Kd * lightGain;
	
	hdn = Ks * ldn * litV.z;
	DiffuseContrib = ldn * LightColor;
	SpecularContrib = hdn * LightColor;
	
}

float4 phongPS(
	vertexOutput IN,
	uniform float3 SurfaceColor,
	uniform float Kd,
	uniform float Ks,
	uniform float SpecExpon,
	uniform float3 LampColor,
	uniform float3 AmbiColor) : COLOR
{
	float3 diffContrib;
	float3 specContrib;
	phong(IN,Kd,Ks,SpecExpon,LampColor,AmbiColor,diffContrib,specContrib);
	
	float3 result = specContrib + (SurfaceColor * diffContrib);
	// float3 result = SurfaceColor;
	return float4(result,1.0f);
}

technique10 Simple10
{
	pass p0
	{
		SetVertexShader(
			CompileShader(
				vs_4_0,
				std_d_VS(
					WorldITXf,
					WorldXf,
					ViewIXf,
					WvpXf,
					gLight0Dir)));

		SetGeometryShader(NULL);

		SetPixelShader(
			CompileShader(
				ps_4_0,
				phongPS(
					gSurfaceColor,
					gKd,
					gKs,
					gSpecExpon,
					gLight0Color,
					gLightAmbiColor)));
	}
}


