BITS 16

start:
    mov ax, 07C0h
    add ax, 288
    mov ss, ax
    mov sp, 4096

    mov ax, 07C0h
    mov ds, ax
   
    call print_ascii_table
        
    jmp $


print_ascii_table:
    mov cl, 0      ; ASCII character number
    mov ch, 0       ; Symbols in line

    mov ah, 0Eh
     
.repeat: 
    mov al, 20h     ; Printing service space
    int 10h
   
    cmp cl, 0
    je .nul 
    cmp cl, 7
    je .bell
    cmp cl, 8
    je .ht
    cmp cl, 10
    je .lf
    cmp cl, 13
    je .cr
    
    mov al, cl      ; Write current ASCII symbol
    int 10h         ; 'Write to TTY' interruption
 
    mov al, 20h     ; Printing service spacei;
    int 10h
    int 10h

.continue:    
    mov al, 20h     ; Printing service spacei;
    int 10h  
    mov al, 0B3h     ; Printing service vertical line
    int 10h

    cmp cl, 255
    je .done
    
    add cl, 1
    add ch, 1
   
    cmp ch, 13
    je .newline

    jmp .repeat

.newline:
    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h

    mov ch, 0

    jmp .repeat

.nul:
    mov al, 'N'
    int 10h
    mov al, 'U'
    int 10h
    mov al, 'L'
    int 10h
 
    jmp .continue
    
.bell:
    mov al, 'B'
    int 10h
    mov al, 'E'
    int 10h
    mov al, 'L'
    int 10h
 
    jmp .continue

 .ht:
    mov al, 'H'
    int 10h
    mov al, 'T'
    int 10h
    mov al, ' '
    int 10h
 
    jmp .continue

.lf:
    mov al, 'L'
    int 10h
    mov al, 'F'
    int 10h
    mov al, ' '
    int 10h
 
    jmp .continue
 
.cr:
    mov al, 'C'
    int 10h
    mov al, 'R'
    int 10h
    mov al, ' '
    int 10h
 
    jmp .continue
  
 

.done:
    ret

    times 510-($-$$) db 0
    dw 0xAA55

