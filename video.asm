// Run this part from command line:
// x64sc -8 video.d64 video.prg
// then start $1c00

.segment VIDEO []
#import "fm_const.asm"
#import "loadersymbols-c64.inc"

.namespace PART4_ns {

.const FRAME_DELAY = 16  // how many raster screen frames to display one frame of video, this has to be multiple of 8 because of breaking news scroller
.const FRAME_DELAY_FOR_FRYBA = 8
.const BORDER_COLOR = $0f
.const BACKGROUND_COLOR = $0b
.const fryba_scroll_pointer_zp = $02  // and $fc

#if RUNNING_COMPLETE
    // Started as whole compilation of parts
#else
    // This has to happen only when starting separately

    *= install "loader_install" // same as install jsr
    .var installer_c64 = LoadBinary("tools/krill194/loader/build/install-c64.prg", BF_C64FILE)
    installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

    *= loadraw "loader_resident" // same as loader code block address
    .var loader_c64 = LoadBinary("tools/krill194/loader/build/loader-c64.prg", BF_C64FILE)
    loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)
    
    BasicUpstart2(PART4_ns.start)
#endif


*= $9300 "Part4_code"
start:
    #if RUNNING_COMPLETE
    #else // runing separate
        jsr install
        bcs load_error
    #endif
    clc
    ldx #<file_font  // Vector pointing to a string containing loaded file name
    ldy #>file_font
    jsr loadraw
    bcs load_error
    #if RUNNING_COMPLETE
    #else // runing separate
        clc
        ldx #<file_f5  // Vector pointing to a string containing loaded file name
        ldy #>file_f5
        jsr loadraw
        bcs load_error
        clc
        ldx #<file_music  // Vector pointing to a string containing loaded file name
        ldy #>file_music
        jsr loadraw
        bcs load_error
    #endif
    jmp start2


file_music: .text "MUSIC"  //filename on diskette
          .byte $00
file_font:   .text "VFONT"  //filename on diskette
          .byte $00
file_f5:   .text "F5"  //filename on diskette
          .byte $00
load_error:
    sta $0400  // display error screen code
    lda #$04
    sta $d020
    sta $d021
    jmp *


start2:
    // turn off basic
    lda $01
    and #$fe
    sta $01
    // set gfx colors
    lda #BORDER_COLOR
    sta $d020
    jsr fill_color  // fill $d800 with foreground color
    // fill $d800 line 22 with breaking news color
    lda #$00
    ldx #$27
!:
    sta $db6f,x
    dex
    bne !-

    lda #BACKGROUND_COLOR
    sta $d021

    // set bank, do not use masking, only values can be $00, $01, $02 and $03
    lda #$02
    sta $dd00

    #if RUNNING_COMPLETE
    #else // runing separate
        // start music
        ldx #0
        ldy #0
        lda #0
        jsr $1000
    #endif 


// THIS HAS TO HAPPEN EVERY TIME
    // distribute_font()
    // set zero page indirect pointer to scroll_text
    lda #<scroll_text
    sta fryba_scroll_pointer_zp
    lda #>scroll_text
    sta fryba_scroll_pointer_zp + 1
    // setup irq
    init_irq()

load_loop:
    // wait for signal to start loading
    lda loading_sempahore
    bne load_loop
    lda #$01
    sta loading_sempahore  // prevent loading without trigger from irq1
    // start loading
    clc
    ldx #<file_b  // Vector pointing to a string containing loaded file name
    ldy #>file_b
    jsr loadraw
    bcs load_error2
    inc file_b + 1  // increment file name  BA > BB > BC ...

    // Check if filename is set to BN, it does not exist, that means end
    lda file_b + 1
    cmp #$4f  // B'N'+1
    bne load_loop
wait_for_last_block_to_playback:
    lda screen_index
    cmp #13
    bne wait_for_last_block_to_playback

    sei
    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315
    cli
end_of_video:
    // background color is defined in $d800-$dbff as $0f. 0 is not important
    // fill $d800 with $0c color (GRAY)
    lda #$0c
    sta $d021
    jsr fill_color
    // fill $d800 with $0b color (DARK_GRAY)
    lda #$0b
    sta $d021
    jsr fill_color
    // now video pixels are same color as background
    // clear $0400 and switch screen there
    //TODO
    lda #$00
    sta $d020
    sta $d021
    // load 3d scroller part with planets
    clc
    ldx #<file_b  // Vector pointing to a string containing loaded file name
    ldy #>file_b
    jsr loadraw
    bcs load_error2
    jmp $8000 // TODO kde zacina kod?

load_error2:
    sta $0400  // display error screen code
    lda #$04
    sta $d020
    sta $d021
    jmp *

loading_sempahore:  // 0: load next part of video, non-zero: wait
    .byte 0  //initially load, first part is pre-loaded but load the next one immediately

file_b:   .text "BA"  //filename on diskette
          .byte $00
file_scroller:
          .text "scrll"  //filename on diskette
          .byte $00


screen_index:  // moview screen, every FRAME_DELAY of frames
    .byte 0
frame_index:  // every intrq raster screen is a frame, interval <0 - FRAME_DELAY) backwards
    .byte FRAME_DELAY

// $d018 (upper 4bits +$08 font location)
screen_locations:
    .byte        $20, $30, $40, $50, $60, $70, $80  // bank 2
    .byte        $90, $a0, $b0, $c0, $d0, $e0, $f0  // bank 2
scroll_locations:
    .byte        $4b, $4f, $53, $57, $5b, $5f, $63  // bank 2 4800, 4c00, 5000, 5400, 5800, 5c00, 6000
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
    lda #$1a
    sta $d011
    cli
}
d016_backup:  // backup of $d016
    .byte 0
irq1:
    asl $d019  // ack irq
    wait(8)
    nop
    nop
    nop
    //increase fine scroll
    lda $d016
    and #%11110000
    sta $d016
    //increase fine scroll - step 2
    ldx frame_index
    dex
    txa
    and #%00000111
    ora $d016
    sta $d016
    
    ldx #$01   // render scroll line
    stx $d020
    stx $d021
    sta d016_backup
    // wait 8 line
    wait(86)
    nop
    nop
    lda $d016
    and #%11111000  // reset fine scroll
    ora #%00001000  // widen screen
    sta $d016

    lda #BORDER_COLOR
    sta $d020
    lda #BACKGROUND_COLOR
    sta $d021

    // hardscroll
    lda d016_backup
    and #%00000111
    bne !+
    inc fryba_scroll_pointer_zp  // increase lo nybble
    bne !+
    inc fryba_scroll_pointer_zp + 1  // increase hi nybble
!:
    jsr $1003

    // Count down to next frame
      // decrease frame_index by 1, check if it is zero. 
      // If zero continue to frame update, else skip frame update
    dec frame_index
    lda frame_index
    // call hardscroll every 8th frame
    and #%00000111
    cmp #0
    bne !+
    jsr hardscroll
!:
    lda frame_index
    beq !+
    jmp skip_screen_update
!:
    // Screen update
    lda #FRAME_DELAY
    sta frame_index  // reset delay counter

    // Route between Fryba and video
fryba_route:
    clc  // clear carry (CLC $18) flag means route to Fryba, set carry (SEC $38)flag means route to video
    bcc fryba_start
    jmp next_screen
                // 5 cycles by 7 frames at 16 raster screen per picture = 35 frames
                // 1 hard scroll position per picture
    // Fryba
fryba_start:
    lda #FRAME_DELAY_FOR_FRYBA
    sta frame_index  // overwrite delay because Fryba is faster
    inc screen_index
    lda screen_index
    cmp #5  // Fryba has fixed 5 frames
    bne display_fryba_frame
    dec fryba_full_cycles
    lda fryba_full_cycles
    beq stop_fryba
    lda #$00  // repeat Fryba until video is loaded
    sta screen_index
display_fryba_frame:
    ldx screen_index
    // pre-fill scroll text first
    lda scroll_locations+7,x
    sta tf + 2
    ldy #0
sf: lda (fryba_scroll_pointer_zp),y
    clc
    adc #228  // shift to the right font location
tf: sta $ff70,y
    iny
    cpy #40
    bne sf
    lda screen_locations+7,x
    sta $d018
    jmp skip_screen_update
stop_fryba:
    lda #$38
    sta fryba_route  // next time route to video instead of Fryba
    lda #$00  // end of block, switch to video
    sta screen_index
    sta loading_sempahore  // allow loading next part
    jmp display_frame

fryba_full_cycles:
    .byte 10  // repeat 7 frames 10 times
scroll_text:
    .encoding "screencode_upper"
    .text "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    .text "BREAKING@NEWS[[[@@THE@SUN@SIGNED@OFF@@THIS@IS@THE@END@OF@THE@WORLD@AS@WE@KNOW@IT[@"
    .text "THE@SUN@HAS@ESCAPED@THE@SOLAR@SYSTEM[@CHAOS@UNFOLDS@AS@ENTIRE@ELECTRONICS@INFRASTRUCTURE@COLLAPSES[@ONLY@COMMODORE@MACHINES@REMAIN@FUNCTIONAL[@HUMANITY@SCRAMBLES@TO@ADAPT[@STAY@TUNED@FOR@DEVELOPMENTS[[[@END@OF@TRANSMISSION[@"

next_screen:
    inc screen_index
    lda screen_index
    cmp #7  // max frames in video block
    bne framenot7
frame7:
    lda #$00  
    sta loading_sempahore  // allow loading next part
    jmp display_frame
framenot7:
    cmp #14  // max frames in memory
    bne display_frame
frame14:
    lda #$00
    sta screen_index // end of block
    sta loading_sempahore  // allow loading next part

display_frame:
    ldx screen_index
    lda screen_locations,x
    sta $d018
    jsr hardscroll

skip_screen_update:
    pla
    tay
    pla
    tax
    pla
    rti

irq2:
    jsr $1003
    jmp skip_screen_update

hardscroll:
    // pre-fill scroll text first
    ldx screen_index
    lda scroll_locations,x
    sta tf1 + 2
    ldy #0
sf1:lda (fryba_scroll_pointer_zp),y
    clc
    adc #228  // shift to the right font location
tf1:sta $ff70,y
    iny
    cpy #40
    bne sf1
    rts

// color in A register
fill_color:
    ldx #$00
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    dex
    bne !-
    rts    
.macro distribute_font() { // not needed anymore
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

}  // end namespace PART4_ns