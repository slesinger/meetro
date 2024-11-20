
.const cursor_ptr = $fb
.const NL = $ff

    lda #$37
    sta $01

    ldx #$FF
    sei
    txs
    cld
    stx $d016
    jsr $fda3
    jsr $fd15
    jsr $ff5b

    // print screen message
    ldx #$00
!:  lda message,x
    sta $0400,x
    inx
    cpx #208
    bne !-

    // set cursor position
    lda #240
    sta cursor_ptr
    lda #$04
    sta cursor_ptr + 1

cursor_loop:
    // blink cursor
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

keyb_input:
    lda #$00
    sta $dc00
    ldx $dc01
    cpx #$ff
    bne !+
        // unpressed
    lda #$00  // unblock
    sta key_repeat_countdown
    jmp frame_end
!:  // something was pressed
    lda key_repeat_countdown  // was it pressed before?
    cmp #$00   // 0: ready to read next key
    bne frame_end  // it was pressed before, do nothing
    lda #$01  // block reading next key without releasing first
    sta key_repeat_countdown

    // print character on screen
    ldx t_conv1_ptr
    lda t_conv1,x
    jsr my_chrout
    inc t_conv1_ptr
    inc cursor_ptr
    lda cursor_ptr
    bne frame_end
    inc cursor_ptr + 1

frame_end:
    // wait for frame
!:  lda $d012
    cmp #$f0
    bne !-
    jmp cursor_loop

cursor_x: .byte 0
t_conv1_ptr: .byte 0
cursor_tick: .byte 0  // increase every frame, bit 4 tells if cursor should be displayed
key_repeat_countdown: .byte 0  // only read key of this is 0

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
    cmp #$ff  //  end of good bye
    bne my_regular_chrout
    jmp *  // this is the very end of the demo
my_regular_chrout:
    // print character
    pla
    ldy #$00
    sta (cursor_ptr), y  // write to screen; Note: dummy address that gets always calculated
    // move cursor
    inc cursor_x
    rts

t_conv1:
    .encoding "screencode_upper"
    .text "GOOD BYE. SEE YOU IN 2040.     MAYBE..."; .byte $ff

message:
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $2a, $2a, $2a, $2a
.byte $20, $03, $0f, $0d,  $0d, $0f, $04, $0f,  $12, $05, $20, $36,  $34, $20, $02, $01
.byte $13, $09, $03, $20,  $16, $32, $20, $2a,  $2a, $2a, $2a, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $36, $34, $0b,  $20, $12, $01, $0d
.byte $20, $13, $19, $13,  $14, $05, $0d, $20,  $20, $33, $38, $39,  $31, $31, $20, $02
.byte $01, $13, $09, $03,  $20, $02, $19, $14,  $05, $13, $20, $06,  $12, $05, $05, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20,  $20, $20, $20, $20
.byte $20, $20, $20, $20,  $20, $20, $20, $20,  $08, $0f, $0e, $04,  $01, $0e, $09, $2e
