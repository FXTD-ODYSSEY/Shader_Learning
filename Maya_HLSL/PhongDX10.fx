// Simple phong shader based on nVidia plastic example

/******* Lighting Macros *******/
/** To use "Object-Space" lighting definitions, change these two macros: **/
#define LIGHT_COORDS "World"
// #define OBJECT_SPACE_LIGHTS /* Define if LIGHT_COORDS is "Object" */

float4x4 WorldXf : World;
float4x4 WorldITXf : WorldInverseTranspose;
float4x4 WvpXf : WorldViewProjection;
float4x4 ViewIXf : ViewInverse;

float3 gLamp0Dir : DIRECTION <
    string Object = "DirectionalLight0";
    string UIName =  "Lamp 0 Direction";
    string Space = (LIGHT_COORDS);
> = {0.7f,-0.7f,-0.7f};

float3 gLamp0Color : SPECULAR <
    string Object = "DirectionalLight0";
    string UIName =  "Lamp 0 Color";
    string UIWidget = "Color";
> = {1.0f,1.0f,1.0f};

float3 gAmbiColor : AMBIENT <
    string UIName =  "Ambient Light";
    string UIWidget = "Color";
> = {0.07f,0.07f,0.07f};

float3 gSurfaceColor : DIFFUSE <
    string UIName =  "Surface";
    string UIWidget = "Color";
> = {0.0f,0.0f,1.0f};

float gKd = 0.9f;
float gKs = 0.4f;
float gSpecExpon = 30.0f;

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
	float4 litV = lit(dot(Ln,Nn),dot(Hn,Nn),SpecExpon);
	DiffuseContrib = litV.y * Kd * LightColor + AmbiColor;
	SpecularContrib = litV.z * Ks * LightColor;
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
					gLamp0Dir)));

		SetGeometryShader(NULL);

		SetPixelShader(
			CompileShader(
				ps_4_0,
				phongPS(
					gSurfaceColor,
					gKd,
					gKs,
					gSpecExpon,
					gLamp0Color,
					gAmbiColor)));
	}
}


