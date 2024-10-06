
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

loop:       LOADRAW #<filename1, #>filename1
            bcs error
            LOADRAW #<filename2, #>filename2
            bcc loop
            
error:      ldx #COLOUR_BLACK
:           sta BORDERCOLOUR
            stx BORDERCOLOUR
            jmp :-

filename1:  .asciiz "pic1"
filename2:  .asciiz "pic2"
