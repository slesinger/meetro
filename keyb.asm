// This is PART 1

#import "fm_const.asm"
#import "loadersymbols-c64.inc"
.const loadraw_temp = $0b00  // temp load address 0b00-0d30

*= install "loader_install" // same as install jsr
.var installer_c64 = LoadBinary("install-c64.prgx", BF_C64FILE)  // prgx suffix prevents from cleanin
installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

*= loadraw_temp "loader_resident" // this will be moved to 9000 (loadraw)
.var loader_c64 = LoadBinary("loader-c64.prgx", BF_C64FILE)
loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

.namespace PART1_ns {
    .const cursor_ptr = $ac
    .const NL = $ff
    .const SWITCH_TO_USER = $fe
    .const SWITCH_TO_AI = $fd
    .const END = $fc

BasicUpstart2(start)

*= $0810 "Part1_code"
start:
    // save cursor position
    lda $d3
    sta cursor_x
    lda $d6
    sta cursor_y
    jsr mc_calc_cursor_ptr

    // Call fast loader installation routine:
    jsr install
    bcs load_error

    // print initial error message  t_error1
    ldx #$00
!:  
    txa
    pha
    lda t_error1,x
    beq http_error_printed
    jsr my_chrout
    pla
    tax
    inx
    cpx #95  // length of t_error1
    bne !-
http_error_printed:
    // turn off basic
    lda #$36
    sta $01

    // Copy resident loader from 0b00 to $9000
    ldx #$00
!:  lda loadraw_temp,x
    sta loadraw,x
    lda loadraw_temp + $0100,x
    sta loadraw + $0100,x
    lda loadraw_temp + $0200,x
    sta loadraw + $0200,x
    inx
    bne !-

    init_irq()

    // load next part
    clc
    ldx #<file_music  // Vector pointing to a string containing loaded file name
    ldy #>file_music
    // jsr loadraw
    jsr loadcompd
    bcs load_error

    clc
    ldx #<file_fontm  // Vector pointing to a string containing loaded file name
    ldy #>file_fontm
    jsr loadcompd
    bcs load_error

    // load until keyb finishes
load_finished:
    jmp *

load_error:
    sta $0400  // display error screen code
    lda #$04
    sta $d020
    sta $d021
    jmp *

file_music:   .text "MUSIC"  //filename on diskette
          .byte $00
file_fontm:   .text "FONTM"  //filename on diskette
          .byte $00


.macro init_irq() {
    sei
    lda #<irq0
    sta $0314
    lda #>irq0
    sta $0315
    asl $d019
    lda #$7b
    sta $dc0d
    lda #$81
    sta $d01a
    lda #$1b
    sta $d011
    lda #$80
    sta $d012
    cli
}

irq0:
    asl $d019
    // tick cursor
    inc cursor_tick
    // blink cursor on screen
    lda #$10
    ldy #$00
    bit cursor_tick
    beq !+
    lda (cursor_ptr), y
    and #$7f  // turn off cursor
    jmp !++
!:
    lda (cursor_ptr), y
    ora #$80  // turn on cursor
!:
    sta (cursor_ptr), y

    // AI or keyboard input?
    lda ai_mode
    cmp #SWITCH_TO_USER
    beq keyb_input
    // ai_input
       // wait random time
    jmp prnt_char

    // read keyboard
keyb_input:
    lda #$00
    sta $dc00
    ldx $dc01
    cpx #$ff
    bne !+
        // unpressed
    lda #$00  // unblock
    sta key_repeat_countdown
    jmp irq0_end
!:  // something was pressed
    lda key_repeat_countdown  // was it pressed before?
    cmp #$00   // 0: ready to read next key
    bne irq0_end  // it was pressed before, do nothing
    lda #$01  // block reading next key without releasing first
    sta key_repeat_countdown
prnt_char:
    // print character on screen
t_conv1_ptr:
    lda t_conv1
    cmp #SWITCH_TO_USER  // switch to keyboard mode?
    bne !+
    sta ai_mode
    jmp just_increase
!:
    cmp #SWITCH_TO_AI  // switch to AI mode?
    bne !+
    sta ai_mode
    jmp just_increase
!:
    cmp #END  // end of conversation?
    bne !+
    jmp PART2_start
!:
    jsr my_chrout

    // increase text pointer
just_increase:
    inc t_conv1_ptr+1
    bne !+
    inc t_conv1_ptr+2
!:
irq0_end:
    pla
    tay
    pla
    tax
    pla
    rti
    // jmp $ea31

key_repeat_countdown: .byte 0  // only read key of this is 0

// Prints a character on screen
// Modifies x,y
my_chrout:
    pha
    // disable cursor first
    ldy #$00
    lda (cursor_ptr), y
    and #$7f  // turn off cursor
    sta (cursor_ptr), y
    pla
    pha
    // print character
    cmp #NL  // new line?
    bne my_regular_chrout
    ldx #$00  // new line
    stx cursor_x
    inc cursor_y
    pla
    jmp mc_cursor_moved
my_regular_chrout:
    // print character
    pla
    ldy #$00
    sta (cursor_ptr), y  // write to screen; Note: dummy address that gets always calculated
    // move cursor
    inc cursor_x
    lda cursor_x
    cmp #$28
    bne mc_calc_cursor_ptr
    lda #$00
    sta cursor_x
    inc cursor_y
    // scroll screen up if Y is off screen
mc_cursor_moved:
    lda cursor_y
    cmp #$19
    bne mc_calc_cursor_ptr
    jsr scroll_up
mc_calc_cursor_ptr:
    // calculate screen address of cursor
    ldy cursor_y
    lda screen_column0_hi, y
    sta cursor_ptr+1
    lda screen_column0_lo, y
    clc
    adc cursor_x
    sta cursor_ptr
    bcc !+
    inc cursor_ptr+1
!:
    rts

cursor_x: .byte 0
cursor_y: .byte 0
screen_column0_hi: .byte $04, $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07, $07
screen_column0_lo: .byte $00, $28, $50, $78, $A0, $C8, $F0, $18, $40, $68, $90, $B8, $E0, $08, $30, $58, $80, $A8, $D0, $F8, $20, $48, $70, $98, $C0
cursor_tick: .byte 0  // increase every frame, bit 4 tells if cursor should be displayed
ai_mode: .byte SWITCH_TO_USER  // 1 - keyboard input, 2 - AI input

t_error1:
    .encoding "screencode_upper"
    .text "TRACEBACK (MOST RECENT CALL LAST):"; .byte NL
    .text @"  FILE \"MAIN.PY\" LINE 55"; .byte NL
    .text "HTTP EXCEPTION: HOST NOT FOUND"; .byte NL
    .text ">>> "
t_conv1:
    // human input
    .text "LOAD AI"; .byte SWITCH_TO_AI, NL
    .text "AI: READY."; .byte NL
    .text "> "; .byte SWITCH_TO_USER  // machine input
    // human input
    .text "CREATE A COOL DEMO"; .byte SWITCH_TO_AI, NL
    // AI input
    .text "AI: SURE. WHAT THEME DO YOU WANT?"; .byte NL
    .text "> "; .byte SWITCH_TO_USER
    // human input
    .text "MEETING MY SCENE FRIENDS"; .byte SWITCH_TO_AI, NL
    // AI input
    .text "AI: A MEETRO? OK. SEARCHING SCENE DB..."; .byte NL
    .text "AI: CODE GENERATED AT $1000-$47FF"; .byte NL
    .text "READY."; .byte NL, SWITCH_TO_USER
    // human input
    .text "RUN"; .byte END  // indicate end of conversation


// scroll screen at $0400 by line up
// Modifies x,y
scroll_up:
    dec cursor_y
    ldy #$00  // rows
copy_loop:
    lda screen_column0_hi, y
    sta su_dst + 2
    lda screen_column0_lo, y
    sta su_dst + 1
    iny
    lda screen_column0_hi, y
    sta su_src + 2
    lda screen_column0_lo, y
    sta su_src + 1
    ldx #$27
su_src:
    lda $ffff, x
su_dst:
    sta $ffff, x
    dex
    bpl su_src
    cpy #24
    bne copy_loop

    // clear line 24
    ldx #$27
    lda #$20
clear_loop:
    sta $07c0, x
    dex
    bpl clear_loop
    rts

}
