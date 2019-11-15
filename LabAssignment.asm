; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №n по курсу Программирование на языке ассемблера				;
;	Вариант №vv.																		;
;	Выполнил студент Name.																;
;																						;
;	Исходный модуль LabAssignment.asm													;
;	Содержит функцию на языке ассемблера, разработанную в соответствии с заданием		;
; -------------------------------------------------------------------------------------	;
;	Задание: 
;		Реализовать фильтр обработки изображений
ROUND_MASK	EQU 0F3FFh	; Маска очистки битов округления RCB (bit 11,10) = 00
ROUND_DOWN	EQU 0400h	; Маска установки битов округления вниз (bit 11,10)  = 01
.DATA
	MultiplierTwo	qword	2	; Множитель "2" для фильтра Собеля
.CODE
; -------------------------------------------------------------------------------------	;
; Осуществляет фильтрацию одной цветовой составляющей изображения						;
; void Kernel( PBYTE pDst, PBYTE pSrc, int Width )										;
; Параметры:																			;
;	pDst   - адрес пиксела - результата обработки										;
;   pSrc   - адрес пиксела исходного изображения											;
;	Width  - ширина изображения в пикселах (количество столбцов)							;
; Внимание!!! Для корректной работы приложения необходимо определить константы в файле	;
;	Tuning.h в соответствии с заданием													;
; -------------------------------------------------------------------------------------	;
Kernel PROC	; [RCX] - pDst
			; [RDX] - pSrc
			; R8    - Width
	; Здесь осуществляется копирование одной цветовой составляющей одного пиксела
	;  из исходного изображения. Необходимо заменить этот код в соответствии с заданием
	; mov		al, byte ptr [rdx] ; Копирование
	; mov		byte ptr [rcx], al ;   одного пиксела



	fldz
	
	movzx rax, byte ptr [rdx]
	push rax
	fiadd dword ptr [rsp]
	pop rax 

	movzx rax, byte ptr [rdx + 2*r8]
	push rax
	fiadd dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + 2]
	push rax
	fisub dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + 2*r8 + 2]
	push rax
	fisub dword ptr [rsp]
	pop rax

	fldz

	movzx rax, byte ptr [rdx + r8]
	push rax
	fiadd dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + r8 + 2]
	push rax
	fisub dword ptr [rsp]
	pop rax

	fmul MultiplierTwo
	faddp 

	fldz
	fxch st(1)

	movzx rax, byte ptr [rdx]
	push rax
	fiadd dword ptr [rsp]
	pop rax 

	movzx rax, byte ptr [rdx + 2]
	push rax
	fiadd dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + 2*r8]
	push rax
	fisub dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + 2*r8 + 2]
	push rax
	fisub dword ptr [rsp]
	pop rax

	fldz

	movzx rax, byte ptr [rdx + 1]
	push rax
	fiadd dword ptr [rsp]
	pop rax

	movzx rax, byte ptr [rdx + 2*r8 + 1]
	push rax
	fisub dword ptr [rsp]
	pop rax

	fmul MultiplierTwo
	faddp st(2),st(0)

	fmul st(0),st(0)

	fxch st(1)
	fmul st(0),st(0)

	faddp 
	fsqrt

	sub rsp, 8
	fistp qword ptr [rsp]
	pop rax
	mov byte ptr [rcx], al 

	ret
Kernel ENDP
END
