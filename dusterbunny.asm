 .inesprg 2 ; 2 bank of 16kb data (banks 0-3)
 .ineschr 2 ; 2 bank of 8kb chr data (bank 4-5)
 .inesmap 1 ; MMC1
 .inesmir 0 ; 0=up and down, 1=left/right


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
; $0800-$1fff   (mirror)
; $2000-$2007   8 bytes     NES PPU registers
; $2008-$3fff   (mirror)
; $4000-$4017   18 bytes    APU / IO registers 
; $4018-$401f   (test mode) 
; $4020-$5fff               expansion ROM

; MMC1 bank map:
; $6000-$7fff   8 kb        WRAM
; $8000-$bfff   16 kb       PRG-ROM bank
; $c000-$fff9   16 kb       PRG-ROM bank 
; $fffa-$ffff   6 by        IRQ vectors 

; PPU Map: 
; (PPU) $0000-$0fff 4kb     CHR-ROM bank (pattern table 0)
; (PPU) $1000-$1fff 4kb     CHR-ROM bank (pattern table 1)
; (PPU) $2000-$23ff 1kb     Nametable 0 (23c0 is colortable)
; ..2
; ..3
; ..4
; (PPU) $3000-$3eff (mirror)
; (PPU) $3f00-$3f1f 32b     Palette indexes 
; (PPU) $3f20-$3fff (mirrors)

PPUCTRL   EQU $2000
PPUMASK   EQU $2001
PPUSTATUS EQU $2002
OAMADDR   EQU $2003           ; avoid using this and use OAMDMA instead 
OAMDATA   EQU $2004
PPUSCROLL EQU $2005
PPUADDR   EQU $2006
PPUDATA   EQU $2007

 .bank 0

 .org $0000
    ; zp vars/clobbers 
 .org $0010
    ; globals 

 .org $8000 ; code bank start
boot_wait:
    sei             ; ignore IRQs 
    cld             ; no decimal
    ldx #$ff
    txs             ; $ff to stack
    inx 
    stx PPUCTRL     ; clear PPUCTRL
    stx PPUMASK     ; clear PPUMASK

    ; idle 2 frames before PPU code
    lda #0
    bit PPUSTATUS
.vwait1:
    bit PPUSTATUS 
    bpl .vwait1 
    ; clear memory in between first and second frame 
    txa 
.clrmem:
    sta $000,x 
    sta $100,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx 
    bne .clrmem
.vwait2:
    bit PPUSTATUS
    bpl .vwait2
    ; 50k cycles done, proceed to init

configure_MMC1:
    lda #%00011010
    ; xxx | CHR ROM 8kb (1) | PRG fixed @$8000, switch bank @$c000 (10) | vert mirror (10) 
    sta $8000
    lsr A
    sta $8000 
    lsr A
    sta $8000 
    lsr A
    sta $8000 
    lsr A
    sta $8000       ; $8000 is 'mmc1 control'
    lda #0          ; chr bank 0 (.bank 4) for PPU $0000
    sta $a000
    sta $a000
    sta $a000 
    sta $a000 
    sta $a000       ; a000 is 'chr bank 0 control'
    ; c000 is bank @ $1000 but is ignored in 8kb mode. 
    lda #%00000001
    ; xxx | 0 = enable wram | 0001 for prg bank 1 @ c000 
    sta $e000
    lsr A
    sta $e000 
    lsr A
    sta $e000 
    lsr A
    sta $e000 
    lsr A
    sta $e000       ; e000 = swappable prg bank # 

init:
    ; before you turn the screen back on, copy in pal/nam/atr data 
    ; copy in palette data  
    lda #$3f 
    sta PPUADDR 
    lda #$00 
    sta PPUADDR 
    ldx #0
.pal_loop:
    lda PalData,x 
    sta PPUDATA 
    inx 
    cpx #32
    bcc .pal_loop

    ; copy in nam data 
    lda #$20
    sta PPUADDR 
    lda #$00
    sta PPUADDR     ; $2000 = namtable 1 
    ldx #0
.namloop:
    lda NamData,x 
    sta PPUDATA
    inx 
    bne .namloop
.namloop2:
    lda NamData+256,x
    sta PPUDATA
    inx 
    bne .namloop2
.namloop3:
    lda NamData+512,x
    sta PPUDATA 
    inx 
    bne .namloop3
.namloop4:
    lda NamData+768,x
    sta PPUDATA 
    inx 
    bne .namloop4       ; flood all 1kb into ppu 

    ; copy in atr data 
    lda #$23            ; $23c0 = atr for nam1 
    sta PPUADDR 
    lda #$c0 
    sta PPUADDR 
    ldx #0
.atr_loop:
    lda AtrData,x 
    sta PPUDATA 
    inx 
    cpx #64
    bcc .atr_loop

    lda #%10001000
    ; NMI ON | PPU MASTER | SPRITE 8x8 | BG@$0000 | Sprites@$1000 | VRAM add 1 | Nametable@$2000
    sta PPUCTRL
    lda #%00011110
    ; RGB no emphasis | Show Spr | Show BG | Left sprite column on | Left bg column on | Greyscale off
    sta PPUMASK
    ; remember first read from $2007 is invalid!
    ; if getting graphical glitches, code is too long from vbl. reset $2006 to $0000 by sta #0 twice

    cli             ; IRQs on

loop:
    jmp loop

vblank:
    rti 

brk_vec:
    rti 

PalData:
    .incbin "duster-b.pal"
NamData:
    .incbin "db1.nam"
AtrData:
    .incbin "db1.atr"

 .bank 3        ; prg bank 2, section b
                ; this is seperated out for ease of .organizing the irq vectors.
 .org $fffa     ; location of interrupt
 .dw vblank     ; nmi vec  
 .dw boot_wait  ; reset vec
 .dw brk_vec    ; irq/brk vec

 .bank 4        ; chr bank 1 of 2
 .org $0000
 .incbin "db_charset_a.bin"