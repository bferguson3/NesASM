 .inesprg 1 ; 1 bank of 16kb data
 .ineschr 1 ; 1 bank of 8kb chr data 
 .inesmap 1 ; MMC1, 8kb vram + 2x16kb rom
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
; $6000-$7fff   8 kb        battery backup or wram
; $8000-$fff9   ~32 kb      normal ROM 
; $fffa-$ffff   6 bytes     irq vectors 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; .nes header info (16 bytes):
;0-3      String "NES^Z" used to recognize .NES files.
;4        Number of 16kB ROM banks.
;5        Number of 8kB VROM banks.
;6        bit 0     1 for vertical mirroring, 0 for horizontal mirroring.
;         bit 1     1 for battery-backed RAM at $6000-$7FFF.
;         bit 2     1 for a 512-byte trainer at $7000-$71FF.
;         bit 3     1 for a four-screen VRAM layout. 
;         bit 4-7   Four lower bits of ROM Mapper Type.
;7        bit 0     1 for VS-System cartridges.
;         bit 1-3   Reserved, must be zeroes!
;         bit 4-7   Four higher bits of ROM Mapper Type.
;8        Number of 8kB RAM banks. For compatibility with the previous
;         versions of the .NES format, assume 1x8kB RAM page when this
;         byte is zero.
;9        bit 0     1 for PAL cartridges, otherwise assume NTSC.
;         bit 1-7   Reserved, must be zeroes!
;10-15    Reserved, must be zeroes!

PPUCTRL EQU $2000
PPUMASK EQU $2001
PPUSTATUS EQU $2002

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
    
    cli             ; IRQs on

init:
    lda #%10001000
    ; NMI ON | PPU MASTER | SPRITE 8x8 | BG@$0000 | Sprites@$1000 | VRAM add 1 | Nametable@$2000
    sta PPUCTRL
    lda #%00011110
    ; RGB no emphasis | Show Spr | Show BG | Left sprite column on | Left bg column on | Greyscale off
    sta PPUMASK
    ; remember first read from $2007 is invalid!
    ; if getting graphical glitches, code is too long from vbl. reset $2006 to $0000 by sta #0 twice

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