; -------------------------------------------------------------------------------------  ;
;    ������������ ������ �2 �� ����� ���������������� �� ����� ����������                ;
;    ������� �2.6                                                                        ;
;    �������� ������� ������� ����.                                                      ;
;                                                                                        ;
;    �������� ������ LabAssignment.asm                                                   ;
;    �������� ������� �� ����� ����������, ������������� � ������������ � ��������       ;
; -------------------------------------------------------------------------------------  ;
;    �������: 
;        ����������� ������ ������ ��������� ����������� � �������������� ������������
;       ���������� � ���������� AVX
.DATA
    ; ��������� "2" ��� ������� ������
    MultiplierTwo           real4       2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
    ; ��������� "-1" ��� ����� �����
    MultiplierMinusOne      real4       -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0
.CODE
; -------------------------------------------------------------------------------------  ;
; ������������ ���������� ����� �������� ������������ �����������                        ;
; void Kernel( PBYTE pDst, PBYTE pSrc, int Width )                                       ;
; ���������:                                                                             ;
;    pDst   - ����� ������� - ���������� ���������                                       ;
;   pSrc   - ����� ������� ��������� �����������                                         ;
;    Width  - ������ ����������� � �������� (���������� ��������)                        ;
; ��������!!! ��� ���������� ������ ���������� ���������� ���������� ��������� � �����   ;
;    Tuning.h � ������������ � ��������                                                  ;
; -------------------------------------------------------------------------------------  ;
Kernel PROC ; [RCX] - pDst
            ; [RDX] - pSrc
            ; R8    - Width

    ; ������ ������:
    ; �������������� ������� ����� ��� ([RDX] = z0):
    ; (z1, z2, z3)
    ; (z4, z5, z6)
    ; (z7, z8, z9)
    ; �����:
    ; Gx = 2*(z4 - z0) + z1 + z7 - z3 - z9
    ; Gy = 2*(z2 - z8) + z2 + z3 - z7 - z9
    ; ����� �������� �������� ����� ��������� ����� ����� [RCX] = sqrt(Gx^2 + Gy^2)

    ; ��������� ��������� ����� RSP
    mov rax, rsp

    ; ��������� ��������� ��������� � ����� � ������������ � �����������
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm6
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm7
    sub rsp, 32
    vmovdqu ymmword ptr [rsp], ymm8
    
    ; ������ �� 8 ����������� ������� ������������� �������� �������
    ; (���������� ����������� ����������)
    vpmovzxbd ymm1, qword ptr [rdx + 2]         ; z3
    vpmovzxbd ymm2, qword ptr [rdx + r8]        ; z4
    vpmovzxbd ymm3, qword ptr [rdx + r8 + 2]    ; z6
    vpmovzxbd ymm4, qword ptr [rdx + 2*r8]      ; z7
    vpmovzxbd ymm5, qword ptr [rdx + 2*r8 + 2]  ; z9
    vpmovzxbd ymm6, qword ptr [rdx + 1]         ; z2
    vpmovzxbd ymm7, qword ptr [rdx + 2*r8 + 1]  ; z8
    vpmovzxbd ymm8, qword ptr [rdx]             ; z1

    ; ������������ ����������� ����� ����� � ������������
    vcvtdq2ps ymm1, ymm1
    vcvtdq2ps ymm2, ymm2
    vcvtdq2ps ymm3, ymm3
    vcvtdq2ps ymm4, ymm4
    vcvtdq2ps ymm5, ymm5
    vcvtdq2ps ymm6, ymm6
    vcvtdq2ps ymm7, ymm7
    vcvtdq2ps ymm8, ymm8

    ; �������� �� 2 ��������, ������� � Gx � Gy ����� � ������������� 2
    vmulps ymm2, ymm2, MultiplierTwo    ; z4 
    vmulps ymm3, ymm3, MultiplierTwo    ; z6
    vmulps ymm6, ymm6, MultiplierTwo    ; z2
    vmulps ymm7, ymm7, MultiplierTwo    ; z8
    
    ; ��������� Gx

    ; ��������� ��������� � ���������, ������� � ������� Gx �� ������ "�����"
    vmulps ymm1, ymm1, MultiplierMinusOne   ; -z3
    vmulps ymm3, ymm3, MultiplierMinusOne   ; -2*z6
    vmulps ymm5, ymm5, MultiplierMinusOne   ; -z9

    ; ���������� �������� � �������� Gx
    vmovapd ymm0, ymm1          ; - z3 (�������������� �����)
    vaddps ymm0, ymm0, ymm2     ; + 2*z4
    vaddps ymm0, ymm0, ymm3     ; + 2*z6
    vaddps ymm0, ymm0, ymm4     ; + z7
    vaddps ymm0, ymm0, ymm5     ; - z9
    vaddps ymm0, ymm0, ymm8     ; + z1

    ; Gx^2
    vmulps ymm0, ymm0, ymm0

    ; �������� Gy

    ; ���������� ����������� ����� + � - � ������������ � �������� Gy
    vmulps ymm1, ymm1, MultiplierMinusOne   ; +z3, ���������� ����� Gx
    vmulps ymm4, ymm4, MultiplierMinusOne   ; -2*z4
    vmulps ymm7, ymm7, MultiplierMinusOne   ; -2*z8

    ; ��������� �������� � �������� Gy
    vmovapd ymm9, ymm8          ; + z1 (�������������� �����)
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

    ; ����������� ������������ ����� � ����� dword
    vcvtps2dq ymm0, ymm0
    ; ����������� dword � word 
    ; (�������� ���������� ���������, ����� �� ������� �������� ��� ��������� �������)
    vpackssdw ymm0, ymm0, ymm0 
    ; ����������� word � byte (����������� ���������� ���������)
    vpackuswb ymm0, ymm0, ymm0 

    ; � ���� ������������� ���� ������� ��������� AVX, 
    ; ��������� ����� �������� ����� ���������� � ������� 4� ������ ������ �� �������

    ; ��������� ������ 4 ����� ���������� �� ������� ����� �������� YMM0
    vpextrd dword ptr [rcx], xmm0, 0
    ; ��������� ������� ����� �������� YMM0 � �������
    vextracti128 xmm0, ymm0, 1
    ; ��������� ������ 4 ����� ����������
    vpextrd dword ptr [rcx + 4], xmm0, 0

    ; ��������������� �������� YMM � ������������ � �����������
    vmovdqu ymm8, ymmword ptr [rsp + 0*32]
    vmovdqu ymm7, ymmword ptr [rsp + 1*32]
    vmovdqu ymm6, ymmword ptr [rsp + 2*32]

    ; ��������������� ���� RSP
    mov rsp, rax
   
    ; �������� ��� �������� YMM � ������������ � ������������� �� ������������������
    vzeroall

    ; ������� �� �������
    ret
Kernel ENDP
END
