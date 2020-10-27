//CG Academy HLSL Shader DVD Set
//DVD 1: Shader Writing Fundamentals
//Chapter 12: Simple Shaders




/***********************************************/
/*** automatically-tracked "tweakables" ********/
/***********************************************/

float4x4 wvp : WorldViewProjection < string UIWidget = "None"; >;


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
        float4 position    	: POSITION;
}; 



/**************************************/
/***** VERTEX SHADER ******************/
/**************************************/

vertex2pixel vertex(app2vertex In) 
{ 
	vertex2pixel Out = (vertex2pixel)0; 
    Out.position = mul(In.position, wvp);	// transform vert position to homogeneous clip space 
    return Out; 
} 



/**************************************/
/***** PIXEL SHADER *******************/
/**************************************/

float4 pixel(vertex2pixel In) : COLOR 
{ 
	float4 col = float4(1.0, 1.0, 1.0, 1.0);
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
