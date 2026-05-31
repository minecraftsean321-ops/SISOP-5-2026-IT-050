bits 16
global _start

_start:
    ; 1. Inisialisasi Segmen Register
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 2. Load Kernel dari Floppy Disk ke RAM via BIOS Int 13h
    mov ah, 0x02        ; Fungsi BIOS: Read Sectors
    mov al, 15          ; KELOMPOK 15 SEKTOR (sesuai count=15 di Makefile)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; SEKTOR 2 (Sektor setelah bootloader, tempat kernel berada)
    mov dh, 0           ; Head 0
    mov dl, 0           ; Drive 0 (Floppy A)

    ; Alamat tujuan di RAM: kita taruh kernel di segmen 0x1000:0000
    mov bx, 0x1000
    mov es, bx
    mov bx, 0x0000      ; ES:BX = 0x1000:0000

    int 0x13            ; Jalankan interupsi BIOS
    jc _read_error      ; Jika carry flag aktif = error baca disk

    ; 3. Lompat langsung ke alamat awal Segmen Kernel!
    jmp 0x1000:0000

_read_error:
    ; Jika gagal membaca disk, cetak huruf 'E' di pojok kiri atas
    mov ax, 0xB800
    mov gs, ax
    mov byte [gs:0], 'E'
    mov byte [gs:1], 0x0C
    jmp $

times 510-($-$$) db 0
dw 0xAA55               ; Boot Signature wajib 512 byte