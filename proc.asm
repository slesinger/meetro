//---------------------------------------
init:     // Setup background and border colours:
          lda #$00
          sta $d020
          sta $d021

          // Blank screen to border colour:
        //   lda #$00
        //   sta $d011

          // Call loader installation routine:
          jsr install

          // Initialise the soundtrack:
          lda #$00
          jsr $1000

          // Configure IRQ interrupts:
          sei
          lda #$36 // switch off the BASIC ROM
          sta $01
          lda #<irq
          sta $0314
          lda #>irq
          sta $0315
          lda #$00
          sta $d012
          lda #$01
          sta $d019
          lda #$81
          sta $d01a
          lda #$7b
          sta $dc0d
          lda #$00
          sta $dc0e
          cli

          rts
//---------------------------------------
irq:      inc $d020 // play the soundtrack and at the same
          jsr $1003 // time visualize how much raster time
          dec $d020 // is consumed by a player routine

          inc $d019
          jmp $ea7e
//---------------------------------------
koala:    // Copy screen and colours data into $4400 and $d800:
          ldx #$00
          lda $7f40,x
          sta $4400,x
          lda $8040,x
          sta $4500,x
          lda $8140,x
          sta $4600,x
          lda $8240,x
          sta $4700,x
          lda $8328,x
          sta $d800,x
          lda $8428,x
          sta $d900,x
          lda $8528,x
          sta $da00,x
          lda $8628,x
          sta $db00,x
          inx
          bne *-49

          // Display bitmap at $6000, where it has been previously decrunched:
        //   lda $dd00
        //   and #$fc
        //   ora #$02
        //   sta $dd00
          lda #$18
          sta $d016
          lda #$18
          sta $d018
          lda #$3b
          sta $d011

          rts
//---------------------------------------
hires:    // Copy screen data into $0c00:
          ldx #$00
          lda $3f40,x
          sta $0c00,x
          lda $4040,x
          sta $0d00,x
          lda $4140,x
          sta $0e00,x
          lda $4240,x
          sta $0f00,x
          inx
          bne *-25

          // Display bitmap at $2000, where it has been previously decrunched:
        //   lda $dd00
        //   and #$fc
        //   ora #$03
        //   sta $dd00
          lda #$08
          sta $d016
          lda #$38
          sta $d018
          lda #$3b
          sta $d011

          rts
//---------------------------------------