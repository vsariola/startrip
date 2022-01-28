
org 100h

start:
    mov     al, 0x13
    int     0x10
    mov     dx, 0x3C8       ; set palette
    out     dx, al
    inc     dx
.paletteloop:
    out     dx, al          ; simple grayscale palette
    out     dx, al
    out     dx, al
    inc     ax
    jnz     .paletteloop
    push    0xA000 - 10     ; shift the segment by half a line to center X on screen
    pop     es
    mov     dx, interrupt   ; set interrupt handler
    mov     ax, 0x251C
    int     0x21
    mov     dx, 0x331       ; MIDI Control Port
    mov     al, 0x3F        ; enable MIDI
    out     dx, al
    dec     dx              ; shift dx to MIDI data port
    rep outsb               ; CX is still 0xFF so dumps the whole code to MIDI data port
main:                       ; raycaster heavily based on Hellmood's Essence 64b, https://www.pouet.net/prod.php?which=83204
    xor     bx, bx          ; bx is the distance along the ray
    mov     cl, 64          ; max number of steps
.loop:
    add     bl, -1          ; take step along the ray, note that this will be mutated when we hit a note
    .mutant equ $-1
    mov     ax, 0xCCCD      ; rrrola trick!
    mul     di
    mov     al, dh          ; al = y
    sbb     al, 100         ; shift y to center
    imul    bl              ; y*z
    xchg    ax, dx          ; dx is now y*z, al is now x
    imul    bl              ; x*z
    mov     al, bl          ; al = z
    add     al, 208         ; add time, will be mutated to make the camera move forward
    .time equ $-1           ; didn't use the bios timer, because it doesn't start always from the same value
    add     ah, 8+16*7      ; shift the camera in x
    xor     al, ah          ; (z+time)^(x*z+camx>>8)
    sub     dh, 8+16*3      ; shift the camera in y
    xor     al, dh          ; (z+time)^(x*z+camx>>8)^(y*z+camy>>8)
    test    al, 256-16      ; if any bit but 16 is zero, then loop (as long as cx >0), otherwise we hit a box
    loopnz  .loop
    xchg    ax, bx          ; use z as the color
    stosb                   ; put pixel on screen
    imul    di, 85          ; "random" dithering
    jmp     main

interrupt:
    mov     dx, 0x330       ; MIDI data port again, we almost could've done all midi init here, but
    mov     si, song-1      ; the low bass pad would retriggered every interrupt, so didn't.
    add     byte [si],17    ; 17*15 = 255 = -1, so in 15 interrupts the song goes one step backward
    dec     byte [main.time+si-song+1] ; mutate the camera z in the main loop
    lodsb                   ; load time
    outsb                   ; output 0x9F = Note on
    mov     bx, si          ; bx is now pointing to the song
    xlat                    ; Load note, 0 means no note
    dec     ax              ; note--, 0 => 255 = invalid note, so it will not play actually anything
    out     dx, al
    mov     [main.mutant], al ; Sync the raycaster step size to current note
    outsb                   ; The first note of the melody is also the note volume

data:
    db      0xCF    ; MIDI command: Set instrument on channel 0xF, 0xCF is also iret for the interrupt
    db      100     ; Instrument id 100, sounds cool, whatever it is
    db      0xC0    ; MIDI command: Set instrument on channel 0
    db      89      ; Instrument id 89, sounds cool, no idea what it is
    db      0x90    ; MIDI command: Note On, channel 0
    db      28      ; One octave down from the tonic of the melody (melody starts on note 40)
    db      119     ; Pretty loud, but not max vol, this is reused as the song time
                    ; and chosen to have the melody start at correct position
song:
    db      0x9F    ; MIDI command: Note On, channel 0xF
    db      53, 51, 55, 53, 56, 53, 41, 0, 48, 46, 51, 0, 53, 48, 41 ; Just some random notes I typed in
