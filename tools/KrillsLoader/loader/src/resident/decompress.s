
    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
        chunkdestlo = OUTPOS + $00
        chunkdesthi = OUTPOS + $01
    .else
        chunkdestlo = decdestlo
        chunkdesthi = decdesthi
    .endif

    .macro CHUNKENTRY
        .if GETCHUNK_API
            lda CHUNKSWTCH
            bne begindecomp; branch if GETCHUNK_API routines are switched off
			tsx
			stx LASTSP; exception stack pointer
            lda LASTPC + $01
            beq begindecomp; branch if file's first call to getchunk
			; go back to decompressor context
            lda CHUNKENDLO
            cmp chunkdestlo
            lda CHUNKENDHI
            sbc chunkdesthi
            jcc chunkret; branch if the desired chunk is already available
            CHUNKRESTORE
            jmp (LASTPC); this causes an assertion warning with ld65/.o65 for unknown reasons
begindecomp:
            ; throw exception on stream error
            sec
            .if LOAD_COMPD_API
            rol throwswtch + $01
            .else
            rol LASTPC + $01
            .endif
        .endif
    .endmacro

    .macro CHUNKSETUP
        .if GETCHUNK_API
            lda CHUNKSWTCH
            bne nochunksetup
            clc
            lda chunkdestlo
            sta CHUNKBEGLO
            adc CHUNKENDLO
            sta CHUNKENDLO
            lda chunkdesthi
            sta CHUNKBEGHI
            adc CHUNKENDHI
            sta CHUNKENDHI
nochunksetup:
        .endif
    .endmacro

    .macro CHUNKCHECK; this macro must only be used in decompress stack pointer context,
                     ; with no data or return addresses internal to decompress on the
                     ; stack, so that an rts would return to the caller of decompress
        .if GETCHUNK_API
            .local notcomplet

            lda CHUNKENDLO
            cmp chunkdestlo
            lda CHUNKENDHI
            sbc chunkdesthi
            .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
            lda #$00; the z-flag needs to be set
            .endif
            bcs notcomplet; branch if chunk not complete yet
            jsr chunkout; return chunk
notcomplet:
        .endif
    .endmacro

    .macro CHUNKEOF
        .if GETCHUNK_API
            jmp chunkeof
        .endif
    .endmacro

    .macro CHUNKSUB
        .if GETCHUNK_API
chunkout:   CHUNKBACKUP
			; switch to getchunk context
            clc
            pla
            adc #$01
            sta LASTPC + $00
            pla
            adc #$00
            sta LASTPC + $01
chunkret:   sec
            lda CHUNKENDLO
            sbc CHUNKBEGLO
            sta param4
            lda CHUNKENDHI
            sbc CHUNKBEGHI
            sta param5
            ldx CHUNKBEGLO
            ldy CHUNKBEGHI
            lda CHUNKENDLO
            sta CHUNKBEGLO
            lda CHUNKENDHI
            sta CHUNKBEGHI
            lda #diskio::status::OK
            clc
            rts

            ; eof in streamed file, return to caller if end of stream, too,
            ; otherwise go on if compressed files can be chained
chunkeof:   lda CHUNKSWTCH
            bne chunkok

            .if CHAINED_COMPD_FILES

                .if LOAD_VIA_KERNAL_FALLBACK
            .local closefile
            .local nofallback

            ENABLE_KERNAL_SERIAL_ROUTINES

            BRANCH_IF_INSTALLED nofallback
            jsr getc
            jsr getc

                    .if (!LOAD_UNDER_D000_DFFF) & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE_Y
                    .else
            ENABLE_ALL_RAM_Y
                    .endif

            bcc skiploadad
            cmp #diskio::status::EOF
            beq chunkend

            ldy kernaloff + $01
            SET_MEMCONFIG_Y

            sec
            rts

nofallback:
                    .if (!LOAD_UNDER_D000_DFFF) & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE
                    .else
            ENABLE_ALL_RAM
                    .endif
                .endif; LOAD_VIA_KERNAL_FALLBACK

            .local skiploadad

				.if GETC_API
            lda getcmemfin + $01
            cmp endaddrlo
            lda getcmemfin + $02
            sbc endaddrhi
                .else; !GETC_API
            lda getcmemadr + $01
            cmp endaddrlo
            lda getcmemadr + $02
            sbc endaddrhi
                .endif; !GET_API
            bcs chunkend

            ; go on with the next compressed sub-file
            jsr getc; skip load
            jsr getc; address

skiploadad: lda #$00
            sta CHUNKENDLO
            sta CHUNKENDHI
            sta LASTPC + $01
            beq chunkchain; jmp

            .endif; CHAINED_COMPD_FILES

chunkend:   lda #.lobyte(dochunkeof)
            sta LASTPC + $00
            lda #.hibyte(dochunkeof)
            sta LASTPC + $01

chunkchain: sec
            lda chunkdestlo
            sbc CHUNKBEGLO
            sta param4
            lda chunkdesthi
            sbc CHUNKBEGHI
            sta param5
            ldx CHUNKBEGLO
            ldy CHUNKBEGHI
chunkok:    lda #diskio::status::OK
            clc
            rts

dochunkeof:
            .if LOAD_VIA_KERNAL_FALLBACK
            .local closefile
            .local installed

            ENABLE_KERNAL_SERIAL_ROUTINES

            BRANCH_IF_INSTALLED installed
closefile:  jsr getckernal
            bcc closefile

            SKIPWORD
installed:  lda #diskio::status::EOF

            ldy kernaloff + $01
            SET_MEMCONFIG_Y

    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH    
            ldx hi + $01
            ldy lo + $01
    .endif
            sec
            rts

            .else; !LOAD_VIA_KERNAL_FALLBACK

                .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ldy memconfig + $01
            SET_MEMCONFIG_Y
                .elseif LOAD_VIA_KERNAL_FALLBACK & (PLATFORM <> diskio::platform::COMMODORE_16)
            ldy kernaloff + $01
            SET_MEMCONFIG_Y
                .endif

            lda #diskio::status::EOF

    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH    
            ldx hi + $01
            ldy lo + $01
    .endif
            sec
            rts

            .endif; !LOAD_VIA_KERNAL_FALLBACK

        .endif; GETCHUNK_API
    .endmacro; CHUNKSUB

    .if DECOMPRESSOR = DECOMPRESSORS::EXOMIZER

        .macro CHUNKBACKUP
        .endmacro

        .macro CHUNKRESTORE
            ldx #$00
            ldy #$00
        .endmacro

        FORWARD_DECRUNCHING = 1

        get_crunched_byte = getcmem

        .include "decompress/exodecomp.s"

        decompress = decrunch

    .elseif DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH

        .macro CHUNKBACKUP
        .endmacro

        .macro CHUNKRESTORE
            lda #$00; the z-flag needs to be set
        .endmacro

        .include "decompress/pudecomp.s"

    .elseif DECOMPRESSOR = DECOMPRESSORS::DOYNAX_LZ

        .macro CHUNKBACKUP
            stx LASTXREG
        .endmacro

        .macro CHUNKRESTORE
            ldx LASTXREG
        .endmacro

        .include "decompress/doynaxdecomp.s"

    .elseif DECOMPRESSOR = DECOMPRESSORS::BYTEBOOZER

        .macro CHUNKBACKUP
            sty LASTYREG
        .endmacro

        .macro CHUNKRESTORE
            ldy LASTYREG
        .endmacro

        .include "decompress/bbdecomp.s"

    .elseif DECOMPRESSOR = DECOMPRESSORS::LEVELCRUSH

        .macro CHUNKBACKUP
            stx LASTXREG
        .endmacro

        .macro CHUNKRESTORE
            ldx LASTXREG
        .endmacro

        .include "decompress/lcdecomp.s"

    .else
        .error "***** Error: The selected decompressor option is not implemented. *****"
    .endif

        CHUNKSUB
