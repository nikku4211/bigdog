.include "nes.inc"
.include "global.inc"

.segment "CODE"
.proc reset_handler
  ; The very first thing to do when powering on is to put all sources
  ; of interrupts into a known state.
  sei             ; Disable interrupts
  ldx #$00
  stx PPUCTRL     ; Disable NMI and set VRAM increment to 32
  stx PPUMASK     ; Disable rendering
  stx $4010       ; Disable DMC IRQ
  dex             ; Subtracting 1 from $00 gives $FF, which is a
  txs             ; quick way to set the stack pointer to $01FF
  bit PPUSTATUS   ; Acknowledge stray vblank NMI across reset
  bit SNDCHN      ; Acknowledge DMC IRQ
  lda #$40
  sta P2          ; Disable APU Frame IRQ
  lda #$0F
  sta SNDCHN      ; Disable DMC playback, initialize other channels

vwait1:
  bit PPUSTATUS   ; It takes one full frame for the PPU to become
  bpl vwait1      ; stable.  Wait for the first frame's vblank.

  ; We have about 29700 cycles to burn until the second frame's
  ; vblank.  Use this time to get most of the rest of the chipset
  ; into a known state.

  ; Most versions of the 6502 support a mode where ADC and SBC work
  ; with binary-coded decimal.  Some 6502-based platforms, such as
  ; Atari 2600, use this for scorekeeping.  The second-source 6502 in
  ; the NES ignores the mode setting because its decimal circuit is
  ; dummied out to save on patent royalties, and games either use
  ; software BCD routines or convert numbers to decimal every time
  ; they are displayed.  But some post-patent famiclones have a
  ; working decimal mode, so turn it off for best compatibility.
  cld

  ; Clear OAM and the zero page here.
  ldx #0
  jsr ppu_clear_oam  ; clear out OAM from X to end and set X to 0

  ; There are "holy wars" (perennial disagreements) on nesdev over
  ; whether it's appropriate to zero out RAM in the init code.  Some
  ; anti-zeroing people say it hides programming errors with reading
  ; uninitialized memory, and memory will need to be initialized
  ; again anyway at the start of each level.  Others in favor of
  ; clearing say that a lot more variables need set to 0 than to any
  ; other value, and a clear loop like this saves code size.  Still
  ; others point to the C language, whose specification requires that
  ; uninitialized variables be set to 0 before main() begins.
  txa
clear_zp:
  sta $00,x
  inx
  bne clear_zp
  
  ; Other things that can be done here (not shown):
  ; Set up PRG RAM
  ; Copy initial high scores, bankswitching trampolines, etc. to RAM
  ; Set up initial CHR banks
  ; Set up your sound engine

vwait2:
  bit PPUSTATUS  ; After the second vblank, we know the PPU has
  bpl vwait2     ; fully stabilized.
	
	cli
	
	lda #%00000110 ;prg bank 1 $8000
	sta $8000
	lda #$00
	sta $8001
	
	lda #%00000111 ;prg bank 2 $a000
	sta $8000
	lda #$01
	sta $8001
	
	lda #%00000000 ;chr bank 1 $8000
	sta $8000
	lda #$00
	sta $8001
	
	lda #%00000001 ;chr bank 2 $8000
	sta $8000
	lda #$02
	sta $8001
	
	lda #%00000010 ;chr bank 3 $8000
	sta $8000
	lda #$04
	sta $8001
	
	lda #%00000011 ;chr bank 4 $8000
	sta $8000
	lda #$05
	sta $8001
	
	lda #%00000100 ;chr bank 5 $8000
	sta $8000
	lda #$06
	sta $8001
	
	lda #%00000101 ;chr bank 6 $8000
	sta $8000
	lda #$07
	sta $8001
	
	lda #%00000001	;horizontal mirroring
	sta $A000
	lda #%00000000	;disable PRG RAM
	sta $A001
	
	sta $E000
  
  ; There are two ways to wait for vertical blanking: spinning on
  ; bit 7 of PPUSTATUS (as seen above) and waiting for the NMI
  ; handler to run.  Before the PPU has stabilized, you want to use
  ; the PPUSTATUS method because NMI might not be reliable.  But
  ; afterward, you want to use the NMI method because if you read
  ; PPUSTATUS at the exact moment that the bit turns on, it'll flip
  ; from off to on to off faster than the CPU can see.
  jmp main
.endproc
