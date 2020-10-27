/*********************************************************************NVMH3****
*******************************************************************************
$Revision: #1 $

Copyright NVIDIA Corporation 2008
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
*AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL NVIDIA OR ITS SUPPLIERS
BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY
LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF
NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

% Creates the illusion that the surface is covered with a thin film of
% transparent material, as in oily water, thin shellacs, dirty layered
% ice, etc.

keywords: material virtual_machine


keywords: DirectX10
// Note that this version has twin versions of all techniques,
//   so that this single effect file can be used in *either*
//   DirectX9 or DirectX10

To learn more about shading, shaders, and to bounce ideas off other shader
    authors and users, visit the NVIDIA Shader Library Forums at:

    http://developer.nvidia.com/forums/

*******************************************************************************
******************************************************************************/

/*****************************************************************/
/*** HOST APPLICATION IDENTIFIERS ********************************/
/*** Potentially predefined by varying host environments *********/
/*****************************************************************/

// #define _XSI_		/* predefined when running in XSI */
// #define TORQUE		/* predefined in TGEA 1.7 and up */
// #define _3DSMAX_		/* predefined in 3DS Max */
#ifdef _3DSMAX_
int ParamID = 0x0003;		/* Used by Max to select the correct parser */
#endif /* _3DSMAX_ */
#ifdef _XSI_
#define Main Static		/* Technique name used for export to XNA */
#endif /* _XSI_ */

#ifndef FXCOMPOSER_VERSION	/* for very old versions */
#define FXCOMPOSER_VERSION 180
#endif /* FXCOMPOSER_VERSION */

#ifndef DIRECT3D_VERSION
#define DIRECT3D_VERSION 0xb00
#endif /* DIRECT3D_VERSION */

#define FLIP_TEXTURE_Y	/* Different in OpenGL & DirectX */

/*****************************************************************/
/*** EFFECT-SPECIFIC CODE BEGINS HERE ****************************/
/*****************************************************************/

/******* Lighting Macros *******/
/** To use "Object-Space" lighting definitions, change these two macros: **/
#define LIGHT_COORDS "World"
// #define OBJECT_SPACE_LIGHTS /* Define if LIGHT_COORDS is "Object" */

float Script : STANDARDSGLOBAL <
    string UIWidget = "none";
    string ScriptClass = "object";
    string ScriptOrder = "standard";
    string ScriptOutput = "color";
    string Script = "Technique=Technique?Main:Main10;";
> = 0.8;

/**** UNTWEAKABLES: Hidden & Automatically-Tracked Parameters **********/

// transform object vertices to world-space:
float4x4 gWorldXf : World < string UIWidget="None"; >;
// transform object normals, tangents, & binormals to world-space:
float4x4 gWorldITXf : WorldInverseTranspose < string UIWidget="None"; >;
// transform object vertices to view space and project them in perspective:
float4x4 gWvpXf : WorldViewProjection < string UIWidget="None"; >;
// provide tranform from "view" or "eye" coords back to world-space:
float4x4 gViewIXf : ViewInverse < string UIWidget="None"; >;

//////////////////////////////////////////////////////////////////////////
// tweakables ////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

float3 gLamp0Pos : POSITION <
    string Object = "PointLight0";
    string UIName =  "Lamp 0 Position";
    string Space = (LIGHT_COORDS);
> = {-0.5f,2.0f,1.25f};

// surface color
float3 gSurfaceColor : DIFFUSE <
    string UIName =  "Surface";
    string UIWidget = "Color";
> = {1,1,1};

float gSpecExpon <
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 128.0;
    float UIStep = 1.0;
    string UIName =  "Specular Exponent";
> = 12.0;

// shared shadow mapping supported in Cg version

#include <include\\ThinFilmTex.fxh>

//////////////////////////////////////////////////////////////////////////
// structs ///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

struct appData
{
    float3 Position : POSITION;
    float3 Normal   : NORMAL;
};

struct filmyVertexOutput
{
    float4 HPOS      : POSITION;
    float3 diffCol   : COLOR0;
    float3 specCol   : COLOR1;
    float2 filmDepth : TEXCOORD0;
};

//////////////////////////////////////////////////////////////////////////
// VERTEX SHADER /////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

filmyVertexOutput ThinFilmVS(appData IN,
    uniform float4x4 WorldITXf, // our four standard "untweakable" xforms
	uniform float4x4 WorldXf,
	uniform float4x4 ViewIXf,
	uniform float4x4 WvpXf,
    uniform float FilmDepth,
    uniform float SpecExpon,
    uniform float3 LampPos)
{
    filmyVertexOutput OUT = (filmyVertexOutput)0;
    float3 Nn = mul(IN.Normal,WorldITXf).xyz;
    float4 Po = float4(IN.Position.xyz,1.0);
    float3 Pw = mul(Po,WorldXf).xyz;
    OUT.HPOS = mul(Po,WvpXf);
    float3 Ln = normalize(LampPos - Pw);
    float3 Vn = normalize(ViewIXf[3].xyz - Pw);
    float3 Hn = normalize(Ln + Vn);
    float ldn = dot(Ln,Nn);
    float hdn = dot(Hn,Nn);
    float vdn = dot(Vn,Nn);
    float4 litV = lit(ldn,hdn,SpecExpon);
    OUT.diffCol = litV.yyy;
    OUT.specCol = pow(hdn,SpecExpon).xxx;
    // compute the view depth for the thin film
    float viewdepth = calc_view_depth(vdn,FilmDepth.x);
    OUT.filmDepth = viewdepth.xx;
    return OUT;
}

///////// /////////////////////////////////////////////////////////////////
// PIXEL SHADER //////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

float4 ThinFilmPS(filmyVertexOutput IN,
		    uniform float3 SurfaceColor,
		    uniform sampler2D FringeMapSampler
) : COLOR {
    // lookup fringe value based on view depth
    float3 fringeCol = (float3)tex2D(FringeMapSampler, IN.filmDepth);
    // modulate specular lighting by fringe color, combine with regular lighting
    float3 rgb = fringeCol*IN.specCol + IN.diffCol*SurfaceColor;
    return float4(rgb,1);
}


///////////////////////////////////////
/// TECHNIQUES ////////////////////////
///////////////////////////////////////

#if DIRECT3D_VERSION >= 0xa00
//
// Standard DirectX10 Material State Blocks
//
RasterizerState DisableCulling { CullMode = NONE; };
DepthStencilState DepthEnabling { DepthEnable = TRUE; };
DepthStencilState DepthDisabling {
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
};
BlendState DisableBlend { BlendEnable[0] = FALSE; };

technique10 Main10 <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        SetVertexShader( CompileShader( vs_4_0, ThinFilmVS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,gFilmDepth,gSpecExpon,gLamp0Pos) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, ThinFilmPS(gSurfaceColor,gFringeMapSampler) ) );
	    SetRasterizerState(DisableCulling);
	    SetDepthStencilState(DepthEnabling, 0);
	    SetBlendState(DisableBlend, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF);
    }
}

#endif /* DIRECT3D_VERSION >= 0xa00 */

technique Main <
	string Script = "Pass=p0;";
> {
    pass p0 <
	string Script = "Draw=geometry;";
    > {
        VertexShader = compile vs_3_0 ThinFilmVS(gWorldITXf,gWorldXf,
				gViewIXf,gWvpXf,gFilmDepth,gSpecExpon,gLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = false;
		CullMode = None;
        PixelShader = compile ps_3_0 ThinFilmPS(gSurfaceColor,gFringeMapSampler);
    }
}

/////////////////////////////////// eof ///
