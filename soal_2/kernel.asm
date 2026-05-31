; Menegaskan bahwa ini adalah kode real mode 16-bit
bits 16

; Deklarasi fungsi agar bisa dilihat oleh compiler C (bcc)
global _start
global _putInMemory
global _getChar
extern _main

_start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFF0    ; Atur stack pointer kernel di posisi aman
    sti
    
    call _main

.hang:
    jmp .hang

_putInMemory:
    push bp
    mov bp, sp
    push ds
    
    mov ax, [bp+4]    ; Mengambil parameter ke-1: segment (0xB800)
    mov bx, [bp+6]    ; Mengambil parameter ke-2: address (cursor)
    mov cl, [bp+8]    ; Mengambil parameter ke-3: character (ASCII)
    
    mov ds, ax
    mov [bx], cl      ; Tulis karakter langsung ke memori video
    
    pop ds
    pop bp
    ret

_getChar:
    mov ah, 00h
    int 16h           ; Interupsi BIOS: Baca keyboard (ASCII masuk ke AL)
    
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 07h
    int 10h           ; Interupsi BIOS: Tampilkan karakter ke layar (Echo)
    
    ret