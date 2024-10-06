
.fileopt comment, "Loader resident code portion"
.fileopt compiler, "CA65"
.fileopt author, "Gunnar Ruthenberg"

__NO_LOADER_SYMBOLS_IMPORT = 1
.include "loader.inc"
.include "kernal.inc"

.include "cpu.inc"
.include "cia.inc"

.include "hal/hal.inc"

.importzp BLOCKDESTLO
.importzp BLOCKINDEX
.importzp LOADYBUF
.importzp YPNTRBUF
.importzp LASTBLKIDX
.importzp LASTBLKSIZ
.importzp LOADDESTPTR
.importzp PACCUBUF
.importzp POLLYOFFSET
.importzp DECOMPVARS

.importzp GETCHUNK_VARS

.if BYTESTREAM
.export loadedtab; the test program visualises this
.endif


.macpack longbranch


.segment "DISKIO"


.if GETCHUNK_API
CHUNKSWTCH                  = GETCHUNK_VARS + $00
LASTPC                      = GETCHUNK_VARS + $01
LASTSP                      = GETCHUNK_VARS + $03
LASTXREG                    = GETCHUNK_VARS + $04; LASTXREG and LASTYREG
LASTYREG                    = GETCHUNK_VARS + $04; are never used at the same time
CHUNKBEGLO                  = GETCHUNK_VARS + $05
CHUNKBEGHI                  = GETCHUNK_VARS + $06
CHUNKENDLO                  = GETCHUNK_VARS + $07
CHUNKENDHI                  = GETCHUNK_VARS + $08
.endif

.if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME
DEVICE_NOT_PRESENT          = $00
.else
DEVICE_NOT_PRESENT          = $01
.endif
; special block numbers
SPECIAL_BLOCK_NOS           = $fe; $fe and $ff
LOAD_FINISHED               = $fe; loading finished successfully
LOAD_ERROR                  = $ff; file not found or illegal track or sector

.if PLATFORM = diskio::platform::COMMODORE_16
LOAD_MODULE_WAIT_FOR_BLOCK_READY_DELAY = $0c
.else
LOAD_MODULE_WAIT_FOR_BLOCK_READY_DELAY = $07
.endif


.ifdef DYNLINK_EXPORT
    .macro DYNLINKEXPORT function, label
        .byte function, .lobyte(label - base), .hibyte(label - base)
    .endmacro

    .segment "JUMPTABLE"; this segment is required by the o65 built-in linker config file
    .segment "DATA"

    .word endresijmptable - *
.else
    .ifdef RESIADDR
            .org RESIADDR - 2
            .word * + 2; load address
    .endif
.endif

.include "resident-jumptable.inc"; this also checks sensibility of options
endresijmptable:


.ifndef DYNLINK_EXPORT
            CHECK_RESIDENT_START_ADDRESS
.endif

            TRANSFER_TABLE

.if LOAD_RAW_API

            ; --- load file without decompression ---
            ; in:  x - .lobyte(filename) or track (depends on FILESYSTEM setting in config.inc)
            ;      y - .hibyte(filename) or sector (depends on FILESYSTEM setting in config.inc)
            ;      c - if LOAD_TO_API != 0, c = 0: load to address as stored in the file
            ;                               c = 1: load to caller-specified address (loadaddrlo/hi)
            ; out: c - set on error
            ;      a - status

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the IO space at $d000 is enabled.
.ifdef loadraw
loadraw2:
.else
loadraw:
.endif

            jsr openfile
    .if LOAD_VIA_KERNAL_FALLBACK
            bcs openerror; only with kernal fallback because only then the call might fail
    .endif
:           jsr _pollblock; avoid going via jump table
            bcc :-
            cmp #diskio::status::OK + 1
    .if LOAD_VIA_KERNAL_FALLBACK
openerror:
    .endif
            rts

.endif; LOAD_RAW_API

.if LOAD_COMPD_API

            ; --- load a compressed file ---
            ; in:  x - .lobyte(filename) or track (depends on FILESYSTEM setting in config.inc)
            ;      y - .hibyte(filename) or sector (depends on FILESYSTEM setting in config.inc)
            ;      c - if DECOMPLOAD_TO_API != 0, c = 0: load to address as stored in the file
            ;                                     c = 1: load to caller-specified address (loadaddrlo/hi, ignored)
            ; out: c - set on error
            ;      a - status

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the IO space at $d000 is enabled.
.ifdef loadcompd
loadcompd2:
.else
loadcompd:
.endif
    .if LOAD_TO_API
            ; there is no DECOMPLOAD_TO_API yet
            clc
    .endif
            jsr openfile

    .if LOAD_VIA_KERNAL_FALLBACK
            ; only with kernal fallback because only then the call might fail
            bcc :+
            rts
:
    .endif
            ; throw exception on stream error
            tsx
    .if GETCHUNK_API
            stx LASTSP
    .else
            stx stackpntr + $01
    .endif
    .if EXCEPTIONS & (LOAD_RAW_API | GETC_API | GETCHUNK_API | OPEN_FILE_POLL_BLOCK_API)
            inc throwswtch + $01; throw exception on stream error
    .endif

    .if GETCHUNK_API
            lda #$ff
            sta CHUNKSWTCH; switch the GETCHUNK_API routines off
            sta CHUNKENDLO; probably fails if the decompressed
            sta CHUNKENDHI; data goes up to and including $ffff
    .endif

    .if LOAD_VIA_KERNAL_FALLBACK
            BRANCH_IF_INSTALLED nodeploadf

        .if CHAINED_COMPD_FILES
            jmp :+
kerncompdl: jsr getckernal; skip load
            jsr getckernal; address
:
        .endif

            jsr decompress; calls getckernal, which sets memory configuration

        .if CHAINED_COMPD_FILES
            ENABLE_KERNAL_SERIAL_ROUTINES
            jsr READST
            beq kerncompdl; branch until EOF
        .endif

            ; close the file
kernalwind: jsr getckernal
            bcc kernalwind
            bcs compdeof; jmp
nodeploadf:
    .endif; LOAD_VIA_KERNAL_FALLBACK

    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_ALL_RAM
    .endif

    .if CHAINED_COMPD_FILES

            jmp jsrdecomp

decomploop: jsr getc; skip load address
            jsr getc
jsrdecomp:  jsr decompress

            ; decompression is finished

            lda getcmemadr + $02
            bne :+
            jsr getnewblk; handle special case that decompressing is as quick as loading,
                         ; this call will fetch the loading finished status and ack loading
:
            ; endaddrlo/hi is one past last loaded data byte
        .if GETC_API
            lda getcmemfin + $01
            cmp endaddrlo
            lda getcmemfin + $02
            sbc endaddrhi
        .else
            lda getcmemadr + $01
            cmp endaddrlo
            lda getcmemadr + $02
            sbc endaddrhi
        .endif
            bcc decomploop; decompress all compressed sub-files that may be inside the compressed file
    .else
            jsr decompress

            ; decompression is finished

            lda getcmemadr + $02
            bne compdeof
            jsr getnewblk; handle special case that decompressing is as quick as loading,
                         ; this call will fetch the loading finished status and ack loading
    .endif; CHAINED_COMPD_FILES

            ; loading and decompression is done
compdeof:   lda #diskio::status::OK
            clc; all ok

            ; fall through
maybethrow:
    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ldy memconfig + $01
            SET_MEMCONFIG_Y
    .endif

    .if LOAD_RAW_API | GETC_API | GETCHUNK_API | OPEN_FILE_POLL_BLOCK_API
throwswtch: ldy #$00
            beq dontthrow
    .endif
            ; throw exception
        .if GETCHUNK_API
            ldx LASTSP
        .else
stackpntr:  ldx #$00
        .endif
            txs
dontthrow:
    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
            bcs :+; skip on error
            ; return the execution address in x/y
            ldx lo + $01
            ldy hi + $01
:
    .endif
            rts

.else; !LOAD_COMPD_API

    .if EXCEPTIONS
maybethrow: ldy LASTPC + $01
            beq :++
            stx :+ + $01
            ; throw exception
            ldx LASTSP
            txs
        .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ldx memconfig + $01
            SET_MEMCONFIG_X
        .endif
:           ldx #$00
:           rts
    .endif; EXCEPTIONS
.endif; LOAD_COMPD_API

.if NONBLOCKING_API

            ; in:  x/y  - if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME, lo/hi to 0-terminated filename string
            ;             if FILESYSTEM = FILESYSTEMS::TRACK_SECTOR, a: track, x: sector
            ;      p4   - block fetch time slice when downloading a block in n*8 rasterlines ($00: get a whole block at a time) XXX TODO
            ;      p5   - main loop time slice when downloading a block in n*8 rasterlines (param4 = $00 or param = $00: none) XXX TODO
            ;      c    - if LOAD_TO_API != 0, c = 0: load to address as stored in the file
            ;                                  c = 1: load to caller-specified address (loadaddrlo/hi)
            ; out: c   - set on error
            ;      a   - status
.ifdef loadrawnb
loadrawnb2:
.else
loadrawnb:
.endif
            lda loadstatus
            eor #diskio::status::BUSY
            beq pollbusy

            SET_IRQ_VECTOR(pollirq)

            jsr openfile
            bcc :+
            sta loadstatus
pollbusy:   rts

:           txa
            pha

            CONTROL_IRQ_MASK

            lda #diskio::status::BUSY
            sta loadstatus

            SET_TIMER(POLLINGINTERVAL_STARTLOAD)
            ACK_TIMER_IRQ
            ENABLE_TIMER_IRQ

            pla
            tax
            lda loadstatus
            clc
            rts

pagain:     sta PACCUBUF

    .if LOAD_VIA_KERNAL_FALLBACK
            BRANCH_IF_NOT_INSTALLED pblkready
    .endif

            SET_TIMER(POLLINGINTERVAL_BLOCKSOON)
            lda PACCUBUF
            ACK_TIMER_IRQ_P
            LEAVE_POLL_HANDLER

pollirq:    BRANCH_IF_BLOCK_NOT_READY pagain
            sta PACCUBUF; no pha/pla because hal-c64 needs to retrieve the flags pushed
                        ; on the stack to determine if an irq has been interrupted
pblkready:  BRANCH_IF_IRQS_PENDING ptoirqspnd

ploadblock: DISABLE_TIMER_IRQ
            lda PACCUBUF
            ACK_TIMER_IRQ_P
pseiclisw3: cli
            pha
            txa
            pha
            tya
            pha
            jsr _pollblock; avoid going via jump table
            jcs perror
            cmp #diskio::status::CHANGING_TRACK
            beq ptrkchan
            SET_TIMER(POLLINGINTERVAL_GETBLOCK)
            jmp :+
ptoirqspnd: jmp pirqspendg
ptrkchan:   SET_TIMER(POLLINGINTERVAL_TRACKCHANGE)
:           SET_IRQ_VECTOR(pollirqdly)
            ACK_TIMER_IRQ
            ENABLE_TIMER_IRQ
            SKIPWORD
perror:     sta loadstatus
            pla
            tay
            pla
            tax
            pla
            LEAVE_POLL_HANDLER

pollirqdly: sta PACCUBUF; no pha/pla because hal-c64 needs to retrieve the flags pushed
                        ; on the stack to determine if an irq has been interrupted
            BRANCH_IF_IRQS_PENDING pirqspendg
            SET_IRQ_VECTOR(pollirq)
            SET_TIMER(POLLINGINTERVAL_BLOCKSOON)
            lda PACCUBUF
            ACK_TIMER_IRQ_P
            LEAVE_POLL_HANDLER

pirqspendg: SET_TIMER(POLLINGINTERVAL_REPOLL)
            lda PACCUBUF
            ACK_TIMER_IRQ_P
            LEAVE_POLL_HANDLER

.endif; NONBLOCKING_API


            ; --- open a file ---
            ; in:  x - .lobyte(filename) or track (depends on FILESYSTEM setting in config.inc)
            ;      y - .hibyte(filename) or sector (depends on FILESYSTEM setting in config.inc)
            ;      c - if LOAD_TO_API != 0, c = 0: load to address as stored in the file
            ;                               c = 1: load to caller-specified address (loadaddrlo/hi)
            ; out: c - set on error
            ;      a - status

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the IO space at $d000 is enabled.
.ifdef openfile
openfile2:
.else
openfile:
.endif

.if !LOAD_ONCE
            sty BLOCKINDEX; parameter buffer
.endif

.if LOAD_TO_API
            lda #OPC_STA_ZP
            bcc :+
            lda #OPC_LDA_ZP
:           sta storeladrl
            sta storeladrh
.endif

.if LOAD_PROGRESS_API | BYTESTREAM
            ldy #$00
    .if MAINTAIN_BYTES_LOADED
            sty bytesloadedlo
            sty bytesloadedhi
    .endif
    .if BYTESTREAM
        .if EXCEPTIONS & LOAD_COMPD_API & (LOAD_RAW_API | GETC_API | GETCHUNK_API | OPEN_FILE_POLL_BLOCK_API)
            sty throwswtch + $01; return errors to the caller
        .endif
        .if GETC_API
            sty getcmemfin + $01
            sty getcmemfin + $02
        .else
            sty getcmemadr + $01
        .endif
            sty getcmemadr + $02
            sty getdbyte + $02
            sty blockindex + $01
            sty LASTBLKIDX
        .if GETCHUNK_API
            sty LASTPC + $01; entry switch; return errors to the caller, no exceptions thrown
            sty CHUNKSWTCH; switch the GETCHUNK_API routines on
            sty CHUNKENDLO
            sty CHUNKENDHI
        .endif
            dey
            sty YPNTRBUF

            lda #.lobyte(getcload)
            ldy #.hibyte(getcload)
            jsr puttoloadb
    .endif
.endif; LOAD_PROGRESS_API | BYTESTREAM

.if MEM_DECOMP_TO_API
    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
            lda #OPC_BIT_ZP
    .else
            lda #OPC_STA_ZP
    .endif
            sta storedadrl
            sta storedadrh
.endif

.if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            GET_MEMCONFIG
            sta memconfig + $01
            GOT_MEMCONFIG = 1
.else
            GOT_MEMCONFIG = 0
.endif

.if LOAD_VIA_KERNAL_FALLBACK

USE_WAIT_FOR_BLOCK_READY_KERNAL = 1

    .if !GOT_MEMCONFIG
            GET_MEMCONFIG
    .endif
            sta kernaloff + $01

            BRANCH_IF_NOT_INSTALLED ldrnotinst
            jmp nofallback

            ; loader is not installed,
            ; so load via KERNAL calls

ldrnotinst: ENABLE_KERNAL_SERIAL_ROUTINES

    .if BYTESTREAM
            lda #.lobyte(getckernal)
            ldy #.hibyte(getckernal)
            jsr puttoloadb
    .endif

    .if LOAD_ONCE
            ldx #KERNALFILENO
            jsr CHKIN
            tay
            php
            bcc :+
            cmp #KERNAL_FILENOTOPEN
            bne :+
            jsr READST
            plp; sec
            tax
            lda #diskio::status::FILE_NOT_OPEN
            bne openfail
:           jsr READST
            plp
            tax

    .else; !LOAD_ONCE

            stx namestrpos + $00

        .if USE_WAIT_FOR_BLOCK_READY_KERNAL
            ENABLE_WAITBUSY_KERNAL
        .endif

        .if LOAD_PROGRESS_API | BYTESTREAM
            ldy BLOCKINDEX; get buffered parameter
        .endif
            sty namestrpos + $01
            ldx #$ff
:           inx
namestrpos = * + $01
            lda a:$00,x
            bne :-
            txa
            pha; name length
            lda #KERNALFILENO
            ldx FA
            ldy #$00
            jsr SETLFS
            pla; name length
            ldx namestrpos + $00
            ldy namestrpos + $01
            jsr SETNAM
            jsr OPEN
            bcc :+
            tax
            cmp #KERNAL_FILEOPEN
            bne :+
           ;sec; error
            lda #diskio::status::FILE_OPEN
            SKIPWORD
:
    .endif; !LOAD_ONCE

            lda #diskio::status::GENERIC_KERNAL_ERROR
            bcc fileopen
openfail:   ldy kernaloff + $01
            SET_MEMCONFIG_Y
           ;sec; error
            rts

fileopen:   ldx #KERNALFILENO
            jsr CHKIN

            ; file not found is not detected at this point
            ; but the kernalgbyt function will return an error
            ; when trying to get the first file data byte
            ; (i.e., after "getting" the load address);
            ; the busy led will keep flashing
    .if LOAD_TO_API
            lda #OPC_STA_ZP
            cmp storeladrl
            beq :+
            lda loadaddrlo
            sta LOADDESTPTR + $00
            lda loadaddrhi
            sta LOADDESTPTR + $01
            jsr CHRIN; skip load
            jsr CHRIN; address
            jmp kernopenok
:
    .endif
            jsr CHRIN
kernalstrl: sta LOADDESTPTR + $00
            sta loadaddrlo
            jsr CHRIN
kernalstrh: sta LOADDESTPTR + $01
            sta loadaddrhi
kernopenok:
    .if GETC_API | GETCHUNK_API
            lda kernaloff + $01
            SET_MEMCONFIG
    .endif    
            jmp retrnokclc

nofallback:

.endif; LOAD_VIA_KERNAL_FALLBACK

            GETBYTE_SETUP
            WAKEUP

.if BYTESTREAM | END_ADDRESS_API
            lda #$00
    .if BYTESTREAM
            ldy #loadedtabe - loadedtab - 1
:           sta loadedtab,y; clear the bitfield denoting the blocks already loaded
            dey
            bpl :-
    .endif
    .if END_ADDRESS
           ;lda #$00
            sta endaddrlo
            sta endaddrhi
    .endif
.endif

.if !LOAD_ONCE
            WAIT_FOR_BLOCK_READY

    .if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME
            ; x still contains the lobyte/track function parameter
            stx BLOCKDESTLO; pointer hibyte is already stored at BLOCKINDEX = BLOCKDESTLO + 1
    .endif

    .if INSTALL_FROM_DISK
        .if FILESYSTEM = FILESYSTEMS::TRACK_SECTOR
            txa
            pha
        .endif
            lda #MODULES::LOADFILE
            jsr sendbyte
            ldx #LOAD_MODULE_WAIT_FOR_BLOCK_READY_DELAY; some delay until the drive side is ready
:           dex
            bne :-
            WAIT_FOR_BLOCK_READY
    .endif

    .if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME

            ldy #$00
sendname:   lda (BLOCKDESTLO),y
            pha
        .if INSTALL_FROM_DISK
            jsr sendbyte; filename and maybe trailing 0
        .else
            SENDBYTE
        .endif
            pla
            beq :+
            iny
            cpy #FILENAME_MAXLENGTH
            bne sendname
:
    .elseif FILESYSTEM = FILESYSTEMS::TRACK_SECTOR

        .if INSTALL_FROM_DISK
            pla
        .else
            txa
        .endif
            jsr sendbyte; track
            lda BLOCKINDEX
            jsr sendbyte; sector

    .endif
            ; no asynchronicity:
            ; the drive must be as quick or quicker than the computer here,
            ; it must get the last data bit in time

            ; clear DATA OUT and CLK OUT so they can be polled later
            ; (CLK IN = 0: drive busy; when CLK IN = 1, DATA IN = 1: drive not present)
            CLEAR_DATA_OUT_CLEAR_CLK_OUT_CLEAR_ATN_OUT

    .if LOAD_VIA_KERNAL_FALLBACK
            ; check whether the loader is still installed
            ldx #LOAD_MODULE_WAIT_FOR_BLOCK_READY_DELAY; some delay until the drive side is ready
:           dex
            bne :-
            BRANCH_IF_DATA_IN_CLEAR retrnokclc

            ; if not, try again with kernal routines
            SET_IO_KERNAL
            ldx BLOCKDESTLO + 0
            ldy BLOCKDESTLO + 1
            jmp ldrnotinst
    .endif

.endif; !LOAD_ONCE

retrnokclc: clc
returnok:   lda #diskio::status::OK; $00
            tax; file descriptor, always 0 since this loader
               ; only supports one open file at a time
            ; no asynchronicity:
            ; the drive must be as quick or quicker than the computer here,
            ; it sets the busy flag which the computer polls after returning
dorts:      rts


            ; --- poll for a block to download ---
            ; in:  nothing
            ; out: c - set on error or eof, cleared otherwise
            ;      a - status

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the IO space at $d000 is enabled.

.if LOAD_VIA_KERNAL_FALLBACK
kernlgberr: cmp #diskio::status::EOF
            beq kernalbeof; carry is set on branch
            sec
            rts
.endif

.ifdef pollblock
pollblock2:
.else
pollblock:
.endif

_pollblock:

.if LOAD_VIA_KERNAL_FALLBACK

LOAD_UNDER_E000_FFFF = 1

            BRANCH_IF_INSTALLED getblnofbk

            ENABLE_KERNAL_SERIAL_ROUTINES

            ldx #$fe; $0100 bytes minus 2 bytes for track/sector link
kernalgblk: jsr kernalgbyt
            bcs kernlgberr

    .if LOAD_UNDER_E000_FFFF | (PLATFORM <> diskio::platform::COMMODORE_16)
        .if (!LOAD_UNDER_D000_DFFF) & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE_Y
        .else
            ENABLE_ALL_RAM_Y
        .endif
    .endif
            ldy #$00
            sta (LOADDESTPTR),y

    .if LOAD_UNDER_E000_FFFF | (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_KERNAL_SERIAL_ROUTINES_Y
    .endif
            
            inc LOADDESTPTR + $00
            bne :+
            inc LOADDESTPTR + $01
:           dex
            bne kernalgblk

            clc
kernalbeof: lda #diskio::status::OK
            rts
getblnofbk:

.endif; LOAD_VIA_KERNAL_FALLBACK

.if OPEN_FILE_POLL_BLOCK_API
            lda #diskio::status::FILE_NOT_OPEN
            BRANCH_IF_IDLE dorts; will set the carry flag if branching
.endif; OPEN_FILE_POLL_BLOCK_API

.if OPEN_FILE_POLL_BLOCK_API | NONBLOCKING_API
            jsr getblock
            bcs err2status
            lda #diskio::status::CHANGING_TRACK
           ;clc
            BRANCH_IF_CHANGING_TRACK dorts
           ;clc
            bcc returnok; jmp
.else; !(OPEN_FILE_POLL_BLOCK_API | NONBLOCKING_API)
            jsr getblock
            bcc returnok
.endif; !(OPEN_FILE_POLL_BLOCK_API | NONBLOCKING_API)

			; translate getblock error code to diskio::status,
			; always returns with carry set to satisfy pollblock return semantics,
            ; accu argument is DEVICE_NOT_PRESENT ($00 or $01),
            ; LOAD_FINISHED ($fe, file loaded successfully),
            ; or LOAD_ERROR ($ff, file not found or illegal t or s)
err2status:
            IDLE

            cmp #LOAD_FINISHED; $fe
            beq returnok; returns with carry set
strobdelay: clc
.if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME
            ; accu = $ff (LOAD_ERROR) -> diskio::status::FILE_NOT_FOUND ($fb)
            ; accu = $00 (DEVICE_NOT_PRESENT) -> diskio::status::DEVICE_NOT_PRESENT ($fc)
            adc #diskio::status::DEVICE_NOT_PRESENT; $fc

            .assert diskio::status::DEVICE_NOT_PRESENT - diskio::status::FILE_NOT_FOUND = 1, error, "Error: Invalid code optimization"
.else
            ; accu = $ff (LOAD_ERROR) -> diskio::status::INVALID_PARAMETERS ($fa)
            ; accu = $01 (DEVICE_NOT_PRESENT) -> diskio::status::DEVICE_NOT_PRESENT ($fc)
            adc #diskio::status::DEVICE_NOT_PRESENT - 1; $fb

            .assert diskio::status::DEVICE_NOT_PRESENT - diskio::status::INVALID_PARAMETERS = 2, error, "Error: Invalid code optimization"
.endif
pollfail:   sec
            rts

getblock:   lda #DEVICE_NOT_PRESENT
            PREPARE_SEND_BLOCK_SIGNAL
            WAIT_FOR_BLOCK_READY
            bmi pollfail; branch if device not present

            BEGIN_SEND_BLOCK_SIGNAL
            ; no asynchronicity
            jsr strobdelay; adc # : sec : rts - waste some time to make sure the drive is ready
            END_SEND_BLOCK_SIGNAL

            jsr get1byte; get block index or error/eof code
.if GETBYTE_SETS_VALUE_FLAGS = 0
            tax
.endif

            ; when enabling this, the PRINTHEX symbol must be marked as an import in the dynlink library -
            ; uncomment the PRINTHEX import line in ../Makefile for this purpose.
            ; note: currently collides with C-64 memory config check, so use C-16 for debugging
DEBUG_BLOCKLOAD = 0

.if DEBUG_BLOCKLOAD
            .import PRINTHEX

            pha
            lda #$ff
            ldx #$08
            jsr PRINTHEX
            pla
            ldx #$00
            jsr PRINTHEX            
.endif; DEBUG_BLOCKLOAD

            sta BLOCKINDEX
            bne not1stblk

            ; first block: get load address
            jsr get1byte; block size
            pha
            jsr get1byte; load address lo

.if DEBUG_BLOCKLOAD
            ldx #$04
            jsr PRINTHEX
.endif; DEBUG_BLOCKLOAD
            
storeladrl: sta loadaddrlo; is changed to lda on load_to
            sta BLOCKDESTLO
            jsr get1byte; load address hi

.if DEBUG_BLOCKLOAD
            ldx #$02
            jsr PRINTHEX
.endif; DEBUG_BLOCKLOAD

storeladrh: sta loadaddrhi; is changed to lda on load_to
            sta storebyte + $02

            pla; block size
            sec
            sbc #$02
            bcs fin1stblk; jmp

not1stblk:  cmp #SPECIAL_BLOCK_NOS; check for special block numbers: LOAD_FINISHED ($fe, loading finished successfully), LOAD_ERROR ($ff)
.if LOAD_PROGRESS_API | END_ADDRESS | LOAD_UNDER_D000_DFFF
            jcs polldone
.else
            bcs polldone
.endif
            ; calculate the position in memory according to the block number,
            ; this is performing: pos = loadaddr + blockindex * 254 - 2
            lda loadaddrlo
           ;clc
            sbc BLOCKINDEX
            php
            clc
            sbc BLOCKINDEX
            sta BLOCKDESTLO
            lda loadaddrhi
            adc BLOCKINDEX
            plp
            sbc #$01
            sta storebyte + $02

            jsr get1byte; get block size - 1

fin1stblk:
.if DEBUG_BLOCKLOAD
            ldx #$06
            jsr PRINTHEX
.endif; DEBUG_BLOCKLOAD

.if MAINTAIN_BYTES_LOADED
            pha; block size - 1
            sec
            adc bytesloadedlo
            sta bytesloadedlo
            bcc :+
            inc bytesloadedhi
:           pla; block size - 1
.endif
            ; a contains block size - 1
.if BYTESTREAM
            sta blocksize
.endif
            tax; a contains block size - 1
            eor #$ff
            tay; 0 - block size
            sec
            txa
            adc BLOCKDESTLO
            sta storebyte + $01
            bcs :+
            dec storebyte + $02
:
            ; getblock loop/get1byte subroutine
.if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ; trading off speed for size: choose one of two getblock loops
            ; depending on the destination of the data to be downloaded
            lda storebyte + $02
            cmp #.hibyte($cf00)
            bcc :+
            cmp #.hibyte($e000)
            bcc getblockio
:
.endif; LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)

            lda #OPC_STA_ABSY; enable getblock loop
            SKIPWORD
get1byte:   lda #OPC_RTS     ; disable getblock loop
            sta getbloopsw
getblkloop: GETBYTE
getbloopsw: 
storebyte:  sta a:$00,y      ; 5
            iny              ; 2
            bne getblkloop   ; 3
                             ; = 10
.ifndef DYNLINK_EXPORT
            .assert .hibyte(* + 1) = .hibyte(getblkloop), warning, "***** Performance warning: Page boundary crossing (getblkloop). Please relocate the DISKIO segment a few bytes up or down. *****"
.endif

.if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            beq gotblock; jmp

getblockio: lda storebyte + $01
            sta storebytio + $01
            lda storebyte + $02
            sta storebytio + $02
getblklpio: GETBYTE
            STOREBYTE_ALLRAM
            iny
            bne getblklpio

    .ifndef DYNLINK_EXPORT
            .assert .hibyte(* + 1) = .hibyte(getblklpio), warning, "***** Performance warning: Page boundary crossing (getblklpio). Please relocate the DISKIO segment a few bytes up or down. *****"
    .endif

gotblock:
.endif; LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)

.if BYTESTREAM
            lda BLOCKINDEX
            jsr loadedsub
            ora loadedtab,y
            sta loadedtab,y; mark this block as loaded
.endif

.if END_ADDRESS
            ; update end address
            ldx storebyte + $01
            cpx endaddrlo
            ldy storebyte + $02
            iny
            tya
            sbc endaddrhi
            bcc :+
            stx endaddrlo
            sty endaddrhi
:
.endif; END_ADDRESS

.if DEBUG_BLOCKLOAD
            sec
    .if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME
            lda #diskio::status::INTERNAL_ERROR - diskio::status::DEVICE_NOT_PRESENT
    .else
            lda #diskio::status::INTERNAL_ERROR - diskio::status::DEVICE_NOT_PRESENT + 1
    .endif
            ldy BLOCKINDEX
.else; !DEBUG_BLOCKLOAD
            clc; ok
.endif; !DEBUG_BLOCKLOAD

polldone:   ENDGETBLOCK; restore clock configuration
            rts

.if INSTALL_FROM_DISK | (FILESYSTEM <> FILESYSTEMS::DIRECTORY_NAME)
sendbyte:   SENDBYTE
            rts
.endif

.if (!GETC_API) & (GETCHUNK_API | LOAD_COMPD_API) & CHAINED_COMPD_FILES
getc:
    .if (DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH) | (DECOMPRESSOR = DECOMPRESSORS::DOYNAX_LZ)
            jmp (toloadbt + $01)
    .else
            jmp (toloadb0 + $01)
    .endif
.endif

.if GETC_API
            ; --- get a byte from the raw file stream ---
            ; in:  nothing
            ; out: a - value if c = 0, status otherwise
            ;      c - error or EOF

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the
            ; IO space at $d000 is disabled if data is accessed at $d000..$dfff.
    .ifdef getc
getc2:
    .else
getc:
    .endif

getcjmp:    jmp getcload
.endif; GETC_API


.if GETCHUNK_API

            ; --- get an uncompressed chunk from the compressed file stream ---
            ; in:  x/y   - lo/hi of chunk size
            ; out: a     - status
            ;      x/y   - lo/hi of chunk address
            ;      p4/p5 - lo/hi of retrieved chunk size
            ;      c     - set on error

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the
            ; IO space at $d000 is disabled if data is accessed at $d000..$dfff.
    .ifdef getchunk
getchunk2:
    .else
getchunk:
    .endif
            clc
            txa
            adc CHUNKENDLO
            sta CHUNKENDLO
            tya
            adc CHUNKENDHI
            sta CHUNKENDHI
            jmp decompress
.endif; GETCHUNK_API

.if LOAD_VIA_KERNAL_FALLBACK

            ; get a byte from the file's byte-stream using the KERNAL API
            ; sets memory configuration and buffers the y register
    .if BYTESTREAM
getckernal: sty LOADYBUF

            ENABLE_KERNAL_SERIAL_ROUTINES

            jsr kernalgbyt

        .if (!LOAD_UNDER_D000_DFFF) & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE_Y
        .else
            ENABLE_ALL_RAM_Y
        .endif

            bcc :+
            ldy kernaloff + $01; only on errors on subsequent getc calls, restore the previous
            SET_MEMCONFIG_Y    ; memory configuration which had been active before calling openfile
:
            ldy LOADYBUF
            rts

    .endif; BYTESTREAM

            ; get a byte from the file using the KERNAL API,
            ; the KERNAL ROM must be enabled
            ; in  : nothing
            ; out : a - status on error
            ;     : c - set on error
kernalgbyt: jsr READST; get KERNAL status byte
            bne kernalerr
    .if MAINTAIN_BYTES_LOADED
            inc bytesloadedlo
            bne @0
            inc bytesloadedhi
@0:
    .endif
    
    .if USE_WAIT_FOR_BLOCK_READY_KERNAL
            WAIT_FOR_BLOCK_READY_KERNAL
    .endif
            jsr CHRIN
            clc
            rts

            ; EOF or error, close file
kernalerr:  pha; KERNAL status byte
            lda #KERNALFILENO
            jsr CLOSE
            jsr CLRCHN

    .if END_ADDRESS_API
        .if MAINTAIN_BYTES_LOADED
            clc
            lda bytesloadedlo
            adc loadaddrlo
            sta endaddrlo
            lda bytesloadedhi
            adc loadaddrhi
            sta endaddrhi
        .else
            lda LOADDESTPTR + $00
            sta endaddrlo
            lda LOADDESTPTR + $01
            sta endaddrhi
        .endif
    .endif; !END_ADDRESS_API

kernaloff:  lda #$00
            SET_MEMCONFIG
            pla; KERNAL status byte
            cmp #KERNAL_STATUS_EOF
            bne kernaloerr
            ; EOF
            lda #diskio::status::EOF
           ;sec
            rts
kernaloerr: sec
            tax
            bpl :+; branch if not illegal track or sector, or device not present
            cmp #KERNAL_STATUS_ILLEGAL_TRACK_OR_SECTOR
            beq kernillts
            bne kerndevnp
:           and #KERNAL_STATUS_FILE_NOT_FOUND
            beq kerngenerc; branch if error not known, generic KERNAL error
    .if EXCEPTIONS
            lda #diskio::status::FILE_NOT_FOUND; this is also returned if the file starts on an illegal track or sector
            SKIPWORD
kernillts:  lda #diskio::status::ILLEGAL_TRACK_OR_SECTOR
            SKIPWORD
kerndevnp:  lda #diskio::status::DEVICE_NOT_PRESENT
            SKIPWORD
kerngenerc: lda #diskio::status::GENERIC_KERNAL_ERROR
            jmp maybethrow
    .else; !EXCEPTIONS
            lda #diskio::status::FILE_NOT_FOUND; this is also returned if the file starts on an illegal track or sector
            rts
kernillts:  lda #diskio::status::ILLEGAL_TRACK_OR_SECTOR
            rts
kerndevnp:  lda #diskio::status::DEVICE_NOT_PRESENT
            rts
kerngenerc: lda #diskio::status::GENERIC_KERNAL_ERROR
            rts
    .endif; !EXCEPTIONS

.endif; LOAD_VIA_KERNAL_FALLBACK

.if BYTESTREAM | HAS_DECOMPRESSOR
            ; get a byte from the file's byte-stream, read from memory

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the
            ; IO space at $d000 is disabled if data is accessed at $d000..$dfff.
getcmem:
getcmemadr: lda a:$00
    .if GETC_API
            clc
    .endif
            inc getcmemadr + $01
            beq getcmeminc
            rts; one extra byte for one cycle less

getcmeminc: inc getcmemadr + $02

    .if GETC_API
            sty LOADYBUF
getcmemchk: pha; current stream byte
            lda getcmemadr + $02
            cmp endaddrhi
            bne :++
            sta getcmemfin + $02
           ;sec
            lda endaddrlo
            sbc getcmemadr + $01
            beq setcmemeof
            sta YPNTRBUF
            lda getcmemadr + $01
            sta getcmemfin + $01
            lda #.lobyte(getcmemfin)
            ldy #.hibyte(getcmemfin)
:           jsr puttoloadb
:
        .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_ALL_RAM_Y
        .endif

            pla; current stream byte
            ldy LOADYBUF
            clc
            rts

            ; get a byte from the file byte-stream's last block, read from memory

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the
            ; IO space at $d000 is disabled if data is accessed at $d000..$dfff.
getcmemfin: lda a:$00
            inc getcmemfin + $01
            clc
            dec YPNTRBUF
            bne getcmemfin - $01
            pha
            sty LOADYBUF
setcmemeof: lda #.lobyte(getcmemeof)
            ldy #.hibyte(getcmemeof)
            bne :--; jmp

            ; return eof after the file's byte-stream has ended

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call restores
            ; the previous memory configuration which was active before
            ; calling openfile.
getcmemeof:
        .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            lda memconfig + $01
            SET_MEMCONFIG
        .endif
            lda #diskio::status::EOF
            sec
    .endif; GETC_API

            rts
.endif; BYTESTREAM | HAS_DECOMPRESSOR

.if BYTESTREAM
            ; get a byte from the file's byte-stream, download a file block before if possible

            ; C-64: When LOAD_UNDER_D000_DFFF is non-0, this call assumes that the
            ; IO space at $d000 is disabled if data is accessed at $d000..$dfff.
getcload:   sty LOADYBUF

dogetcload: ldy YPNTRBUF
getdbyte:   lda a:$00,y
    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE_Y
    .endif
            inc YPNTRBUF
            beq blockindex; branch to process next stream block
            BRANCH_IF_BLOCK_READY getnewblk; download block as soon as possible

    .if GETC_API
            clc
    .endif
loadbytret:
    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_ALL_RAM_Y
        .if GETC_API
            bcc :+
            ldy memconfig + $01   ; and only on errors on subsequent getc calls, it restores the previous
            SET_MEMCONFIG_Y       ; memory configuration which had been active before calling openfile
:
        .endif
    .endif
            ldy LOADYBUF
            rts

firstblock: ; set stream buffer pointers
            lda #$ff
            eor blocksize
            sta YPNTRBUF
            lda storebyte + $01
            sta getdbyte + $01
            lda storebyte + $02
            sta getdbyte + $02
            inc blockindex + $01; $00 -> $01, first block has been downloaded,
                                ; set flag to skip waiting for the next block download

    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_ALL_RAM
    .endif
            bne dogetcload; jmp: return first file byte and maybe download another block before that

blockindex: ldy #$00; block index and flag to skip waiting for the next block to download,
                    ; the value is increased for every loaded block and set to $ff after loading is finished
            stx xbuf + $02
            bne chkloaded; do not wait for block here if first block has been loaded already

            ; first block
            SKIPBYTE
waitforblk: pla; current stream byte
            jsr getnewblk2
            bcs xbuf + $01; branch on error
    .if LOAD_UNDER_D000_DFFF & (PLATFORM <> diskio::platform::COMMODORE_16)
            ENABLE_IO_SPACE_Y
    .endif
            ldy blockindex + $01
            beq firstblock

chkloaded:  pha; current stream byte
            tya
            iny; block index
            beq xbuf - $01; $ff = last block had been loaded already, clear carry: ok
            jsr loadedsub
            and loadedtab,y
            beq waitforblk; branch if the next block in the stream is not yet loaded

            ; advance stream pointer
            ; this is not done after the first file block had been downloaded
            lda #$fd
            ldy blockindex + $01
            cpy LASTBLKIDX
            bne :+
           ;sec
            lda LASTBLKSIZ
:           tax
            sec
            adc getdbyte + $01
            sta getdbyte + $01
            bcc :+
            inc getdbyte + $02
:           lda getdbyte + $02

            txa
            eor #$ff
            sta YPNTRBUF

            inc blockindex + $01
            bne xbuf - $01; jmp; clear carry: ok

getnewblk:  stx xbuf + $02
getnewblk2: pha; current stream byte
            jsr getblock
            bcs gotstatus; branch if block number is DEVICE_NOT_PRESENT ($00 or $01), LOAD_FINISHED ($fe), LOAD_ERROR ($ff, file not found or illegal t or s)

            lda BLOCKINDEX; update last
            cmp LASTBLKIDX; block index
            bcc xbuf + $00; and size
            sta LASTBLKIDX
blocksize = * + 1
            lda #$00
            sta LASTBLKSIZ

            clc; ok
xbuf:       pla; current stream byte
            ldx #$00
    .if (LOAD_UNDER_D000_DFFF | GETC_API) & (PLATFORM <> diskio::platform::COMMODORE_16)
            jmp loadbytret; restore memory configuration
    .else
            ldy LOADYBUF
            rts
    .endif

            ; the status byte has been received, end loading
gotstatus:  pha; DEVICE_NOT_PRESENT ($00), LOAD_FINISHED ($fe), or LOAD_ERROR ($ff, file not found or illegal t or s)

            ; switch to memory-read getc routine
            clc
            lda YPNTRBUF
            adc getdbyte + $01
            sta getcmemadr + $01; current stream buffer position lo
    .if GETC_API
            sta getcmemfin + $01
    .endif
            lda YPNTRBUF
            bne :+
            sec
:           lda #$00
            adc getdbyte + $02; current stream buffer position hi
    .if GETC_API
            sta getcmemfin + $02
    .endif
            jsr setgetcmem

            lda #$ff
            sta blockindex + $01; mark load finished

            pla; DEVICE_NOT_PRESENT ($00), LOAD_FINISHED ($fe), or LOAD_ERROR ($ff, file not found or illegal t or s)
            jsr err2status
           ;tax; cmp #diskio::status::OK
    .if GETC_API
           ;sec
            bne :+
            ; EOF
            pla; current stream byte
            ldx xbuf + $02
            jmp getcmemchk; will clear carry to return ok
:
    .else
            beq xbuf - $01; clear carry: ok
    .endif
            ; an error occured, stop loading and/or decompressing, return error to the caller,
            ; a = status
           ;sec
    .if (GETC_API | GETCHUNK_API)
            ; the current stream byte is still on the stack
            tsx
            inx
            txs
    .endif
    .if EXCEPTIONS
            jmp maybethrow
    .else
            rts
    .endif


loadedsub:  tay
            and #%00000111
            tax
            tya
            lsr
            lsr
            lsr
            tay
            lda loadedor,x
            rts

loadedor:   .byte $80, $40, $20, $10, $08, $04, $02, $01; or-values for the bitfield
loadedtab:  .res 32, 0; bitfield for already-loaded blocks, 256 bits for 64 kB minus 514 (256*2 + 2) bytes of memory
loadedtabe:
.endif; BYTESTREAM

.if MEM_DECOMP_API

            ; --- decompress a compressed file from memory ---
            ; in:  a   - compression method (ignored)
            ;      x/y - lo/hi of compressed file in memory
            ;      c   - if MEMDECOMP_TO_API != 0, c = 0: decompress to address as stored in the file
            ;                                      c = 1: decompress to caller-specified address (loadaddrlo/hi)

            ; out: undefined
.ifdef memdecomp
memdecomp2:
.else
memdecomp:
.endif
            stx getcmemadr + $01
    .if BYTESTREAM
            tya
            jsr setgetcmem
        .if GETC_API
            lda #$00
            sta endaddrhi
        .endif
    .else
            sty getcmemadr + $02
    .endif

    .if CHAINED_COMPD_FILES
            jmp domemdecomp


            ; --- decompress a chained compressed file from memory ---
            ; --- use this for subsequent decompression in a chained compressed file ---
            ; in:  a - compression method (ignored)
            ;      c - if MEMDECOMP_TO_API != 0, c = 0: decompress to address as stored in the file
            ;                                    c = 1: decompress to caller-specified address (loadaddrlo/hi)
            ; out: undefined
.ifdef cmemdecomp
cmemdecomp2:
.else
cmemdecomp:
.endif
        .if GETC_API
            lda #$00
            sta endaddrhi
        .endif
            jsr getcmem; skip subfile load address,
            jsr getcmem; the state of the c-flag is preserved

domemdecomp:
    .endif; CHAINED_COMPD_FILES

    .if MEM_DECOMP_TO_API
        .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
            lda #OPC_BIT_ZP
        .else
            lda #OPC_STA_ZP
        .endif
            bcc :+
            lda #OPC_LDA_ZP
:           sta storedadrl
            sta storedadrh
    .endif

    .if GETCHUNK_API
            lda #$ff
            sta CHUNKSWTCH; switch the GETCHUNK_API routines off
            sta CHUNKENDLO; probably fails if the decompressed
            sta CHUNKENDHI; data goes up to and including $ffff
                          ; (but this probably happens anyways because of the in-place depacking data offset of ~3 bytes,
                          ; making the compressed data load to $00, $01 and the zeropage after destination pointer wrap)
    .endif

    .if DECOMPRESSOR = DECOMPRESSORS::PUCRUNCH
            jsr decompress
            ; return the execution address in x/y
            ldx lo + $01
            ldy hi + $01
            rts
    .else
            jmp decompress
    .endif

.endif; MEM_DECOMP_API

.if UNINSTALL_API

            ; --- uninstall the loader ---
            ; in:  nothing
            ; out: undefined
    .ifdef uninstall
uninstall2:
    .else
uninstall:
    .endif
            DO_UNINSTALL
            rts
.endif; UNINSTALL_API

.if HAS_DECOMPRESSOR
			.include "resident/decompress.s"
.endif; HAS_DECOMPRESSOR

.if BYTESTREAM | HAS_DECOMPRESSOR
setgetcmem: sta getcmemadr + $02
            lda #.lobyte(getcmem)
            ldy #.hibyte(getcmem)

            ; patch the various calls to the getchar routines,
            ; one out of five functions is used:
            ; getcmem    - get a char from memory after the whole file is loaded
            ; getcmemfin - get a char from the last file block in memory
            ; getcmemeof - get EOF
            ; getcload   - get a char and before that, download a file block if possible/necessary
            ; getckernal - get a char when using the KERNAL API as fallback
puttoloadb:
    .if GETC_API
            sta getcjmp + $01
            sty getcjmp + $02
    .endif
    .if DECOMPRESSOR <> DECOMPRESSORS::NONE
            SETDECOMPGETBYTE
    .endif
            rts
.endif; BYTESTREAM | HAS_DECOMPRESSOR

.ifndef DYNLINK_EXPORT
            CHECK_RESIDENT_END_ADDRESS
.endif
