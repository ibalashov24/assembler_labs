; -------------------------------------------------------------------------------------	;
;	������������ ������ �n �� ����� ���������������� �� ����� ����������				;
;	������� �vv.																		;
;	�������� ������� Name.																;
;																						;
;	�������� ������ LabAssignment.asm													;
;	�������� ������� �� ����� ����������, ������������� � ������������ � ��������		;
; -------------------------------------------------------------------------------------	;
;	�������: 
;		����������� ������ ��������� �����������
ROUND_MASK	EQU 0F3FFh	; ����� ������� ����� ���������� RCB (bit 11,10) = 00
ROUND_DOWN	EQU 0400h	; ����� ��������� ����� ���������� ���� (bit 11,10)  = 01
.DATA
	MultiplierTwo	qword	2	; ��������� "2" ��� ������� ������
.CODE
; -------------------------------------------------------------------------------------	;
; ������������ ���������� ����� �������� ������������ �����������						;
; void Kernel( PBYTE pDst, PBYTE pSrc, int Width )										;
; ���������:																			;
;	pDst   - ����� ������� - ���������� ���������										;
;   pSrc   - ����� ������� ��������� �����������											;
;	Width  - ������ ����������� � �������� (���������� ��������)							;
; ��������!!! ��� ���������� ������ ���������� ���������� ���������� ��������� � �����	;
;	Tuning.h � ������������ � ��������													;
; -------------------------------------------------------------------------------------	;
Kernel PROC	; [RCX] - pDst
			; [RDX] - pSrc
			; R8    - Width
	; ����� �������������� ����������� ����� �������� ������������ ������ �������
	;  �� ��������� �����������. ���������� �������� ���� ��� � ������������ � ��������
	; mov		al, byte ptr [rdx] ; �����������
	; mov		byte ptr [rcx], al ;   ������ �������



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
