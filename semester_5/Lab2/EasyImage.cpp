#include "StdAfx.h"

#define KERNEL_MATRIX_WIDTH 3
#define KERNEL_MATRIX_HIGHT 3

int EasyImage::Load(LPCTSTR FileName)
{
	HANDLE hf;
	BITMAPFILEHEADER bfh;
	BITMAPINFOHEADER bih;
	DWORD  rcnt  ;
	COLORREF Pixel ;
	UINT32 RowTailLen ;
 

	hf = CreateFile( FileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL ) ;

	if ( INVALID_HANDLE_VALUE == hf )
		return EasyImage::EI_OpenFileError  ;

	ReadFile( hf, &bfh, sizeof(BITMAPFILEHEADER), &rcnt, NULL ) ;
	if ( (sizeof(BITMAPFILEHEADER) != rcnt) || bfh.bfType != 'MB' )
	{
		CloseHandle(hf) ; 
		return EasyImage::EI_WrongFileFormat ;
	}

	ReadFile( hf, &bih, sizeof(BITMAPINFOHEADER), &rcnt, NULL ) ;
	if ( sizeof(BITMAPINFOHEADER) != rcnt )
	{
		CloseHandle(hf) ; 
		return EasyImage::EI_WrongFileFormat ;
	}

	if ( bfh.bfOffBits != SetFilePointer( hf, bfh.bfOffBits, 0, FILE_BEGIN ))
	{
		CloseHandle(hf) ; 
		return EasyImage::EI_WrongFileFormat ;
	}

	
	switch( bih.biBitCount )
	{
	case 24:
		Create( bih.biWidth, bih.biHeight ) ;
		RowTailLen = bih.biWidth / 4 ;
		RowTailLen = bih.biWidth - RowTailLen*4 ;
		for ( int i = 0 ; i < bih.biHeight ; i++ )
		{
			for ( int j = 0 ; j < bih.biWidth ; j++ )
			{
				ReadFile( hf, &Pixel, 3, &rcnt, NULL ) ;
				if ( 3 != rcnt )
				{
					CloseHandle(hf) ; 
					return EasyImage::EI_WrongFileFormat ;
				}

				pRed  [ (bih.biHeight-i-1)*bih.biWidth + j ] = GetRValue( Pixel ) ;
				pGreen[ (bih.biHeight-i-1)*bih.biWidth + j ] = GetGValue( Pixel ) ;
				pBlue [ (bih.biHeight-i-1)*bih.biWidth + j ] = GetBValue( Pixel ) ;
			}
			ReadFile( hf, &Pixel, RowTailLen, &rcnt, NULL ) ;
		}
		break ;
	default:
		CloseHandle(hf) ; 
		return EasyImage::EI_WrongFileFormat ;
	}

	CloseHandle(hf) ;
	return EasyImage::EI_Success ;
}


int EasyImage::Create(int Width, int Hight)
{
	if ( NULL != pRed   ) delete pRed  ;
	if ( NULL != pGreen ) delete pGreen ;
	if ( NULL != pBlue  ) delete pBlue  ;

	eiWidth  = Width ;
	eiHight  = Hight ;
	CalcTime = 0     ;
	
	pRed = new BYTE[Width*Hight] ;
	memset( pRed, 0, Width*Hight ) ;

	pGreen = new BYTE[Width*Hight] ;
	memset( pGreen, 0, Width*Hight ) ;

	pBlue = new BYTE[Width*Hight] ;
	memset( pBlue, 0, Width*Hight ) ;

	return EasyImage::EI_Success ;
}

void EasyImage::Clear( void )
{
	if ( NULL != pRed )
	{
		delete pRed ;
		pRed = NULL ;
	}

	if ( NULL != pGreen )
	{
		delete pGreen ;
		pGreen = NULL ;
	}

	if ( NULL != pBlue )
	{
		delete pBlue ;
		pBlue = NULL ;
	}

	eiWidth  = eiHight = 0 ;
	CalcTime = 0           ;
}


void EasyImage::View( HDC hdc, RECT rect, BOOL TimeView )
{
	HDC memDC                ;
    HBITMAP memBM            ;
	int viewWidth, viewHight ;
	int Width, Hight         ;
	TCHAR	TimeString[64]   ;
	size_t	TimeLen          ;
	SIZE    TimeSize         ;

	Width = rect.right - rect.left ;
	Hight = rect.bottom - rect.top ;

	if ( NULL == pRed )
		return ;

	if ( Width <= 0 || Width > eiWidth )
		viewWidth = eiWidth ;
	else
		viewWidth = Width   ;

	if ( Hight <= 0 || Hight > eiHight )
		viewHight = eiHight ;
	else
		viewHight = Hight   ;


	_stprintf_s( TimeString, 63, _T("Time -- %d ts/pixel"), CalcTime ) ;
	TimeLen = _tcslen( TimeString ) ;
	GetTextExtentPoint32( hdc, TimeString, (int)TimeLen, &TimeSize ) ;

	ActualRect.left = rect.left ;
	ActualRect.top  = rect.top  ;
	ActualRect.right  = rect.left + viewWidth ;
	ActualRect.bottom = rect.top  + viewHight ;

	if (TimeView)
		TextOut( hdc, (ActualRect.right+ActualRect.left)/2 - TimeSize.cx/2, 
		ActualRect.bottom + TimeSize.cy, TimeString, (int)TimeLen ) ;


	memDC = CreateCompatibleDC ( hdc );
	memBM = CreateCompatibleBitmap ( hdc, viewWidth, viewHight );
	SelectObject ( memDC, memBM );

	for ( int i = 0 ; i < viewHight ; i++ )
		for ( int j = 0 ; j < viewWidth ; j++ )
		{
			COLORREF pix = RGB( pBlue[i*eiWidth + j], pGreen[i*eiWidth + j], pRed[i*eiWidth + j] ) ;
			SetPixel( memDC, j, i, pix ) ;
			//SetPixel( memDC, j, i, (*this)[i][j]) ;
		}

	BitBlt( hdc, rect.left, rect.top, viewWidth, viewHight, memDC, 0, 0, SRCCOPY ) ;
	DeleteObject( memDC ) ;
	DeleteObject( memBM ) ;
}

EasyImage& EasyImage::operator=( EasyImage& a ) 
{
	Create( a.eiWidth, a.eiHight ) ;
	memcpy( pRed,   a.pRed,   eiWidth * eiHight ) ;
	memcpy( pGreen, a.pGreen, eiWidth * eiHight ) ;
	memcpy( pBlue,  a.pBlue,  eiWidth * eiHight ) ;
	return *this ;
}


long long EasyImage::Filtering( EasyImage& Src, FILTER_DSC& Filter )
{
	long long start   ; // Значение счетчика тиков при входе
			            // в функцию

	// Матрица содержит все пикселы, для которых может быть вычислено значение (некрайние)
	int Hight = Src.Hight() - Filter.FilterMatrixWidth + 1 ;
	int Width = (Src.Width() - Filter.FilterMatrixHight + 1) / Filter.PixelsAtOnce ;
	Width *= Filter.PixelsAtOnce ;


	if (  Hight < 1 || Width < 1 )
		return 0 ;

	Create( Width, Hight ) ;
	start = __rdtsc() ;

	for( int i = 0 ; i < Hight ; i++ )
	{
		int dstRow = i * Width       ;
		int srcRow = i * Src.Width() ;
		for ( int j = 0 ; j < Width ; j += Filter.PixelsAtOnce )
		{
			Filter.KernelFunc( pRed  +dstRow+j, Src.pRed  +srcRow+j, Src.Width() ) ; 
			Filter.KernelFunc( pGreen+dstRow+j, Src.pGreen+srcRow+j, Src.Width() ) ; 
			Filter.KernelFunc( pBlue +dstRow+j, Src.pBlue +srcRow+j, Src.Width() ) ; 
		}
	}

	CalcTime = (__rdtsc() - start)/( Width * Hight )  ;
	return CalcTime ;
}

static TCHAR CustomFilter[128] = _T( "bmp\0*.bmp" ) ;
int EasyImage::OpenDlg( HINSTANCE hInst, HWND hWnd )
{
	OPENFILENAME ofn ;
	TCHAR	FileName[128] = _T("\0") ;

	ofn.lStructSize = sizeof( OPENFILENAME )  ;
	ofn.hwndOwner   = hWnd                    ;
	ofn.hInstance   = hInst                   ;
	ofn.lpstrFilter = _T("bmp files (*.bmp)\0*.bmp\0All Files (*.*)\0*.*\0\0") ;
	ofn.lpstrCustomFilter = CustomFilter           ;
	ofn.nMaxCustFilter    = sizeof( CustomFilter ) ;
	ofn.nFilterIndex      = 0                      ;
	ofn.lpstrFile         = FileName               ;
	ofn.nMaxFile          = sizeof( FileName )     ;
	ofn.lpstrFileTitle    = NULL                   ;
	ofn.lpstrInitialDir   = NULL                   ;
	ofn.lpstrTitle        = _T("Open Image..." )   ;
	ofn.Flags             = OFN_FILEMUSTEXIST | OFN_HIDEREADONLY ;
	ofn.lpstrDefExt       = _T("bmp")         ;
	ofn.FlagsEx           = NULL              ;

	if ( 0 != GetOpenFileName( &ofn ))
		return Load(FileName) ;
	else
		return EasyImage::EI_OpenFileError ;
}
