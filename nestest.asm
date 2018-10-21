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

 .org $8000 ; goes in 8k.

Start:  lda #%00000000  ; NMI off, PPU master, sprite 8x8, bg $0000, sprite $0000, ppu inc 0, nametable $2000
        sta $2000
        lda #%00011110
        sta $2001

        lda #$3f
        sta $2006       ; 2006 is TARGET BASE vram addr via storing to 2007
        lda #0
        sta $2006       ; set to palette addr of 3f00

loadpal:
        lda #$0f        ;Universal background color
        sta $2007       ;3f00
        lda #$02        ;bg palette 0: 3f01-03
        sta $2007       ;01
        lda #$03
        sta $2007       ;02
        lda #$04
        sta $2007       ;03
        lda #$01        
        sta $2007       ;04 - skip
        lda #$06        ; BG Palette 1: 3f05-07
        sta $2007       ;05
        lda #$07
        sta $2007       ;06
        lda #$08
        sta $2007       ;07
        lda #$01     
        sta $2007       ;3f08 - skip
        lda #$08        ; BG Palette 2 - 3f09-3f0b
        sta $2007       ;09
        lda #$09
        sta $2007       ;0a
        lda #$0A
        sta $2007       ;0b
        lda #$01
        sta $2007       ;0c - skip
        lda #$0B        ; BG Palette 3 - 3f0d-3f0f
        sta $2007       ;0d
        lda #$0C
        sta $2007       ;0e
        lda #$0D        
        sta $2007       ;0f
        lda #$01    
        sta $2007       ;3f10 - mirror of 3f00
        lda #$0D        ; Sprite Palette 0 - 3f11-13
        sta $2007       ;11
        lda #$08
        sta $2007       ;12
        lda #$2B
        sta $2007       ;13
        lda #$01
        sta $2007       ;14-skip
        lda #$05        ; Sprite Palette 1 - 3f15-17
        sta $2007       ;15
        lda #$06
        sta $2007       ;16
        lda #$07
        sta $2007       ;17
        lda #$01
        sta $2007       ;18-skip
        lda #$08        ; Sprite Palette 2 - 3f19-1b
        sta $2007       ;19
        lda #$09
        sta $2007       ;1a
        lda #$0A
        sta $2007       ;1b
        lda #$01
        sta $2007       ;1c - skip
        lda #$0B        ; Sprite Palette 3 - 3f1d-1f
        sta $2007       ;1d
        lda #$0C
        sta $2007       ;1e
        lda #$0D
        sta $2007       ;1f

waitblank:
        lda $2002
        bpl waitblank   ; waits until v is blanked before gfx code

        lda #$20
        sta $2006
        lda #$a0        ; skip 64 lines - 2 row.
        sta $2006
        ldx #0
        ldy #20
FillLoop:
        sty $2007
        inx
        cpx #100
        bcc FillLoop    ; fills screen with tile #20

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
 
        lda #$30
        sta $2004       ; y-addr
        lda #0
        sta $2004       ; tile no
        lda #%00000001
        sta $2004       ; color bit 
        inc player_x
        lda player_x
        sta $2004       ; x-pos
        
        rts 

 .bank 1 
 .org $fffa ; location of interrupt
 .dw 0       ; nmi int loc ? 
 .dw Start   ; go to reset 
 .dw 0       ; vblank interrupt (?)

 .bank 2 
 .org $0000 ; gfx data at 0
 .incbin "test.chr"
