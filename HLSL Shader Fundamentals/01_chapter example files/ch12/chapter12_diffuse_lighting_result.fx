//CG Academy HLSL Shader DVD Set
//DVD 1: Shader Writing Fundamentals
//Chapter 12: Simple Shaders

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

/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

float4x4 wvp 	: WorldViewProjection < string UIWidget = "None"; >;
float4x4 World 	: World 				< string UIWidget = "None"; >;



/****************************************************/
/********** SHADER STRUCTS **************************/
/****************************************************/

// input from application 
struct app2vertex
{ 
	float4 position		: POSITION; 
	float4 normal		: NORMAL; 
}; 


// output to pixel shader 
struct vertex2pixel
{ 
        float4 position    	: POSITION;
        float4 diffuse    	: COLOR;
}; 



/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

vertex2pixel vertex(app2vertex In) 
{ 
	vertex2pixel Out = (vertex2pixel)0; 
    Out.position = mul(In.position, wvp);	// transform vert position to homogeneous clip space
    
    float3 worldSpacePos = mul(In.position, World);
    
    float3 lightVec = light1Pos - worldSpacePos;
    
    float3 L = normalize(lightVec);
    float3 N = normalize(In.normal);
    
    float brightness = dot(N, L);
    
    float brightnessClamped = max(brightness, 0);
    
    Out.diffuse = brightnessClamped * light1Color;
    
    return Out; 
} 



/**************************************/
/***** PIXEL SHADER *******************/
/**************************************/

float4 pixel(vertex2pixel In) : COLOR 
{ 
	float4 col = In.diffuse;
	return col; 
} 



/****************************************************/
/********** TECHNIQUES ******************************/
/****************************************************/

technique Complete 
{  
	pass simple  
    {		 
	VertexShader = compile vs_1_1 vertex(); 
	ZEnable = true; 
	ZWriteEnable = true; 
 	CullMode = cw; 
	AlphaBlendEnable = false; 
	PixelShader = compile ps_2_0 pixel(); 
	}  

}  
