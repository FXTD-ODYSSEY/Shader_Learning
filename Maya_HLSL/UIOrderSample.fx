//**************************************************************************/
// Copyright 2011 Autodesk, Inc.  
// All rights reserved.
// Use of this software is subject to the terms of the Autodesk license 
// agreement provided at the time of installation or download, or which 
// otherwise accompanies this software in either electronic or hard copy form.   
//**************************************************************************/

// Simple shader which draws in constant color and demonstrates the usage of the UIOrder annotation 
// to control the order of display in the attribute editor.  If you do not specify the UIOrder uniform 
//parameters will be displayed in the order returned by the effect compiler, which is not warrantied.

Texture d : Diffuse
<
    string UIName = "Texture d ";
    int UIOrder = 20;
>;

Texture c : Diffuse
<
    string UIName = "Texture c ";
    int UIOrder = 17;
>;

Texture f : Diffuse
<
    string UIName = "Texture f";
    int UIOrder = 25;
>;

float e
<
   string UIName = "Parameter e";
   int UIOrder = 22;
>;

//a will be assigned the UI order corresponding  to the order in which the effect conmpier returns it
//given the other UIOrder are large numbers this should appear before.
float a
<
   string UIName = "Parameter a";
>;


float g
<
   string UIName = "Parameter g";
   int UIOrder = 35;
>;

float b
<
   string UIName = "Parameter b";
>;


float4x4 gWvpXf : WorldViewProjection < string UIType="None"; >;

struct appdata
{
	float3 Position	: POSITION;
	float3 Normal	: NORMAL;
};

struct vertexOutput
{
	float4 HPosition	: POSITION;	
};

vertexOutput std_d_VS( appdata IN )
{
	vertexOutput OUT = (vertexOutput)0;	
	float4 Po = float4(IN.Position.xyz,1.0f); // homogeneous location coordinates	
	OUT.HPosition = mul(Po,gWvpXf);
	return OUT;
}


float4 PS( vertexOutput IN) : COLOR
{
	return float4(1.0f,0.0f,0.0f,1.0f);
}

technique10 Simple10
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_4_0, std_d_VS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader( ps_4_0,PS()));
	}
}


