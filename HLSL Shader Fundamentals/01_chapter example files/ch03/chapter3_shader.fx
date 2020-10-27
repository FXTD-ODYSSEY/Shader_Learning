//CG Academy HLSL Shader DVD Set
//DVD 1: Shader Writing Fundamentals
//Chapter 3: Structure of the FX Framework

/************* TWEAKABLES **************/

float4 AmbientColor : Ambient
<
    string UIName = "Ambient Color";
> = {0.25f, 0.25f, 0.25f, 1.0f};


float4 DiffuseColor : Diffuse
<
    string UIName = "Diffuse Color";
> = {1.0f, 1.0f, 1.0f, 1.0f};


float4 SpecularColor : Specular
<
    string UIName = "Specular Color";
> = { 0.2f, 0.2f, 0.2f, 1.0f };


float Glossiness <
	string UIWidget = "slider";
    int UIMin = 1;
    int UIMax = 128;
    int UIStep = 1;
    int UIStepPower = 16;
    string UIName = "Glossiness";
> = 40;


texture diffuseMap : DiffuseMap
<
    string name = "default_color.dds";
	string UIName = "Diffuse Texture";
    string TextureType = "2D";
>;


texture normalMap : NormalMap
<
    string name = "default_bump_normal.dds";
	string UIName = "Normal Map";
    string TextureType = "2D";
>;






/************** light info **************/

float4 light1Pos : POSITION
<
	string UIName = "Light Position";
	string Object = "PointLight";
	string Space = "World";
	int refID = 0;
> = {100.0f, 100.0f, 100.0f, 0.0f};


float4 light1Color : LIGHTCOLOR
<
	int LightRef = 0;
> = { 1.0f, 1.0f, 1.0f, 0.0f };





/****************************************************/
/********** SAMPLERS ********************************/
/****************************************************/

sampler2D diffuseMapSampler = sampler_state
{
	Texture = <diffuseMap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Anisotropic;
};

sampler2D normalMapSampler = sampler_state
{
	Texture = <normalMap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Anisotropic;
};




/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

float4x4 WorldViewProjection 	: WorldViewProjection 	< string UIWidget = "None"; >;
float4x4 WorldInverseTranspose 	: WorldInverseTranspose < string UIWidget = "None"; >;
float4x4 ViewInverse 			: ViewInverse 			< string UIWidget = "None"; >;
float4x4 World 					: World 				< string UIWidget = "None"; >;




/****************************************************/
/********** CG SHADER FUNCTIONS *********************/
/****************************************************/

// input from application
	struct a2v {
	float4 position		: POSITION;
	float2 texCoord		: TEXCOORD0;
	float3 tangent		: TANGENT;
	float3 binormal		: BINORMAL;
	float3 normal		: NORMAL;
};


// output to fragment program
struct v2f {
        float4 position    		: POSITION;
		float2 texCoord    		: TEXCOORD0;
		float3 eyeVec			: TEXCOORD1;
		float3 lightVec   		: TEXCOORD2;
		float3 worldNormal		: TEXCOORD3;
		float3 worldTangent		: TEXCOORD4;
		float3 worldBinormal	: TEXCOORD5;
};


// blinn lighting with lit function
float4 blinn2(float3 N, float3 L, float3 V, uniform float4 diffuseColor, uniform float4 specularColor, uniform float Glossiness)
	{
	float3 H = normalize(V+L);											//calculate the half angle
	float4 lighting = lit(dot(L,N), dot(N,H), Glossiness);				//pass the diffuse (NdotL), specular (NdotH), and glossiness terms to the lit function
	return diffuseColor*lighting.y + specularColor*lighting.z;			//the lit function returns the clamped diffuse componenet in Y and the specular component, raised to the power of the glossinees in the Z
	}





/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

v2f v(a2v In, uniform float4 lightPosition)
{
	v2f Out; 															//create the output struct
    Out.worldNormal = mul(In.normal, WorldInverseTranspose).xyz;		//put the normal in world space pass it to the pixel shader
    Out.worldTangent = mul(In.tangent, WorldInverseTranspose).xyz;		//put the tangent in world space pass it to the pixel shader
    Out.worldBinormal = mul(In.binormal, WorldInverseTranspose).xyz;	//put the binormal in world space pass it to the pixel shader
    float3 worldSpacePos = mul(In.position, World);						//put the vertex in world space
    Out.lightVec = lightPosition - worldSpacePos;						//create the world space light vector and pass it to the pixel shader
	Out.texCoord.xy = In.texCoord;										//pass the UV coordinates to the pixel shader
    Out.eyeVec = ViewInverse[3].xyz - worldSpacePos;					//create the world space eye vector and pass it to the pixel shader
    Out.position = mul(In.position, WorldViewProjection);				//put the vertex position in clip space and pass it to the pixel shader
    return Out;
}




/**************************************/
/***** FRAGMENT PROGRAM ***************/
/**************************************/

float4 f(v2f In,uniform float4 lightColor) : COLOR
{
  //fetch the diffuse and normal maps
  float4 ColorTexture = tex2D(diffuseMapSampler, In.texCoord.xy);				//the tex2d function takes the texture sampler and the texture coordinates and returns the texel color at that point
  float3 normal = tex2D(normalMapSampler, In.texCoord).xyz * 2.0 - 1.0;			//the normal must be expanded from 0-1 to -1 to 1

  //create tangent space vectors
  float3 Nn = In.worldNormal;
  float3 Tn = In.worldTangent;
  float3 Bn = In.worldBinormal;
  
  //offset world space normal with normal map values
  float3 N = (Nn * normal.z) + (normal.x * Bn + normal.y * -Tn);				//we use the values of the normal map to tweek surface normal, tangent, and binormal
  N = normalize(N);																//normalizing the result gives us the new surface normal
  
  //create lighting vectors - view vector and light vector
  float3 V = normalize(In.eyeVec);												//the light vector and eye vector must be normalized here so all vectors will be normalized
  float3 L = normalize(In.lightVec.xyz);
  
  //lighting
  
  //ambient light
  float4 C = AmbientColor * ColorTexture;										//To create the ambient term, we multiply the ambient color and the diffuse texture
  
  DiffuseColor *= ColorTexture;													//To get the final diffuse color we multiply the diffuse color by the diffuse texture
  SpecularColor *= ColorTexture.a;												//To get the final specular color we multiply the specular color by the diffuse texture alpha channel - this lets us make a "specular mask" with the diffuse alpha channel
  
  //diffuse and specular light
  C += light1Color * blinn2(N, L, V, DiffuseColor, SpecularColor, Glossiness);	//we pass all our values to the lighting function and multiply by the light color to get our final output color

  return C + 0.1;
}





/****************************************************/
/********** TECHNIQUES ******************************/
/****************************************************/

technique regular
{ 
    pass one 
    {		
	VertexShader = compile vs_1_1 v(light1Pos);									//here we call the vertex shader function and tell it we want to use VS 1.1 as the profile					
	ZEnable = true;																//this enables sorting based on the Z buffer
	ZWriteEnable = true;														//this writes the depth value to the Z buffer so other objects will sort correctly this this one
	CullMode = CW;																//this enables backface culling.  CW stands for clockwise.  You can change it to CCW, or none if you want.
	AlphaBlendEnable = false;													//This disables transparency.  If you make it true, the alpha value of the final pixel shader color will determine how transparent the surface is.
	PixelShader = compile ps_2_0 f(light1Color);								//here we call the pixel shader function and tell it we want to use the PS 2.0 profile
    }
}



