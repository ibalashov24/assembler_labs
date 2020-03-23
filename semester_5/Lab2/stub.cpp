#include "stdafx.h"
#define SOBEL 1



#define KERNEL SOBEL

#if KERNEL == SOBEL
extern "C" void Kernel_stub(PBYTE pDst, PBYTE pSrc, int Width)
{
	double px1, px2, px ;
	
	px1 =
		-*(pSrc - Width - 1)
		- (*(pSrc - Width)) *2.
		- *(pSrc - Width + 1)
		+ *(pSrc + Width - 1)
		+ (*(pSrc + Width)) *2.
		+ *(pSrc + Width + 1);
	px2 =
		-*(pSrc - Width - 1)
		- (*(pSrc - 1)) *2.
		- *(pSrc + Width - 1)
		+ *(pSrc - Width + 1)
		+ (*(pSrc + 1)) *2.
		+ *(pSrc + Width + 1);

	px = sqrt(px1*px1 + px2*px2);

	if (px > 255)
		px = 255;

	*pDst = px;
}
#else
#endif