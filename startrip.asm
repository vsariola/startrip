
org 100h

start:
    mov     al, 0x13
    int     0x10
    mov     dx, 0x3C8
    out     dx, al
    inc     dx
.paletteloop:
    out     dx, al
    out     dx, al
    out     dx, al
    inc     ax
    jnz     .paletteloop
    push    0xA000 - 10
    pop     es
    mov     dx, interrupt
    mov     ax, 0x251C
    int     0x21
    mov     dx, 0x331        ; MIDI Control Port
    mov     al, 0x3F
    out     dx, al
    dec     dx
    rep outsb
main:           ; raycaster heavily based on Hellmood's Essence 64b, https://www.pouet.net/prod.php?which=83204
    xor     bx, bx
    mov     cl, 64
.loop:
    add     bl, -1
    .mutant equ $-1
    mov     ax, 0xCCCD ; rrrola trick!
    mul     di
    mov     al, dh
    sbb     al, 100
    imul    bl
    xchg    ax, dx
    imul    bl
    mov     al, bl
    add     al, 208
    .time equ $-1
    add     ah, 8+16*7
    xor     al, ah
    sub     dh, 8+16*3
    xor     al, dh
    test    al, 256-16
    loopnz  .loop
    xchg    ax, bx
    stosb
    imul    di, 85
    jmp     main


interrupt:
    mov     dx, 0x330
    mov     si, song-1
    add     byte [si],17
    dec     byte [main.time+si-song+1]
    lodsb
    outsb
    mov     bx, si
    xlat
    dec     ax
    out     dx, al
    mov     [main.mutant], al
    outsb

data:
    db      0xCF   ; 0xCF is also iret
    db      100

    db      0xC0
    db      89

    db      0x90
    db      28
    db      119

song:
    db      0x9F
    db      53, 51, 55, 53, 56, 53, 41, 0, 48, 46, 51, 0, 53, 48, 41
