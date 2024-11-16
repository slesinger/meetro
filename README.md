# Hondani Meetro

## Issues
- video blika
- results ikony
- pregenerovat nahodne velka pismena, schazi tam pravy sloupec
- zapakovat prg, vejde se nam to na disketu?
- vylepsit google font - pixel-detail

### Nice to have
- loader by mel umet switchovat banky
- fryba by mohl mit font optimalizovany pro sebe. Mozna to nebude velky rozdil.

## Build process

### Build disk image
/usr/bin/java -jar /home/honza/projects/c64/pc-tools/kickass/KickAss.jar build-floppy.asm



-autostartprgmode 1 -autostart ${kickassembler:buildFilename} -moncommands ${kickassembler:viceSymbolsFilename}


## Disk layout
There will be following files visible on the disk
- `fastload.prg` - the first program that will be loaded and autostarted
- `keyb.prg` - the main program, call it rather "START ME PLEASE    PRG"
Remaining data will be stored as sectors and will not be visible from BAM

## How the memory is loaded over time

See `memory.ods`

### Autostart loads
Will bootstrap first code
 - from 0700 where there are $20 and petsci screen 0798-07e8
   load_screen1.bin
 - from 0800 keyb (prg)

 ### keyb (prg)
As a starting part it will also have basic SYS command in case autostart will not work.
This consists of keyb code and its texts.
The load size has to be small, to execute initial part and install loader.

 - 0800-0bfff keyb code with fastloader
 - 9000-91fff fastloader, Fastload routine that will be copied to $9000 for reuse in other parts.
Execution point is $0810
Will load font_matrix (prg)

## font_matrix (prg)

 - 1000 - 1bfff music
 - ????0800 - 0dff lookups (6 pages)    !!!! has to play with previous part
 - 4000 - 4c8f font (12 pages)
 - code (4 pages)
 - 9000-91ff fastloader

 Can further load during run of the part:
    - 0800 - 0dff lookups

transition to the next part will be with blank screen and music playing

## Krill's Fastloader

### Compile library binaries

In tools/krill194/loader/src, enter ```make prg INSTALL=0e00 RESIDENT=9000 ZP=90```


## video

Possible SID locations:
$1000 - $1bff

Possible code locations:
$1c00 - $1fff, $9200 - $9fff

Possible screen memory locations:  (Bank1 3+6, Bank2 14, Bank3 2+8, Bank4 0), 5+28 usable frames
$0400  fryba 1
$0800  fryba 2
$0c00  fryba 3
SID  $1000-$1bff
Code $1c00-$1fff
Font $2000-$27ff
$2800 a
$2c00 b
$3000 c
$3400 d
$3800 e
$3c00 f

$4000 - $47ff font
$4800, each $0400

$8000 - $87ff font
$8800 2 fryba 4
$8c00 3 fryba 5
Unusefull font shadow $9000-$9fff, to be used for loader code
$a000 8
$a400 9
$a800 a
$ac00 b
$b000 c
$b400 d
$b800 e
$bc00 f

Whole bank4 is beeter to use for something else than frames
$c000 - $c7ff decided not to use
$c800 possible frame, does not make sense
$cc00 possible frame, does not make sense
$d000 - $dfff completely unusable
$e000 ? kernal  kernal cannot be disabled unless interrupts are disabled
$e400 ? kernal
$e800 ? kernal
$ec00 ? kernal

Out of which there are following video frame blocks:
$0400 - $0fff 3 frames Fryba1
$2800 - $3fff 6 frames block a1
$4800 - $7fff 14frames block b
($8800 - $8fff 2 frames Fryba2)
$a000 - $bfff 8 frames block a2

While loading blocks a1+a2 and b will alternate.
Sequence of playback:
Fryba looping until a1+a2 loaded
a1+a2 playing while b loading
b loading while a1+a2 playing
repeat

/*
Demo loading and progress strategy:

Autostart fastloader.prg > load start $182
it will contain blocks:
Load keyb.prg at $0810 - $09d0 (2 sectors), jmp $0810
Load font_matrix.prg at $0a00 - $0c00 (1 sector)
Load music at 1000
Load font at 2000-27ff
Load installer at 2800 - 3b63
Load Krills loader 3c00 - 3dff
jmp $0a00
 - reloacate Krills loader to 9000
 - run Krills install routine at $37A6
 - disable basic, kernal
Load video code at 9200



// Compile all parts to a single file

// Memory map
// PART 1
// Default-segment:
//   $0801-$080c Basic
//   $080e-$080d Basic End
//   $0810-$09c4 Part1_code
// PART 2
// Default-segment:
//   $0a00-$0f7f Part2_lookups
//   $1000-$1fcf Part2_music
//   $2000-$3fff screen data
//   $4000-$4bff Part2_font
//   $4c00-$4dc7 Part2_code

#define RUNNING_COMPLETE
#import "fm_const.asm"

#import "keyb.asm"
#import "font_matrix.asm"



*/
