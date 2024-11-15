#importonce

#define HURRY_UP  // comment out for production release
// #define RUNNING_COMPLETE  // comment out when you want to run parts as single file

.const PART2_start = $4d00

.const hires_memory = $2000
.const color_memory = $0400

.const NUM_CHARS = 32
.const SCREEN_CHAR_LINES = 25
.const FONT_CHAR_WIDTH = 3
.const FONT_CHAR_HEIGHT = 4

.const TMP_PTR = $BB
.const TMP_PTR2 = $C1

.enum { USPACE, UA, UB, UC, UD, UE, UF, UG, UH, UI, UJ, UK, UL, UM, UN, UO, UP, UQ, UR, US, UT, UU, UV, UW, UX, UY, UZ, UHH, U2, UDOT, UQUESTION, UPLUS }

.const SEARCH_TEXT = "LATEST NEWS"
.var end_of_main
