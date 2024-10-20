.segment MAIN []
#import "loadersymbols-c64.inc"


          *= install  // same as install jsr
.var installer_c64 = LoadBinary("tools/krill194/loader/build/install-c64.prg", BF_C64FILE)
installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)
//---------------------------------------
          *= loadraw  // same as loader code block address
.var loader_c64 = LoadBinary("tools/krill194/loader/build/loader-c64.prg", BF_C64FILE)
loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)
//---------------------------------------
          *= $1000
.var soundtrack = LoadBinary("tools/KrillsLoader/attitude-guides/irq-loader-usage-tutorial/soundtrack.prg", BF_C64FILE)
soundtrack_ptr: .fill soundtrack.getSize(), soundtrack.get(i)
//---------------------------------------
    *= $c000
    #import "decruncher.asm"

    *= $c100
          
    jsr init  // Initialise IRQ loader and setup IRQ interrupt routine

loop:
    inc $d020
    clc
    ldx #<file1  // Vector pointing to a string containing loaded file name
    ldy #>file1
    jsr loadraw  // Load file to a memory address of $A000
    // Decrunch loaded file into $6000:
    ldx #>$a000
    ldy #<$a000
    jsr decrunch
    jsr koala

    clc
    ldx #<file2
    ldy #>file2
    jsr loadraw
    // Decrunch loaded file into $2000:
    ldx #>$a000
    ldy #<$a000
    jsr decrunch
    jsr hires

    jmp loop

//---------------------------------------
file1:    .text "AA"  //filename on diskette
          .byte $00
file2:    .text "AB"  //filename on diskette
          .byte $00
//---------------------------------------
// Do not forget to include the source code file with all auxiliary routines:
#import "proc.asm"

//---------------------------------------
.file [name="krillsteststart.prg", segments="MAIN"]

.disk [filename="krillstestdisk.d64", name="HONDANI", id="2025!"]
{
[name="START", type="prg", segments="MAIN" ],
// [name="START", type="prg", prgFiles="krillsteststart.prg" ],
[name="AA", type="prg", prgFiles="tools/KrillsLoader/attitude-guides/irq-loader-usage-tutorial/aa" ],
[name="AB", type="prg", prgFiles="tools/KrillsLoader/attitude-guides/irq-loader-usage-tutorial/ab" ],
}