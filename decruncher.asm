// ---------------------------------
//  VARIABLES...      # NO. OF BYTES
.const zp_base = $02       //  -
.const cpl     = zp_base+0 //  1
.const cur     = zp_base+1 //  1
.const zp      = zp_base+2 //  -
.const put     = zp_base+2 //  2
.const get     = zp_base+4 //  2
.const cps     = zp_base+6 //  2
// ---------------------------------
decrunch:
        sty get
        stx get+1

        ldy #2
        lda (get),y
        sta cur,y
        dey
        bpl *-6

        clc
        lda #3
        adc get
        sta get
        bcc *+4
        inc get+1

d_loop: jsr d_get

dl_1:   php
        lda #1

dl_2:   jsr d_get
        bcc dl_2e
        jsr d_get
        rol
        bpl dl_2

dl_2e:   plp
        bcs d_copy

d_plain:sta cpl

        ldy #0
        lda (get),y
        sta (put),y
        iny
        cpy cpl
        bne *-7

        ldx #get-zp
        jsr d_add
        iny
        beq d_loop
        sec
        bcs dl_1

d_copy: adc #0
        beq d_end
        sta cpl
        cmp #3

        lda #0
        sta cps
        sta cps+1

        rol
        jsr d_get
        rol
        jsr d_get
        rol
        tax

dc_1s:  ldy tab,x

dc_1:   jsr d_get
        rol cps
        rol cps+1
        dey
        bne dc_1
        txa
        dex
        and #3
        beq dc_1e
        inc cps
        bne dc_1s
        inc cps+1
        bne dc_1s

dc_1e:  sec
        lda put
        sbc cps
        sta cps
        lda put+1
        sbc cps+1
        sta cps+1

        lda (cps),y
        sta (put),y
        iny
        cpy cpl
        bne *-7

        ldx #put-zp
        jsr d_add
        bpl d_get
        jmp d_loop

d_get:  asl cur
        bne dg_end
        pha
        tya
        pha
        ldy #0
        lda (get),y
        inc get
        bne *+4
        inc get+1
        sec
        rol
        sta cur
        pla
        tay
        pla

dg_end: rts

d_add:  clc
        tya
        adc zp,x
        sta zp,x
        bcc *+4
        inc zp+1,x
        dex
        dex
        bpl d_add

d_end:  rts

tab:
       .byte 4,2,2,2
       .byte 5,2,2,3
// ---------------------------------