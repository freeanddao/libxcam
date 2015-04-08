/*
 * function: kernel_denoise
 *     bi-laterial filter for denoise usage
 * input:    image2d_t as read only
 * output:   image2d_t as write only
 * sigma_r:  the parameter to set sigma_r in the Gaussian filtering
 * imw:      image width, used for edge detect
 * imh:      image height, used for edge detect
 */


"__constant float gausssingle[25]={0.6411,0.7574,0.8007,0.7574,0.6411,0.7574,0.8948,0.9459,0.8948,0.7574,0.8007,0.94595945,1,0.9459,0.8007,0.7574,0.8948,0.9459,0.8948,0.7574,0.6411,0.7574,0.8007,0.7574,0.6411};                     "
"__constant int fw=5;                     "
"__constant int fwh=2;                     "
"void dotmultiply (__local float *pFilter, int fw ,__local float *pInput,__local float *pOutput,int offset1, int offset2, int offset3)                     "
"{                     "
"	for(int yOut =0;yOut <fw;yOut++)                     "
"	{                     "
"		int yInTopLeft = yOut*fw;                     "
"		for (int xOut =0; xOut<fw;xOut ++)                     "
"		{                     "
"			float msum=0;                     "
"			msum+=pFilter[offset1+yInTopLeft+xOut]*pInput[offset2+yInTopLeft+xOut];                     "
"			pOutput[offset3+yOut*fw+xOut]=msum;                     "
"		}                     "
"	}                     "
"}                     "
"                     "
"void dotmultiplygauss (__local float *pFilter, int fw , __constant float *pInput, __local float *pOutput,int offset1, int offset2, int offset3)           "
"{                     "
"	for(int yOut =0;yOut <fw;yOut++)                     "
"	{                     "
"		int yInTopLeft = yOut*fw;                     "
"		for (int xOut =0; xOut<fw;xOut ++)                     "
"		{                     "
"			float msum=0;                     "
"			msum+=pFilter[offset1+yInTopLeft+xOut]*pInput[offset2+yInTopLeft+xOut];                     "
"			pOutput[offset3+yOut*fw+xOut]=msum;                     "
"		}                     "
"	}                     "
"}                     "
"                     "
"float matrixsum(__local float *pIn, int length,int offset)                     "
"{                     "
"	float ssum=0;                     "
"	for(int i=0;i<length;i++)                     "
"		ssum+=pIn[offset+i];                     "
"                     "
"	return ssum;                     "
"}                     "
"                     "
" __kernel void kernel_denoise(__read_only image2d_t srcRGB, __write_only image2d_t dstRGB, float sigma_r, unsigned int imw, unsigned int imh) "
"{                     "
"	int gidX = get_global_id(1);                         "
"	int gidY = get_global_id(0);                        "
"	int localX = get_local_id(1);                        "
"	int localY = get_local_id(0);                       "
"	float R=0;                     "
"	float G=0;                     "
"	float B=0;                     "
"	float normF=0;                     "
"	float dR,dG,dB;                     "
"	__local float F[25*30*4*5];                     "
"	int offset=localY*(30*25*5)+localX*25*5;                     "
"	int offsetH,offsetF,offsetR,offsetG,offsetB;                     "
"	offsetH= offset + 3*25;                     "
"	offsetF= offset + 4*25;                     "
"	offsetR= offset;                     "
"	offsetG= offset + 1*25;                     "
"	offsetB= offset + 2*25;                     "
"                     "
"	sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE |CLK_FILTER_NEAREST;                     "
"	int x = gidX*4;                     "
"	int y = gidY;                     "
"	float4 line[4];                     "
"	float4 tmp;                     "
"	int k=0;                     "
"                     "
"	line[0] = read_imagef(srcRGB, sampler, (int2)(x,y));                     "
"	line[1] = read_imagef(srcRGB, sampler, (int2)(x+1,y));                     "
"	line[2] = read_imagef(srcRGB, sampler, (int2)(x+2,y));                     "
"	line[3] = read_imagef(srcRGB, sampler, (int2)(x+3,y));                     "
"                     "
"	if (x > fwh &&                     "
"			x <(imw-fwh) &&                     "
"			y >fwh &&                     "
"			y <(imh-fwh))                     "
"	{                     "
"		for(k=0;k<4;k++)                     "
"		{                     "
"			int i = 0;                     "
"			int j = 0;                     "
"			for(i=0;i<fw;i++)                     "
"			{                     "
"				for(j=0;j<fw;j++)                     "
"				{                     "
"					tmp=read_imagef(srcRGB, sampler, (int2)(x+k-fwh+i,y+j-fwh));                     "
"					F[offsetR+i*fw+j]=tmp.x;                     "
"					F[offsetG+i*fw+j]=tmp.y;                     "
"					F[offsetB+i*fw+j]=tmp.z;                     "
"					dR=tmp.x-line[k].x;                     "
"					dG=tmp.y-line[k].y;                     "
"					dB=tmp.z-line[k].z;                     "
"					F[offsetH+i*fw+j]=exp(-(dR*dR+dG*dG+dB*dB)/(2*pow(sigma_r,2)));                     "
"				}                     "
"			}                     "
"			dotmultiplygauss(F, fw ,gausssingle ,F,offsetH,0,offsetF);                     "
"			normF=matrixsum(F,25,offsetF);                     "
"			dotmultiply(F,fw,F,F,offsetF,offsetR,offsetH);                     "
"			line[k].x=matrixsum(F,25,offsetH)/normF;                     "
"			dotmultiply(F,fw,F,F,offsetF,offsetG,offsetH);                     "
"			line[k].y=matrixsum(F,25,offsetH)/normF;                     "
"			dotmultiply(F,fw,F,F,offsetF,offsetB,offsetH);                     "
"			line[k].z=matrixsum(F,25,offsetH)/normF;                     "
"			line[k].w=1.0;                     "
"		}                     "
"	}                     "
"                     "
"	write_imagef(dstRGB,(int2)(x,y),line[0]);                     "
"	write_imagef(dstRGB,(int2)(x+1,y),line[1]);                     "
"	write_imagef(dstRGB,(int2)(x+2,y),line[2]);                     "
"	write_imagef(dstRGB,(int2)(x+3,y),line[3]);                     "
"}                     "
