
.ifndef _KERNAL_INC_
_KERNAL_INC_ = 1

DEVICE_SCREEN                          = $03

INDEX1                                 = $22; utility pointer area
FRFTOP                                 = $33; pointer: bottom of string storage
FRESPC                                 = $35; utility string pointer
FACEXP                                 = $61; FAC exponent
FACHO                                  = $62; FAC mantissa
STRDSC                                 = $64; temporary string descriptor
 STRDSC_LEN                            = 0
 STRDSC_PTR                            = 1
FACSGN                                 = $66; FAC sign
STATUS                                 = $90
NUMOPENFILES                           = $98

CINV                                   = $0314
CBINV                                  = $0316


.if .defined(PLATFORM) & (PLATFORM = 16)

DFLTO                                  = $99; default output device
FA                                     = $ae; current io device
USE4DY                                 = $f9

PALETTE                                = $07f9
PALETTE_DEFAULT                        = $ff
PALETTE_USER                           = $00

CLRSCR                                 = $d88b

IBASIN                                 = $0322; CHRIN vector
IBSOUT                                 = $0324; CHROUT vector

.else; !(.defined(PLATFORM) & (PLATFORM = 16))

KERNAL_ROM                             = $e000
KERNAL_ROM_SIZE                        = $2000

ARG                                    = $69
DFLTO                                  = $9a; default output device
FA                                     = $ba; current io device
PNT                                    = $d1
PNTR                                   = $d3
LDTB1                                  = $d9

COLOR                                  = $0286
PAL_NTSC                               = $02a6; 0: NTSC

NMINV                                  = $0318
IBASIN                                 = $0324; CHRIN vector
IBSOUT                                 = $0326; CHROUT vector

POLYX                                  = $e059
CLRSCR                                 = $e544
ROWSLO                                 = $ecf0

.endif; !(.defined(PLATFORM) & (PLATFORM = 16))


LSTNSA                                 = $ff93
 SA_TALK                               = $20
 SA_UNTALK                             = $3f
 SA_LISTEN                             = $40
 SA_UNLISTEN                           = $5f
 SA_OPENCHANNEL                        = $60
 SA_CLOSE                              = $e0
 SA_OPEN                               = $f0
TKSA                                   = $ff96
IECIN                                  = $ffa5
IECOUT                                 = $ffa8
UNTLK                                  = $ffab
UNLSTN                                 = $ffae
LISTEN                                 = $ffb1
TALK                                   = $ffb4
READST                                 = $ffb7
 KERNAL_STATUS_ILLEGAL_TRACK_OR_SECTOR = %11000000; returned if a mid-file block is on an illegal track or sector
 KERNAL_STATUS_DEVICE_NOT_PRESENT      = %10000000; this is also returned if a file starts on an illegal track or sector
 KERNAL_STATUS_EOF                     = %01000000
 KERNAL_STATUS_FILE_NOT_FOUND          = %00000010
SETLFS                                 = $ffba
 COMMAND_ERROR_CHANNEL                 = $0f
SETNAM                                 = $ffbd
OPEN                                   = $ffc0
 KERNAL_TOOMANYFILES                   = $01
 KERNAL_FILEOPEN                       = $02
 KERNAL_FILENOTOPEN                    = $03
 KERNAL_FILENOTFOUND                   = $04
 KERNAL_DEVICENOTPRESENT               = $05
 KERNAL_NOTINPUTFILE                   = $06
 KERNAL_NOTOUTPUTFILE                  = $07
 KERNAL_MISSINGFILENAME                = $08
 KERNAL_ILLEGALDEVICENUMBER            = $09
CLOSE                                  = $ffc3
CHKIN                                  = $ffc6
CHKOUT                                 = $ffc9
CLRCHN                                 = $ffcc
CHRIN                                  = $ffcf
CHROUT                                 = $ffd2
LOAD                                   = $ffd5
SAVE                                   = $ffd8

.endif; !_KERNAL_INC_
