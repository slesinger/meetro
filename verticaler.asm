
.namespace PART3_ns {

// #import "fm_lookups.asm"
// #import "fm_const.asm"

.var music = LoadSid("data/Ucieczka_z_Tropiku.sid")
*=music.location "Part2_music"
.fill music.size, music.getData(i)


#if RUNNING_ALL
    // Started as whole compilation of parts
#else
    // when compiled and started as a single part
    BasicUpstart2(PART3_ns.start)
#endif

#import "lib_fast_load.asm"  // at $9000

*= $2000 "Part2_code"
start:
    // start music
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init

    init_irq()

    fastloader_init()  // call this only once to upload code to the floppy
    fastloader_load($38, 2, 8)  // load from track 2, 8 sectors in total and store to memory $2800

    jmp *

.macro init_irq() {
    sei
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    asl $d019
    lda #$7b
    sta $dc0d
    lda #$81
    sta $d01a
    lda #$1b
    ora #$20  // bit 5 (hires)
    sta $d011
    lda #$0  // where raster interrupt will be triggered
    sta $d012
    cli
}

irq1:
    asl $d019
    inc $d020
    jsr music.play 
    dec $d020
    // dec $d020
    // jsr up_new_line
    // jsr up_copy_screen
!:
    // inc $d020
    pla
    tay
    pla
    tax
    pla
    rti


up_new_line:
up_new_line_src:
    lda #$28
!:  lda $a000,x
    sta $07c0,x
    dex
    bpl !-
    inc up_new_line_src + 2
    rts


up_copy_screen:
.for (var i=0;i<40*24;i++) {
    lda $0400+40 + i
    sta $0400 + i
}
    rts

}