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
frame_counter: .db 0
animation_ticker: .db 0
animation_offset: .db 0
joy_byte: .db 0
p1_anm_dir_offset: .db 0
player_moving: .db 0 
        ; NES resolution is 256x240.

 .org $8000 ; goes in 8k.

Start:  lda $2002
        lda #%00001000  ; NMI off, PPU master, sprite 8x8, bg $0000, sprite $0000, ppu inc 0, nametable $2000
        sta $2000
        lda #0
        sta $2001       ; disable screen rendering
        
; Misc Setup Code 
        lda #4
        sta p1_anm_dir_offset
        lda #2
        sta animation_offset
        lda #124
        sta player_x 
        sta player_y 

; Fill In Background
; Not all emus fill tile with 0
        lda #$20
        sta $2006
        lda #$00        ; skip 64 lines - 2 row.
        sta $2006
        ldx #0
.FillLoop:
        lda MapData,x 
        sta $2007
        inx
        cpx #255
        bne .FillLoop    ; fills screen with tile #20
        
        ldx #0
.FillLoop2:
        lda MapData+256,x
        sta $2007 
        inx 
        cpx #255 
        bne .FillLoop2

        ldx #0
.FillLoop3:
        lda MapData+512,x
        sta $2007 
        inx 
        cpx #255 
        bne .FillLoop3

        ldx #0
.fillloop4:
        lda MapData+(256*3),x 
        sta $2007 
        inx 
        cpx #$c0
        bne .fillloop4

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
.color_bg_loop:
        lda MapAttr,x
        sta $2007
        inx 
        cpx #64
        bcc .color_bg_loop

; enable screen rendering
        lda #%00011110
        sta $2001



;;;;;;;;;;;;;;;;;;;;
;; GAME loop

loop:
           

        lda $2002
        bpl loop                ; wait for vblank

        inc frame_counter
        lda frame_counter
        cmp #60
        bcc .skip_f
        lda #0
        sta frame_counter       ; count which frame we're on
.skip_f: 
        inc animation_ticker
        lda player_moving
        cmp #1
        bcs .fast_walk
        lda animation_ticker 
        cmp #30 
        bcc .skip_a 
        lda #0 
        sta animation_ticker
        lda animation_offset 
        cmp #2 
        bcc .set_2
        lda #0 
        sta animation_offset
        jmp .skip_a
.fast_walk:
        lda animation_ticker
        cmp #15                 ; reset animation ticker every 15 frames
        bcc .skip_a 
        lda #0 
        sta animation_ticker
        lda animation_offset
        cmp #2
        bcc .set_2
        lda #0
        sta animation_offset
        jmp .skip_a
.set_2: lda #2
        sta animation_offset    ; toggle it between 2<>0
.skip_a:

        jsr CheckInput  
        jsr DrawLoop            ; vblank draw routines
        jsr CheckButtons

        jmp loop


;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input Code 

CheckButtons:
        lda #%00001000
        bit joy_byte
        bne .up_pressed
        lda #%00000100
        bit joy_byte
        bne .down_pressed
        lda #%00000010
        bit joy_byte
        bne .left_pressed 
        lda #%00000001
        bit joy_byte
        bne .right_pressed 
        lda #0
        sta player_moving
        rts 
.left_pressed:
        dec player_x
        lda #1 
        sta player_moving
        lda #8 
        sta p1_anm_dir_offset
        rts
.right_pressed: 
        inc player_x
        lda #1 
        sta player_moving
        lda #12
        sta p1_anm_dir_offset
        rts
.up_pressed:
        dec player_y
        lda #1
        sta player_moving
        lda #0
        sta p1_anm_dir_offset
        rts 
.down_pressed:
        lda #4 
        sta p1_anm_dir_offset
        lda #1
        sta player_moving
        inc player_y
        rts

CheckInput:
        ; strobe pad 1
        lda #$01
        sta $4016
        sta joy_byte
        lsr a 
        sta $4016
.checkinput_loop:
        lda $4016
        lsr a
        rol joy_byte
        bcc .checkinput_loop
        rts


;;;;;;;;;;;;;;;;;;;;;;;;;
;; VBlank Draws 
;; warning - only 6800 cycles until vset.

DrawLoop:
        ; draw all sprites:
        ldx #0
        stx $2003
        stx $2003       ; set 2004 target to spr-ram 0000 (set by ppu flag to either 0000 or 1000)
        
        ; HERO SPRITE (2x2)
        lda player_y
        sta $2004       ; y-addr
        lda #$0
        clc 
        adc animation_offset
        adc p1_anm_dir_offset
        sta $2004       ; tile no
        lda #%00000000
        sta $2004       ; color bit 
        lda player_x
        sta $2004       ; x-pos

        lda player_y 
        sta $2004
        lda #$1
        clc 
        adc animation_offset
        adc p1_anm_dir_offset
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
        lda #$10
        clc 
        adc animation_offset
        adc p1_anm_dir_offset
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
        clc 
        adc animation_offset
        adc p1_anm_dir_offset
        sta $2004
        lda #0
        sta $2004
        lda player_x
        clc
        adc #8
        sta $2004
        ; end hero sprite

        rts

PalData: 
 .incbin "output.pal"
MapData:
 .incbin "output.nam"
MapAttr:
 .incbin "output.atr"

 .bank 1 

 .org $fffa ; location of interrupt
 .dw 0       ; nmi int loc ? 
 .dw Start   ; go to reset 
 .dw 0       ; vblank interrupt (?)

 .bank 2 
 .org $0000 ; gfx data at 0
 .incbin "test.chr"
