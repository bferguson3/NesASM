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
        lda #%00011110
        sta $2001

waitblank:
        lda $2002
        bpl waitblank   ; waits until v is blanked before gfx code

        lda $2002       ; ?
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


; Fill In Background
        lda #$20
        sta $2006
        lda #$a0        ; skip 64 lines - 2 row.
        sta $2006
        ldx #0
        ldy #1
FillLoop:
        sty $2007
        inx
        cpx #200
        bne FillLoop    ; fills screen with tile #20

        lda #$23
        sta $2006
        lda #$c0
        sta $2006
        ldx #0
        lda #%00011011
.color_bg_loop:
        sta $2007
        inx 
        cpx #200
        bcc .color_bg_loop

loop:
        jsr DrawLoop
        jmp loop

DrawLoop:
        lda $2002
        bpl DrawLoop
        ; wait for vblank
        ; draw all sprites:
        ldx #0
        stx $2003
        stx $2003       ; set 2004 target to spr-ram 0000 (set by ppu flag to either 0000 or 1000)

        inc player_y
        lda player_y
        sta $2004       ; y-addr
        lda #0
        sta $2004       ; tile no
        lda #%00000000
        sta $2004       ; color bit 
        inc player_x
        lda player_x
        sta $2004       ; x-pos
        
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
