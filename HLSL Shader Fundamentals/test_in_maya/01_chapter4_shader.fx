//CG Academy HLSL Shader DVD Set
//DVD 1: Shader Writing Fundamentals
//Chapter 4: Basic Programming - Data Types



/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

// float4x4 wvp : WorldViewProjection < string UIWidget = "None"; >;
float4x4 gWvpXf : WorldViewProjection < string UIType="None"; >;


float4 AmbientColor : Ambient
<
    string UIName = "Ambient Color";
> = {0.25f, 0.25f, 0.25f, 1.0f};
/****************************************************/
/********** SHADER STRUCTS **************************/
/****************************************************/

// input from application 
struct app2vertex
{ 
	float4 position		: POSITION; 
}; 


// output to pixel shader 
struct vertex2pixel
{ 
        float4 position    		: POSITION; 
        float4 color    		: COLOR; 
}; 



/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

vertex2pixel vertex(app2vertex In) 
{ 
	vertex2pixel Out = (vertex2pixel)0; 
    Out.position = mul(In.position, gWvpXf);	// transform vert position to homogeneous clip space 

	//new code goes here!
	//----------------------------------


	Out.color = AmbientColor;


	//----------------------------------
    return Out; 
} 



/**************************************/
/***** PIXEL SHADER *******************/
/**************************************/

float4 pixel(vertex2pixel In) : COLOR 
{ 
	float4 col = In.color;			// set pixel color to incoming vertex color

	return col; 
} 



/****************************************************/
/********** TECHNIQUES ******************************/
/****************************************************/

// technique Complete 
// {  
// 	pass simple  
//     {		 
// 	VertexShader = compile vs_1_1 vertex(); 
// 	ZEnable = true; 
// 	ZWriteEnable = true; 
//  	CullMode = cw; 
// 	AlphaBlendEnable = false; 
// 	PixelShader = compile ps_2_0 pixel(); 
// 	}  

// }  

technique11 Main
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_4_0, vertex()));
		// ZEnable = true; 
		// ZWriteEnable = true; 
		// CullMode = cw; 
		// AlphaBlendEnable = false; 
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader( ps_4_0,pixel()));
	}
}