 .inesprg 1 ; 16kBx[1] prg bank
 .ineschr 1 ; 8kBx[1] chr bank
 .inesmap 1 ; MMC1
 .inesmir 0 ; 0=horizonal (a over b)

 .bank 0    ; prg bank 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NES MEMORY MAP EXAMPLE 8 PAGE RAM:
;
; $0000-$000F	16 bytes	Local variables and function arguments
; $0010-$00FF	240 bytes	Global variables accessed most often, including certain pointer tables
; $0100-$019F	160 bytes	Data to be copied to nametable during next vertical blank (see The frame and NMIs)
; $01A0-$01FF	96 bytes	Stack
; $0200-$02FF	256 bytes	Data to be copied to OAM during next vertical blank
; $0300-$03FF	256 bytes	Variables used by sound player, and possibly other variables
; $0400-$07FF	1024 bytes	Arrays and less-often-accessed global variables

PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002

 .org $0010     ; vars go here

 .org $8000     ; default prg bank loc

ppu_startup: 
    ; first, wait 30k cycles 
    lda #0
    bit PPUSTATUS
.vwait1:
    bit PPUSTATUS 
    bpl .vwait1 
.vwait2:
    bit PPUSTATUS 
    bpl .vwait2 
    ; here, 50k cycles should have passed.

init:
    lda #%10001000
    ; Vblank NMI ON | PPU Master | Sprite 8x8 | BG $0000 | Sprite $1000 | VRAM+1 | Nametable $2000
    sta PPUCTRL
    lda #%00011110
    ; BGR no emphasis | show sprites | show bg | sprites left col on | bg left col on | greyscale off
    sta PPUMASK

loop:
    jmp loop

vblank:
    rti 

 .bank 1            ; final bank
 .org $fffa
 .dw vblank         ; NMI v
 .dw ppu_startup    ; reset 
 .dw 0              ; IRQ/BRK

 .bank 2            ; chr bank...?