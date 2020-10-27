// Autodesk 'Uber' Shader for Maya and 3dsMax, DirectX 11, HLSL 5
//
// Copyright 2012 Autodesk, Inc.  All rights reserved.
// Use of this software is subject to the terms of the 
// Autodesk license agreement provided at the time of 
// installation or download, or which otherwise accompanies 
// this software in either electronic or hard copy form. 
//
// Thanks to:	Ben Cloward, Microsoft, AMD, NVidia (John McDonald & Bryan Dudash),
//				Vlachos et all, Colin Barre-Brisebois, John Hable, ATI (Scheuermann),
//				Kelemen-Szirmaykalos, Ward.

 
//------------------------------------
// Notes
//------------------------------------
// Shader uses 'pre-multiplied alpha' as its render state and this Uber Shader is build to work in unison with that.
// Alternatively, in Maya, the dx11Shader node allows you to set your own render states by supplying the 'overridesDrawState' annotation in the technique
// You may find it harder to get proper transparency sorting if you choose to do so.

// The technique annotation 'isTransparent' is used to tell Maya how treat the technique with respect to transparency.
//	- If set to 0 the technique is always considered opaque
//	- If set to 1 the technique is always considered transparent
//	- If set to 2 the plugin will check if the parameter marked with the OPACITY semantic is less than 1.0
//	- If set to 3 the plugin will use the transparencyTest annotation to create a MEL procedure to perform the desired test.
// Maya will then render the object twice. Front faces follow by back faces.

// For some objects you may need to switch the Transparency Algorithm to 'Depth Peeling' to avoid transparency issues.
// Models that require this usually have internal faces.




//------------------------------------
// Defines
//------------------------------------
// how many mip map levels should Maya generate or load per texture. 
// 0 means all possible levels
// some textures may override this value, but most textures will follow whatever we have defined here
// If you wish to optimize performance (at the cost of reduced quality), you can set NumberOfMipMaps below to 1

#define NumberOfMipMaps 0
#define PI 3.1415926
#define _3DSMAX_SPIN_MAX 99999

#ifndef _MAYA_
	#define _3DSMAX_	// at time of writing this shader, Nitrous driver did not have the _3DSMAX_ define set
	#define _ZUP_		// Maya is Y up, 3dsMax is Z up
#endif

#ifdef _MAYA_
	#define _SUPPORTTESSELLATION_	// at time of writing this shader, 3dsMax did not support tessellation
#endif





//------------------------------------
// State
//------------------------------------
#ifdef _MAYA_
	RasterizerState WireframeCullFront
	{
		CullMode = Front;
		FillMode = WIREFRAME;
	};
#endif



//------------------------------------
// Map Channels
//------------------------------------
#ifdef _3DSMAX_
	int texcoord0 : Texcoord
	<
		int Texcoord = 0;
		int MapChannel = 1;
		string UIWidget = "None";
	>;

	int texcoord1 : Texcoord
	<
		int Texcoord = 1;
		int MapChannel = 2;
		string UIWidget = "None";
	>;

	int texcoord2 : Texcoord
	<
		int Texcoord = 2;
		int MapChannel = 3;
		string UIWidget = "None";
	>;
#endif



//------------------------------------
// Samplers
//------------------------------------
SamplerState CubeMapSampler
{
	Filter = ANISOTROPIC;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;    
};

SamplerState SamplerAnisoWrap
{
	Filter = ANISOTROPIC;
	AddressU = Wrap;
	AddressV = Wrap;
};

SamplerState SamplerShadowDepth
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Border;
	AddressV = Border;
	BorderColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
};


//------------------------------------
// Textures
//------------------------------------
Texture2D EmissiveTexture
<
	string UIGroup = "Ambient and Emissive";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Emissive Map";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 101;
	int UVEditorOrder = 2;
>;

Texture2D AmbientOcclusionTexture
<
	string UIGroup = "Ambient and Emissive";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Ambient Occlusion Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 106;
	int UVEditorOrder = 2;
>;

Texture2D DiffuseTexture
<
	string UIGroup = "Diffuse";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Diffuse Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 201;
	int UVEditorOrder = 1;
>;

Texture2D LightmapTexture
<
	string UIGroup = "Diffuse";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Lightmap Map";
	string ResourceType = "2D";	
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 301;
	int UVEditorOrder = 3;
>;

Texture2D SpecularTexture
<
	string UIGroup = "Specular";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Specular Map";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 402;
	int UVEditorOrder = 4;
>;

Texture2D AnisotropicTexture
<
	string UIGroup = "Specular";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Anisotropic Direction Map";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 408;
	int UVEditorOrder = 10;
>;

Texture2D NormalTexture
<
	string UIGroup = "Normal";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Normal Map";
	string ResourceType = "2D";
	int mipmaplevels = 0;	// If mip maps exist in texture, Maya will load them. So user can pre-calculate and re-normalize mip maps for normal maps in .dds
	int UIOrder = 501;
	int UVEditorOrder = 5;
>;

TextureCube ReflectionTextureCube : environment
<
	string UIGroup = "Reflection";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Reflection CubeMap";	// Note: do not rename to 'Reflection Cube Map'. This is named this way for backward compatibilty (resave after compat_maya_2013ff10.mel)
	string ResourceType = "Cube";
	int mipmaplevels = 0; // Use (or load) max number of mip map levels so we can use blurring
	int UIOrder = 602;
	int UVEditorOrder = 6;
>;

Texture2D ReflectionTexture2D : environment
<
	string UIGroup = "Reflection";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Reflection 2D Map";
	string ResourceType = "2D";
	int mipmaplevels = 0; // Use (or load) max number of mip map levels so we can use blurring
	int UIOrder = 603;
	int UVEditorOrder = 6;
>;

Texture2D ReflectionMask
<
	string UIGroup = "Reflection";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Reflection Mask";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 701;
	int UVEditorOrder = 7;
>;

#ifdef _SUPPORTTESSELLATION_
	Texture2D DisplacementTexture
	<
		string UIGroup = "Tessellation and Displacement";
		string ResourceName = "";
		string UIWidget = "FilePicker";
		string UIName = "Displacement Map";
		string ResourceType = "2D";	
		int mipmaplevels = NumberOfMipMaps;
		int UIOrder = 801;
		int UVEditorOrder = 8;
	>;
#endif

Texture2D TranslucencyThicknessMask
<
	string UIGroup = "Translucency";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Thickness Mask";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 1001;
	int UVEditorOrder = 10;
>;

Texture2D BlendedNormalMask
<
	string UIGroup = "Diffuse";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Blended Normal Mask";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 1101;
	int UVEditorOrder = 11;
>;

TextureCube DiffuseIBLTextureCube
<
	string UIGroup = "Diffuse";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "IBL Cube Map";
	string ResourceType = "Cube";	
	int mipmaplevels = 0; // Use (or load) max number of mip map levels so we can use blurring
	int UIOrder = 1151;
	int UVEditorOrder = 10;
>;

Texture2D DiffuseIBLTexture2D
<
	string UIGroup = "Diffuse";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "IBL 2D Map";
	string ResourceType = "2D";
	int mipmaplevels = 0; // Use (or load) max number of mip map levels so we can use blurring
	int UIOrder = 1152;
	int UVEditorOrder = 9;
>;

Texture2D OpacityMaskTexture
<
	string UIGroup = "Opacity";
	string ResourceName = "";
	string UIWidget = "FilePicker";
	string UIName = "Opacity Mask";
	string ResourceType = "2D";
	int mipmaplevels = NumberOfMipMaps;
	int UIOrder = 222;
	int UVEditorOrder = 12;
>;



//------------------------------------
// Shadow Maps
//------------------------------------
TextureCube pointlight0ShadowMap : SHADOWMAP
<
	string Object = "Light 0";	// UI Group for lights, auto-closed
	string UIWidget = "None";
	int UIOrder = 5010;
>;

Texture2D light0ShadowMap : SHADOWMAP
<
	string Object = "Light 0";	// UI Group for lights, auto-closed
	string UIWidget = "None";
	int UIOrder = 5010;
>;

TextureCube pointlight1ShadowMap : SHADOWMAP
<
	string Object = "Light 1";
	string UIWidget = "None";
	int UIOrder = 5020;
>;

Texture2D light1ShadowMap : SHADOWMAP
<
	string Object = "Light 1";	// UI Group for lights, auto-closed
	string UIWidget = "None";
	int UIOrder = 5020;
>;

TextureCube pointlight2ShadowMap : SHADOWMAP
<
	string Object = "Light 2";
	string UIWidget = "None";
	int UIOrder = 5030;
>;

Texture2D light2ShadowMap : SHADOWMAP
<
	string Object = "Light 2";	// UI Group for lights, auto-closed
	string UIWidget = "None";
	int UIOrder = 5030;
>;

//------------------------------------
// Internal depth textures for Maya depth-peeling transparency
//------------------------------------
#ifdef _MAYA_

	Texture2D transpDepthTexture : transpdepthtexture
	<
		string UIWidget = "None";
	>;

	Texture2D opaqueDepthTexture : opaquedepthtexture
	<
		string UIWidget = "None";
	>;

#endif

//------------------------------------
// Per Frame parameters
//------------------------------------
cbuffer UpdatePerFrame : register(b0)
{
	float4x4 viewInv 		: ViewInverse 			< string UIWidget = "None"; >;   
	float4x4 view			: View					< string UIWidget = "None"; >;
	float4x4 prj			: Projection			< string UIWidget = "None"; >;
	float4x4 viewPrj		: ViewProjection		< string UIWidget = "None"; >;

	// A shader may wish to do different actions when Maya is rendering the preview swatch (e.g. disable displacement)
	// This value will be true if Maya is rendering the swatch
	bool IsSwatchRender     : MayaSwatchRender      < string UIWidget = "None"; > = false;

	// If the user enables viewport gamma correction in Maya's global viewport rendering settings, the shader should not do gamma again
	bool MayaFullScreenGamma : MayaGammaCorrection < string UIWidget = "None"; > = false;
}


//------------------------------------
// Per Object parameters
//------------------------------------
cbuffer UpdatePerObject : register(b1)
{
	float4x4 world 		: World 					< string UIWidget = "None"; >;
	float4x4 worldIT 	: WorldInverseTranspose 	< string UIWidget = "None"; >;
	#ifndef _SUPPORTTESSELLATION_
		float4x4 wvp		: WorldViewProjection				< string UIWidget = "None"; >;
	#endif


	// ---------------------------------------------
	// Lighting GROUP
	// ---------------------------------------------
	bool LinearSpaceLighting
	<
		string UIGroup = "Lighting";
		string UIName = "Linear Space Lighting";
		int UIOrder = 10;
	> = true;

	bool UseShadows
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string UIGroup = "Lighting";
			string UIName = "Shadows";
			int UIOrder = 11;
		#endif
	> = true;

	float shadowMultiplier
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string UIGroup = "Lighting";
			string UIWidget = "Slider";
			float UIMin = 0.000;
			float UIMax = 1.000;
			float UIStep = 0.001;
			string UIName = "Shadow Strength";
			int UIOrder = 12;
		#endif
	> = {1.0f};

	// This offset allows you to fix any in-correct self shadowing caused by limited precision.
	// This tends to get affected by scene scale and polygon count of the objects involved.
	float shadowDepthBias : ShadowMapBias
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string UIGroup = "Lighting";
			string UIWidget = "Slider";
			float UIMin = 0.000;
			float UISoftMax = 10.000;
			float UIStep = 0.001;
			string UIName = "Shadow Bias";
			int UIOrder = 13;
		#endif
	> = {0.01f};

	// flips back facing normals to improve lighting for things like sheets of hair or leaves
	bool flipBackfaceNormals
	<
		string UIGroup = "Lighting";
		string UIName = "Double Sided Lighting";
		int UIOrder = 14;
	> = true;


	// -- light props are inserted here via UIOrder 20 - 49


	float rimFresnelMin
	<
		string UIGroup = "Lighting";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Rim Light Min";
		int UIOrder = 60;
	> = 0.8;

	float rimFresnelMax
	<
		string UIGroup = "Lighting";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Rim Light Max";
		int UIOrder = 61;
	> = 1.0;

	float rimBrightness
	<
		string UIGroup = "Lighting";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 10.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.001;
		string UIName = "Rim Light Brightness";
		int UIOrder = 62;
	> = 0.0;


	// ---------------------------------------------
	// Ambient and Emissive GROUP
	// ---------------------------------------------
	bool UseEmissiveTexture
	<
		string UIGroup = "Ambient and Emissive";
		string UIName = "Emissive Map";
		int UIOrder = 100;
	> = false;

	float EmissiveIntensity
	<
		string UIGroup = "Ambient and Emissive";
		string UIName = "Emissive Intensity";
		int UIOrder = 103;
		float UIMin = 0.0;
		float UISoftMax = 2.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.1;
	> = 1.0f;

	float3 AmbientSkyColor : Ambient
	<
		string UIGroup = "Ambient and Emissive";
		string UIName = "Ambient Sky Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 104;
	> = {0.0f, 0.0f, 0.0f };

	float3 AmbientGroundColor : Ambient
	<
		string UIGroup = "Ambient and Emissive";
		string UIName = "Ambient Ground Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 105;
	> = {0.0f, 0.0f, 0.0f };

	bool UseAmbientOcclusionTexture
	<
		string UIGroup = "Ambient and Emissive";
		string UIName = "Ambient Occlusion Map";
		int UIOrder = 106;
	> = false;




	// ---------------------------------------------
	// Diffuse GROUP
	// ---------------------------------------------
	int DiffuseModel
	<
		string UIGroup = "Diffuse";
		string UIName = "Diffuse Model";
		string UIFieldNames ="Lambert:Blended Normal (Skin):Soften Diffuse (Hair)";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 198;
	> = false;

	bool UseDiffuseTexture
	<
		string UIGroup = "Diffuse";
		string UIName = "Diffuse Map";
		int UIOrder = 199;
	> = false;

	bool UseDiffuseTextureAlpha
	<
		string UIGroup = "Diffuse";
		string UIName = "Diffuse Map Alpha";
		int UIOrder = 200;
	> = false;

	float3 DiffuseColor : Diffuse
	<
		string UIGroup = "Diffuse";
		string UIName = "Diffuse Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 203;
	> = {1.0f, 1.0f, 1.0f };



	bool UseLightmapTexture
	<
		string UIGroup = "Diffuse";
		string UIName = "Lightmap Map";
		int UIOrder = 300;
	> = false;


	// blended normal

	// This mask map allows you to control the amount of 'softening' that happens on different areas of the object
	bool UseBlendedNormalTexture
	<
		string UIGroup = "Diffuse";
		string UIName = "Blended Normal Mask";
		int UIOrder = 1100;
	> = false;

	float blendNorm
	<
		string UIGroup = "Diffuse";
		float UIMin = 0.0;
		float UISoftMax = 1.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.1;
		string UIName   = "Blended Normal";
		int UIOrder = 1103;
	> = 0.15;


	bool UseDiffuseIBLMap
	<
		string UIGroup = "Diffuse";
		string UIName = "IBL Map";
		int UIOrder = 1150;
	> = false;

	int DiffuseIBLType
	<		
		string UIGroup = "Diffuse";
		string UIWidget = "Slider";
		string UIFieldNames ="Cube:2D Spherical:2D LatLong:Cube & 2D Spherical:Cube & 2D LatLong";
		string UIName = "IBL Type";
		int UIOrder = 1154;
		float UIMin = 0;
		float UIMax = 4;
		float UIStep = 1;
	> = 0;

	float DiffuseIBLIntensity
	<
		string UIGroup = "Diffuse";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 2.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.001;
		string UIName = "IBL Intensity";
		int UIOrder = 1155;
	> = 0.5;

	float DiffuseIBLBlur
	<
		string UIGroup = "Diffuse";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 10.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.001;
		string UIName = "IBL Blur";
		int UIOrder = 1156;
	> = 5.0;

	float DiffuseIBLRotation
	<
		string UIGroup = "Diffuse";
		string UIName = "IBL Rotation";
		float UIMin = 0.0;
		float UISoftMin = 0;
		float UISoftMax = 360;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 1.0;
		int UIOrder = 1157;
		string UIWidget = "Slider";
	> = {0.0f};

	float DiffuseIBLPinching
	<
		string UIGroup = "Diffuse";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMin = 1.0;
		float UISoftMax = 1.5;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.1;
		string UIName = "IBL Spherical Pinch";
		int UIOrder = 1158;
	> = 1.1;


	// ---------------------------------------------
	// Opacity GROUP
	// ---------------------------------------------
	float Opacity : OPACITY
	<
		string UIGroup = "Opacity";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Opacity";
		int UIOrder = 220;
	> = 1.0;

	bool UseOpacityMaskTexture
	<
		string UIGroup = "Opacity";
		string UIName = "Opacity Mask";
		int UIOrder = 221;
	> = false;

	// at what value do we clip away pixels
	float OpacityMaskBias
	<
		string UIGroup = "Opacity";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Opacity Mask Bias";
		int UIOrder = 224;
	> = 0.1;

	float OpacityFresnelMin
	<
		string UIGroup = "Opacity";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Opacity Fresnel Min";
		int UIOrder = 225;
	> = 0.0;

	float OpacityFresnelMax
	<
		string UIGroup = "Opacity";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Opacity Fresnel Max";
		int UIOrder = 226;
	> = 0.0;



	// ---------------------------------------------
	// Specular GROUP
	// ---------------------------------------------
	int SpecularModel
	<
		string UIGroup = "Specular";
		string UIName = "Specular Model";
		string UIFieldNames ="Blinn:Kelemen-Szirmaykalos (Skin):Anisotropic (Brushed Metal/Hair)";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 400;
	> = false;

	bool UseSpecularTexture
	<
		string UIGroup = "Specular";
		string UIName = "Specular Map";
		int UIOrder = 401;
	> = false;

	float3 SpecularColor : Specular
	<
		string UIGroup = "Specular";
		string UIName = "Specular Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 404;
	> = {1.0f, 1.0f, 1.0f };

	float SpecPower
	<
		string UIGroup = "Specular";
		string UIWidget = "Slider";
		float UIMin = 0.0;	// 0 for anisotropic
		float UISoftMax = 100.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Specular Power";
		int UIOrder = 405;
	> = 20.0;

	bool UseAnisotropicDirectionMap
	<
		string UIGroup = "Specular";
		string UIName = "Anisotropic Direction Map";
		int UIOrder = 406;
	> = false;

	int AnisotropicDirectionType
	<
		string UIGroup = "Specular";
		string UIName = "Anisotropic Direction Type";
		string UIFieldNames ="Tangent space (Comb/Flow map)";
		float UIMin = 0;
		float UIMax = 0;
		int UIOrder = 407;
	> = false;

	float AnisotropicRoughness1
	<
		string UIGroup = "Specular";
		string UIWidget = "Slider";
		float UIMin = -(_3DSMAX_SPIN_MAX);
		float UISoftMin = -1.0;
		float UISoftMax = 1.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Anisotropic Spread X";
		int UIOrder = 409;
	> = 0.2;

	float AnisotropicRoughness2
	<
		string UIGroup = "Specular";
		string UIWidget = "Slider";
		float UIMin = -(_3DSMAX_SPIN_MAX);
		float UISoftMin = -1.0;
		float UISoftMax = 1.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Anisotropic Spread Y";
		int UIOrder = 410;
	> = 0.4;

	bool UseAnisotropicMapAlphaMask
	<
		string UIGroup = "Specular";
		string UIWidget = "Slider";
		string UIName = "Mix Blinn-Anisotropic by Direction Alpha";
		int UIOrder = 412;
	> = false;


	// ---------------------------------------------
	// Normal GROUP
	// ---------------------------------------------
	bool UseNormalTexture
	<
		string UIGroup = "Normal";
		string UIName = "Normal Map";
		int UIOrder = 500;
	> = false;

	float NormalHeight
	<
		string UIGroup = "Normal";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 5.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Normal Height";
		int UIOrder = 503;
	> = 1.0;

	bool SupportNonUniformScale
	<
		string UIGroup = "Normal";
		string UIName = "Support Non-Uniform Scale";
		int UIOrder = 504;
	> = true;

	int NormalCoordsysX
	<		
		string UIGroup = "Normal";
		string UIWidget = "Slider";
		float UIMin = 0;
		float UIMax = 1;
		float UIStep = 1;
		string UIFieldNames ="Positive:Negative";
		string UIName = "Normal X (Red)";
		int UIOrder = 505;
	> = 0;

	int NormalCoordsysY
	<		
		string UIGroup = "Normal";
		string UIWidget = "Slider";
		float UIMin = 0;
		float UIMax = 1;
		float UIStep = 1;
		string UIFieldNames ="Positive:Negative";
		string UIName = "Normal Y (Green)";
		int UIOrder = 506;
	> = 0;



	// ---------------------------------------------
	// Reflection GROUP
	// ---------------------------------------------
	bool UseReflectionMap
	<
		string UIGroup = "Reflection";
		string UIName = "Reflection Map";
		int UIOrder = 600;
	> = false;

	int ReflectionType
	<		
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		string UIFieldNames ="Cube:2D Spherical:2D LatLong:Cube & 2D Spherical:Cube & 2D LatLong";
		string UIName = "Reflection Type";
		float UIMin = 0;
		float UIMax = 4;
		float UIStep = 1;
		int UIOrder = 601;
	> = 0;

	float ReflectionIntensity
	<
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 5.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.1;
		string UIName = "Reflection Intensity";
		int UIOrder = 604;
	> = 0.2;

	float ReflectionBlur
	<
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UISoftMax = 10.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.001;
		string UIName = "Reflection Blur";
		int UIOrder = 605;
	> = 0.0;

	float ReflectionRotation
	<
		string UIGroup = "Reflection";
		string UIName = "Reflection Rotation";
		float UISoftMin = 0;
		float UISoftMax = 360;
		float UIMin = 0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 1;
		int UIOrder = 606;
		string UIWidget = "Slider";
	> = {0.0f};

	float ReflectionPinching
	<
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		float UISoftMin = 1.0;
		float UISoftMax = 1.5;
		float UIStep = 0.1;
		float UIMin = 0.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		string UIName = "Reflection Spherical Pinch";
		int UIOrder = 607;
	> = 1.1;

	float ReflectionFresnelMin
	<
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Reflection Fresnel Min";
		int UIOrder = 608;
	> = 0.0;

	float ReflectionFresnelMax
	<
		string UIGroup = "Reflection";
		string UIWidget = "Slider";
		float UIMin = 0.0;
		float UIMax = 1.0;
		float UIStep = 0.001;
		string UIName = "Reflection Fresnel Max";
		int UIOrder = 609;
	> = 0.0;

	bool UseReflectionMask
	<
		string UIGroup = "Reflection";
		string UIName = "Reflection Mask";
		int UIOrder = 700;
	> = false;

	// When enabled uses the alpha channel of the specular texture to determine how much reflection needs to blur on parts of the object.
	// If this is disabled, the object's reflection is blurred equal amounts everywhere.
	bool UseSpecAlphaForReflectionBlur
	<
		string UIGroup = "Reflection";
		string UIName = "Spec Alpha For Reflection Blur";
		int UIOrder = 703;
	> = false;

	// When enabled, uses the specular color to tint the color of the cube map reflection.
	// When disabled, the cube map is not tinted and colors are used as found in the cube map.
	bool UseSpecColorToTintReflection
	<
		string UIGroup = "Reflection";
		string UIName = "Spec Color to Tint Reflection";
		int UIOrder = 704;
	> = false;

	bool ReflectionAffectOpacity
	<
		string UIGroup = "Reflection";
		string UIName = "Reflections Affect Opacity";
		int UIOrder = 705;
	> = true;

	#ifdef _SUPPORTTESSELLATION_
		// ---------------------------------------------
		// Tessellation and Displacement GROUP
		// ---------------------------------------------
		int DisplacementModel
		<
			string UIGroup = "Tessellation and Displacement";
			string UIName = "Displacement Model";
			string UIFieldNames ="Grayscale:Tangent Vector";
			float UIMin = 0;
			float UIMax = 1;
			float UIStep = 1;
			int UIOrder = 799;
		> = false;

		bool UseDisplacementMap
		<
			string UIGroup = "Tessellation and Displacement";
			string UIName = "Displacement Map";
			int UIOrder = 800;
		> = false;

		int VectorDisplacementCoordSys
		<		
			string UIGroup = "Tessellation and Displacement";
			string UIWidget = "Slider";
			string UIFieldNames ="Mudbox (XZY):Maya (XYZ)";
			string UIName = "Displacement Coordsys";
			float UIMin = 0;
			float UIMax = 1;
			float UIStep = 1;
			int UIOrder = 804;
		> = 0;

		float DisplacementHeight
		<
			string UIGroup = "Tessellation and Displacement";
			float UISoftMin = 0.0;
			float UISoftMax = 10.0;
			string UIName = "Displacement Height";
			float UIMin = -(_3DSMAX_SPIN_MAX);
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.1;
			int UIOrder = 805;
		> = 0.5;

		// This allows you to control what the 'base' value for displacement is.
		// When the offset value is 0.5, that means that a gray value (color: 128,128,128) will get 0 displacement.
		// A value of 0 would then dent in.
		// A value of 1 would then extrude.
		float DisplacementOffset
		<
			string UIGroup = "Tessellation and Displacement";
			float UISoftMin = -1.0;
			float UISoftMax = 1.0;
			float UIMin = -(_3DSMAX_SPIN_MAX);
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.1;
			string UIName = "Displacement Offset";
			int UIOrder = 806;
		> = 0.5;

		// This gives the artist control to prevent this shader from clipping away faces to quickly when displacement is actually keeping the faces on screen.
		// This is also important for e.g. shadow map generation to make sure displaced vertices are not clipped out of the light's view
		// See BBoxExtraScale for artist control over Maya clipping the entire object away when it thinks it leaves the view.
		float DisplacementClippingBias
		<
			string UIGroup = "Tessellation and Displacement";
			float UISoftMin = 0.0;
			float UISoftMax = 99.0;
			float UIMin = -(_3DSMAX_SPIN_MAX);
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.5;
			string UIName = "Displacement Clipping Bias";
			int UIOrder = 807;
		> = 5.0;

		// This gives the artist control to prevent maya from clipping away the entire object to fast in case displacement is used.
		// Its semantic has to be BoundingBoxExtraScale
		float BBoxExtraScale : BoundingBoxExtraScale
		<
			string UIGroup = "Tessellation and Displacement";
			float UIMin = 1.0;
			float UISoftMax = 10.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.5;
			string UIName = "Bounding Box Extra Scale";
			int UIOrder = 808;
		> = 1.0;

		float TessellationRange
		<
			string UIGroup = "Tessellation and Displacement";
			string UIWidget = "Slider";
			float UIMin = 0.0;
			float UISoftMax = 999.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 1.0;
			string UIName = "Tessellation Range";
			int UIOrder = 809;
		> = {0};

		float TessellationMin
		<
			string UIGroup = "Tessellation and Displacement";
			float UIMin = 1.0;
			float UISoftMax = 10.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.5;
			string UIName = "Tessellation Minimum";
			int UIOrder = 810;
		> = 3.0;

		float FlatTessellation
		<
			string UIGroup = "Tessellation and Displacement";
			float UIMin = 0.0;
			float UIMax = 1.0;
			float UIStep = 0.1;
			string UIName = "Flat Tessellation";
			int UIOrder = 811;
		> = 0.0;
	#endif



	// ---------------------------------------------
	// Translucency GROUP
	// ---------------------------------------------
	bool UseTranslucency
	<
		string UIGroup = "Translucency";
		string UIName = "Translucency";
		int UIOrder = 999;
	> = false;

	bool UseThicknessTexture
	<
		string UIGroup = "Translucency";
		string UIName = "Thickness Mask";
		int UIOrder = 1000;
	> = false;

	// This determines how much the normal (per pixel) influences the translucency.
	// If this value is 0, then the translucency is very uniform over the entire object.
	// Meaning: the object is translucent the same amount everywhere (although the thickness map will still be in affect, if you use one)
	// If the value is higher, for example 0.5. This means the translucent effect is broken up (distorted) based on the normal. 
	// The result will feel more organic.
	float translucentDistortion
	<
		string UIGroup = "Translucency";
		string UIWidget = "Spinner";
		float UIMin = 0.0;
		float UISoftMax = 10.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.05;
		string UIName = "Light Translucent Distortion";
		int UIOrder = 1003;
	> = 0.2;

	// This changes the focus or size of the translucent areas. 
	// Similar to how you can change the size of specular reflection by changing the specular power (aka Specular Glossiness).
	float translucentPower
	<
		string UIGroup = "Translucency";
		string UIWidget = "Spinner";
		float UIMin = 0.0;
		float UISoftMax = 20.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Light Translucent Power";
		int UIOrder = 1004;
	> = 3.0;

	// This is to adjust the amount of translucency caused by the light(s) behind the object.
	float translucentScale
	<
		string UIGroup = "Translucency";
		string UIWidget = "Spinner";
		float UIMin = 0.0;
		float UISoftMax = 1.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Light Translucent Scale";
		int UIOrder = 1005;
	> = 1.0;

	// This is the translucency the object always has, even if no light is directly behind it.
	float translucentMin
	<
		string UIGroup = "Translucency";
		string UIWidget = "Spinner";
		float UIMin = 0.0;
		float UISoftMax = 1.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		string UIName = "Translucent Minimum";
		int UIOrder = 1006;
	> = 0.0;

	float3 SkinRampOuterColor
	<
		string UIGroup = "Translucency";
		string UIName = "Outer Translucent Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 1007;
	> = {1.0f, 0.64f, 0.25f };

	float3 SkinRampMediumColor
	<
		string UIGroup = "Translucency";
		string UIName = "Medium Translucent Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 1008;
	> = {1.0f, 0.21f, 0.14f };

	float3 SkinRampInnerColor
	<
		string UIGroup = "Translucency";
		string UIName = "Inner Translucent Color";
		string UIWidget = "ColorPicker";
		int UIOrder = 1009;
	> = {0.25f, 0.05f, 0.02f };


	// ---------------------------------------------
	// UV assignment GROUP
	// ---------------------------------------------
	// Use the Surface Data Section to set your UVset names for each Texcoord.
	// E.g. TexCoord1 = uv:UVset
	// Then pick a Texcoord in the UV Section to use that UVset for a texture.

	int EmissiveTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Emissive Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2001;
	> = 0;

	int DiffuseTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Diffuse Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2002;
	> = 0;

	int LightmapTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Light Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2003;
	> = 1;

	int AmbientOcclusionTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Ambient Occlusion Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2003;
	> = 1;

	int BlendedNormalMaskTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Blended Normal Mask UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2004;
	> = 0;

	int OpacityMaskTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Opacity Mask UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2005;
	> = 0;

	int SpecularTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Specular Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2006;
	> = 0;

	int AnisotropicTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Anisotropic Dir Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2007;
	> = 0;

	int NormalTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Normal Map UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2008;
	> = 0;

	int ReflectionMaskTexcoord
	<		
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Reflection Mask UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2009;
	> = 0;

	#ifdef _SUPPORTTESSELLATION_
		int DisplacementTexcoord
		<		
			string UIGroup = "UV";
			string UIWidget = "Slider";
			string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
			string UIName = "Displacement Map UV";
			float UIMin = 0;
			float UIMax = 2;
			float UIStep = 1;
			int UIOrder = 2010;
		> = 0;
	#endif

	int ThicknessTexcoord
	<	
		string UIGroup = "UV";
		string UIWidget = "Slider";
		string UIFieldNames ="TexCoord0:TexCoord1:TexCoord2";
		string UIName = "Translucency Mask UV";
		float UIMin = 0;
		float UIMax = 2;
		float UIStep = 1;
		int UIOrder = 2011;
	> = 0;


} //end UpdatePerObject cbuffer



//------------------------------------
// Light parameters
//------------------------------------
cbuffer UpdateLights : register(b2)
{
	// ---------------------------------------------
	// Light 0 GROUP
	// ---------------------------------------------
	// This value is controlled by Maya to tell us if a light should be calculated
	// For example the artist may disable a light in the scene, or choose to see only the selected light
	// This flag allows Maya to tell our shader not to contribute this light into the lighting
	bool light0Enable : LIGHTENABLE
	<
		string Object = "Light 0";	// UI Group for lights, auto-closed
		string UIName = "Enable Light 0";
		int UIOrder = 20;
	#ifdef _MAYA_
		> = false;	// maya manages lights itself and defaults to no lights
	#else
		> = true;	// in 3dsMax we should have the default light enabled
	#endif

	// follows LightParameterInfo::ELightType
	// spot = 2, point = 3, directional = 4, ambient = 5,
	int light0Type : LIGHTTYPE
	<
		string Object = "Light 0";
		string UIName = "Light 0 Type";
		string UIFieldNames ="None:Default:Spot:Point:Directional:Ambient";
		int UIOrder = 21;
		float UIMin = 0;
		float UIMax = 5;
		float UIStep = 1;
	> = 2;	// default to spot so the cone angle etc work when "Use Shader Settings" option is used

	float3 light0Pos : POSITION 
	< 
		string Object = "Light 0";
		string UIName = "Light 0 Position"; 
		string Space = "World"; 
		int UIOrder = 22;
		int RefID = 0; // 3DSMAX
	> = {100.0f, 100.0f, 100.0f}; 

	float3 light0Color : LIGHTCOLOR 
	<
		string Object = "Light 0";
		#ifdef _3DSMAX_
			int LightRef = 0;
			string UIWidget = "None";
		#else
			string UIName = "Light 0 Color"; 
			string UIWidget = "Color"; 
			int UIOrder = 23;
		#endif
	> = { 1.0f, 1.0f, 1.0f};

	float light0Intensity : LIGHTINTENSITY 
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 0";
			string UIName = "Light 0 Intensity"; 
			float UIMin = 0.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.01;
			int UIOrder = 24;
		#endif
	> = { 1.0f };

	float3 light0Dir : DIRECTION 
	< 
		string Object = "Light 0";
		string UIName = "Light 0 Direction"; 
		string Space = "World"; 
		int UIOrder = 25;
		int RefID = 0; // 3DSMAX
	> = {100.0f, 100.0f, 100.0f}; 

	#ifdef _MAYA_
		float light0ConeAngle : HOTSPOT // In radians
	#else
		float light0ConeAngle : LIGHTHOTSPOT
	#endif
	<
		string Object = "Light 0";
		#ifdef _3DSMAX_
			int LightRef = 0;
			string UIWidget = "None";
		#else
			string UIName = "Light 0 Cone Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 26;
		#endif
	> = { 0.46f };

	#ifdef _MAYA_
		float light0FallOff : FALLOFF // In radians. Sould be HIGHER then cone angle or lighted area will invert
	#else
		float light0FallOff : LIGHTFALLOFF
	#endif
	<
		string Object = "Light 0";
		#ifdef _3DSMAX_
			int LightRef = 0;
			string UIWidget = "None";
		#else
			string UIName = "Light 0 Penumbra Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 27;
		#endif
	> = { 0.7f };

	float light0AttenScale : DECAYRATE
	<
		string Object = "Light 0";
		string UIName = "Light 0 Decay";
		float UIMin = 0.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		int UIOrder = 28;
	> = {0.0};

	bool light0ShadowOn : SHADOWFLAG
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 0";
			string UIName = "Light 0 Casts Shadow";
			string UIWidget = "None";
			int UIOrder = 29;
		#endif
	> = true;

	float4x4 light0Matrix : SHADOWMAPMATRIX		
	< 
		string Object = "Light 0";
		string UIWidget = "None"; 
	>;



	// ---------------------------------------------
	// Light 1 GROUP
	// ---------------------------------------------
	bool light1Enable : LIGHTENABLE
	<
		string Object = "Light 1";
		string UIName = "Enable Light 1";
		int UIOrder = 30;
	> = false;

	int light1Type : LIGHTTYPE
	<
		string Object = "Light 1";
		string UIName = "Light 1 Type";
		string UIFieldNames ="None:Default:Spot:Point:Directional:Ambient";
		float UIMin = 0;
		float UIMax = 5;
		int UIOrder = 31;
	> = 2;

	float3 light1Pos : POSITION 
	< 
		string Object = "Light 1";
		string UIName = "Light 1 Position"; 
		string Space = "World"; 
		int UIOrder = 32;
		int RefID = 1; // 3DSMAX
	> = {-100.0f, 100.0f, 100.0f}; 

	float3 light1Color : LIGHTCOLOR 
	<
		string Object = "Light 1";
		#ifdef _3DSMAX_
			int LightRef = 1;
			string UIWidget = "None";
		#else
			string UIName = "Light 1 Color"; 
			string UIWidget = "Color"; 
			int UIOrder = 33;
		#endif
	> = { 1.0f, 1.0f, 1.0f};

	float light1Intensity : LIGHTINTENSITY 
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 1";
			string UIName = "Light 1 Intensity"; 
			float UIMin = 0.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.01;
			int UIOrder = 34;
		#endif
	> = { 1.0f };

	float3 light1Dir : DIRECTION 
	< 
		string Object = "Light 1";
		string UIName = "Light 1 Direction"; 
		string Space = "World"; 
		int UIOrder = 35;
		int RefID = 1; // 3DSMAX
	> = {100.0f, 100.0f, 100.0f}; 

	#ifdef _MAYA_
		float light1ConeAngle : HOTSPOT // In radians
	#else
		float light1ConeAngle : LIGHTHOTSPOT
	#endif
	<
		string Object = "Light 1";
		#ifdef _3DSMAX_
			int LightRef = 1;
			string UIWidget = "None";
		#else
			string UIName = "Light 1 Cone Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 36;
		#endif
	> = { 0.46f };

	#ifdef _MAYA_
		float light1FallOff : FALLOFF // In radians. Sould be HIGHER then cone angle or lighted area will invert
	#else
		float light1FallOff : LIGHTFALLOFF
	#endif
	<
		string Object = "Light 1";
		#ifdef _3DSMAX_
			int LightRef = 1;
			string UIWidget = "None";
		#else
			string UIName = "Light 1 Penumbra Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 37;
		#endif
	> = { 0.0f };

	float light1AttenScale : DECAYRATE
	<
		string Object = "Light 1";
		string UIName = "Light 1 Decay";
		float UIMin = 0.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		int UIOrder = 38;
	> = {0.0};

	bool light1ShadowOn : SHADOWFLAG
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 1";
			string UIName = "Light 1 Casts Shadow";
			string UIWidget = "None";
			int UIOrder = 39;
		#endif
	> = true;

	float4x4 light1Matrix : SHADOWMAPMATRIX		
	< 
		string Object = "Light 1";
		string UIWidget = "None"; 
	>;



	// ---------------------------------------------
	// Light 2 GROUP
	// ---------------------------------------------
	bool light2Enable : LIGHTENABLE
	<
		string Object = "Light 2";
		string UIName = "Enable Light 2";
		int UIOrder = 40;
	> = false;

	int light2Type : LIGHTTYPE
	<
		string Object = "Light 2";
		string UIName = "Light 2 Type";
		string UIFieldNames ="None:Default:Spot:Point:Directional:Ambient";
		float UIMin = 0;
		float UIMax = 5;
		int UIOrder = 41;
	> = 2;

	float3 light2Pos : POSITION 
	< 
		string Object = "Light 2";
		string UIName = "Light 2 Position"; 
		string Space = "World"; 
		int UIOrder = 42;
		int RefID = 2; // 3DSMAX
	> = {100.0f, 100.0f, -100.0f}; 

	float3 light2Color : LIGHTCOLOR 
	<
		string Object = "Light 2";
		#ifdef _3DSMAX_
			int LightRef = 2;
			string UIWidget = "None";
		#else
			string UIName = "Light 2 Color"; 
			string UIWidget = "Color"; 
			int UIOrder = 43;
		#endif
	> = { 1.0f, 1.0f, 1.0f};

	float light2Intensity : LIGHTINTENSITY 
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 2";
			string UIName = "Light 2 Intensity"; 
			float UIMin = 0.0;
			float UIMax = _3DSMAX_SPIN_MAX;
			float UIStep = 0.01;
			int UIOrder = 44;
		#endif
	> = { 1.0f };

	float3 light2Dir : DIRECTION 
	< 
		string Object = "Light 2";
		string UIName = "Light 2 Direction"; 
		string Space = "World"; 
		int UIOrder = 45;
		int RefID = 2; // 3DSMAX
	> = {100.0f, 100.0f, 100.0f}; 

	#ifdef _MAYA_
		float light2ConeAngle : HOTSPOT // In radians
	#else
		float light2ConeAngle : LIGHTHOTSPOT
	#endif
	<
		string Object = "Light 2";
		#ifdef _3DSMAX_
			int LightRef = 2;
			string UIWidget = "None";
		#else
			string UIName = "Light 2 Cone Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 46;
		#endif
	> = { 0.46f };

	#ifdef _MAYA_
		float light2FallOff : FALLOFF // In radians. Sould be HIGHER then cone angle or lighted area will invert
	#else
		float light2FallOff : LIGHTFALLOFF
	#endif
	<
		string Object = "Light 2";
		#ifdef _3DSMAX_
			int LightRef = 2;
			string UIWidget = "None";
		#else
			string UIName = "Light 2 Penumbra Angle"; 
			float UIMin = 0;
			float UIMax = PI/2;
			int UIOrder = 47;
		#endif
	> = { 0.0f };

	float light2AttenScale : DECAYRATE
	<
		string Object = "Light 2";
		string UIName = "Light 2 Decay";
		float UIMin = 0.0;
		float UIMax = _3DSMAX_SPIN_MAX;
		float UIStep = 0.01;
		int UIOrder = 48;
	> = {0.0};

	bool light2ShadowOn : SHADOWFLAG
	<
		#ifdef _3DSMAX_
			string UIWidget = "None";
		#else
			string Object = "Light 2";
			string UIName = "Light 2 Casts Shadow";
			string UIWidget = "None";
			int UIOrder = 49;
		#endif
	> = true;

	float4x4 light2Matrix : SHADOWMAPMATRIX		
	< 
		string Object = "Light 2";
		string UIWidget = "None"; 
	>;

} //end lights cbuffer

// Shadow pass parameters
float lightRange : LightRange  
< 
	string UIWidget = "None"; 
> = 100000.0f;

//------------------------------------
// Hardware Fog parameters
//------------------------------------
bool MayaHwFogEnabled : HardwareFogEnabled < string UIWidget = "None"; > = false;
int MayaHwFogMode : HardwareFogMode < string UIWidget = "None"; > = 0;
float MayaHwFogStart : HardwareFogStart < string UIWidget = "None"; > = 0.0f;
float MayaHwFogEnd : HardwareFogEnd < string UIWidget = "None"; > = 100.0f;
float MayaHwFogDensity : HardwareFogDensity < string UIWidget = "None"; > = 0.1f;
float4 MayaHwFogColor : HardwareFogColor < string UIWidget = "None"; > = { 0.5f, 0.5f, 0.5f , 1.0f };

//------------------------------------
// Structs
//------------------------------------
struct APPDATA
{ 
	float3 position		: POSITION;
	float2 texCoord0	: TEXCOORD0; 
	float2 texCoord1	: TEXCOORD1; 
	float2 texCoord2	: TEXCOORD2;
	float3 normal		: NORMAL;
	float3 binormal		: BINORMAL;
	float3 tangent		: TANGENT; 
};

struct SHADERDATA
{
	float4 position			: SV_Position;
	float2 texCoord0		: TEXCOORD0; 
	float2 texCoord1		: TEXCOORD1;
	float2 texCoord2		: TEXCOORD2;
	float3 worldNormal   	: NORMAL;
	float4 worldTangent 	: TANGENT; 
	float3 worldPosition	: TEXCOORD3;

	#ifdef _SUPPORTTESSELLATION_
		// Geometry generated control points:
		// .worldPosition is CP0, so we don't need to store it again
		float3 CP1    : TEXCOORD4;
		float3 CP2    : TEXCOORD5;

		// PN-AEN with displacement fix:
		float4 dominantEdge    : TEXCOORD6;	// both vertices of an edge
		float2 dominantVertex  : TEXCOORD7;	// corner

		// Dominant normal and tangent for VDM crack fix:
		// this could be compacted into less texcoords, but left as-is for readability
		float3 dominantNormalE0 : TEXCOORD8;
		float3 dominantNormalE1 : TEXCOORD9;
		float3 dominantNormalCorner : TEXCOORD10;

		float3 dominantTangentE0 : TEXCOORD11;
		float3 dominantTangentE1 : TEXCOORD12;
		float3 dominantTangentCorner : TEXCOORD13;

		float clipped : CLIPPED;
	#endif
	float3 FogFactor	: TEXCOORD14;
};


#ifdef _SUPPORTTESSELLATION_
	struct HSCONSTANTDATA
	{
		float TessFactor[3]		: SV_TessFactor;		// tessellation amount for each edge of patch
		float InsideTessFactor	: SV_InsideTessFactor;	// tessellation amount within a patch surface (would be float2 for quads)
		float3 CPCenter			: CENTER;				// Geometry generated center control point
	};
#endif


//------------------------------------
// Functions
//------------------------------------

float2 pickTexcoord(int index, float2 t0, float2 t1, float2 t2)
{
	float2 tcoord = t0;

	if (index == 1)
		tcoord = t1;
	else if (index == 2)
		tcoord = t2;

	return tcoord;
}

float3 RotateVectorYaw(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);

	rotatedVec.x = ( cos(angle) * vec.x ) - ( sin(angle) * vec.z );
	rotatedVec.z = ( sin(angle) * vec.x ) + ( cos(angle) * vec.z );	

	return rotatedVec;
}

float3 RotateVectorRoll(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);

	#ifdef _ZUP_
		rotatedVec.z = ( cos(angle) * vec.z ) - ( sin(angle) * vec.y );
		rotatedVec.y = ( sin(angle) * vec.z ) + ( cos(angle) * vec.y );
	#else
		rotatedVec.y = ( cos(angle) * vec.y ) - ( sin(angle) * vec.z );
		rotatedVec.z = ( sin(angle) * vec.y ) + ( cos(angle) * vec.z );	
	#endif	

	return rotatedVec;
}

float3 RotateVectorPitch(float3 vec, float degreeOfRotation)
{
	float3 rotatedVec = vec;
	float angle = radians(degreeOfRotation);

	rotatedVec.x = ( cos(angle) * vec.x ) - ( sin(angle) * vec.y );
	rotatedVec.y = ( sin(angle) * vec.x ) + ( cos(angle) * vec.y );	

	return rotatedVec;
}

// Spot light cone
float lightConeangle(float coneAngle, float coneFalloff, float3 lightVec, float3 lightDir) 
{ 
	// the cone falloff should be equal or bigger then the coneAngle or the light inverts
	// this is added to make manually tweaking the spot settings easier.
	if (coneFalloff < coneAngle)
		coneFalloff = coneAngle;

	float LdotDir = dot(normalize(lightVec), lightDir); 

	// cheaper cone, no fall-off control would be:
	// float cone = pow(saturate(LdotDir), 1 / coneAngle); 

	// higher quality cone (more expensive):
	float cone = smoothstep( cos(coneFalloff), cos(coneAngle), LdotDir);

	return cone; 
} 

float2 SphericalReflectionUVFunction(float3 ReflectVec, float pinching)
{
	float AddOp = ((ReflectVec.x * ReflectVec.x) + (ReflectVec.y * ReflectVec.y));
	float AddOp3054 = (ReflectVec.z + pinching);
	float AddOp3057 = (AddOp + (AddOp3054 * AddOp3054));
	float MulOp = (sqrt(AddOp3057) * 2.0);
	float AddOp3059 = ((ReflectVec.x / MulOp) + 0.5);
	float AddOp3062 = ((ReflectVec.y / MulOp) + 0.5);
	float2 VectorConstruct = float2(AddOp3059, AddOp3062);
	return VectorConstruct.xy;
}

float2 Latlong(float3 v) 
{
	// Some geometries in Maya have trouble if the normal points exactly to an up vector
	// This caused noise-like artifacts when used in combination with mip-map blurring.
	// This hack-around adds a tiny offset to resolve it:
	v += float3(0.00001, 0.00001, 0.00001);

	#ifndef _ZUP_
		v = v.xzy;	// flip zy because this function will calculate with z-up
	#endif

	v = normalize(v);
	float theta = acos(v.z); // +z is up 

	float phi = atan2(v.y, v.x) + PI;
	return float2(phi / (2*PI), theta / PI);
}

#define SHADOW_FILTER_TAPS_CNT 10
float2 SuperFilterTaps[SHADOW_FILTER_TAPS_CNT] 
< 
	string UIWidget = "None"; 
> = 
{ 
    {-0.84052f, -0.073954f}, 
    {-0.326235f, -0.40583f}, 
    {-0.698464f, 0.457259f}, 
    {-0.203356f, 0.6205847f}, 
    {0.96345f, -0.194353f}, 
    {0.473434f, -0.480026f}, 
    {0.519454f, 0.767034f}, 
    {0.185461f, -0.8945231f}, 
    {0.507351f, 0.064963f}, 
    {-0.321932f, 0.5954349f} 
};

float shadowMapTexelSize 
< 
	string UIWidget = "None"; 
> = {0.00195313}; // (1.0f / 512)

// Shadows:
// Percentage-Closer Filtering
float lightShadow(float4x4 LightViewPrj, uniform Texture2D ShadowMapTexture, float3 VertexWorldPosition)
{	
	float shadow = 1.0f;

	float4 Pndc = mul( float4(VertexWorldPosition.xyz,1.0) ,  LightViewPrj); 
	Pndc.xyz /= Pndc.w; 
	if ( Pndc.x > -1.0f && Pndc.x < 1.0f && Pndc.y  > -1.0f   
		&& Pndc.y <  1.0f && Pndc.z >  0.0f && Pndc.z <  1.0f ) 
	{ 
		float2 uv = 0.5f * Pndc.xy + 0.5f; 
		uv = float2(uv.x,(1.0-uv.y));	// maya flip Y
		float z = Pndc.z - shadowDepthBias / Pndc.w; 

		// we'll sample a bunch of times to smooth our shadow a little bit around the edges:
		shadow = 0.0f;
		for(int i=0; i<SHADOW_FILTER_TAPS_CNT; ++i) 
		{ 
			float2 suv = uv + (SuperFilterTaps[i] * shadowMapTexelSize);
			float val = z - ShadowMapTexture.SampleLevel(SamplerShadowDepth, suv, 0 ).x;
			shadow += (val >= 0.0f) ? 0.0f : (1.0f / SHADOW_FILTER_TAPS_CNT);
		}

		// a single sample would be:
		// shadow = 1.0f;
		// float val = z - ShadowMapTexture.SampleLevel(SamplerShadowDepth, uv, 0 ).x;
		// shadow = (val >= 0.0f)? 0.0f : 1.0f;
		
		shadow = lerp(1.0f, shadow, shadowMultiplier);  
	} 

	return shadow;
}

// point light shadow
float pointLightShadow(uniform TextureCube ShadowMapTexture, float3 VertexWorldPosition, float3 lightPos)
{
	float shadow = 1.0f;
	float3 lookup = VertexWorldPosition - lightPos;
	float Distance = length(lookup);
	float3 normalizeLookup = normalize(lookup);
	float SampledDistance = (ShadowMapTexture.Sample(CubeMapSampler, normalizeLookup).r)*lightRange;
	if (SampledDistance > 0.0)
	{
		if (Distance <= SampledDistance + shadowDepthBias*Distance) {
			shadow = 1.0f;
		} else {
			shadow = 0.0f;
		}

		shadow = lerp(1.0f, shadow, shadowMultiplier);
	}

	return shadow;
}


// This function is a modified version of Colin Barre-Brisebois GDC talk
float3 translucency(float3 thickness, float3 V, float3 L, float3 N, float lightAttenuation, 
					float gammaCorrection, float3 albedoColor)
{
	float3 LightVec = L + (N * translucentDistortion);
	float fLTDot = pow(saturate(dot(V,-LightVec)), translucentPower) * translucentScale;
	float3 translucence = lightAttenuation * (fLTDot + translucentMin) * thickness;

	float3 skinDepthColor = albedoColor * translucence;

	// if the outcolor is set to complete black, we assume user does not want to use ramp
	// We'll then use the above: albedo * translucence
	if (SkinRampOuterColor.r > 0 && SkinRampOuterColor.g > 0 && SkinRampOuterColor.b > 0)
	{
		if (translucence.r > 0.9)
		{
			skinDepthColor = lerp( SkinRampOuterColor, float3(1,1,1), (translucence.r-0.9)/0.1);
		}
		else if (translucence.r > 0.7)
		{
			skinDepthColor = lerp( SkinRampMediumColor, SkinRampOuterColor, (translucence.r-0.7)/0.2);
		}
		else if (translucence.r > 0.4)
		{
			skinDepthColor = lerp( SkinRampInnerColor, SkinRampMediumColor, (translucence.r-0.4)/0.3);
		}
		else
		{
			skinDepthColor = lerp( float3(0,0,0), SkinRampInnerColor, translucence.r/0.4);
		}

		skinDepthColor = pow( skinDepthColor, gammaCorrection);
	}

	return skinDepthColor;
}

// This function is from Nvidia's Human Head demo
float fresnelReflectance( float3 H, float3 V, float F0 )  
{
	float base = 1.0 - dot( V, H );
	float exponential = pow( base, 5.0 );  
	return exponential + F0 * ( 1.0 - exponential );
}

// This function is from Nvidia's Human Head demo
float beckmannBRDF(float ndoth, float m)
{
  float alpha = acos( ndoth );  
  float ta = tan( alpha );  
  float val = 1.0/(m*m*pow(ndoth,4.0)) * exp(-(ta*ta)/(m*m));
  return val;  
}

// This function is from Nvidia's Human Head demo
float3 KelemenSzirmaykalosSpecular(float3 N, float3 L, float3 V, float roughness, float3 specularColorIn)
{
	float3 result = float3(0.0, 0.0, 0.0);
	float ndotl = dot(N, L);
	if (ndotl > 0.0)
	{
		float3 h = L + V;
		float3 H = normalize( h );
		float ndoth = dot(N, H);
		float PH = beckmannBRDF(ndoth, roughness);
		float F = fresnelReflectance( H, V, 0.028 );
		float frSpec = max( PH * F / dot( h, h ), 0 ); 
		result = ndotl * specularColorIn * frSpec;
	}
	return result;
}

// This function is from John Hable's Siggraph talk
float3 blendedNormalDiffuse(float3 L, float3 Ng, float3 Nm, float softenMask, float shadow)
{
	float redBlend = lerp(0, 0.9, softenMask);
	float redSoften = redBlend * blendNorm;
	float blueBlend = lerp(0, 0.35, softenMask);
	float blueSoften = blueBlend * blendNorm;
	
	float DNr = (saturate(dot(Ng, L) * (1 - redSoften) + redSoften) * shadow);//diffuse using geometry normal
	float DNb = (saturate(dot(Nm, L) * (1 - blueSoften) + blueSoften) * shadow);//diffuse using normal map
	float R = lerp(DNb, DNr, redBlend);//final diffuse for red channel using more geometry normal
	float B = lerp(DNb, DNr, blueBlend);//final diffuse for blue using more normal map
	float3 finalDiffuse = float3(R, B, B);
	float cyanReduction = 0.03 + R;
	finalDiffuse.gb = min(cyanReduction, finalDiffuse.gb);
	return finalDiffuse;
}

#ifdef _SUPPORTTESSELLATION_
	// Pick dominant for crack free displacement (original function by Bryan Dudash, modified to support any float3)
	float3 PickDominant( float3 vec,			// vector to change
					float U, float V, float W,	// barycoords
					float3 DE0A, float3 DE0B,	// domimant edge 0 vertex A and B
					float3 DE1A, float3 DE1B,	// domimant edge 1 vertex A and B
					float3 DE2A, float3 DE2B,	// domimant edge 2 vertex A and B
					float3 DV0, float3 DV1, float3 DV2 )	// dominant corners
	{
		// Override the texture coordinates along the primitive edges and at the corners.  
		// Keep the original interpolated coords for the inner area of the primitive.

		float3 dominantVector = vec;

		float edgeThreshold = 0.0001f;
		float edgeU = (U == 0) ? 1 : 0;
		float edgeV = (V == 0) ? 1 : 0;
		float edgeW = (W == 0) ? 1 : 0;

		float corner = ((edgeU + edgeV + edgeW) == 2) ? 1 : 0;		// two are 0, means we are a corner
		float edge   = ((edgeU + edgeV + edgeW) == 1) ? 1 : 0;		// one of them is 0, means we are an edge
		float innerarea = ((edgeU + edgeV + edgeW) == 0) ? 1 : 0;	// none are 0, means we are interior

		if (innerarea != 1)
		{
			// Note: the order of the vertices/edges we choose here can be different per application
			//		 and depend on how the index buffer was generated.
			//		 These work for Maya with its PN-AEN18 primitive generator
			if (corner)
			{
				if (U > 1.0 - edgeThreshold)
					dominantVector = DV1;
				else if (V > 1.0 - edgeThreshold)
					dominantVector = DV2;
				else if (W > 1.0 - edgeThreshold)
					dominantVector = DV0;	
			}
			else
			{
				if (edgeU)
					dominantVector = lerp(DE2A, DE2B, W);
				else if (edgeV)
					dominantVector = lerp(DE0A, DE0B, U);
				else 
					dominantVector = lerp(DE1A, DE1B, V);
			}
		}

		return dominantVector;
	}

	// outside of view?
	float IsClipped(float4 clipPos)
	{
		float W = clipPos.w + DisplacementClippingBias;	// bias allows artist to control to early clipping due to displacement
		// Test whether the position is entirely inside the view frustum.
		return (-W <= clipPos.x && clipPos.x <= W
			 && -W <= clipPos.y && clipPos.y <= W
			 && -W <= clipPos.z && clipPos.z <= W)
		   ? 0.0f
		   : 1.0f;
	}

	// Compute whether all three control points along the edge are outside of the view frustum.
	// By doing this, we're ensuring that 
	// 1.0 means clipped, 0.0 means unclipped.
	float ComputeClipping(float3 cpA, float3 cpB, float3 cpC)
	{
		// Compute the projected position for each position, then check to see whether they are clipped.
		float4 projPosA = mul( float4(cpA,1), viewPrj ),
			   projPosB = mul( float4(cpB,1), viewPrj ),
			   projPosC = mul( float4(cpC,1), viewPrj );
     
		return min(min(IsClipped(projPosA), IsClipped(projPosB)), IsClipped(projPosC));
	}

	// PN Triangles and PN-AEN control points:
	float3 ComputeCP(float3 posA, float3 posB, float3 normA) 
	{
		return (2.0f * posA + posB - (dot((posB - posA), normA) * normA)) / 3.0f;
	}
#endif

// Clip pixel away when opacity mask is used
void OpacityMaskClip(float2 uv)
{
	if (UseOpacityMaskTexture)
	{
		float OpacityMaskMap = OpacityMaskTexture.Sample(SamplerAnisoWrap, uv).x;

		// clip value when less then 0 for punch-through alpha.
		clip( OpacityMaskMap < OpacityMaskBias ? -1:1 );
	}
}

// Ward anisotropic specular lighting, modified to support anisotropic direction map (aka Comb or Flow map)
float3 WardAniso(float3 N, float3 H, float NdotL, float NdotV, float Roughness1, float Roughness2, float3 anisotropicDir, float3 specColor)
{
	float3 binormalDirection = cross(N, anisotropicDir);

	float HdotN = dot(H, N);
	float dotHDirRough1 = dot(H, anisotropicDir) / Roughness1;
	float dotHBRough2 = dot(H, binormalDirection) / Roughness2;
 
	float attenuation = 1.0;
	float3 spec = attenuation * specColor
		* sqrt(max(0.0, NdotL / NdotV)) 
		* exp(-2.0 * (dotHDirRough1 * dotHDirRough1 
		+ dotHBRough2 * dotHBRough2) / (1.0 + HdotN));

	return spec;
}

// Calculate a light:
struct lightOut
{
	float Specular;
	float3 Color;
};

lightOut CalculateLight	(	bool lightEnable, int lightType, float lightAtten, float3 lightPos, float3 vertWorldPos, 
							float3 lightColor, float lightIntensity, float3 lightDir, float lightConeAngle, float lightFallOff, float4x4 lightViewPrjMatrix, uniform Texture2D lightShadowMap,
							uniform TextureCube pointlightShadowMap, bool lightShadowOn, float3 vertexNormal, float3 normal, float3 diffuseColorIn, 
							float3 eyeVec, float roughness,	float3 specularColorIn, float3 thickness, float softenMask, 
							float gammaCorrection, float rim, float glossiness, float opacity, float3 ambientOcclusion, float4 anisotropicDir )
{
	lightOut OUT = (lightOut)0;

	OUT.Specular = 0.0;
	OUT.Color = float3(0,0,0);

	if (lightEnable)
	{
		// For Maya, flip the lightDir:
		#ifdef _MAYA_
			lightDir = -lightDir;
		#endif

		// Ambient light does no diffuse, specular shading or shadow casting.
		// Because it does equal shading from all directions to the object, we will also not have it do any translucency.
		bool isAmbientLight = (lightType == 5);
		if (isAmbientLight)
		{
			OUT.Color = diffuseColorIn * lightColor * lightIntensity;
			// Ambient Occlusion (and sometimes Lightmap) should affect the contribution of the ambient light:
			OUT.Color.rgb *= ambientOcclusion;
			return OUT;
		}

		// directional light has no position, so we use lightDir instead
		bool isDirectionalLight = (lightType == 4);
		float3 lightVec = lerp(lightPos - vertWorldPos, lightDir, isDirectionalLight);

		float3 L = normalize(lightVec);	

		// Diffuse:
		float3 diffuseColor = float3(0,0,0);
		if (DiffuseModel == 0)	// Lambert:
		{
			diffuseColor = saturate(dot(normal, L)) * diffuseColorIn;
		}
		else if (DiffuseModel == 1)	// Soften Diffuse, aka Blended Normal (skin):
		{
			diffuseColor = blendedNormalDiffuse(L, vertexNormal, normal, softenMask, 1.0) * diffuseColorIn;
		}
		else if (DiffuseModel == 2) // (hair/fur):
		{
			/// lerp to shift the shadow boundary for a softer look:
			diffuseColor = saturate( lerp(0.25, 1.0, dot(normal, L) ) ) * diffuseColorIn;
		}

		// Rim Light:
		float3 rimColor = rim * saturate(dot(normal, -L));	 

		// Specular:
		float3 specularColor = float3(0,0,0);

		if (SpecularModel == 0 || UseAnisotropicMapAlphaMask)		// BLINN
		{
			// Phong:
			// float3 R = -reflect(L, normal); 
			// float RdotV = saturate(dot(R,eyeVec));
			// specularColor = (pow(RdotV, glossiness) * specularColorIn);

			float3 H = normalize(L + eyeVec); // half angle
			float NdotH = saturate( dot(normal, H) );
			specularColor = specularColorIn * pow(NdotH, glossiness);
			specularColor *= saturate( dot(normal, L) );	// prevent spec leak on back side of model
		}
		if (SpecularModel == 1)	 // Kelemen-Szirmay-Kalos (skin):
		{
			specularColor = KelemenSzirmaykalosSpecular(normal, L, eyeVec, roughness, specularColorIn);
		}
		if (SpecularModel == 2)	 // Ward Anisotropic (brushed metal/hair):
		{
			float3 H = normalize(L + eyeVec);

			float NdotL = saturate( dot(normal, L) );
			float NdotH = dot(normal, H);
			float NdotV = dot(normal, eyeVec);

			float3 anisoSpecularColor = specularColorIn;
			anisoSpecularColor = WardAniso(normal, H, NdotL, NdotV, AnisotropicRoughness1, AnisotropicRoughness2, anisotropicDir.xyz, specularColorIn.xyz);

			anisoSpecularColor *= NdotL;	// prevent spec leak on back side of model

			if (UseAnisotropicMapAlphaMask)
				specularColor = lerp(specularColor, anisoSpecularColor, anisotropicDir.a);
			else
				specularColor = anisoSpecularColor;

			specularColor *= max(0, SpecPower/20.0);	// div by 20 so the default spec power has no effect
		}

		// Light Attenuation:
		bool enableAttenuation = lightAtten > 0.0001f;
		float attenuation = 1.0f;
		if (!isDirectionalLight)	// directional lights do not support attenuation, skip calculation
		{
			attenuation = lerp(1.0, 1 / pow(length(lightVec), lightAtten), enableAttenuation);
		}

		// compensate diffuse and specular color with various light settings:
		specularColor *= (lightColor * lightIntensity * attenuation);
		diffuseColor *= (lightColor * lightIntensity * attenuation);

		// Spot light Cone Angle:
		if (lightType == 2)
		{
			float angle = lightConeangle(lightConeAngle, lightFallOff, lightVec, lightDir);
			diffuseColor *= angle;
			specularColor *= angle;
		}

		// Shadows:
		if (UseShadows && lightShadowOn) 
		{
			float shadow = 1.0f;
			if(lightType == 3) { 
				shadow = pointLightShadow(pointlightShadowMap, vertWorldPos, lightPos);
			} else {
				shadow = lightShadow(lightViewPrjMatrix, lightShadowMap, vertWorldPos);
			}
			diffuseColor *= shadow;
			specularColor *= shadow;
		}


		// Translucency should be added on top after shadow and cone:
		if (UseTranslucency)
		{
			float3 transColor = translucency(thickness, eyeVec, L, vertexNormal, attenuation, gammaCorrection, diffuseColorIn);
			diffuseColor += transColor;
		}


		// Add specular and rim light on top of final output color
		// multiply OUT.Color with opacity since we are using a pre-multiplied alpha render state
		// if we don't do this, the rim may have halo's around it when the object is fully transparent
		OUT.Color += diffuseColor;
		OUT.Color *= opacity;
		if (!ReflectionAffectOpacity)	// multiply specular with opacity for pre-mul alpha only when reflections do not make object opaque in those areas
			specularColor *= opacity;
		OUT.Color += specularColor + rimColor;

		// Output specular and rim for opacity:
		OUT.Specular = dot(saturate(specularColor), float3(0.3f, 0.6f, 0.1f)) + rimColor.r;


	} // end if light enabled

	return OUT;
}



//------------------------------------
// vertex shader with tessellation
//------------------------------------
// take inputs from 3d-app
// vertex animation/skinning would happen here
SHADERDATA vt(APPDATA IN) 
{
	SHADERDATA OUT = (SHADERDATA)0;

	// we pass vertices in world space
	float4 worldPos = mul( float4(IN.position, 1), world );
	OUT.worldPosition.xyz = worldPos.xyz;

	#ifdef _SUPPORTTESSELLATION_
		OUT.position = worldPos;
	#else
		OUT.position = float4(IN.position.xyz, 1);
	#endif

	// Pass through texture coordinates
	// flip Y for Maya
	#ifdef _MAYA_
		OUT.texCoord0 = float2(IN.texCoord0.x,(1.0-IN.texCoord0.y));
		OUT.texCoord1 = float2(IN.texCoord1.x,(1.0-IN.texCoord1.y));
		OUT.texCoord2 = float2(IN.texCoord2.x,(1.0-IN.texCoord2.y));
	#else
		OUT.texCoord0 = IN.texCoord0;
		OUT.texCoord1 = IN.texCoord1;
		OUT.texCoord2 = IN.texCoord2;
	#endif		

	// output normals in world space:
	if (!SupportNonUniformScale)
		OUT.worldNormal = normalize(mul(IN.normal, (float3x3)world));
	else
		OUT.worldNormal = normalize(mul(IN.normal, (float3x3)worldIT));

	// output tangent in world space:
	if (!SupportNonUniformScale)
		OUT.worldTangent.xyz = normalize( mul(IN.tangent, (float3x3)world) );
	else
		OUT.worldTangent.xyz = normalize( mul(IN.tangent, (float3x3)worldIT) );

	// store direction for normal map:
	OUT.worldTangent.w = 1;
	if (dot(cross(IN.normal.xyz, IN.tangent.xyz), IN.binormal.xyz) < 0.0) OUT.worldTangent.w = -1;
		
	#ifdef _SUPPORTTESSELLATION_
		float4 HPosition = mul(OUT.position, viewPrj);
	#else
		float4 HPosition = mul( float4(IN.worldPosition, 1.0f), viewPrj ); 
	#endif
	
	float fogFactor = 0.0f;
	if (MayaHwFogMode == 0) {
		fogFactor = saturate((MayaHwFogEnd - HPosition.z) / (MayaHwFogEnd - MayaHwFogStart));
	}
	else if (MayaHwFogMode == 1) {
		fogFactor = rcp(exp(HPosition.z * MayaHwFogDensity));
	}
	else if (MayaHwFogMode == 2) {
		fogFactor = rcp(exp(pow(HPosition.z * MayaHwFogDensity, 2)));
	}
	
	OUT.FogFactor = float3(fogFactor, fogFactor, fogFactor);

	return OUT;
}


//------------------------------------
// vertex shader without tessellation
//------------------------------------
SHADERDATA v(APPDATA IN) 
{
	SHADERDATA OUT = vt(IN);
		
	// If we don't use tessellation, pass vertices in clip space:
	#ifdef _SUPPORTTESSELLATION_
		OUT.position = mul( float4(OUT.position.xyz, 1), viewPrj );
	#else
		OUT.position = mul( float4(IN.position, 1), wvp );
	#endif

	return OUT;
}

#ifdef _SUPPORTTESSELLATION_
	//------------------------------------
	// hull shader
	//------------------------------------
	// executed once per control point.
	// control points can be considered the original vertices of the mesh
	// outputs a control point
	// run parallel with hull constant function
	[domain("tri")]
	[partitioning("fractional_odd")]
	[outputtopology("triangle_cw")]
	[patchconstantfunc("HS_Constant")]
	[outputcontrolpoints(3)]
	[maxtessfactor(64.0)]


		// PN-AEN without displacement fix:
		// SHADERDATA HS( InputPatch<SHADERDATA, 9> IN, uint index : SV_OutputControlPointID, uint patchID : SV_PrimitiveID )

		// PN Triangles, no crack fixes:
		// SHADERDATA HS( InputPatch<SHADERDATA, 3> IN, uint index : SV_OutputControlPointID, uint patchID : SV_PrimitiveID )


	// PN-AEN and displacement fix
	//		the index buffer is made up as follows:
	//		the triangle vertices index (int3)					// PNAEN9 and PNAEN18
	//		the 3 adjacent edges vertices index (3 * int2)		// PNAEN9 and PNAEN18
	//		the 3 dominant edges vertices index (3 * int2)		// PNAEN18
	//		the dominant position vertices index (int3)			// PNAEN18
	SHADERDATA HS( InputPatch<SHADERDATA, 18> IN, uint index : SV_OutputControlPointID, uint patchID : SV_PrimitiveID )
	{
		SHADERDATA OUT = (SHADERDATA)0;

		// copy everything first:
		OUT = IN[index];

		// Compute the next output control point ID so we know which edge we're on.
		const uint nextIndex = index < 2 ? index + 1 : 0; // (index + 1) % 3


		// PN-AEN 9 and 18: 
			const uint neighborIndex = 3 + 2 * index;
			const uint neighborNextIndex = neighborIndex + 1;

			float3 myCP, neighborCP;	
	
			// Calculate original PN control points and neighbors'.  Then average.
			myCP = ComputeCP( IN[index].worldPosition, IN[nextIndex].worldPosition, IN[index].worldNormal );
			neighborCP = ComputeCP( IN[neighborIndex].worldPosition, IN[neighborNextIndex].worldPosition, IN[neighborIndex].worldNormal );
			OUT.CP1 = (myCP + neighborCP) / 2;

			myCP = ComputeCP( IN[nextIndex].worldPosition, IN[index].worldPosition, IN[nextIndex].worldNormal );
			neighborCP = ComputeCP( IN[neighborNextIndex].worldPosition, IN[neighborIndex].worldPosition, IN[neighborNextIndex].worldNormal );
			OUT.CP2 = (myCP + neighborCP) / 2;
		
		// PN Triangles only would be:
			// OUT.CP1 = ComputeCP( IN[index].worldPosition, IN[nextIndex].worldPosition, IN[index].worldNormal);
			// OUT.CP2 = ComputeCP( IN[nextIndex].worldPosition, IN[index].worldPosition, IN[nextIndex].worldNormal);

		// Clipping:
			 OUT.clipped = ComputeClipping(OUT.worldPosition, OUT.CP1, OUT.CP2);

		// PN-AEN discontinuity code for displacement UVs:

			const uint dominantEdgeIndex = 9 + 2 * index;
			const uint dominantEdgeNextIndex = dominantEdgeIndex + 1;
			const uint dominantVertexIndex = 15 + index;

			// Note: the order of the vertices/edges we choose here can be different per application and
			//		 depend on how the index buffer was generated.
			//		 These work for Maya with its PN-AEN18 primitive generator
			float2 dominantEdgeUV = pickTexcoord(DisplacementTexcoord, IN[dominantEdgeIndex].texCoord0, IN[dominantEdgeIndex].texCoord1, IN[dominantEdgeIndex].texCoord2);
			float2 dominantEdgeNextUV = pickTexcoord(DisplacementTexcoord, IN[dominantEdgeNextIndex].texCoord0, IN[dominantEdgeNextIndex].texCoord1, IN[dominantEdgeNextIndex].texCoord2);
			float2 dominantVertexUV = pickTexcoord(DisplacementTexcoord, IN[dominantVertexIndex].texCoord0, IN[dominantVertexIndex].texCoord1, IN[dominantVertexIndex].texCoord2);

			OUT.dominantEdge = float4( dominantEdgeNextUV, dominantEdgeUV );
			OUT.dominantVertex = dominantVertexUV;

		// VDM dominant normal and tangent for displacement crack fix:
			OUT.dominantNormalE0 = IN[dominantEdgeNextIndex].worldNormal.xyz;
			OUT.dominantNormalE1 = IN[dominantEdgeIndex].worldNormal.xyz;
			OUT.dominantNormalCorner = IN[dominantVertexIndex].worldNormal.xyz;

			OUT.dominantTangentE0 = IN[dominantEdgeNextIndex].worldTangent.xyz;
			OUT.dominantTangentE1 = IN[dominantEdgeIndex].worldTangent.xyz;
			OUT.dominantTangentCorner = IN[dominantVertexIndex].worldTangent.xyz;

		return OUT;
	}


	//------------------------------------
	// Hull shader constant function
	//------------------------------------
	// executed once per patch
	// outputs user defined data per patch and tessellation factor
	// calculates control points for vertex and normal and passes to domain
	// This hull shader passes the tessellation factors through to the HW tessellator, 
	// run parallel with hull function
	HSCONSTANTDATA HS_Constant( const OutputPatch<SHADERDATA, 3> IN, uint patchID : SV_PrimitiveID )
	{
		HSCONSTANTDATA OUT = (HSCONSTANTDATA)0;
    
		// future todo:   
		// triangle is on silhouette?
		// triangle is facing camera? If facing backwards, reduce tessellation
		// triangle lies in high frequency area of displacement map (density-based tessellation)?

		// Now setup the PNTriangle control points...
		// Center control point
		float3 f3E = (IN[0].CP1 + IN[0].CP2 + IN[1].CP1 + IN[1].CP2 + IN[2].CP1 + IN[2].CP2) / 6.0f;
		float3 f3V = (IN[0].worldPosition + IN[1].worldPosition + IN[2].worldPosition) / 3.0f;
		OUT.CPCenter = f3E + ((f3E - f3V) / 2.0f);

		// Clipping:
		float4 centerViewPos = mul( float4(OUT.CPCenter, 1), viewPrj );
		bool centerClipped = IsClipped(centerViewPos);

		if (IN[0].clipped && IN[1].clipped && IN[2].clipped && centerClipped) 
		{
			// If all control points are clipped, the surface cannot possibly be visible.
			// Not entirely true, because displacement mapping can make them visible in the domain shader
			// so we provide the user with a bias factor to avoid clipping too early
			OUT.TessFactor[0] = OUT.TessFactor[1] = OUT.TessFactor[2] = 0;
		}
		else
		{
			// Camera based tessellation, per object. So very basic.
			float3 CameraPosition = viewInv[3].xyz;
			float LengthOp = length((CameraPosition - world[3].xyz));
			float DivOp = (TessellationRange / LengthOp);
			float MaxOp = max(TessellationMin + DivOp, 1);
			OUT.TessFactor[0] = OUT.TessFactor[1] = OUT.TessFactor[2] = MaxOp;
		}
 
		// Inside tess factor is just the average of the edge factors
		OUT.InsideTessFactor = ( OUT.TessFactor[0] + OUT.TessFactor[1] + OUT.TessFactor[2] ) / 3.0f;

		return OUT;
	}


	//------------------------------------
	// domain shader
	//------------------------------------
	// outputs the new vertices based on previous tessellation.
	// also calculates new normals and uvs
	// This domain shader applies contol point weighting to the barycentric coords produced by the FF tessellator 
	// If you wanted to do any vertex lighting, it would have to happen here.
	[domain("tri")]
	SHADERDATA DS( HSCONSTANTDATA HSIN, OutputPatch<SHADERDATA, 3> IN, float3 f3BarycentricCoords : SV_DomainLocation )
	{
		SHADERDATA OUT = (SHADERDATA)0;

		// The barycentric coordinates
		float fU = f3BarycentricCoords.x;
		float fV = f3BarycentricCoords.y;
		float fW = f3BarycentricCoords.z;

		// Precompute squares and squares * 3 
		float fUU = fU * fU;
		float fVV = fV * fV;
		float fWW = fW * fW;
		float fUU3 = fUU * 3.0f;
		float fVV3 = fVV * 3.0f;
		float fWW3 = fWW * 3.0f;

		// PN position:
		float3 position = IN[0].worldPosition * fWW * fW +
							IN[1].worldPosition * fUU * fU +
							IN[2].worldPosition * fVV * fV +
							IN[0].CP1 * fWW3 * fU +
							IN[0].CP2 * fW * fUU3 +
							IN[2].CP2 * fWW3 * fV +
							IN[1].CP1 * fUU3 * fV +
							IN[2].CP1 * fW * fVV3 +
							IN[1].CP2 * fU * fVV3 +
							HSIN.CPCenter * 6.0f * fW * fU * fV;

		// Flat position:
		float3 flatPosition = IN[0].worldPosition * fW +
						IN[1].worldPosition * fU +
						IN[2].worldPosition * fV;

		// allow user to blend between PN tessellation and flat tessellation:
		position = lerp(position, flatPosition, FlatTessellation);

		// Interpolate normal
		float3 normal = IN[0].worldNormal * fW + IN[1].worldNormal * fU + IN[2].worldNormal * fV;

		// Normalize the interpolated normal
		OUT.worldNormal = normalize(normal);

		// Compute tangent:
		float3 tangent = IN[0].worldTangent.xyz * fW + IN[1].worldTangent.xyz * fU + IN[2].worldTangent.xyz * fV;
		OUT.worldTangent.xyz = normalize(tangent.xyz);

		// Pass through the direction of the binormal as calculated in the vertex shader
		OUT.worldTangent.w = IN[0].worldTangent.w;

		// Linear interpolate the texture coords
		OUT.texCoord0 = IN[0].texCoord0 * fW + IN[1].texCoord0 * fU + IN[2].texCoord0 * fV;
		OUT.texCoord1 = IN[0].texCoord1 * fW + IN[1].texCoord1 * fU + IN[2].texCoord1 * fV;
		OUT.texCoord2 = IN[0].texCoord2 * fW + IN[1].texCoord2 * fU + IN[2].texCoord2 * fV;

		// apply displacement map (only when not rendering the Maya preview swatch):
		if (UseDisplacementMap && !IsSwatchRender)
		{
			// Fix Displacement Seams.
			// we assume here that the displacement UVs is UVset 0.
			// if this UVset index is changed, it should als be changed in the hull shader
			// PN-AEN 18 with displacement UV seam fix
			float2 displaceUV = pickTexcoord(DisplacementTexcoord, OUT.texCoord0, OUT.texCoord1, OUT.texCoord2);
			float3 displacementUVW = PickDominant(	float3(displaceUV, 0),
															fU, fV, fW,
															float3( IN[0].dominantEdge.xy, 0), float3( IN[0].dominantEdge.zw, 0), 
															float3( IN[1].dominantEdge.xy, 0), float3( IN[1].dominantEdge.zw, 0),
															float3( IN[2].dominantEdge.xy, 0), float3( IN[2].dominantEdge.zw, 0),
															float3( IN[0].dominantVertex.xy, 0), 
															float3( IN[1].dominantVertex.xy, 0), 
															float3( IN[2].dominantVertex.xy, 0));

			// We can still get cracks here because the world tangent and normal may be different for vertices on each side of the UV seam,
			// because we do the tangent to world conversion, we get the same diplacement amount, but it results in different movement once converted to world space.
			// And even a tiny difference between normal or tangent will cause large cracks.
			float3 displacementNormal = PickDominant(	OUT.worldNormal,
															fU, fV, fW,
															IN[0].dominantNormalE0, IN[0].dominantNormalE1, 
															IN[1].dominantNormalE0, IN[1].dominantNormalE1,
															IN[2].dominantNormalE0, IN[2].dominantNormalE1,
															IN[0].dominantNormalCorner, 
															IN[1].dominantNormalCorner, 
															IN[2].dominantNormalCorner);

			displacementNormal = normalize(displacementNormal);

			if (DisplacementModel == 1)	// Tangent Vector Displacement
			{
				float3 displacementTangent = PickDominant(	OUT.worldTangent.xyz,
																fU, fV, fW,
																IN[0].dominantTangentE0, IN[0].dominantTangentE1, 
																IN[1].dominantTangentE0, IN[1].dominantTangentE1,
																IN[2].dominantTangentE0, IN[2].dominantTangentE1,
																IN[0].dominantTangentCorner, 
																IN[1].dominantTangentCorner, 
																IN[2].dominantTangentCorner);

				displacementTangent = normalize(displacementTangent);

				float3 vecDisp = DisplacementTexture.SampleLevel(SamplerAnisoWrap, displacementUVW.xy, 0).xyz;
				vecDisp -= DisplacementOffset;

				float3 Bn = cross(displacementNormal, displacementTangent); 
				float3x3 toWorld = float3x3(displacementTangent, Bn.xyz, displacementNormal);

				float3 VDMcoordSys = vecDisp.xzy;		// Mudbox
				if (VectorDisplacementCoordSys == 1)
				{
					VDMcoordSys = vecDisp.xyz;			// Maya or ZBrush
				}

				float3 vecDispW = mul(VDMcoordSys, toWorld) * DisplacementHeight;
				position.xyz += vecDispW;
			}
			else
			{
				// offset (-0.5) so that we can have negative displacement also
				float offset = DisplacementTexture.SampleLevel(SamplerAnisoWrap, displacementUVW.xy, 0).x - DisplacementOffset;
				position.xyz += displacementNormal * offset * DisplacementHeight;
			}
		}

		// Update World Position value for inside pixel shader:
		OUT.worldPosition = position.xyz;

		// Transform model position with view-projection matrix
		//OUT.position = float4(position.xyz, 1);							// with geo
		OUT.position = mul( float4(position.xyz, 1), viewPrj );				// without geo
        
		return OUT;
	}


	//------------------------------------
	// Geometry Shader
	//------------------------------------
	// This is a sample Geo shader. Disabled in this shader, but left here for your reference.
	// If you wish to enable it, search for 'with geo' in this shader for code to change.
	[maxvertexcount(3)] // Declaration for the maximum number of vertices to create
	void GS( triangle SHADERDATA IN[3], inout TriangleStream<SHADERDATA> TriStream )
	{
		SHADERDATA OUT;
    
		// quick test to see if geo also works:
		for( int i=0; i<3; ++i )
		{
			OUT = IN[i];
			OUT.position = mul( mul( float4(OUT.position.xyz, 1), view) , prj);
			TriStream.Append( OUT );
		}
		TriStream.RestartStrip(); // end triangle
	}
#endif

//------------------------------------
// pixel shader
//------------------------------------
float4 f(SHADERDATA IN, bool FrontFace : SV_IsFrontFace) : SV_Target
{
	#ifdef _3DSMAX_
		FrontFace = !FrontFace;
	#endif

	// clip are early as possible
	float2 opacityMaskUV = pickTexcoord(OpacityMaskTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
	OpacityMaskClip(opacityMaskUV);

	float gammaCorrection = lerp(1.0, 2.2, LinearSpaceLighting);

	float3 N = normalize(IN.worldNormal.xyz);
	if (flipBackfaceNormals)
	{
		N = lerp (-N, N, FrontFace);
	}
	float3 Nw = N;

	// Tangent and BiNormal:
	float3 T = normalize(IN.worldTangent.xyz);
	float3 Bn = cross(N, T); 
	Bn *= IN.worldTangent.w; 

	if (UseNormalTexture)
	{
		float3x3 toWorld = float3x3(T, Bn, N);

		float2 normalUV = pickTexcoord(NormalTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float3 NormalMap = NormalTexture.Sample(SamplerAnisoWrap, normalUV).xyz * 2 - 1;

		if (NormalCoordsysX > 0)
			NormalMap.x = -NormalMap.x;
		if (NormalCoordsysY > 0)
			NormalMap.y = -NormalMap.y;

		NormalMap.xy *= NormalHeight; 
		NormalMap = mul(NormalMap.xyz, toWorld);

		N = normalize(NormalMap.rgb);
	}
	
	float3 V = normalize( viewInv[3].xyz - IN.worldPosition.xyz );

	float glossiness =  max(1.0, SpecPower);
	float specularAlpha = 1.0;
	float3 specularColor = SpecularColor;
	if (UseSpecularTexture)
	{
		float2 opacityUV = pickTexcoord(SpecularTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float4 SpecularTextureSample = SpecularTexture.Sample(SamplerAnisoWrap, opacityUV);

		specularColor *= pow(SpecularTextureSample.rgb, gammaCorrection);
		specularAlpha = SpecularTextureSample.a;
		glossiness *= (SpecularTextureSample.a + 1);
	}

	float4 anisotropicDir = float4(T, 1);	// alpha is the blinn-aniso mask
	if (UseAnisotropicDirectionMap)
	{
		float2 anisoDirUV = pickTexcoord(AnisotropicTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);

		if (AnisotropicDirectionType == 0)	// use tangent map for direction
		{
			anisotropicDir = AnisotropicTexture.Sample(SamplerAnisoWrap, anisoDirUV);
			anisotropicDir.xyz = anisotropicDir.xyz * 2 - 1;	// unpack
		}
	}

	float roughness = min( SpecPower/100.0f, 1) * specularAlpha;		// divide by 100 so we get more user friendly values when switching from Phong based on slider range.
	roughness = 1.0f-roughness;											// flip so it is more user friendly when switching from Phong

	float reflectFresnel = saturate((saturate(1.0f - dot(N, V))-ReflectionFresnelMin)/(ReflectionFresnelMax - ReflectionFresnelMin));	

	bool reflectMapUsed = UseReflectionMap;
	float3 reflectionColor = lerp(float3(1,1,1), specularColor, UseSpecColorToTintReflection) * (ReflectionIntensity*reflectMapUsed) * reflectFresnel;	
	if (UseReflectionMask)
	{
		float2 reflectionMaskUV = pickTexcoord(ReflectionMaskTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float4 ReflectionMaskSample = ReflectionMask.Sample(SamplerAnisoWrap, reflectionMaskUV);

		reflectionColor *=  ReflectionMaskSample.r;
	}

	float3 diffuseColor = DiffuseColor;
	diffuseColor *= (1 - saturate(reflectionColor));
	float diffuseAlpha = 1.0f;
	if (UseDiffuseTexture)
	{
		float2 diffuseUV = pickTexcoord(DiffuseTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float4 diffuseTextureSample = DiffuseTexture.Sample(SamplerAnisoWrap, diffuseUV);

		if (UseDiffuseTextureAlpha)
		{
			diffuseAlpha = diffuseTextureSample.a;
		}

		diffuseColor *= pow(diffuseTextureSample.rgb, gammaCorrection);
	}

	// Opacity:
	float opacity = saturate(diffuseAlpha * Opacity);

	// allow opacity to changed based on angle from camera:
	// This will only work well for polygons that are facing the camera
	if (OpacityFresnelMin > 0 || OpacityFresnelMax > 0)
	{
		float opacityFresnel = saturate( (saturate(1.0f - dot(N, V))-OpacityFresnelMin)/(OpacityFresnelMax - OpacityFresnelMin) );
		opacityFresnel *= FrontFace;
		opacity *= opacityFresnel;
	}

	float3 reflectColorTotal = reflectionColor;
	if (reflectMapUsed)
	{
		// below "8" should really be the number of mip maps levels in the cubemap, but since we don't know this (Maya is not passing this to us) we hard code it.
		float ReflectionMipLevel = (ReflectionBlur + (8.0 * (UseSpecAlphaForReflectionBlur * (1 - specularAlpha))));

		float3 reflectMapColor = float3(0,0,0);

		if (ReflectionType == 0 || ReflectionType == 3 || ReflectionType == 4)	// CUBE	
		{
			float3 reflectionVector = reflect(-V, N);
			#ifdef _ZUP_
				reflectionVector = reflectionVector.xzy;
			#endif
			reflectionVector = RotateVectorYaw(reflectionVector, ReflectionRotation);
			reflectionVector = normalize(reflectionVector);
			reflectMapColor += pow(ReflectionTextureCube.SampleLevel(CubeMapSampler, reflectionVector, ReflectionMipLevel).rgb, gammaCorrection);
		}

		if (ReflectionType == 1 || ReflectionType == 3)	// 2D SPHERICAL
		{
			float3 reflectionVector = reflect(V, N);
			#ifdef _ZUP_
				reflectionVector = reflectionVector.xzy;
			#endif
			reflectionVector = RotateVectorYaw(reflectionVector, ReflectionRotation);
			reflectionVector = normalize(reflectionVector);
			float2 sphericalUVs = SphericalReflectionUVFunction(reflectionVector, ReflectionPinching);
			reflectMapColor += pow(ReflectionTexture2D.SampleLevel(SamplerAnisoWrap, sphericalUVs, ReflectionMipLevel).rgb, gammaCorrection);
		}
		else if (ReflectionType == 2 || ReflectionType == 4)	// 2D LATLONG
		{
			float3 reflectionVector = reflect(-V, N);
			#ifdef _ZUP_
				reflectionVector = reflectionVector.xzy;
			#endif
			reflectionVector = RotateVectorYaw(reflectionVector, ReflectionRotation);
			reflectionVector = normalize(reflectionVector);
			float2 latLongUVs = Latlong(reflectionVector);
			reflectMapColor += pow(ReflectionTexture2D.SampleLevel(SamplerAnisoWrap, latLongUVs, ReflectionMipLevel).rgb, gammaCorrection);
		}

		reflectColorTotal *= reflectMapColor;

		if (!ReflectionAffectOpacity)	// multiply reflection with opacity for pre-mul alpha only when reflections do not make object opaque in those areas
			reflectColorTotal *= opacity;
	}

	#ifndef _ZUP_
		float ambientUpAxis = N.y;
	#else
		float ambientUpAxis = N.z;
	#endif

	float3 ambientColor = (lerp(AmbientGroundColor, AmbientSkyColor, ((ambientUpAxis * 0.5) + 0.5)) * diffuseColor);

	float3 ambientOcclusion = float3(1,1,1);
	if (UseAmbientOcclusionTexture)
	{
		float2 aomapUV = pickTexcoord(AmbientOcclusionTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float3 aomapTextureSample = AmbientOcclusionTexture.Sample(SamplerAnisoWrap, aomapUV).rgb;
		ambientOcclusion *= aomapTextureSample.rgb;
		ambientColor *= ambientOcclusion;
	}

	// emissive after AO to make sure AO does not block glow
	if (UseEmissiveTexture)
	{
		float2 emissiveUV = pickTexcoord(EmissiveTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float4 EmissiveColor = EmissiveTexture.Sample(SamplerAnisoWrap, emissiveUV);

		ambientColor += EmissiveColor.rgb * EmissiveIntensity;
	}

	if (UseLightmapTexture)
	{
		// We assume this texture does not need to be converted to linear space
		float2 lightmapUV = pickTexcoord(LightmapTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		float3 lightmapTextureSample = LightmapTexture.Sample(SamplerAnisoWrap, lightmapUV).rgb;
		diffuseColor *= lightmapTextureSample.rgb;
	}

	float3 thickness = float3(1,1,1);
	if (UseThicknessTexture)
	{
		float2 thicknessUV = pickTexcoord(ThicknessTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		thickness = TranslucencyThicknessMask.Sample(SamplerAnisoWrap, thicknessUV).xyz;
	}

	float softenMask = 1.0f;
	if (UseBlendedNormalTexture)
	{
		float2 softenUV = pickTexcoord(BlendedNormalMaskTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		softenMask = BlendedNormalMask.Sample(SamplerAnisoWrap, softenUV).r;
	}

	// Rim light:
	// This will only work well for polygons that are facing the camera
	float rim = saturate((saturate(1.0f - dot(N, V))-rimFresnelMin)/(max(rimFresnelMax, rimFresnelMin)  - rimFresnelMin));
	rim *= FrontFace;
	rim *= rimBrightness * max(specularAlpha, 0.2);	



	// --------
	// LIGHTS:
	// --------
	// future todo: Maya could pass light info in array so we can loop any number of lights.

	// light 0:
	lightOut light0 = CalculateLight(	light0Enable, light0Type, light0AttenScale, light0Pos, IN.worldPosition.xyz, 
										light0Color, light0Intensity, light0Dir, light0ConeAngle, light0FallOff, light0Matrix, 
										light0ShadowMap, pointlight0ShadowMap, light0ShadowOn, Nw, N, diffuseColor, V, roughness, specularColor,
										thickness, softenMask, gammaCorrection, rim, glossiness, opacity, ambientOcclusion, anisotropicDir );

	// light 1:
	lightOut light1 = CalculateLight(	light1Enable, light1Type, light1AttenScale, light1Pos, IN.worldPosition.xyz, 
										light1Color, light1Intensity, light1Dir, light1ConeAngle, light1FallOff, light1Matrix, 
										light1ShadowMap, pointlight1ShadowMap, light1ShadowOn, Nw, N, diffuseColor, V, roughness, specularColor,
										thickness, softenMask, gammaCorrection, rim, glossiness, opacity, ambientOcclusion, anisotropicDir );

	// light 2:
	lightOut light2 = CalculateLight(	light2Enable, light2Type, light2AttenScale, light2Pos, IN.worldPosition.xyz, 
										light2Color, light2Intensity, light2Dir, light2ConeAngle, light2FallOff, light2Matrix, 
										light2ShadowMap, pointlight2ShadowMap, light2ShadowOn, Nw, N, diffuseColor, V, roughness, specularColor,
										thickness, softenMask, gammaCorrection, rim, glossiness, opacity, ambientOcclusion, anisotropicDir );

	float3 lightTotal =  light0.Color + light1.Color + light2.Color;


	// ----------------------
	// IMAGE BASED LIGHTING
	// ----------------------
	// Diffuse IBL
	bool useDiffuseIBL = UseDiffuseIBLMap;
	if (useDiffuseIBL)
	{
		float diffuseIBLMipLevel = DiffuseIBLBlur;

		// We use the world normal to sample the lighting texture
		float3 diffuseIBLVec = N;
		#ifdef _ZUP_
			diffuseIBLVec = diffuseIBLVec.xzy;
		#endif

		diffuseIBLVec = RotateVectorYaw(diffuseIBLVec, DiffuseIBLRotation);
		diffuseIBLVec = normalize(diffuseIBLVec);

		float3 diffuseIBLcolor = float3(0,0,0);
		if (DiffuseIBLType == 0 || DiffuseIBLType == 3 || DiffuseIBLType == 4)	// CUBE
		{
			diffuseIBLcolor = pow(DiffuseIBLTextureCube.SampleLevel(CubeMapSampler, diffuseIBLVec, diffuseIBLMipLevel).rgb, gammaCorrection);
		}

		if (DiffuseIBLType == 1 || DiffuseIBLType == 3)	// 2D SPHERICAL
		{
			float2 sphericalUVs = SphericalReflectionUVFunction(-diffuseIBLVec, DiffuseIBLPinching);
			float3 preDiffuseIBL = diffuseIBLcolor;
			diffuseIBLcolor = pow(DiffuseIBLTexture2D.SampleLevel(SamplerAnisoWrap, sphericalUVs, diffuseIBLMipLevel).rgb, gammaCorrection);

			if (DiffuseIBLType == 3)	// combine Cube and Spherical
				diffuseIBLcolor += preDiffuseIBL;
		}
		else if (DiffuseIBLType == 2 || DiffuseIBLType == 4)	// 2D LATLONG
		{
			float2 latLongUVs = Latlong(diffuseIBLVec);
			float3 preDiffuseIBL = diffuseIBLcolor;
			diffuseIBLcolor = pow(DiffuseIBLTexture2D.SampleLevel(SamplerAnisoWrap, latLongUVs, diffuseIBLMipLevel).rgb, gammaCorrection);

			if (DiffuseIBLType == 4)	// combine Cube and Latlong
				diffuseIBLcolor += preDiffuseIBL;
		}

		// The Diffuse IBL gets added to what the dynamic lights have already illuminated
		// The Diffuse IBL texture should hold diffuse lighting information, so we multiply the diffuseColor (diffuseTexture) by the IBL
		// IBL intensity allows the user to specify how much the IBL contributes on top of the dynamic lights
		// Also compensate for pre-multiplied alpha
		lightTotal += diffuseColor * diffuseIBLcolor * DiffuseIBLIntensity * opacity;
	}



	// ----------------------
	// FINAL COLOR AND ALPHA:
	// ----------------------
	// ambient must also compensate for pre-multiplied alpha
	float3 result = (ambientColor * opacity) + reflectColorTotal;
	result += lightTotal;

	// do gamma correction in shader:
	if (!MayaFullScreenGamma)
		result = pow(result, 1/gammaCorrection);

	// final alpha:
	float transparency = opacity;
	if (ReflectionAffectOpacity)
	{
		float cubeTransparency = dot(saturate(reflectColorTotal), float3(0.3, 0.6, 0.1));
		float specTotal = light0.Specular + light1.Specular + light2.Specular;
		transparency += (cubeTransparency + specTotal);
	}
	transparency = saturate(transparency);	// keep 0-1 range

	if (MayaHwFogEnabled) {
		float fogFactor = (1.0f - IN.FogFactor.x) * MayaHwFogColor.a;
		result =  lerp(result, MayaHwFogColor.rgb, fogFactor);
	}	
	
	return float4(result, transparency);
}


#ifdef _MAYA_

	void Peel(SHADERDATA IN)
	{
		float currZ = abs( mul( float4(IN.worldPosition, 1.0f), view ).z );

		float4 Pndc  = mul( float4(IN.worldPosition, 1.0f), viewPrj );
		float2 UV = Pndc.xy / Pndc.w * float2(0.5f, -0.5f) + 0.5f;
		float prevZ = transpDepthTexture.Sample(SamplerShadowDepth, UV).r;
		float opaqZ = opaqueDepthTexture.Sample(SamplerShadowDepth, UV).r;
		float bias = 0.00002f;
		if (currZ < prevZ * (1.0f + bias) || currZ > opaqZ * (1.0f - bias))
		{
			discard;
		}
	}

	float4 LinearDepth(SHADERDATA IN)
	{
		return abs( mul( float4(IN.worldPosition, 1.0f), view ).z );
	}

	float4 DepthComplexity(float opacity)
	{
		return opacity > 0.001f ? 1.0f : 0.0f;
	}

	struct MultiOut2
	{
		float4 target0 : SV_Target0;
		float4 target1 : SV_Target1;
	};

	MultiOut2 fTransparentPeel(SHADERDATA IN, bool FrontFace : SV_IsFrontFace)
	{
		Peel(IN);

		MultiOut2 OUT;
		OUT.target0 = f(IN, FrontFace);
		OUT.target1 = LinearDepth(IN);
		return OUT;
	}

	MultiOut2 fTransparentPeelAndAvg(SHADERDATA IN, bool FrontFace : SV_IsFrontFace)
	{
		Peel(IN);

		MultiOut2 OUT;
		OUT.target0 = f(IN, FrontFace);
		OUT.target1 = DepthComplexity(OUT.target0.w);
		return OUT;
	}

	MultiOut2 fTransparentWeightedAvg(SHADERDATA IN, bool FrontFace : SV_IsFrontFace)
	{
		MultiOut2 OUT;
		OUT.target0 = f(IN, FrontFace);
		OUT.target1 = DepthComplexity(OUT.target0.w);
		return OUT;
	}

	//------------------------------------
	// wireframe pixel shader
	//------------------------------------
	float4 fwire(SHADERDATA IN) : SV_Target
	{
		return float4(0,0,1,1);
	}


	//------------------------------------
	// pixel shader for shadow map generation
	//------------------------------------
	//float4 ShadowMapPS( float3 Pw, float4x4 shadowViewProj ) 
	float4 ShadowMapPS(SHADERDATA IN) : SV_Target
	{ 
		// clip as early as possible
		float2 opacityMaskUV = pickTexcoord(OpacityMaskTexcoord, IN.texCoord0, IN.texCoord1, IN.texCoord2);
		OpacityMaskClip(opacityMaskUV);

		float4 Pndc = mul( float4(IN.worldPosition, 1.0f), viewPrj ); 

		// divide Z and W component from clip space vertex position to get final depth per pixel
		float retZ = Pndc.z / Pndc.w; 

		retZ += fwidth(retZ); 
		return retZ.xxxx; 
	}

	//------------------------------------
	// pixel shader for point light shadow map generation
	//------------------------------------
	float4 PointLightShadowPassPS(SHADERDATA IN) : SV_Target
	{ 
		float3 LightToVertex = float3(0.0, 0.0, 0.0);
		float LightToPixelDistance = 0.0;

		LightToVertex = IN.worldPosition.xyz - viewInv[3].xyz;
		LightToPixelDistance = length(LightToVertex) / lightRange;
		return float4(LightToPixelDistance, 0.0f, 0.0f, 0.0f);

	}

#endif

//-----------------------------------
// Objects without tessellation
//------------------------------------
technique11 TessellationOFF
<
	bool overridesDrawState = false;	// we do not supply our own render state settings
	int isTransparent = 3;
	// objects with clipped pixels need to be flagged as isTransparent to avoid the occluding underlying geometry since Maya renders the object with flat shading when computing depth
	string transparencyTest = "Opacity < 1.0 || (UseDiffuseTexture && UseDiffuseTextureAlpha) || UseOpacityMaskTexture || OpacityFresnelMax > 0 || OpacityFresnelMin > 0";
	// 'VariableNameAsAttributeName = false' can be used to tell Maya's DX11ShaderNode to use the UIName annotation string for the Maya attribute name instead of the shader variable name.
	// When changing this option, the attribute names generated for the shader inside Maya will change and this can have the side effect that older scenes have their shader attributes reset to default.
	// bool VariableNameAsAttributeName = false;

#ifdef _MAYA_
	// Tells Maya that the effect supports advanced transparency algorithm,
	// otherwise Maya would render the associated objects simply by alpha
	// blending on top of other objects supporting advanced transparency
	// when the viewport transparency algorithm is set to depth-peeling or
	// weighted-average.
	bool supportsAdvancedTransparency = true;
#endif
>
{  
	pass p0
	< 
		string drawContext = "colorPass";	// tell maya during what draw context this shader should be active, in this case 'Color'
	>
	{
		SetVertexShader(CompileShader(vs_5_0, v()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, f()));
	}

	#ifdef _MAYA_

		pass pTransparentPeel
		<
			// Depth-peeling pass for depth-peeling transparency algorithm.
			string drawContext = "transparentPeel";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, v()));
			SetHullShader(NULL);
			SetDomainShader(NULL);
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentPeel()));
		}

		pass pTransparentPeelAndAvg
		<
			// Weighted-average pass for depth-peeling transparency algorithm.
			string drawContext = "transparentPeelAndAvg";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, v()));
			SetHullShader(NULL);
			SetDomainShader(NULL);
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentPeelAndAvg()));
		}

		pass pTransparentWeightedAvg
		<
			// Weighted-average algorithm. No peeling.
			string drawContext = "transparentWeightedAvg";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, v()));
			SetHullShader(NULL);
			SetDomainShader(NULL);
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentWeightedAvg()));
		}

		pass pShadow
		< 
			string drawContext = "shadowPass";	// shadow pass
		>
		{
			SetVertexShader(CompileShader(vs_5_0, v()));
			SetHullShader(NULL);
			SetDomainShader(NULL);
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, ShadowMapPS()));
		}

		pass pShadowPointLight
		< 
			string drawContext = "pointLightShadowPass";	// point light shadow pass
		>
		{
			SetVertexShader(CompileShader(vs_5_0, v()));
			SetHullShader(NULL);
			SetDomainShader(NULL);
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, PointLightShadowPassPS()));
		}
	#endif
}

#ifdef _SUPPORTTESSELLATION_
	//-----------------------------------
	// Objects with tessellation
	//------------------------------------
	// Vertex Index Buffer options:
	// index_buffer_type: None;			// no divergent normals and no displacement crack fix
	// index_buffer_type: PNAEN9;		// divergent normals crack fix; no displacement UV seam crack fix
	// index_buffer_type: PNAEN18,		// crack fix for divergent normals and UV seam displacement
	technique11 TessellationON
	<
		string index_buffer_type = "PNAEN18";	// tell Maya what type of index buffer we want. Must be unique name per generator
		bool overridesDrawState = false;
		int isTransparent = 3;
		string transparencyTest = "Opacity < 1.0 || (UseDiffuseTexture && UseDiffuseTextureAlpha) || UseOpacityMaskTexture || OpacityFresnelMax > 0 || OpacityFresnelMin > 0";
		bool supportsAdvancedTransparency = true;
	>
	{  
		pass p0
		< 
			string drawContext = "colorPass";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);								// without geo
			//SetGeometryShader( CompileShader(gs_5_0, GS()) );		// with geo
			SetPixelShader(CompileShader(ps_5_0, f()));
		}

		pass pTransparentPeel
		<
			// Depth-peeling pass for depth-peeling transparency algorithm.
			string drawContext = "transparentPeel";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentPeel()));
		}

		pass pTransparentPeelAndAvg
		<
			// Weighted-average pass for depth-peeling transparency algorithm.
			string drawContext = "transparentPeelAndAvg";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentPeelAndAvg()));
		}

		pass pTransparentWeightedAvg
		<
			// Weighted-average algorithm. No peeling.
			string drawContext = "transparentWeightedAvg";
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, fTransparentWeightedAvg()));
		}

		pass pShadow
		< 
			string drawContext = "shadowPass";	// shadow pass
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, ShadowMapPS()));
		}

		pass pShadowPointLight
		< 
			string drawContext = "pointLightShadowPass";	// point light shadow pass
		>
		{
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);
			SetPixelShader(CompileShader(ps_5_0, PointLightShadowPassPS()));
		}
	}

	//-----------------------------------
	// Wireframe
	//------------------------------------
	technique11 WireFrame
	<
		string index_buffer_type = "PNAEN18";
		bool overridesDrawState = false;		// since we only change the fillMode, it can remain on false. If we changed the blend state, it would have to be true
		int isTransparent = 0;
	>
	{  
		pass p0
		< 
			string drawContext = "colorPass";
		>
		{
			SetRasterizerState(WireframeCullFront);
			SetVertexShader(CompileShader(vs_5_0, vt()));
			SetHullShader(CompileShader(hs_5_0, HS()));
			SetDomainShader(CompileShader(ds_5_0, DS()));
			SetGeometryShader(NULL);								// without geo
			//SetGeometryShader( CompileShader(gs_5_0, GS()) );		// with geo
			SetPixelShader(CompileShader(ps_5_0, fwire()));
		}
	}
#endif
