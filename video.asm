


.namespace PART4_ns {


.var music = LoadSid("data/Ucieczka_z_Tropiku.sid")
*=music.location "Part2_music"
.fill music.size, music.getData(i)

.var font = LoadBinary("data/video_font.bin")
*=$2000 "Part4_font1"
.fill font.getSize(), font.get(i)
*=$4000 "Part4_font2"
.fill font.getSize(), font.get(i)
*=$8000 "Part4_font3"
.fill font.getSize(), font.get(i)
*=$c000 "Part4_font4"
.fill font.getSize(), font.get(i)

.var screens0 = LoadBinary("data/video_screens.bin_1_0400-0c00.bin")
*=$0400 "Part4_video_screens.bin_1_0400-0c00.bin"
.fill screens0.getSize(), screens0.get(i)
.var screens1 = LoadBinary("data/video_screens.bin_1_2800-3c00.bin")
*=$2800 "Part4_video_screens.bin_1_2800-3c00.bin"
.fill screens1.getSize(), screens1.get(i)
.var screens2 = LoadBinary("data/video_screens.bin_2_4800-7c00.bin")
*=$4800 "Part4_video_screens.bin_2_4800-7c00.bin"
.fill screens2.getSize(), screens2.get(i)
.var screens3 = LoadBinary("data/video_screens.bin_3_8800-8c00.bin")
*=$8800 "Part4_video_screens.bin_3_8800-8c00.bin"
.fill screens3.getSize(), screens3.get(i)
// .var screens4 = LoadBinary("data/video_screens.bin_3_a000-bc00.bin")
// *=$a000 "Part4_video_screens.bin_3_a000-bc00.bin"
// .fill screens4.getSize(), screens4.get(i)


#if RUNNING_ALL
    // Started as whole compilation of parts
#else
    // when compiled and started as a single part
    // BasicUpstart2(PART4_ns.start)
    // sys7168
#endif

*= $1c00 "Part4_code"
start:
    // turn off basic
    lda $01
    and #$fe
    sta $01
    // start music
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init

    init_irq()
!:
    jmp !-

current_frame_index:
    .byte 0

screen_locations:  // $d018 (upper 4bits +$08 font location)
    .byte   $18, $28, $38,                                 $a8, $b8,  $c8, $d8, $e8, $f8  // bank 1
    .byte        $20, $30,  $40, $50, $60, $70,  $80, $90, $a0, $b0,  $c0, $d0, $e0, $f0  // bank 2
    .byte        $20, $30,                       $80, $90, $a0, $b0,  $c0, $d0, $e0, $f0  // bank 3

screen_banks:  // $dd00 AND x
    .byte  3,3,3,              3,3, 3,3,3,3  // bank 1  9x
    .byte    2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2  // bank 2  14x
    .byte    1,1,          1,1,1,1, 1,1,1,1  // bank 3  10x
    .byte    0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0  // bank 4

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
    // lda #$1b
    // ora #$20  // bit 5 (hires)
    // sta $d011
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
    // inc $d020

    jsr $ff9f  // scan keyboard
    jsr $ffe4  // clear keyboard buffer
    cmp #$20   // spacebar check
    bne !++
    // switch screen location
    inc current_frame_index
    lda current_frame_index
    cmp #26 //#33  // max frames in video
    bne !+
    lda #$00
    sta current_frame_index
!:
    ldx current_frame_index
    lda screen_locations,x
    sta $d018

    // switch bank
    lda $dd02
    ora 3
    sta $dd02
    lda $dd00
    and #$fc
    ora screen_banks,x
    sta $dd00

!:

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
    rts

}