 .inesprg 1 ; 1 bank of 16kb data
 .ineschr 1 ; 1 bank of 8kb chr data 
 .inesmap 0 ; SMB style cart, 8kb vram + 2x16kb rom
 .inesmir 1 ; 0=horiz, 1=vertic

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
player_x: .db 0 
player_y: .db 0

 .org $8000 ; goes in 8k.

Start:  lda #%00001000  ; NMI off, PPU master, sprite 8x8, bg $0000, sprite $0000, ppu inc 0, nametable $2000
        sta $2000
        lda #0
        sta $2001       ; disable screen rendering
        
; Fill In Background
; Not all emus fill tile with 0
        lda #$20
        sta $2006
        lda #$00        ; skip 64 lines - 2 row.
        sta $2006
        lda #0
        ldx #0
        ldy #0
.FillLoop:
        sta $2007
        inx
        cpx #255
        bne .FillLoop    ; fills screen with tile #20
        ldx #0
        iny
        cpy #3
        bne .FillLoop

        lda #$3f
        sta $2006       ; 2006 is TARGET BASE vram addr via storing to 2007
        lda #0
        sta $2006       ; set to palette addr of 3f00

        ldx #0
pal_loop:
        lda PalData,x
        sta $2007
        inx 
        cpx #32
        bne pal_loop


        lda #$23
        sta $2006
        lda #$c0
        sta $2006
        ldx #0
        lda #%00011011
.color_bg_loop:
        sta $2007
        inx 
        cpx #64
        bcc .color_bg_loop

; enable screen rendering
        lda #%00011110
        sta $2001

loop:
        lda $2002
        bpl loop
        jsr DrawLoop
        jmp loop

DrawLoop:
        ; draw all sprites:
        ldx #0
        stx $2003
        stx $2003       ; set 2004 target to spr-ram 0000 (set by ppu flag to either 0000 or 1000)

        inc player_y
        inc player_x
        
        lda player_y
        sta $2004       ; y-addr
        lda #0
        sta $2004       ; tile no
        lda #%00000000
        sta $2004       ; color bit 
        lda player_x
        sta $2004       ; x-pos

        lda player_y 
        sta $2004
        lda #1
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc 
        adc #8
        sta $2004

        lda player_y 
        sta $2004
        lda #2
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc 
        adc #16
        sta $2004

        lda player_y
        clc 
        adc #8 
        sta $2004
        lda #$10
        sta $2004
        lda #0
        sta $2004
        lda player_x
        sta $2004

        lda player_y
        clc 
        adc #8 
        sta $2004
        lda #$11
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc
        adc #8
        sta $2004

        lda player_y
        clc 
        adc #8 
        sta $2004
        lda #$12
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc
        adc #16
        sta $2004

        lda player_y
        clc 
        adc #16 
        sta $2004
        lda #$20
        sta $2004
        lda #0
        sta $2004
        lda player_x
        sta $2004

        lda player_y
        clc 
        adc #16 
        sta $2004
        lda #$21
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc 
        adc #8
        sta $2004

        lda player_y
        clc 
        adc #16 
        sta $2004
        lda #$22
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc 
        adc #16
        sta $2004
        
        rts 

PalData: 
 .incbin "output.pal"

 .bank 1 

 .org $fffa ; location of interrupt
 .dw 0       ; nmi int loc ? 
 .dw Start   ; go to reset 
 .dw 0       ; vblank interrupt (?)

 .bank 2 
 .org $0000 ; gfx data at 0
 .incbin "test.chr"
