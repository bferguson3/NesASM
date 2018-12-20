 .inesprg 1 ; 1 bank of 16kb data
 .ineschr 1 ; 1 bank of 8kb chr data 
 .inesmap 1 ; MMC1, 8kb vram + 2x16kb rom
 .inesmir 0 ; 0=up and down, 1=left/right

  .bank 0 ; PRG bank 0
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

 .org $0000
; zp vars/clobbers 
 .org $0010
; globals 

 .org $8000 ; code bank start
boot_wait:
    ; idle 2 frames before PPU code
    lda #0
    bit PPUSTATUS
.vwait1:
    bit PPUSTATUS 
    bpl .vwait1 
.vwait2:
    bit PPUSTATUS
    bpl .vwait2
    ; 50k cycles done, proceed to init

init:

loop:
    jmp loop

vblank:
    rti 

 .bank 1 

 .org $fffa ; location of interrupt
 .dw vblank      ; nmi vec  
 .dw boot_wait   ; reset vec
 .dw 0           ; irq/brk vec

 .bank 2 ; chr bank