; -------------------------------------------------------------------------------------  ;
;    Лабораторная работа №n по курсу Программирование на языке ассемблера                ;
;    Вариант №2.6                                                                        ;
;    Выполнил студент Балашов Илья.                                                      ;
;                                                                                        ;
;    Исходный модуль LabAssignment.asm                                                   ;
;    Содержит функцию на языке ассемблера, разработанную в соответствии с заданием       ;
; -------------------------------------------------------------------------------------  ;
;    Задание: 
;        Реализовать фильтр Собеля обработки изображений с использованием вещественных
;       вычислений
.DATA
    ; Множитель "2" для фильтра Собеля
    MultiplierTwo           real4       2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
    ; Множитель "-1"
    MultiplierMinusOne      real4       -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0
.CODE
; -------------------------------------------------------------------------------------  ;
; Осуществляет фильтрацию одной цветовой составляющей изображения                        ;
; void Kernel( PBYTE pDst, PBYTE pSrc, int Width )                                       ;
; Параметры:                                                                             ;
;    pDst   - адрес пиксела - результата обработки                                       ;
;   pSrc   - адрес пиксела исходного изображения                                         ;
;    Width  - ширина изображения в пикселах (количество столбцов)                        ;
; Внимание!!! Для корректной работы приложения необходимо определить константы в файле   ;
;    Tuning.h в соответствии с заданием                                                  ;
; -------------------------------------------------------------------------------------  ;
Kernel PROC ; [RCX] - pDst
            ; [RDX] - pSrc
            ; R8    - Width

    ; Фильтр Собеля:
    ; Обрабатываемая матрица имеет вид ([RDX] = z0):
    ; (z1, z2, z3)
    ; (z4, z5, z6)
    ; (z7, z8, z9)
    ; Пусть:
    ; Gx = 2*(z4 - z0) + z1 + z7 - z3 - z9
    ; Gy = 2*(z2 - z8) + z2 + z3 - z7 - z9
    ; Тогда итоговое значение после обработки будет равно [RCX] = sqrt(Gx^2 + Gy^2)

    vzeroall

    ; Сохранять ymm6 и ymm7, ymm8
    
    ; Читаем по 8 экземпляров каждого элемента матрицы:
    vpmovsxbd ymm1, qword ptr [rdx + 2]         ; z3
    vpmovsxbd ymm2, qword ptr [rdx + r8]        ; z4
    vpmovsxbd ymm3, qword ptr [rdx + r8 + 2]    ; z6
    vpmovsxbd ymm4, qword ptr [rdx + 2*r8]      ; z7
    vpmovsxbd ymm5, qword ptr [rdx + 2*r8 + 2]  ; z9
    vpmovsxbd ymm6, qword ptr [rdx + 1]         ; z2
    vpmovsxbd ymm7, qword ptr [rdx + 2*r8 + 1]  ; z8
    vpmovsxbd ymm8, qword ptr [rdx]             ; z1

    ; Конвертируем целые числа в вещественные
    vcvtdq2ps ymm1, ymm1
    vcvtdq2ps ymm2, ymm2
    vcvtdq2ps ymm3, ymm3
    vcvtdq2ps ymm4, ymm4
    vcvtdq2ps ymm5, ymm5
    vcvtdq2ps ymm6, ymm6
    vcvtdq2ps ymm7, ymm7
    vcvtdq2ps ymm8, ymm8

    ; Умножаем элементы средней строки на 2
    vmulps ymm2, ymm2, MultiplierTwo 
    vmulps ymm3, ymm3, MultiplierTwo
    vmulps ymm6, ymm6, MultiplierTwo
    vmulps ymm7, ymm7, MultiplierTwo

    ; Применяем отрицание к элементам, которые в матрице Gx со знаком "минус"
    vmulps ymm1, ymm1, MultiplierMinusOne
    vmulps ymm3, ymm3, MultiplierMinusOne
    vmulps ymm5, ymm5, MultiplierMinusOne

    ; Производим сложение и получаем Gx
    vaddps ymm0, ymm0, ymm1
    vaddps ymm0, ymm0, ymm2
    vaddps ymm0, ymm0, ymm3
    vaddps ymm0, ymm0, ymm4
    vaddps ymm0, ymm0, ymm5
    vaddps ymm0, ymm0, ymm8

    ; Gx^2
    vmulps ymm0, ymm0, ymm0

        
    ; Получаем Gy

    vmulps ymm1, ymm1, MultiplierMinusOne
    vmulps ymm4, ymm4, MultiplierMinusOne
    vmulps ymm5, ymm5, MultiplierMinusOne
    vmulps ymm7, ymm7, MultiplierMinusOne

    vaddps ymm9, ymm9, ymm8
    vaddps ymm9, ymm9, ymm6
    vaddps ymm9, ymm9, ymm1
    vaddps ymm9, ymm9, ymm4
    vaddps ymm9, ymm9, ymm5
    vaddps ymm9, ymm9, ymm7

    ; Gy^2
    vmulps ymm9, ymm9, ymm9

    ; Gx^2 + Gy^2
    vaddps ymm0, ymm0, ymm9

    ; sqrt(Gx^2 + Gy^2)
    vsqrtps ymm0, ymm0

    

    ; TODO: Optimize it!!!
     
    ; Конветируем вешественные числа в целые DWORD
    vcvtps2dq ymm0, ymm0
    ; Упаковываем результат из DWORD в BYTE
    vpackssdw ymm0, ymm0, ymm0 ; из dword в word
    vpacksswb ymm0, ymm0, ymm0 ; из word в byte

    ; Извлекаем первые 4 байта результата из младшей части регистра YMM0
    vpextrd dword ptr [rcx], xmm0, 0
    ; Переносим старшую часть регистра YMM0 в младшую
    vextracti128 xmm0, ymm0, 1
    ; Извлекаем вторые 4 байта результата
    vpextrd dword ptr [rcx + 4], xmm0, 0
   
    ; Зануляем все регистры YMM
    vzeroall
    ; Возврат из функции
    ret
Kernel ENDP
END
