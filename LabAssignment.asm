; -------------------------------------------------------------------------------------	;
;	������������ ������ �n �� ����� ���������������� �� ����� ����������				;
;	������� �2.6																		;
;	�������� ������� ������� ����.														;
;																						;
;	�������� ������ LabAssignment.asm													;
;	�������� ������� �� ����� ����������, ������������� � ������������ � ��������		;
; -------------------------------------------------------------------------------------	;
;	�������: 
;		����������� ������ ������ ��������� ����������� � �������������� ������������
;       ����������
.DATA
	MultiplierTwo	dword	2	; ��������� "2" ��� ������� ������
.CODE
; -------------------------------------------------------------------------------------	;
; ������������ ���������� ����� �������� ������������ �����������						;
; void Kernel( PBYTE pDst, PBYTE pSrc, int Width )										;
; ���������:																			;
;	pDst   - ����� ������� - ���������� ���������										;
;   pSrc   - ����� ������� ��������� �����������										;
;	Width  - ������ ����������� � �������� (���������� ��������)						;
; ��������!!! ��� ���������� ������ ���������� ���������� ���������� ��������� � �����	;
;	Tuning.h � ������������ � ��������													;
; -------------------------------------------------------------------------------------	;
Kernel PROC	; [RCX] - pDst
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

	; ��������� ����������� ������� ����� ��� ������������ ��� ��������������
	mov r9, rsp

	; ��������� ������ �������������� ������� � ����
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
	
	; ��������� Gx

	; ��������� �������� � ������������� +-1
	fldz ; ������������� ����� ����
	fiadd dword ptr [rsp + 8* 7]
	fisub dword ptr [rsp + 8* 5]
	fiadd dword ptr [rsp + 8* 2]
	fisub dword ptr [rsp + 8* 0]

	; ��������� �������� � ������������� +-2
	fldz ; ������������� ����� ����
	fiadd dword ptr [rsp + 8* 4]
	fisub dword ptr [rsp + 8* 3]
	fimul MultiplierTwo 
	faddp

	; �������� Gx � ��������
	fmul st(0),st(0)
	

	; ��������� Gy

	; ��������� �������� � ������������� +-1
	fldz ; ������������� ����� ����
	fiadd dword ptr [rsp + 8* 7]
	fiadd dword ptr [rsp + 8* 5]
	fisub dword ptr [rsp + 8* 2]
	fisub dword ptr [rsp + 8* 0]

	; ��������� �������� � ������������� +-2
	fldz
	fiadd dword ptr [rsp + 8* 6]
	fisub dword ptr [rsp + 8* 1]
	fimul MultiplierTwo ; �������� �� 2
	faddp ; ��������� �������� � ������������� 2 � ����� ��������� ���������

	; �������� Gy � ��������
	fmul st(0),st(0)

	; Gx^2 + Gy^2
	faddp

	; sqrt(Gx^2 + Gy^2)
	fsqrt

	; ���������� ����������� �������� � �������
	sub rsp, 8				; ���������� ������� �����, ����� ��������� ��� ����� ��������
	fistp qword ptr [rsp]	; ������ ������� ����� FPU �� ������� �����
	pop rax					; ��������� ��������� ��������� � ������� ������ ����������
	mov byte ptr [rcx], al	; ���������� ���������

	; ������� ����
	mov rsp, r9

	; ������� �� �������
	ret
Kernel ENDP
END
