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
.DATA
	MultiplierTwo	dword	2	; Множитель "2" для фильтра Собеля
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
	
	; Сохраняем изначальную вершину стека для последующего его восстановления
	mov r9, rsp

	movzx rax, byte ptr [rdx]
	push rax
	movzx rax, byte ptr [rdx + 1]
	push rax
	movzx rax, byte ptr [rdx + 2]
	push rax
	movzx rax, byte ptr [rdx + r8]
	push rax
	movzx rax, byte ptr [rdx + r8 + 2]
	push rax
	movzx rax, byte ptr [rdx + 2*r8]
	push rax
	movzx rax, byte ptr [rdx + 2*r8 + 1]
	push rax
	movzx rax, byte ptr [rdx + 2*r8 + 2]
	push rax
	

	; Вычисляем Gx

	; Элементы с коэффициентом +-1
	fldz
	fiadd dword ptr [rsp + 8* 7]
	fisub dword ptr [rsp + 8* 5]
	fiadd dword ptr [rsp + 8* 2]
	fisub dword ptr [rsp + 8* 0]

	; Элементы с коэффициентов +-2
	fldz
	fiadd dword ptr [rsp + 8* 4]
	fisub dword ptr [rsp + 8* 3]
	fimul MultiplierTwo 
	faddp

	; Возводим в квадртат
	fmul st(0),st(0)
	
	; Вычисляем Gy

	; Элементы с коэффициентом +-1
	fldz
	fiadd dword ptr [rsp + 8* 7]
	fiadd dword ptr [rsp + 8* 5]
	fisub dword ptr [rsp + 8* 2]
	fisub dword ptr [rsp + 8* 0]

	; Элементы с коэффициентов +-2
	fldz
	fiadd dword ptr [rsp + 8* 6]
	fisub dword ptr [rsp + 8* 1]
	fimul MultiplierTwo 
	faddp

	; Возводим в квадртат
	fmul st(0),st(0)

	; Gx^2 + Gy^2
	faddp

	; sqrt(Gx^2 + Gy^2)
	fsqrt

	; Записываем вычисленное значение в матрицу
	sub rsp, 8
	fistp qword ptr [rsp]
	pop rax
	mov byte ptr [rcx], al 

	; Очищаем стек
	mov rsp, r9

	ret
Kernel ENDP
END
