// Run this part from command line:
// x64sc -8 video.d64 video.prg
// then start $1c00

.segment VIDEO []
#import "loadersymbols-c64.inc"

.namespace PART4_ns {

.const FRAME_DELAY = 16  // how many raster screen frames to display one frame of video, this has to be multiple of 8 because of breaking news scroller
.const FRAME_DELAY_FOR_FRYBA = 8
.const BORDER_COLOR = $0f
.const BACKGROUND_COLOR = $0b

#if RUNNING_ALL
    // Started as whole compilation of parts
#else
    // This has to happen only when starting separately
    .var music = LoadSid("data/Ucieczka_z_Tropiku.sid")
    *=music.location "Part2_music"  // $1000
    .fill music.size, music.getData(i)

    .var font = LoadBinary("data/video_font.bin")
    *=$2000 "Part4_font1"
    .fill font.getSize(), font.get(i)

    // Include Fryba
    // .var fryba1 = LoadBinary("data/F1.bin", BF_C64FILE)
    // *=$0400 "Part4_Fryba1.bin"
    // .fill fryba1.getSize(), fryba1.get(i)

    // .var fryba2 = LoadBinary("data/F2.bin", BF_C64FILE)
    // *=$8800 "Part4_Fryba2.bin"
    // .fill fryba2.getSize(), fryba2.get(i)

    *= install "loader_install" // same as install jsr
    .var installer_c64 = LoadBinary("tools/krill194/loader/build/install-c64.prg", BF_C64FILE)
    installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

    *= loadraw "loader_resident" // same as loader code block address
    .var loader_c64 = LoadBinary("tools/krill194/loader/build/loader-c64.prg", BF_C64FILE)
    loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

#endif

*= $1c00 "Part4_code"
start:
// THIS HAPPENS ONLY WHEN STARTING SEPARATELY
    // turn off basic
    lda $01
    and #$fe
    sta $01
    // set gfx colors
    lda #BORDER_COLOR
    sta $d020
    // fill $d800 with foreground color
    ldx #$00
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    dex
    bne !-
    lda #BACKGROUND_COLOR
    sta $d021

    // set bank $4000
    lda $dd00
    and #$fc
    ora #$02
    sta $dd00

    // Call loader installation routine:
    jsr install

    // start music
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init



// THIS HAS TO HAPPEN EVERY TIME
    distribute_font()
    init_irq()

load_loop:
    // wait for signal to start loading
    lda loading_sempahore
    // inc $d020
    bne load_loop
    lda #$01
    sta loading_sempahore  // prevent loading without trigger from irq1
    // start loading
    // dec $d020
    clc
    ldx #<file_b  // Vector pointing to a string containing loaded file name
    ldy #>file_b
    jsr loadraw
    inc file_b + 1  // increment file name  B0 > B1

    // wait for ? blocks to complete display
    // inc $d020  // indicate that loading is finished

    // Check if filename is set to BN, it does not exist, that means end
    lda file_b + 1
    cmp #$4f  // B'N'+1
    bne load_loop


end_of_video:
    inc $d020
    jmp end_of_video

loading_sempahore:  // 0: load next part of video, non-zero: wait
    .byte 1  //initially wait because first part is pre-loaded

file_b:   .text "BA"  //filename on diskette
          .byte $00

current_frame_index:
    .byte 0
current_frame_countdown:
    .byte FRAME_DELAY

// $d018 (upper 4bits +$08 font location)
screen_locations_fryba:
    .byte   $18, $28, $38                                                                 // bank 1
    .byte        $20, $30                                                                 // bank 3
screen_locations_a1a2:
    .byte        $20, $30, $40, $50, $60, $70, $80  // bank 2
screen_locations_b:
    .byte        $90, $a0, $b0, $c0, $d0, $e0, $f0  // bank 2

// $dd00 AND x
screen_banks_fryba:
    .byte  3,3,3                             // bank 1  3x
    .byte      1,1                           // bank 3  3x
// screen_banks_a1a2:
//     .byte                      3,3, 3,3,3,3  // bank 1  6x
//     .byte                  1,1,1,1, 1,1,1,1  // bank 3  8x
// screen_banks_b:
//     .byte    2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2  // bank 2  14x

.macro init_irq() {
    sei
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    asl $d019
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #$81
    sta $d01a
    lda #$e0  // where raster interrupt will be triggered
    sta $d012
    lda #$1b
    sta $d011
    cli
}

irq1:
    asl $d019  // ack irq
    wait(1)
    nop  // stabilize raster
    nop
    lda #$01   // render scroll line
    sta $d020
    sta $d021
    //increase fine scroll
    lda $d016
    and #%11110000
    sta $d016
    lda current_frame_countdown
    lsr  // because countdown if from 0-15 but we need cursor width 0-7
    and #%00000111
    ora $d016
    sta $d016

    // wait 8 line
    wait(93)
    nop
    lda $d016
    and #%11111000  // reset fine scroll
    ora #%00001000  // widen screen
    sta $d016

    lda #BORDER_COLOR
    sta $d020
    lda #BACKGROUND_COLOR
    sta $d021

    // inc $d020
    jsr music.play 
    // dec $d020

    // Count down to next frame
      // decrease current_frame_countdown by 1, check if it is zero. 
      // If zero continue to frame update, else skip frame update
    dec current_frame_countdown
    beq !+
    jmp skip_frame_update
!:
    // Frame_update
    lda #FRAME_DELAY
    sta current_frame_countdown  // reset delay counter

    // Route between Fryba and video
    clc  // clear carry (CLC $18) flag means route to Fryba, set carry (SEC $38)flag means route to video
sec // skip Fryba temporarily
    bcs route_blocks

    // Fryba
    lda #FRAME_DELAY_FOR_FRYBA
    sta current_frame_countdown  // overwrite delay because Fryba is faster
    inc current_frame_index
    lda current_frame_index
    cmp #5  // Fryba has fixed 5 frames
    bne display_fryba_frame
    lda #$00  // repeat Fryba until video is loaded
    sta current_frame_index
display_fryba_frame:
    ldx current_frame_index
    lda screen_locations_fryba,x
    sta $d018
    // switch bank // https://csdb.dk/forums/?roomid=11&topicid=112031&firstpost=2

    lda screen_banks_fryba,x
    cmp current_bank
    beq !+  // do not switch bank because it is the same
    sta current_bank
    lda $dd02
    tay
    ora 3
    sta $dd02
        // pokud je tento blok zapnut, tak se nahravani podela
        lda $dd00
        and #$fc
        ora screen_banks_fryba,x
        sta $dd00
    tya
    sta $dd02  //restore
!:
    jmp skip_frame_update
current_bank:
    .byte 3

    // Route between a1a2 and b
route_blocks:
    clc  // clear carry (CLC $18) flag means route to a1a2, set carry (SEC $38)flag means route to b
    bcs b

a1a2:  // represents block B 0-6
    inc current_frame_index
    lda current_frame_index
    cmp #7  // max frames in video block a1+a2
    bne display_a1a2_frame
    lda #$38
    sta route_blocks
    lda #$00  // end of block, switch to block b
    sta current_frame_index
    sta loading_sempahore
    jmp display_b_frame
display_a1a2_frame:
    ldx current_frame_index
    lda screen_locations_a1a2,x
    sta $d018
    jmp skip_frame_update

b:  // represents block B 7-13
    inc current_frame_index
    lda current_frame_index
    cmp #7  // max frames in video block a1+a2
    bne display_b_frame
    lda #$18
    sta route_blocks
    lda #$00  // end of block, switch to block b
    sta current_frame_index
    sta loading_sempahore
    jmp display_a1a2_frame
display_b_frame:
    ldx current_frame_index
    lda screen_locations_b,x
    sta $d018
    jmp skip_frame_update

skip_frame_update:
    pla
    tay
    pla
    tax
    pla
    rti

.macro distribute_font() {
    ldx #0
!:
    lda $2000,x
    sta $4000,x
    lda $2100,x
    sta $4100,x
    lda $2200,x
    sta $4200,x
    lda $2300,x
    sta $4300,x
    lda $2400,x
    sta $4400,x
    lda $2500,x
    sta $4500,x
    lda $2600,x
    sta $4600,x
    lda $2700,x
    sta $4700,x
    inx
    bne !-
}

.macro wait(count) {
    ldx #count
!:
    dex
    bne !-
}

.file [name="video.prg", segments="VIDEO"]

.disk [filename="video.d64", name="HONDANI", id="2025!"]
{
    [name="START", type="prg", segments="VIDEO" ],
    // [name="START", type="prg", prgFiles="krillsteststart.prg" ],
    [name="F5", type="prg", prgFiles="data/F5.bin" ],
    [name="BA", type="prg", prgFiles="data/BA.bin" ],
    [name="BB", type="prg", prgFiles="data/BB.bin" ],
    [name="BC", type="prg", prgFiles="data/BC.bin" ],
    [name="BD", type="prg", prgFiles="data/BD.bin" ],
    [name="BE", type="prg", prgFiles="data/BE.bin" ],
    [name="BF", type="prg", prgFiles="data/BF.bin" ],
    [name="BG", type="prg", prgFiles="data/BG.bin" ],
    [name="BH", type="prg", prgFiles="data/BH.bin" ],
    [name="BI", type="prg", prgFiles="data/BI.bin" ],
    [name="BJ", type="prg", prgFiles="data/BJ.bin" ],
    [name="BK", type="prg", prgFiles="data/BK.bin" ],
    [name="BL", type="prg", prgFiles="data/BL.bin" ],
    [name="BM", type="prg", prgFiles="data/BM.bin" ],
    [name="BN", type="prg", prgFiles="data/BN.bin" ],
}

}  // end namespace PART4_ns