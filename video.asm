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
.const fryba_scroll_pointer_zp = $02  // and $fc

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
    .var fryba5 = LoadBinary("data/F5.bin", BF_C64FILE)
    *=$6400 "Part4_Fryba5.bin"
    .fill fryba5.getSize(), fryba5.get(i)

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
    // fill $d800 line 22 with breaking news color
    lda #$00
    ldx #$27
!:
    sta $db6f,x
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
    // set zero page indirect pointer to fryba_scroll_text
    lda #<fryba_scroll_text+50
    sta fryba_scroll_pointer_zp
    lda #>fryba_scroll_text
    sta fryba_scroll_pointer_zp + 1
    // setup irq
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
screen_locations_a:
    .byte        $20, $30, $40, $50, $60, $70, $80  // bank 2
screen_locations_b:
    .byte        $90, $a0, $b0, $c0, $d0, $e0, $f0  // bank 2
scroll_locations_a:
    .byte        $4b, $4f, $53, $57, $5b, $5f, $63  // bank 2 4800, 4c00, 5000, 5400, 5800, 5c00, 6000
scroll_locations_b:
    .byte        $67, $6b, $6f, $73, $77, $7b, $7f  // bank 2 6400, 6800, 6c00, 7000, 7400, 7800, 7c00


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
    nop
    nop
    lda #$01   // render scroll line
    sta $d020
    sta $d021
    //increase fine scroll
    lda $d016
    and #%11110000
    // sta $d016
    ldx current_frame_countdown
    dex
    txa
    and #%00000111
    cmp #0
    bne !+
    inc $d020  // increase lo nybble
    inc fryba_scroll_pointer_zp  // increase lo nybble
    bne !+
    inc fryba_scroll_pointer_zp + 1  // increase hi nybble
!:  ora $d016
    // sta $d016

    // wait 8 line
    wait(107)
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
fryba_route:
    clc  // clear carry (CLC $18) flag means route to Fryba, set carry (SEC $38)flag means route to video
    bcc fryba_start
    jmp route_blocks
                // 5 cycles by 7 frames at 16 raster screen per picture = 35 frames
                // 1 hard scroll position per picture
    // Fryba
fryba_start:
    lda #FRAME_DELAY_FOR_FRYBA
    sta current_frame_countdown  // overwrite delay because Fryba is faster
    inc current_frame_index
    lda current_frame_index
    cmp #5  // Fryba has fixed 5 frames
    bne display_fryba_frame
    dec fryba_full_cycles
    lda fryba_full_cycles
    beq stop_fryba
    lda #$00  // repeat Fryba until video is loaded
    sta current_frame_index
display_fryba_frame:
    ldx current_frame_index
    // pre-fill scroll text first
    lda scroll_locations_b,x
    sta tf + 2
    ldy #0
sf: lda (fryba_scroll_pointer_zp),y
    clc
    adc #228  // shift to the right font location
tf: sta $ff70,y
    iny
    cpy #40
    bne sf
    lda screen_locations_b,x
    sta $d018
    jmp skip_frame_update
stop_fryba:
    lda #$38
    sta fryba_route  // next time route to video instead of Fryba
    lda #$00  // end of block, switch to video
    sta current_frame_index
    lda sf + 1
    sta sf1 + 1
    jmp display_a1a2_frame

current_bank:
    .byte 3
fryba_full_cycles:
    .byte 10  // repeat 7 frames 10 times
fryba_scroll_text:
    .encoding "screencode_upper"
    .text "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    .text "BREAKING@NEWS[[[@@THE@SUN@SIGNED@OFF@@THIS@IS@THE@END@OF@THE@WORLD@AS@WE@KNOW@IT[@"
    .text "THE@SUN@HAS@ESCAPED@THE@SOLAR@SYSTEM[@CHAOS@UNFOLDS@AS@ENTIRE@ELECTRONICS@INFRASTRUCTURE@COLLAPSES[@ONLY@COMMODORE@MACHINES@REMAIN@FUNCTIONAL[@HUMANITY@SCRAMBLES@TO@ADAPT[@STAY@TUNED@FOR@DEVELOPMENTS[[[@END@OF@TRANSMISSION[@"

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
    // pre-fill scroll text first
    lda scroll_locations_a,x
    sta tf1 + 2
    ldy #0
sf1:lda (fryba_scroll_pointer_zp),y
    clc
    adc #228  // shift to the right font location
tf1:sta $ff70,y
    iny
    cpy #40
    bne sf1
    lda screen_locations_a,x
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
    // pre-fill scroll text first
    lda scroll_locations_b,x
    sta tf2 + 2
    ldy #0
sf2:lda (fryba_scroll_pointer_zp),y
    clc
    adc #228  // shift to the right font location
tf2:sta $ff70,y
    iny
    cpy #40
    bne sf2
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