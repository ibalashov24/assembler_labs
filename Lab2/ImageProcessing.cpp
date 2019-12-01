// Filtering.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "ImageProcessing.h"

#define MAX_LOADSTRING 100

// Декларация функции - ядра фильтра. 
// Сама функция реализована на языке ассемблера в LabnKernel_Name_xx.asm
extern "C" KERNEL_FUNC Kernel ;
extern "C" KERNEL_FUNC Kernel_stub;

// Дескриптор функции ядра фильтра
// Тип FILTER_DSC определен в EasyImage.h как структура из четырех компонент
//		1. Указатель на функцию ядра фильта (здесь Kernel_asm из LabnKernel_Name_xx.asm)
//		2. Количество строк в матрице ядра фильтра (здесь 3)
//		3. Количество столбцов в матрице ядра фильтра (здесь 3)
//		4. Количество последовательных пикселов строки, обрабатываемых функцией за одно
//			обращение (здесь 1)
#ifndef STUB
FILTER_DSC dsc_asm = { Kernel, KERNEL_MATRIX_HIGHT, KERNEL_MATRIX_WIDTH, PIXELS_IN_PARALLEL };
#else
FILTER_DSC dsc_asm = { Kernel_stub, KERNEL_MATRIX_HIGHT, KERNEL_MATRIX_WIDTH, PIXELS_IN_PARALLEL };
#endif
/* ------------------------------------------------------------------------------------ - */



// Global Variables:
HINSTANCE hInst;								// current instance
TCHAR szTitle[MAX_LOADSTRING];					// The title bar text
TCHAR szWindowClass[MAX_LOADSTRING];			// the main window class name

// Forward declarations of functions included in this code module:
ATOM				MyRegisterClass(HINSTANCE hInstance);
BOOL				InitInstance(HINSTANCE, int);
LRESULT CALLBACK	WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK	About(HWND, UINT, WPARAM, LPARAM);

// Исходное и результирующее изображения
EasyImage img_src, img_dst;

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPTSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

 	// TODO: Place code here.
	MSG msg;
	HACCEL hAccelTable;

	// Initialize global strings
	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_IMAGEPROCESSING, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);

	// Perform application initialization:
	if (!InitInstance (hInstance, nCmdShow))
	{
		return FALSE;
	}

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_IMAGEPROCESSING));

	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0))
	{
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
		{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}

	return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;

	wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ICON_FROG));
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName = MAKEINTRESOURCE(IDC_IMAGEPROCESSING);
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_ICON_FROG));

	return RegisterClassEx(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   HWND hWnd;

   hInst = hInstance; // Store instance handle in our global variable

   hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, NULL, NULL, hInstance, NULL);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND	- process the application menu
//  WM_PAINT	- Paint the main window
//  WM_DESTROY	- post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;
	RECT  rc, rc_left, rc_right;
	int Border;

	switch (message)
	{
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		// Parse the menu selections:
		switch (wmId)
		{
		case ID_FILE_LOADIMAGE:
			if (EasyImage::EI_Success != img_src.OpenDlg(hInst, hWnd))
				MessageBox(hWnd, _T("Open File Error"), NULL, MB_ICONERROR | MB_OK);
			else
			{
				img_dst.Clear();
				InvalidateRect(hWnd, NULL, TRUE);
			}
			break;
		case ID_FILE_FILTERING:
			img_dst.Filtering(img_src, dsc_asm);
			InvalidateRect(hWnd, NULL, TRUE);
			break;
		case IDM_EXIT:
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		GetClientRect(hWnd, &rc);

		Border = (rc.bottom - rc.top) / 20;
		rc_left = rc_right = rc;
		rc_left.top = rc_right.top = rc.top + Border;
		rc_left.bottom = rc_right.bottom = rc.bottom - 3 * Border;
		rc_left.left = rc.left + Border;
		rc_left.right = rc.left + (rc.right - rc.left) / 2 - Border / 2;
		rc_right.left = rc.left + (rc.right - rc.left) / 2 + Border / 2;
		rc_right.right = rc.right - Border;

		img_src.View(hdc, rc_left);
		img_dst.View(hdc, rc_right, TRUE);

		ValidateRect(hWnd, NULL);
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
