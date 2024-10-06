
.include "standard.inc"

.include "loader.inc"

.if PLATFORM = diskio::platform::COMMODORE_16
    .include "ted.inc"
.else
    .include "vic.inc"
.endif


bitmap     = $4000
screen     = $6000

one_bits   = COLOUR_DARKGREY
zero_bits  = COLOUR_MEDIUMGREY

.if FILESYSTEM = FILESYSTEMS::TRACK_SECTOR
id         = $0400
.endif; FILESYSTEM = FILESYSTEMS::TRACK_SECTOR


            MEMSET #bitmap, #BITMAP_SIZE, #BITMAP_BACKGROUND

.if PLATFORM = diskio::platform::COMMODORE_16
            lda #$00   ; disable all interrupts,
            sta TED_IMR; as KERNAL routines do cli
            lda TED_IRR; with LOAD_VIA_KERNAL_FALLBACK
            sta TED_IRR

            MEMSET #screen, #SCREEN_SIZE, #MAKE_HIRES_INTENSITIES(one_bits, zero_bits)
            MEMSET #screen + PAD(SCREEN_SIZE), #SCREEN_SIZE, #MAKE_HIRES_COLOURS(one_bits, zero_bits)
.else
            lda #CIA_CLR_INTF | EVERY_IRQ; disable KERNAL timer interrupts,
            sta CIA1_ICR                 ; as KERNAL routines do cli
            bit CIA1_ICR                 ; with LOAD_VIA_KERNAL_FALLBACK

            MEMSET #screen, #SCREEN_SIZE, #MAKE_HIRES_COLOURS(one_bits, zero_bits)
.endif

            DISPLAY_HIRES_BITMAP bitmap, screen

            lda #COLOUR_BLACK
            sta BORDERCOLOUR

            LOADER_INSTALL
            bcs error


side1file:  lda #COLOUR_BLACK
            sta BORDERCOLOUR

.if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME

			LOADRAW #<filename1, #>filename1; filename1 is only found on the first side
			bcc side2file; branch on success
			cmp #diskio::status::FILE_NOT_FOUND
            bne error

.elseif FILESYSTEM = FILESYSTEMS::TRACK_SECTOR

ID = $0400

			LOADRAW trackid, sectorid; load side ID
			bcs waitside1
			lda id
			cmp #'a'; $41
			bne waitside1

			LOADRAW track1, sector1
			bcc side2file; branch on success

.endif; FILESYSTEM = FILESYSTEMS::TRACK_SECTOR

waitside1:	inc BORDERCOLOUR
			jmp side1file


side2file:  lda #COLOUR_BLACK
            sta BORDERCOLOUR

.if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME

			LOADRAW #<filename2, #>filename2; filename2 is only found on the second side
			bcc side1file; branch on success
			cmp #diskio::status::FILE_NOT_FOUND
            bne error

.elseif FILESYSTEM = FILESYSTEMS::TRACK_SECTOR

			LOADRAW trackid, sectorid; load side ID
			bcs waitside2
			lda id
			cmp #'b'; $42
			bne waitside2

			LOADRAW track2, sector2
			bcc side1file; branch on success

.endif; FILESYSTEM = FILESYSTEMS::TRACK_SECTOR

waitside2:  inc BORDERCOLOUR
			jmp side2file


error:      ldx #COLOUR_BLACK
:           sta BORDERCOLOUR
            stx BORDERCOLOUR
            jmp :-

.if FILESYSTEM = FILESYSTEMS::DIRECTORY_NAME
filename1:  .asciiz "pic1"
filename2:  .asciiz "pic2"
.elseif FILESYSTEM = FILESYSTEMS::TRACK_SECTOR
trackid:    .byte 17
sectorid:   .byte 7
track1:     .byte 17
sector1:    .byte 9
track2:     .byte 17
sector2:    .byte 9
.endif; FILESYSTEM = FILESYSTEMS::TRACK_SECTOR
