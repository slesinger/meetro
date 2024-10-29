// This is PART 1

#import "fm_const.asm"
#import "loadersymbols-c64.inc"
.const loadraw_temp = $0b00  // temp load address 0b00-0d30

*= install "loader_install" // same as install jsr
.var installer_c64 = LoadBinary("install-c64.prg", BF_C64FILE)
installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

*= loadraw_temp "loader_resident" // this will be moved to 9000 (loadraw)
.var loader_c64 = LoadBinary("loader-c64.prg", BF_C64FILE)
loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

.namespace PART1_ns {

BasicUpstart2(start)

*= $0810 "Part1_code"
start:
    // print t_error1
    lda #<t_error1
    sta TMP_PTR
    lda #>t_error1
    sta TMP_PTR+1
    ldx #$00
    // print initial error message
!:
    lda t_error1,x
    beq init
    jsr $ffd2    // If the routine fools with Y, be sure to save and restore it.
    inx
    cpx #95  // length of t_error1
    bne !-       // (65C02 would normally use BRA, but BNE will work here.)

    // turn off basic
    lda $01
    and #$fe
    sta $01

    init_irq()

    // Call fast loader installation routine:
    jsr install

    // Copy resident loader from 0a00 to $9000
    ldx #$00
!:
    lda loadraw_temp,x
    sta loadraw,x
    lda loadraw_temp + $0100,x
    sta loadraw + $0100,x
    lda loadraw_temp + $0200,x
    sta loadraw + $0200,x
    inx
    bne !-

init:

    // load next part
    clc
    ldx #<file_b  // Vector pointing to a string containing loaded file name
    ldy #>file_b
    jsr loadraw
    cmp #$00
    beq load_ok
    sta $0400  // load error
    sta $d020
    jmp *

    // load until keyb finishes
load_ok:
    jmp *

file_b:   .text "SMALL" //"FONTM"  //filename on diskette
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
    ldy $d3
    bit cursor_tick
    beq !+
    lda ($d1), y
    and #$7f
    jmp !++
!:
    lda ($d1), y
    ora #$80
!:
    sta ($d1), y

    // AI or kyeboard input?
    lda ai_mode
    cmp #$01
    beq keyb_input
    // ai_input
       // wait random time
    jmp prnt_char

    // read keyboard
keyb_input:
    jsr $f142        // Calling KERNAL GETIN ($ffe4) for keyboard only
#if HURRY_UP
    jmp prnt_char
#endif
    beq irq0_end
prnt_char:
    // print character on screen
t_conv1_ptr:
    lda t_conv1
    cmp #$01  // switch to keyboard mode?
    bne !+
    sta ai_mode
    // clear keyboard buffer
    lda #$00
    sta $c6
    jmp just_increase
!:
    cmp #$02  // switch to AI mode?
    bne !+
    sta ai_mode
    jmp just_increase
!:
    cmp #$03  // end of conversation?
    bne !+
    jmp $c100 //PART2_start
!:
    cmp #$0d // new line? make sure cursor is off
    bne !+
    lda ($d1), y
    and #$7f                                           // MA BYT 7f
    sta ($d1), y     // ta pozice je nejaka divna, takze to zatim neresim
    lda #$0d    
!:
    jsr $e716        // Calling KERNAL CHROUT ($ffd2) but for screen output

    // increase text pointer
just_increase:
    inc t_conv1_ptr+1
    bne !+
    inc t_conv1_ptr+2
!:
irq0_end:
    jmp $ea31
    // pla
    // tay
    // pla
    // tax
    // pla
    // rti


cursor_tick: .byte 0  // increase every frame, bit 4 tells if cursor should be displayed
ai_mode: .byte 1  // 1 - keyboard input, 2 - AI input

t_error1:
    .text "TRACEBACK (MOST RECENT CALL LAST):"; .byte $0d
    .text @"  FILE \"MAIN.PY\" LINE 55"; .byte $0d
    .text "HTTP EXCEPTION: HOST NOT FOUND"; .byte $0d
    .text ">>> "
t_conv1:
    // human input
    .text "LOAD AI"; .byte $0d, $02
    .text "> "; .byte $01  // machine input
    // human input
    .text "CREATE A COOL DEMO"; .byte $0d, $02
    // AI input
    .text "AI: SURE. WHAT THEME DO YOU WANT?"; .byte $0d
    .text "> "; .byte $01
    // human input
    .text "MEETING MY SCENE FRIENDS"; .byte $0d, $02
    // AI input
    .text "AI: A MEETRO? OK. SEARCHING SCENE DB..."; .byte $0d
    .text "AI: CODE IS READY. $1000-$47FF"; .byte $0d
    .text "READY."; .byte $0d, $01
    // human input
    .text "RUN"; .byte $03  // indicate end of conversation

}
