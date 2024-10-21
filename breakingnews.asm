
BasicUpstart2(start)


.const BORDER_COLOR = $0f
.const BACKGROUND_COLOR = $0b


start:
    init_irq()
    // make screen thinner
    lda #$41
    sta $0770
    sta $0772
    sta $0774
    sta $0776
    sta $0770-40
    sta $0770+40
    rts
!:  jmp !-

current_frame_countdown:
    .byte 0

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
    inc current_frame_countdown
    lda current_frame_countdown
    and #%00000111
    sta current_frame_countdown
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

skip_frame_update:
    pla
    tay
    pla
    tax
    pla
    rti


.macro wait(count) {
    ldx #count
!:
    dex
    bne !-
}

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
    lda #$e1  // where raster interrupt will be triggered
    sta $d012
    lda #$1b
    sta $d011
    cli
}