#importonce
#import "fm_const.asm"
#import "loadersymbols-c64.inc"

#if RUNNING_COMPLETE
#else 
    *= install "loader_install" // same as install jsr
    .var installer_c64 = LoadBinary("install-c64.prgx", BF_C64FILE)
    installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

    *= loadraw "loader_resident" // this will be moved to 9000 (loadraw)
    .var loader_c64 = LoadBinary("loader-c64.prgx", BF_C64FILE)
    loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

    // .var music = LoadSid("Ucieczka_z_Tropiku.sid")  // music is loaded in previous part. Separately is disabled
    // *=music.location "Part2_music"
    // .fill music.size, music.getData(i)

    // .var font = LoadBinary("data/search-font.bin", BF_C64FILE)  // is loaded during this part
    // *=$2000 "Part4_font_results"
    // .fill font.getSize(), font.get(i)

    // .var results_text = LoadBinary("data/results-text.bin")  // is loaded during this part
    // *=$5a00 "Part4_font_restexts"
    // .fill results_text.getSize(), results_text.get(i)
#endif 



.var font_data = LoadBinary("data/googlefont.bin")  // 3x4 characters, 32 letters "?abcdefghijklmnopqrstuvwxyzHOD2+"
*=$4000 "Part2_font"
font3x4_memory: .fill font_data.getSize(), font_data.get(i)

.var search_data = LoadBinary("data/googlesearch.bin")
search_hires: .fill search_data.getSize(), search_data.get(i)



*=$5400 "Part2_lookups"
font3x4_lookup:
// create byte lookup table for 3x4 font offset. Each char is 4*4*8=128 bytes big
.for (var i=0;i<NUM_CHARS;i++) {
    .var char_offset = i * FONT_CHAR_WIDTH*FONT_CHAR_HEIGHT*8
    .var line_offset = 0
    .byte (<font3x4_memory) + mod(char_offset + line_offset, 256)
    .byte (>font3x4_memory) + ((char_offset + line_offset) >> 8)
    .eval line_offset += FONT_CHAR_WIDTH * 8
    .byte (<font3x4_memory) + mod(char_offset + line_offset, 256)
    .byte (>font3x4_memory) + ((char_offset + line_offset) >> 8)
    .eval line_offset += FONT_CHAR_WIDTH * 8
    .byte (<font3x4_memory) + mod(char_offset + line_offset, 256)
    .byte (>font3x4_memory) + ((char_offset + line_offset) >> 8)
    .eval line_offset += FONT_CHAR_WIDTH * 8
    .byte (<font3x4_memory) + mod(char_offset + line_offset, 256)
    .byte (>font3x4_memory) + ((char_offset + line_offset) >> 8)
}

multiply_320_hires_memory:
.for (var i=0; i < SCREEN_CHAR_LINES; i++) {
    .byte (<hires_memory) + mod(i * 40*8, 256)
    .byte (>hires_memory) + floor(i * 40*8 / 256)
}

x3_offset:
.for (var i = 0; i < 14; i++) {
    .byte mod(i * FONT_CHAR_WIDTH*8, 256)
    .byte floor(i * FONT_CHAR_WIDTH*8 / 256)
}

y_multiply_40_plus_400:
.for (var i = 0; i < SCREEN_CHAR_LINES; i++) {
    .byte mod(i * 40, 256)
    .byte floor(i * 40 / 256) + $04
}


updates:
// character, x, y, color
// generate randomp characters on random positions with random colors
// do it to list first as it needs to be updated before it is copied to memory
.var update_timeline = List(256)
.struct UpdateItem {character, x, y, color}
.function screen_color(bg_color, fg_color) {
    .return (fg_color << 4) + bg_color
}
.const question_marks_only = 40
// .var update_colors = List().add(BLACK, DARK_GRAY, GRAY, LIGHT_GRAY)
// // fill update_timeline with "null" UpdateItem 0 because null is not working in the list
// .for (var i = 0; i < 256; i++) {
//     .eval update_timeline.set(i, UpdateItem(0, 0, 0, 0))
// }

// // Input is UpdateItem having x a y position. Function iterates over all items in update_timeline and 
// // if the item has the same x and y position, it returns true.
// .function is_populated(item) {
//     .for (var i = 0; i < update_timeline.size(); i++) {
//         .var current_item = update_timeline.get(i)
//         .if (current_item.x == item.x && current_item.y == item.y) {
//             .return true
//         }
//     }
//     .return false
// }

// .for (var i = 0; i < question_marks_only; i++) {
//     .var item = UpdateItem(30, round(random() * 12), round(random() * 5), (update_colors.get((random() * (update_colors.size()-1))) << 4) + WHITE)
//     .eval update_timeline.set(i, item)
// }
// .for (var i = question_marks_only; i < 256; i++) {
//     .var item = UpdateItem(
//         round(random() * 32), 
//         round(random() * 12), 
//         round(random() * 5), 
//         screen_color(WHITE, update_colors.get((random() * (update_colors.size()-1))))
//     )
//     // .eval is_populated(item) ? i-- : update_timeline.set(i, item)
// }

// output generated by update_timeline.ipynb
.eval update_timeline.set(0, UpdateItem(UQUESTION, 8, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(1, UpdateItem(UQUESTION, 2, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(2, UpdateItem(UQUESTION, 0, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(3, UpdateItem(UQUESTION, 8, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(4, UpdateItem(UQUESTION, 10, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(5, UpdateItem(UQUESTION, 0, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(6, UpdateItem(UQUESTION, 2, 2, screen_color(WHITE, 12)))
.eval update_timeline.set(7, UpdateItem(UQUESTION, 3, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(8, UpdateItem(UQUESTION, 11, 2, screen_color(WHITE, 15)))
.eval update_timeline.set(9, UpdateItem(UQUESTION, 6, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(10, UpdateItem(UQUESTION, 5, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(11, UpdateItem(UQUESTION, 0, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(12, UpdateItem(UQUESTION, 7, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(13, UpdateItem(UQUESTION, 4, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(14, UpdateItem(UQUESTION, 6, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(15, UpdateItem(UQUESTION, 0, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(16, UpdateItem(UPLUS, 8, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(17, UpdateItem(UPLUS, 0, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(18, UpdateItem(UB, 7, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(19, UpdateItem(UO, 7, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(20, UpdateItem(UO, 1, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(21, UpdateItem(UQ, 9, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(22, UpdateItem(UZ, 2, 2, screen_color(WHITE, 15)))
.eval update_timeline.set(23, UpdateItem(UL, 5, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(24, UpdateItem(UG, 4, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(25, UpdateItem(UC, 6, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(26, UpdateItem(UA, 0, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(27, UpdateItem(UZ, 4, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(28, UpdateItem(UI, 1, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(29, UpdateItem(UM, 3, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(30, UpdateItem(U2, 9, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(31, UpdateItem(UU, 0, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(32, UpdateItem(UL, 11, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(33, UpdateItem(UC, 8, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(34, UpdateItem(UP, 5, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(35, UpdateItem(UD, 10, 4, screen_color(WHITE, 15)))
.eval update_timeline.set(36, UpdateItem(UG, 4, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(37, UpdateItem(UK, 2, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(38, UpdateItem(UE, 3, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(39, UpdateItem(UX, 5, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(40, UpdateItem(UQ, 8, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(41, UpdateItem(UP, 6, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(42, UpdateItem(UO, 3, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(43, UpdateItem(UM, 9, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(44, UpdateItem(UF, 11, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(45, UpdateItem(UZ, 2, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(46, UpdateItem(UL, 11, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(47, UpdateItem(UPLUS, 2, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(48, UpdateItem(U2, 0, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(49, UpdateItem(UG, 3, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(50, UpdateItem(UW, 7, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(51, UpdateItem(UR, 10, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(52, UpdateItem(UU, 2, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(53, UpdateItem(U2, 0, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(54, UpdateItem(UX, 1, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(55, UpdateItem(UJ, 4, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(56, UpdateItem(UA, 11, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(57, UpdateItem(UT, 1, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(58, UpdateItem(UI, 8, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(59, UpdateItem(UPLUS, 10, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(60, UpdateItem(UA, 5, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(61, UpdateItem(UZ, 6, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(62, UpdateItem(UD, 11, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(63, UpdateItem(UU, 10, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(64, UpdateItem(UF, 10, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(65, UpdateItem(UC, 7, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(66, UpdateItem(UPLUS, 1, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(67, UpdateItem(UX, 6, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(68, UpdateItem(UH, 9, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(69, UpdateItem(UC, 9, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(70, UpdateItem(UD, 6, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(71, UpdateItem(UX, 9, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(72, UpdateItem(UQ, 11, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(73, UpdateItem(UF, 10, 4, screen_color(WHITE, 15)))
.eval update_timeline.set(74, UpdateItem(UR, 3, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(75, UpdateItem(UN, 0, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(76, UpdateItem(UA, 5, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(77, UpdateItem(UL, 8, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(78, UpdateItem(UI, 11, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(79, UpdateItem(UC, 8, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(80, UpdateItem(UD, 9, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(81, UpdateItem(UJ, 0, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(82, UpdateItem(UK, 8, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(83, UpdateItem(UD, 10, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(84, UpdateItem(UV, 9, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(85, UpdateItem(UW, 3, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(86, UpdateItem(UG, 1, 2, screen_color(WHITE, 15)))
.eval update_timeline.set(87, UpdateItem(UE, 2, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(88, UpdateItem(UL, 10, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(89, UpdateItem(UV, 1, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(90, UpdateItem(UD, 4, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(91, UpdateItem(UW, 9, 4, screen_color(WHITE, 15)))
.eval update_timeline.set(92, UpdateItem(UN, 7, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(93, UpdateItem(UG, 8, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(94, UpdateItem(UQ, 0, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(95, UpdateItem(UF, 5, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(96, UpdateItem(UN, 11, 2, screen_color(WHITE, 11)))
.eval update_timeline.set(97, UpdateItem(UH, 0, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(98, UpdateItem(UB, 2, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(99, UpdateItem(UF, 0, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(100, UpdateItem(UI, 4, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(101, UpdateItem(UK, 9, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(102, UpdateItem(UD, 5, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(103, UpdateItem(UX, 10, 2, screen_color(WHITE, 12)))
.eval update_timeline.set(104, UpdateItem(UR, 3, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(105, UpdateItem(UO, 3, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(106, UpdateItem(UG, 10, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(107, UpdateItem(UV, 6, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(108, UpdateItem(UT, 6, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(109, UpdateItem(UZ, 7, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(110, UpdateItem(UB, 5, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(111, UpdateItem(UG, 3, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(112, UpdateItem(UM, 4, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(113, UpdateItem(UN, 6, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(114, UpdateItem(UZ, 11, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(115, UpdateItem(UP, 10, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(116, UpdateItem(UI, 3, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(117, UpdateItem(UA, 11, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(118, UpdateItem(UB, 2, 2, screen_color(WHITE, 12)))
.eval update_timeline.set(119, UpdateItem(UO, 2, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(120, UpdateItem(UA, 1, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(121, UpdateItem(UK, 8, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(122, UpdateItem(UL, 8, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(123, UpdateItem(UZ, 9, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(124, UpdateItem(UM, 11, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(125, UpdateItem(UC, 7, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(126, UpdateItem(UV, 11, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(127, UpdateItem(UF, 9, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(128, UpdateItem(UY, 5, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(129, UpdateItem(UI, 0, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(130, UpdateItem(UJ, 4, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(131, UpdateItem(UP, 8, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(132, UpdateItem(UF, 0, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(133, UpdateItem(UQ, 1, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(134, UpdateItem(UF, 5, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(135, UpdateItem(UV, 5, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(136, UpdateItem(UP, 6, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(137, UpdateItem(UT, 1, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(138, UpdateItem(US, 3, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(139, UpdateItem(UF, 2, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(140, UpdateItem(UW, 1, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(141, UpdateItem(UK, 6, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(142, UpdateItem(UC, 4, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(143, UpdateItem(UA, 11, 2, screen_color(WHITE, 15)))
.eval update_timeline.set(144, UpdateItem(UE, 2, 4, screen_color(WHITE, 15)))
.eval update_timeline.set(145, UpdateItem(UX, 2, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(146, UpdateItem(UB, 1, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(147, UpdateItem(UV, 2, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(148, UpdateItem(UN, 0, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(149, UpdateItem(UU, 10, 4, screen_color(WHITE, 11)))
.eval update_timeline.set(150, UpdateItem(UK, 8, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(151, UpdateItem(UM, 3, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(152, UpdateItem(UU, 6, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(153, UpdateItem(UL, 3, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(154, UpdateItem(UN, 2, 2, screen_color(WHITE, 15)))
.eval update_timeline.set(155, UpdateItem(UA, 6, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(156, UpdateItem(UC, 8, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(157, UpdateItem(UT, 8, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(158, UpdateItem(UO, 11, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(159, UpdateItem(UX, 1, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(160, UpdateItem(UE, 2, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(161, UpdateItem(UB, 3, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(162, UpdateItem(UP, 5, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(163, UpdateItem(UN, 7, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(164, UpdateItem(UF, 2, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(165, UpdateItem(UK, 5, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(166, UpdateItem(UB, 8, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(167, UpdateItem(UR, 8, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(168, UpdateItem(UK, 6, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(169, UpdateItem(UE, 2, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(170, UpdateItem(UX, 2, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(171, UpdateItem(UT, 8, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(172, UpdateItem(UN, 6, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(173, UpdateItem(UP, 11, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(174, UpdateItem(UL, 10, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(175, UpdateItem(UP, 7, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(176, UpdateItem(UB, 10, 0, screen_color(WHITE, 15)))
.eval update_timeline.set(177, UpdateItem(UH, 5, 0, screen_color(WHITE, 12)))
.eval update_timeline.set(178, UpdateItem(US, 10, 2, screen_color(WHITE, 12)))
.eval update_timeline.set(179, UpdateItem(UR, 5, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(180, UpdateItem(UR, 1, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(181, UpdateItem(UI, 11, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(182, UpdateItem(UX, 9, 4, screen_color(WHITE, 12)))
.eval update_timeline.set(183, UpdateItem(UA, 1, 4, screen_color(WHITE, 15)))
.eval update_timeline.set(184, UpdateItem(UC, 0, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(185, UpdateItem(US, 5, 3, screen_color(WHITE, 15)))
.eval update_timeline.set(186, UpdateItem(UG, 8, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(187, UpdateItem(UA, 10, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(188, UpdateItem(UP, 8, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(189, UpdateItem(UV, 6, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(190, UpdateItem(UO, 7, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(191, UpdateItem(UT, 5, 3, screen_color(WHITE, 11)))
.eval update_timeline.set(192, UpdateItem(UQ, 7, 1, screen_color(WHITE, 11)))
.eval update_timeline.set(193, UpdateItem(UZ, 7, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(194, UpdateItem(UL, 2, 0, screen_color(WHITE, 11)))
.eval update_timeline.set(195, UpdateItem(UT, 4, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(196, UpdateItem(UE, 1, 1, screen_color(WHITE, 12)))
.eval update_timeline.set(197, UpdateItem(UT, 7, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(198, UpdateItem(UL, 9, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(199, UpdateItem(US, 5, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(200, UpdateItem(UE, 8, 3, screen_color(WHITE, 12)))
.eval update_timeline.set(201, UpdateItem(UPLUS, 6, 1, screen_color(WHITE, 15)))
.eval update_timeline.set(202, UpdateItem(U2, 11, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(203, UpdateItem(USPACE, 0, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(204, UpdateItem(USPACE, 4, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(205, UpdateItem(USPACE, 7, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(206, UpdateItem(USPACE, 1, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(207, UpdateItem(USPACE, 7, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(208, UpdateItem(USPACE, 2, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(209, UpdateItem(USPACE, 1, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(210, UpdateItem(USPACE, 2, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(211, UpdateItem(USPACE, 11, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(212, UpdateItem(USPACE, 5, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(213, UpdateItem(USPACE, 3, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(214, UpdateItem(USPACE, 9, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(215, UpdateItem(USPACE, 9, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(216, UpdateItem(USPACE, 5, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(217, UpdateItem(USPACE, 0, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(218, UpdateItem(USPACE, 11, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(219, UpdateItem(USPACE, 7, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(220, UpdateItem(USPACE, 10, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(221, UpdateItem(USPACE, 2, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(222, UpdateItem(USPACE, 10, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(223, UpdateItem(USPACE, 9, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(224, UpdateItem(USPACE, 6, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(225, UpdateItem(USPACE, 8, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(226, UpdateItem(USPACE, 9, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(227, UpdateItem(USPACE, 10, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(228, UpdateItem(USPACE, 0, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(229, UpdateItem(USPACE, 3, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(230, UpdateItem(USPACE, 6, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(231, UpdateItem(USPACE, 5, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(232, UpdateItem(USPACE, 0, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(233, UpdateItem(USPACE, 0, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(234, UpdateItem(USPACE, 11, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(235, UpdateItem(USPACE, 10, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(236, UpdateItem(USPACE, 10, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(237, UpdateItem(USPACE, 4, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(238, UpdateItem(USPACE, 8, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(239, UpdateItem(USPACE, 2, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(240, UpdateItem(USPACE, 11, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(241, UpdateItem(USPACE, 7, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(242, UpdateItem(USPACE, 3, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(243, UpdateItem(USPACE, 1, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(244, UpdateItem(USPACE, 8, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(245, UpdateItem(USPACE, 11, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(246, UpdateItem(USPACE, 4, 1, screen_color(WHITE, 0)))
.eval update_timeline.set(247, UpdateItem(USPACE, 1, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(248, UpdateItem(USPACE, 6, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(249, UpdateItem(USPACE, 5, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(250, UpdateItem(USPACE, 6, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(251, UpdateItem(USPACE, 8, 0, screen_color(WHITE, 0)))
.eval update_timeline.set(252, UpdateItem(USPACE, 3, 3, screen_color(WHITE, 0)))
.eval update_timeline.set(253, UpdateItem(USPACE, 4, 4, screen_color(WHITE, 0)))
.eval update_timeline.set(254, UpdateItem(USPACE, 1, 2, screen_color(WHITE, 0)))
.eval update_timeline.set(255, UpdateItem(USPACE, 2, 1, screen_color(WHITE, 0)))

// honza
.eval update_timeline.set(question_marks_only + 8, UpdateItem(UH, 3, 2, screen_color(WHITE, BLUE)))
.eval update_timeline.set(question_marks_only + 14, UpdateItem(UO, 4, 2, screen_color(WHITE, BLUE)))
.eval update_timeline.set(question_marks_only + 16, UpdateItem(UN, 5, 2, screen_color(WHITE, BLUE)))
.eval update_timeline.set(question_marks_only + 22, UpdateItem(UZ, 6, 2, screen_color(WHITE, BLUE)))
.eval update_timeline.set(question_marks_only + 24, UpdateItem(UA, 7, 2, screen_color(WHITE, BLUE)))
//ondra
.eval update_timeline.set(question_marks_only + 40, UpdateItem(UO, 4, 2, screen_color(WHITE, LIGHT_RED)))
.eval update_timeline.set(question_marks_only + 44, UpdateItem(UN, 5, 2, screen_color(WHITE, LIGHT_RED)))
.eval update_timeline.set(question_marks_only + 46, UpdateItem(UD, 6, 2, screen_color(WHITE, LIGHT_RED)))
.eval update_timeline.set(question_marks_only + 52, UpdateItem(UR, 7, 2, screen_color(WHITE, LIGHT_RED)))
.eval update_timeline.set(question_marks_only + 56, UpdateItem(UA, 8, 2, screen_color(WHITE, LIGHT_RED)))
//dan.
.eval update_timeline.set(question_marks_only + 72, UpdateItem(UD, 6, 2, screen_color(WHITE, GREEN)))
.eval update_timeline.set(question_marks_only + 76, UpdateItem(UA, 7, 2, screen_color(WHITE, GREEN)))
.eval update_timeline.set(question_marks_only + 80, UpdateItem(UN, 8, 2, screen_color(WHITE, GREEN)))
.eval update_timeline.set(question_marks_only + 82, UpdateItem(UDOT, 9, 2, screen_color(WHITE, GREEN)))

// H i
.eval update_timeline.set(question_marks_only + 100, UpdateItem(UI, 9, 2, screen_color(WHITE, LIGHT_BLUE)))

// H LIGHT_BLUE
.eval update_timeline.set(question_marks_only + 101, UpdateItem(UHH, 3, 2, screen_color(WHITE, LIGHT_BLUE)))
// o LIGHT_RED
.eval update_timeline.set(question_marks_only + 102, UpdateItem(UO, 4, 2, screen_color(WHITE, RED)))
// n ORANGE
.eval update_timeline.set(question_marks_only + 103, UpdateItem(UN, 5, 2, screen_color(WHITE, ORANGE)))
// a GREEN
.eval update_timeline.set(question_marks_only + 104, UpdateItem(UA, 7, 2, screen_color(WHITE, GREEN)))
// n LIGHT_RED
.eval update_timeline.set(question_marks_only + 105, UpdateItem(UN, 8, 2, screen_color(WHITE, RED)))
// i ORANGE
.eval update_timeline.set(question_marks_only + 106, UpdateItem(UI, 9, 2, screen_color(WHITE, ORANGE)))
// clear remaining character
// .eval update_timeline.set(question_marks_only + 201, UpdateItem(USPACE, 2, 1, screen_color(WHITE, BLACK)))
// .eval update_timeline.set(question_marks_only + 202, UpdateItem(USPACE, 3, 0, screen_color(WHITE, BLACK)))

// copy list to memory
.for (var i = 0; i < 256; i++) {
    .var item = update_timeline.get(i)
    .byte item.character
    .byte item.x
    .byte item.y
    .byte item.color
}
