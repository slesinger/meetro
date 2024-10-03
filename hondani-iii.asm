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

