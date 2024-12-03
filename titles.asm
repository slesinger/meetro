#import "fm_const.asm"
#import "loadersymbols-c64.inc"

/*
Block 1: 0400-1000 -> 3 frames   block 0
Block 2: 2800-4000 -> 6 frames   block 1
Block 3: 4800-8000 -> 14 frames  block 2
Block 4: 9400-c000 -> 8 frames   block 3
Block 5: e000-ffff -> 8 frames   block 4

Video files on diskete will be named as <1 letter sequence code for video part><block number>. Example A0
*/

.namespace PART6_ns {

.const FRAME_DELAY = 7//7  // how many raster screen frames to display one frame of video, this has to be multiple of 8 because of breaking news scroller
.const TITLE_FONT6_SCREEN_D018 = $32  // $8800-$9000
.const TITLE_FONT_SCREEN_D018 = $30  // $8800-$9000
.const TITLE_BANK_DD00 = $01  // $8c00-$8fe8
.const TOP_D012 = $a2 // where top bar raster interrupt will be triggered
.const BOTTOM_D012 = $d7 // where bottom bar raster interrupt will be triggered


#if RUNNING_COMPLETE
    // Started as whole compilation of parts
#else
    BasicUpstart2(PART6_ns.start)
    *= install "loader_install" // same as install jsr
    .var installer_c64 = LoadBinary("tools/krill194/loader/build/install-c64.prg", BF_C64FILE)
    installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

    *= loadraw "loader_resident" // same as loader code block address
    .var loader_c64 = LoadBinary("tools/krill194/loader/build/loader-c64.prg", BF_C64FILE)
    loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

    *= $4000 "font" // same as loader code block address
    .var font = LoadBinary("datab/bond-font.bin", BF_C64FILE)
    font_ptr: .fill font.getSize(), font.get(i)

    *= $8800 "font6" // same as loader code block address
    .var font6 = LoadBinary("datab/font6.bin", BF_C64FILE)
    font6_ptr: .fill font6.getSize(), font6.get(i)

    file_music:
        .text "MUSIC"  //filename on diskette
        .byte $00
#endif 
    
*= $9300 "Part6_code"
start:
#if RUNNING_COMPLETE
    // Started as whole compilation of parts
#else
    jsr install
    // bcs load_error
    clc
    ldx #<file_music  // Vector pointing to a string containing loaded file name
    ldy #>file_music
    jsr loadcompd
    // bcs load_error

    // init music
    jsr $1000
#endif 

    // disable basic and kernal
    // disable_basic_kernal()
    disable_basic()
    distribute_font()
    // init screen and font
    lda #TITLE_FONT_SCREEN_D018
    sta $d018
    lda screen_banks
    lda #TITLE_BANK_DD00
    sta $dd00
jsr empty_title
    // disable screen
    // lda $d011
    // and #%11101111
    // sta $d011

    // clean screen
    // fill $d800 with $0c color (GRAY)
    lda #$00
    sta $d020
    sta $d021
    lda #$0c
    jsr fill_color

    // set text mode

    // setup irq
    init_irq()

    // load loop, responsible for loading video files and semaphoring to irq routine for displaying
load_loop:
    //wait for semaphore to be 0
    lda semaphore
    cmp #$00
    bne load_loop
    //  load all frames
    clc
    ldx #<file_video  // Vector pointing to a string containing loaded file name
    ldy #>file_video
    disable_basic()
    jsr loadcompd   //  asi se to bude muset rucne nakopirovat do 9800-c000 a do e000-ffff
    disable_basic()
    bcs load_error

    lda file_video+1
    cmp #$33  // '3'  // file X3 intend for e000 but has to load to a000 and copy to e000
    bne !+
    jsr copy_a000_to_e000  // copy loaded video part to e000-ffff
!:
    // increase video block (0-4)
    inc file_video+1
    lda file_video+1
    cmp #$35  // $35 '5'
    bne load_loop  // not all blocks loaded yet
    // signal all blocks loaded
    lda #$01
    sta semaphore  // start displaying it
    // wait for signal from irq that loading can continue (after first 3 frames are displayed)
    lda #$30  // '0'  reset block number to 0
    sta file_video+1
    inc file_video+0  // move to next video part
    jmp load_loop  // display next video part

load_error:
    sta $0400  // display error screen code
    lda #$05  // TODO sem to skace pred uderem loktu do hlavy
    sta $d020
    sta $d021
    jmp *

file_video:
    .text "A0"  //filename on diskette
    .byte $00

irq1:
    asl $d019  // ack irq
    // check is semaphore allows displaying
    lda semaphore
    cmp #$01      // is displaying
    bne title_top  // is loading and title is displayed
    // Count down to next frame
      // decrease frame_index by 1, check if it is zero. 
      // If zero continue to frame update, else skip frame update
    dec frame_index
    lda frame_index
    beq !+
    jmp irq1_end
!:
    // Screen update
    lda #FRAME_DELAY
    sta frame_index  // reset delay counter

    ldx screen_index
    lda screen_locations,x
    sta $d018
    sta $07f8
    lda screen_banks,x
    sta $dd00
    sta $07f9
    inc screen_index
    lda screen_index
    cmp #37  // number of frames in memory in total
    bne irq1_end
    lda #0  // Start video over
    sta screen_index
    sta semaphore
    jsr copy_title
    // jmp irq1_end  // make sure that title will render nice since next frame will be displayed

title_top:
    wait(5)
    lda #WHITE
    sta $d020
    sta $d021
    lda #TITLE_FONT6_SCREEN_D018
    sta $d018
    lda #TITLE_BANK_DD00
    sta $dd00
    wait(8)
    lda #BLACK
    sta $d020
    sta $d021
    lda #BOTTOM_D012  // where raster interrupt will be triggered
    sta $d012
    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315

irq1_end:
    jsr $1003
irq2_end:
    pla
    tay
    pla
    tax
    pla
    rti

irq2:
    asl $d019  // ack irq
    wait(3)
    lda #YELLOW
    sta $d020
    sta $d021
    lda #TITLE_FONT_SCREEN_D018
    sta $d018
    wait(9)
    lda #BLACK
    sta $d020
    sta $d021
    lda #TOP_D012  // where top bar raster interrupt will be triggered
    sta $d012
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    jmp irq2_end

semaphore:  // 0: loading only, 1: displaying,
    .byte 0
screen_index:  // moview screen, every FRAME_DELAY of frames
    .byte 0
frame_index:  // every intrq raster screen is a frame, interval <0 - FRAME_DELAY) backwards
    .byte FRAME_DELAY+1

screen_locations:  // $d018 (upper 4bits +$08 font location)
    .byte   $18, $28, $38,                                 $a8, $b8,  $c8, $d8, $e8, $f8  // bank 1
    .byte        $20, $30,  $40, $50, $60, $70,  $80, $90, $a0, $b0,  $c0, $d0, $e0, $f0  // bank 2
    .byte                                        $80, $90, $a0, $b0,  $c0, $d0, $e0, $f0  // bank 3 a000-bfe8
    // .byte                                        $80, $90, $a0, $b0,  $c0, $d0, $e0, $f0  // bank 4 e000-ffe8
    .byte                                        $80, $a0, $b0,  $c0, $e0, $f0  // bank 4 e000-ffe8 - not usin 90 and d0 because there is some garbage in ram

.byte 0,0,0,0,0,0,0,0,0,0

screen_banks:  // $dd00 AND x
    .byte  3,3,3,              3,3, 3,3,3,3  // bank 1  9x
    .byte    2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2  // bank 2  14x
    .byte                  1,1,1,1, 1,1,1,1  // bank 3  8x
    .byte                  0,0,0, 0,0,0  // bank 4  8x

.byte 0,0,0,0,0,0,0,0,0,0

// Define 2 rows of 20 character length text
titles_ptr: .byte 0
titles:
    .encoding "screencode_upper"
    .text "__THE_SUN_IS_GONE___"
    .text "IT_WENT_REALLY_SILLY"

    .text "GREETINGS___________"
    .text "TOPAZ_EPIC_GHOUL_JAM"

    .text "GREETINGS___________"
    .text "_TRANCE_CARTEL_DEATH"

    .text "GREETINGS___________"
    .text "CULT_SAO_BLAZE_ORIGO"

    .text "GREETINGS___________"
    .text "_____ASPHYXIA_ASTRAL"

    .text "DEMO_IS_JOINT_EFFORT"
    .text "HONZA____DAN___ONDRA"

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
    lda #TOP_D012  // where raster interrupt will be triggered
    sta $d012
    lda #$1a
    sta $d011
    cli
}

.macro disable_basic_kernal() {
    sei
    lda #$35 //#$34
    sta $01
    cli
}

.macro disable_basic() {
    sei
    lda #$36
    sta $01
    cli
}

.macro distribute_font() {
    ldx #$00
df_loop:
    sei
    lda $4000, x
    sta $2000, x
    sta $8000, x
    sta $c000, x
    lda $4100, x
    sta $2100, x
    sta $8100, x
    sta $c100, x
    lda $4200, x
    sta $2200, x
    sta $8200, x
    sta $c200, x
    lda $4300, x
    sta $2300, x
    sta $8300, x
    sta $c300, x
    lda $4400, x
    sta $2400, x
    sta $8400, x
    sta $c400, x
    lda $4500, x
    sta $2500, x
    sta $8500, x
    sta $c500, x
    lda $4600, x
    sta $2600, x
    sta $8600, x
    sta $c600, x
    lda $4700, x
    sta $2700, x
    sta $8700, x
    sta $c700, x
    inx
    cli
    bne df_loop
}

.macro wait(count) {
    ldx #count
!:  dex
    bne !-
}

copy_a000_to_e000:
    ldx #$00
!:
    lda $a000, x
    sta $e000, x
    lda $a100, x
    sta $e100, x
    lda $a200, x
    sta $e200, x
    lda $a300, x
    sta $e300, x
    lda $a400, x
    sta $e400, x
    lda $a500, x
    sta $e500, x
    lda $a600, x
    sta $e700, x
    lda $a800, x
    sta $e800, x
    lda $a900, x
    sta $e900, x
    lda $aa00, x
    sta $ea00, x
    lda $ab00, x
    sta $eb00, x
    lda $ac00, x
    sta $ec00, x
    lda $ad00, x
    sta $ed00, x
    lda $ae00, x
    sta $ee00, x
    lda $af00, x
    sta $ef00, x

    lda $b000, x
    sta $f000, x
    lda $b100, x
    sta $f100, x
    lda $b200, x
    sta $f200, x
    lda $b300, x
    sta $f300, x
    lda $b400, x
    sta $f400, x
    lda $b500, x
    sta $f500, x
    lda $b600, x
    sta $f700, x
    lda $b800, x
    sta $f800, x
    lda $b900, x
    sta $f900, x
    lda $ba00, x
    sta $fa00, x
    lda $bb00, x
    sta $fb00, x
    lda $bc00, x
    sta $fc00, x
    lda $bd00, x
    sta $fd00, x
    lda $be00, x
    sta $fe00, x
    lda $bee8, x
    sta $fee8, x
    inx
    beq !+
    jmp !-
!:
    rts

empty_title:
    ldx #$00
    lda #$06
!:
    sta $8c00, x
    sta $8d00, x
    inx
    bne !-
!:
    sta $8e00, x
    inx
    cpx #48+40
    bne !-
    ldx #$a0
!:
    sta $8f48, x
    dex
    bne !-
    jmp copy_title_only

copy_title:
    // copy last screen to 8c00-8fe8
    disable_basic_kernal()
    ldx #$00
!:
    lda $fc00, x
    sta $8c00, x
    lda $fd00, x
    sta $8d00, x
    inx
    bne !-
!:
    lda $fe00, x
    sta $8e00, x
    inx
    cpx #48
    bne !-
    ldx #$a0
!:
    lda $ff48, x
    sta $8f48, x
    dex
    bne !-
    disable_basic()

copy_title_only:
    // copy title part to 8e58
    ldy #$00
!:  lda #$1f
    sta $8e30, y
    iny
    cpy #$28
    bne !-
    // first row of titles
    ldx titles_ptr
    ldy #$00
!:  lda titles, x
    sta $8e58, y
    ora #$20
    sta $8e58+1, y
    ora #$60
    sta $8e58+$28+1, y
    and #$df
    sta $8e58+$28, y
    iny
    iny
    inx
    cpy #40
    bne !-
    // one empty line
    ldy #$00
!:  lda #$1f
    sta $8ea8, y
    iny
    cpy #$28
    bne !-
    // second row of titles
    ldy #$00
!:  lda titles, x   // x must not be destroyed from previous line
    sta $8ed0, y
    ora #$20
    sta $8ed0+1, y
    ora #$60
    sta $8ed0+$28+1, y
    and #$df
    sta $8ed0+$28, y
    iny
    iny
    inx
    cpy #40
    bne !-
    stx titles_ptr
    // one empty line
    ldy #$00
!:  lda #$1f
    sta $8f20, y
    iny
    cpy #$28
    bne !-
    rts
}