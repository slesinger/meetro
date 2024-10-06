
.ifndef _BASIC_INC_
_BASIC_INC_ = 1

BASIC_ROM          = $a000
BASIC_ROM_SIZE     = $2000

LINNUM             = $14

TOKEN_SYS          = $9e

PETSCII_RETURN     = $0d
PETSCII_WHITE      = $05
PETSCII_BLUE       = $1f
PETSCII_YELLOW     = $9e
PETSCII_LIGHTGREEN = $99
PETSCII_LIGHTBLUE  = $9a

.if .defined(PLATFORM) & (PLATFORM = 16)
STROUT             = $9088; Output String
GIVAYF             = $9471; Convert Integer in (AC/YR) to FAC
N32768             = $986c; Constant -32768 in floating point
STRLIT             = $9b74; Set Up String
FADD               = $a066; Perform Addition
FSUB               = $a06c; Perform Subtraction
FMULT              = $a078; Perform Multiply of float in (AC/YR) with FAC
TENC               = $a179; Constant 10 in floating point
DIV10              = $a183; Divide FAC#1 by 10
MOV2M              = $a259; Store FAC#1 in memory at (XR/YR)
FDIV               = $a18c; Divide FAC#2 by float in (AC/YR), result in FAC#1
FDIVT              = $a194; Divide float in (AC/YR) by FAC#1, result in FAC#1
MOVAF              = $a291; Copy FAC#1 to FAC#2
FOUT               = $a46f; Convert FAC#1 to ASCII String
.else
STROUT             = $ab1e; Output String
N32768             = $b1a5; Constant -32768 in floating point
GIVAYF             = $b391; Convert Integer in (AC/YR) to FAC
STRLIT             = $b487; Set Up String
FSUB               = $b850; Perform Subtraction
FADD               = $b867; Perform Addition
FMULT              = $ba28; Perform Multiply of float in (AC/YR) with FAC
TENC               = $baf9; Constant 10 in floating point
DIV10              = $bafe; Divide FAC#1 by 10
FDIV               = $bb07; Divide FAC#2 by float in (AC/YR), result in FAC#1
FDIVT              = $bb0f; Divide float in (AC/YR) by FAC#1, result in FAC#1
MOV2M              = $bbd4; Store FAC#1 in memory at (XR/YR)
MOVAF              = $bc0c; Copy FAC#1 to FAC#2
FOUT               = $bddd; Convert FAC#1 to ASCII String
.endif

PIVAL              = $aea8; Constant PI in floating point
GETADR             = $b7f7; Convert FAC to Integer in LINNUM
FONE               = $b9bc; Floating point constant: 1
MOVFM              = $bba2; Move floating point number from memory to FAC#1

.macro LOAD_ADDRESS
                .word * + $02
.endmacro; LOAD_ADDRESS

.macro BASIC_STARTLINE linenumber
                .assert * = $0801, warning, "***** PC is not $0801 *****"
                .word $080d, linenumber
                .byte TOKEN_SYS, "2061", $00, $00, $00
.endmacro; BASIC_STARTLINE

.endif; !_BASIC_INC_
