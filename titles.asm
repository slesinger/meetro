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
.const TOP_D012 = $a1 // where top bar raster interrupt will be triggered
.const BOTTOM_D012 = $d8 // where bottom bar raster interrupt will be triggered
.const FONT_BLANK_CHAR = $03  // find character in bond-font.bin that is all white


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
    .var font = LoadBinary("datab/vidfont.bin", BF_C64FILE)
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
    bcc !+
    jmp dos
!:
    clc
    ldx #<file_music  // Vector pointing to a string containing loaded file name
    ldy #>file_music
    jsr loadcompd
    bcc !+
    jmp dos
!:
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
    // sta $0400  // display error screen code
    // lda #$05
    // sta $d020
    // sta $d021
    lda #$10  // ending
    sta semaphore
    jmp *  // instead of debug code, initiate ending procedure

file_video:
    .text "A0"  //filename on diskette
    .byte $00

ending_counter: .byte 255
volume: .byte $0f
irq0:
    asl $d019  // ack irq
    jsr $1003
    // set volume
    lda volume
    and #$0f
    ora #$30
    sta $d418
    // check if semaphore allows displaying
    lda semaphore
    cmp #$01      // is displaying
    bne !+  // is loading and title is displayed
    jmp displaying
!:  cmp #$10      // is ending
    beq ending  // video finished and start darking the screen
    jmp title_top_set
ending:
    dec ending_counter
    // decrease sound volume by 1 every 16 frames
    lda ending_counter
    and #$0f
    cmp #$00
    bne !+
    dec volume  // decrease volume
!:
    lda ending_counter
    cmp #254
    bne !+
    lda #$f0
    sta $d018
    jmp irq_end
!:  cmp #$f0
    bne !+
    lda #$00
    sta end_block_addr + 1
    lda #$d8
    sta end_block_addr + 2
    pha
    lda #DARK_GRAY
    jsr end_block_fill
    pla
!:  cmp #$d0
    bne !+
    pha
    lda #BLACK
    jsr end_block_fill
    pla
!:
    cmp #$b0
    bne !+
    lda #$f0
    sta end_block_addr + 1
    lda #$d8
    sta end_block_addr + 2
    pha
    lda #DARK_GRAY
    jsr end_block_fill
    pla
!:  cmp #$90
    bne !+
    pha
    lda #BLACK
    jsr end_block_fill
    pla
!:
    cmp #$70
    bne !+
    lda #$e0
    sta end_block_addr + 1
    lda #$d9
    sta end_block_addr + 2
    pha
    lda #DARK_GRAY
    jsr end_block_fill
    pla
!:  cmp #$50
    bne !+
    pha
    lda #BLACK
    jsr end_block_fill
    pla
!:
    cmp #$30
    bne !+
    lda #$d0
    sta end_block_addr + 1
    lda #$da
    sta end_block_addr + 2
    pha
    lda #DARK_GRAY
    jsr end_block_fill
    pla
!:
    cmp #$10
    bne !+
    pha
    lda #BLACK
    jsr end_block_fill
    pla
!:
    cmp #16
    bne !+
    ldx #BLUE
    stx $d020
!:  cmp #8  // set border color as prequel to ending
    bne !+
    ldx #LIGHT_BLUE
    stx $d020
!:  cmp #$00
    beq !+
    jmp irq_end
!:  jmp dos
displaying:
    // Count down to next frame
      // decrease frame_index by 1, check if it is zero. 
      // If zero continue to frame update, else skip frame update
    dec frame_index
    lda frame_index
    beq !+
    jmp irq_end
!:
    lda #10  // where raster interrupt will be triggered
    sta $d012
    lda #<irq0
    sta $0314
    lda #>irq0
    sta $0315
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
    bne irq_end
    lda #0  // Start video over again
    sta screen_index
    sta semaphore
    jsr copy_title
title_top_set:
    lda #TOP_D012  // where raster interrupt will be triggered
    sta $d012
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    jmp irq_end

irq1:
    asl $d019  // ack irq
    wait(4)
    lda #TITLE_FONT6_SCREEN_D018
    sta $d018
    lda #TITLE_BANK_DD00
    sta $dd00
    nop
    lda #WHITE
    sta $d020
    sta $d021
    wait(10)
    nop
    lda #BLACK
    sta $d020
    sta $d021
    lda #BOTTOM_D012  // where raster interrupt will be triggered
    sta $d012
    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315

irq_end:
    pla
    tay
    pla
    tax
    pla
    rti

irq2:
    asl $d019  // ack irq
    wait(2)
    nop
    nop
    lda #WHITE
    sta $d020
    sta $d021
    wait(9)
    lda #TITLE_FONT_SCREEN_D018
    sta $d018
    lda #BLACK
    sta $d020
    sta $d021
    lda #10  // where top bar raster interrupt will be triggered
    sta $d012
    lda #<irq0
    sta $0314
    lda #>irq0
    sta $0315
    jmp irq_end

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

    .text "LIFE_S_PIECE_OF_SHIT"  // TODO apostrophe
    .text "WHEN_YOU_LOOK_AT_IT_"

    .text "_ALWAYS_LOOK_ON_THE_"
    .text "BRIGHT_SIDE_OF_LIFE_"

    .text "____COME_ON_GUYS____"
    .text "______CHEER_UP______"

    .text "_LIFE_IS_BEAUTIFUL__" 
    .text "__ENJOY_EVERY_DAY___"

    .text "REGARDS_FROM________"
    .text "_____HONZA_DAN_ONDRA"

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
    lda #FONT_BLANK_CHAR
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
    sta $8f47, x
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

// Fill block of memory with color
// A - color
end_block_fill:
    ldx #$00
end_block_addr:
    sta $d800, x
    inx
    cpx #40 * 6
    bne end_block_addr
    rts
dos:
#import "dos.asm"

}