XXX.disk [filename="meetro.d64", name="-HONDANI-MEETRO-", id="2025!", showInfo, storeFilesInDir, interleave=4] {
    [name="LOADER", type="prg", prgFiles="fastloader.prg"],
    [name="KEYB", type="prg", prgFiles="keyb.prg", noStartAddr],
    // [name="KEYB", type="usr", prgFiles="512bytesfile.bin"],
    // [name="HONDANI", type="prg", prgFiles="hondani-iii.prg"],
    // [name="FONTMATRIX", type="prg", prgFiles="font_matrix.prg"],
    // [name="----------------", type="rel"],
    // [name="DATA1", type="prg", prgFiles="data/video_screens.bin_3_a000-bc00.bin"],
}

/*
Demo loading and progress strategy:

Autostart fastloader.prg > load $182
Load keyb.prg at $0810 - $09d0 (2 sectors), jmp $0810
Load font_matrix.prg at $0a00 - $0c00 (1 sector)
Load music at 1000
Load font at 2000
jmp $0a00
disable basic, kernal
Load video code at 9000



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

#define RUNNING_ALL
#import "fm_const.asm"

#import "keyb.asm"
#import "font_matrix.asm"



*/
