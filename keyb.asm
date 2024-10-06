// This is PART 1

#import "fm_const.asm"

.namespace PART1_ns {

BasicUpstart2(start)

*= $0810 "Part1_code"
start:
              jmp PART2_begin
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

    // lda #$01
    // sta $cf

init:
    init_irq()
    jmp *



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
    jsr $ffe4        // Calling KERNAL GETIN
          jmp prnt_char             // disable this for production
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
    jmp PART2_start
!:
    cmp #$0d // new line? make sure cursor is off
    bne !+
    lda ($d1), y
    and #$7f                                           // MA BYT 7f
    sta ($d1), y     // ta pozice je nejaka divna, takze to zatim neresim
    lda #$0d    
!:
    jsr $ffd2        // Calling KERNAL CHROUT
    // increase text pointer
just_increase:
    inc t_conv1_ptr+1
    bne !+
    inc t_conv1_ptr+2
!:
irq0_end:
    jmp $ea31


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
    








#import "lib_fast_load.asm"  // at $9000

*=$0b00 "test_code_for_loading"
PART2_begin:
    // disable basic $a000-$bfff
    lda $01
    and #%11111110
    sta $01

    // ** Example of using the fast loader
    fastloader_init()  // call this only once to upload code to the floppy
    fastloader_load($28, 2, 8)  // load from track 2, 8 sectors in total and store to memory $2800
!:
    inc $d020
    jmp !-




}
