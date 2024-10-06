
.ifndef _FLOAT_INC_
_FLOAT_INC_ = 1

.include "basic.inc"
.include "kernal.inc"


.macro LONGTOFAC longaddr

            lda longaddr + $00
            sta __longbuff + $00
            lda longaddr + $01
            sta __longbuff + $01
            lda longaddr + $02
            sta __longbuff + $02
            lda longaddr + $03
            sta __longbuff + $03

    .ifref __l2fimpl
            jsr __l2fimpl
    .else
            .local endrout

            jsr __l2fimpl; for .ifref detection
            jmp endrout

__l2fimpl:  ; convert signed longword (32 bits) at longaddr to float, store in FAC#1
            .local floatbuff
            .local iszero

            lda __longbuff + $00
            ora __longbuff + $01
            ora __longbuff + $02
            ora __longbuff + $03
            bne @0
            jmp iszero

@0:         lda __longbuff + $03
            php
            bpl @1
            sec
            lda #$00
            sbc __longbuff + $00
            sta __longbuff + $00
            lda #$00
            sbc __longbuff + $01
            sta __longbuff + $01
            lda #$00
            sbc __longbuff + $02
            sta __longbuff + $02
            lda #$00
            sbc __longbuff + $03
            sta __longbuff + $03

            ; hiword
@1:         lda __longbuff + $03
            and #$7f
            ldy __longbuff + $02
            jsr GIVAYF; to FAC
            bit __longbuff + $03
            bpl @2
            lda #.lobyte(N32768)
            ldy #.hibyte(N32768)
            jsr FSUB; subtract -32768
            lda #$7f; sign is negative for unknown reasons
            and FACSGN
            sta FACSGN
@2:         clc
            lda #$10
            adc FACEXP
            sta FACEXP
            ldx #.lobyte(floatbuff)
            ldy #.hibyte(floatbuff)
            jsr MOV2M

            ; loword
            lda __longbuff + $01
            and #$7f
            ldy __longbuff + $00
            jsr GIVAYF; to FAC
            bit __longbuff + $01
            bpl @3
            lda #<N32768
            ldy #>N32768
            jsr FSUB; subtract -32768
            lda #$7f; sign is negative for unknown reasons
            and FACSGN
            sta FACSGN

            ; longword
@3:         lda #.lobyte(floatbuff)
            ldy #.hibyte(floatbuff)
            jsr FADD; add top 16 bits

            lda #$7f; sign is negative for unknown reasons
            and FACSGN
            plp
            bpl @4
            lda #$80
            ora FACSGN
@4:         sta FACSGN
            rts

iszero:     sta FACEXP
            sta FACHO + $00
            sta FACHO + $01
            sta FACHO + $02
            sta FACHO + $03
            sta FACSGN
            rts

__longbuff: .res 4
floatbuff:  .res 5

endrout:

    .endif
.endmacro

.endif; FLOAT_INC
