; -------------------------------------------------------------------------------------  ;
;    Лабораторная работа №2 по курсу Программирование на языке ассемблера                ;
;    Вариант №2.6                                                                        ;
;    Выполнил студент Балашов Илья.                                                      ;
;                                                                                        ;
;    Исходный модуль LabAssignment.asm                                                   ;
;    Содержит функцию на языке ассемблера, разработанную в соответствии с заданием       ;
; -------------------------------------------------------------------------------------  ;
;    Задание: 
;        Реализовать фильтр Собеля обработки изображений с использованием вещественных
;       вычислений и расширения AVX
.DATA
    ; Множитель "2" для фильтра Собеля
    MultiplierTwo           real4       2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
    ; Множитель "-1" для смены знака
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

    ; Сохраняем состояние стека RSP
    mov rax, rsp

    ; Сохраняем состояние регистров в стеке в соответствии с соглашением
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm6
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm7
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm8
    
    ; Читаем по 8 экземпляров каждого используемого элемента матрицы
    ; (используем беззнаковое расширение)
    vpmovzxbd ymm1, qword ptr [rdx + 2]         ; z3
    vpmovzxbd ymm2, qword ptr [rdx + r8]        ; z4
    vpmovzxbd ymm3, qword ptr [rdx + r8 + 2]    ; z6
    vpmovzxbd ymm4, qword ptr [rdx + 2*r8]      ; z7
    vpmovzxbd ymm5, qword ptr [rdx + 2*r8 + 2]  ; z9
    vpmovzxbd ymm6, qword ptr [rdx + 1]         ; z2
    vpmovzxbd ymm7, qword ptr [rdx + 2*r8 + 1]  ; z8
    vpmovzxbd ymm8, qword ptr [rdx]             ; z1

    ; Конвертируем прочитанные целые числа в вещественные
    vcvtdq2ps ymm1, ymm1
    vcvtdq2ps ymm2, ymm2
    vcvtdq2ps ymm3, ymm3
    vcvtdq2ps ymm4, ymm4
    vcvtdq2ps ymm5, ymm5
    vcvtdq2ps ymm6, ymm6
    vcvtdq2ps ymm7, ymm7
    vcvtdq2ps ymm8, ymm8

    ; Умножаем на 2 элементы, которые в Gx и Gy будут с коэффициентом 2
    vmulps ymm2, ymm2, MultiplierTwo    ; z4 
    vmulps ymm3, ymm3, MultiplierTwo    ; z6
    vmulps ymm6, ymm6, MultiplierTwo    ; z2
    vmulps ymm7, ymm7, MultiplierTwo    ; z8
    
    ; Вычисляем Gx

    ; Применяем отрицание к элементам, которые в матрице Gx со знаком "минус"
    vmulps ymm1, ymm1, MultiplierMinusOne   ; -z3
    vmulps ymm3, ymm3, MultiplierMinusOne   ; -2*z6
    vmulps ymm5, ymm5, MultiplierMinusOne   ; -z9

    ; Производим сложение и получаем Gx
    vmovapd ymm0, ymm1          ; - z3 (инициализируем сумму)
    vaddps ymm0, ymm0, ymm2     ; + 2*z4
    vaddps ymm0, ymm0, ymm3     ; + 2*z6
    vaddps ymm0, ymm0, ymm4     ; + z7
    vaddps ymm0, ymm0, ymm5     ; - z9
    vaddps ymm0, ymm0, ymm8     ; + z1

    ; Gx^2
    vmulps ymm0, ymm0, ymm0

    ; Получаем Gy

    ; Выставляем необходимые знаки + и - в соответствии с формулой Gy
    vmulps ymm1, ymm1, MultiplierMinusOne   ; +z3, исправляем после Gx
    vmulps ymm4, ymm4, MultiplierMinusOne   ; -2*z4
    vmulps ymm7, ymm7, MultiplierMinusOne   ; -2*z8

    ; Выполняем сложение и получаем Gy
    vmovapd ymm9, ymm8          ; + z1 (инициализируем сумму)
    vaddps ymm9, ymm9, ymm6     ; + 2*z2
    vaddps ymm9, ymm9, ymm1     ; + z3
    vaddps ymm9, ymm9, ymm4     ; - 2*z4
    vaddps ymm9, ymm9, ymm5     ; - z9
    vaddps ymm9, ymm9, ymm7     ; - 2*z8

    ; Gy^2
    vmulps ymm9, ymm9, ymm9

    ; Gx^2 + Gy^2
    vaddps ymm0, ymm0, ymm9
    ; sqrt(Gx^2 + Gy^2)
    vsqrtps ymm0, ymm0

    ; Конветируем вешественные числа в целые dword
    vcvtps2dq ymm0, ymm0
    ; Упаковываем dword в word 
    ; (знаковая арифметика насыщения, чтобы не портить диапазон для следующей команды)
    vpackssdw ymm0, ymm0, ymm0 
    ; Упаковываем word в byte (беззнаковая арифметика насыщения)
    vpackuswb ymm0, ymm0, ymm0 

    ; В силу независимости двух половин регистров AVX, 
    ; результат после упаковки будет находиться в младших 4х байтах каждой из половин

    ; Извлекаем первые 4 байта результата из младшей части регистра YMM0
    vpextrd dword ptr [rcx], xmm0, 0
    ; Переносим старшую часть регистра YMM0 в младшую
    vextracti128 xmm0, ymm0, 1
    ; Извлекаем вторые 4 байта результата
    vpextrd dword ptr [rcx + 4], xmm0, 0

    ; Восстанавливаем регистры YMM в соответствии с соглашением
    vmovdqu ymm8, ymmword ptr [rsp + 0*32]
    vmovdqu ymm7, ymmword ptr [rsp + 1*32]
    vmovdqu ymm6, ymmword ptr [rsp + 2*32]

    ; Восстанавливаем стек RSP
    mov rsp, rax
   
    ; Зануляем все регистры YMM в соответствии с рекомендацией по производительности
    vzeroall

    ; Возврат из функции
    ret
Kernel ENDP
END
