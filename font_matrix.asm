.namespace PART2_ns {

#import "fm_lookups.asm"
#import "fm_const.asm"

    .var font = LoadBinary("tools/assets/search-font.bin", BF_C64FILE)
    *=$2000 "Part4_font_results"
    .fill font.getSize(), font.get(i)

#if RUNNING_ALL
    // Started as whole compilation of parts
#else
    // when compiled and started as a single part
    BasicUpstart2(PART2_ns.PART2_start)
#endif

// copy 3 characters in a row, 3 rows, from search_hires
.const search_y = 12
.const search_x = 8
.const search_topleft = $2000 + search_y*40*8 + search_x*8
.const straight_line_len = 19

*= $4d00 "Part2_code"
PART2_start:
    // set background colors
    set_background_color(WHITE)
    set_border_color(WHITE)
    start_music()

    hires_on()
    clear_screen()
    clear_color_memory(LIGHT_GRAY, WHITE)  // becomes background color for individual characters

    // init update script
    ldx #$00
    lda #<updates
    sta TMP_PTR
    lda #>updates
    sta TMP_PTR + 1
    init_irq()
    jmp *
upd_count: .byte 0



exec_update_bigchar:
    copy_bmp_3x4()
    clc
    lda #$04
    adc TMP_PTR
    sta TMP_PTR
    bcc !+
    inc TMP_PTR + 1
!:
    inc upd_count
    bne exec_update_end
    lda #<exec_show_search
    sta stage_jsr + 1
    lda #>exec_show_search
    sta stage_jsr + 2
exec_update_end:
    rts

exec_show_search:
    dec exec_show_search_counter
    bne exec_show_search_end
    jsr show_search
    // lda #<exec_type_search
    // sta stage_jsr + 1
    // lda #>exec_type_search
    // sta stage_jsr + 2
    lda #<exec_scroll_results_setup
    sta stage_jsr + 1
    lda #>exec_scroll_results_setup
    sta stage_jsr + 2
exec_show_search_end:
    rts
exec_show_search_counter: .byte 20  // How long to wait before showing search

exec_type_search:
.const font_rom = $1000
    jsr $ff9f  // scan key
    lda $00c5
    cmp #$40
    beq exec_type_search_end
    cmp exec_type_search_last_key
    beq exec_type_search_end
    sta exec_type_search_last_key
    ldx search_text_pointer
    inc search_text_pointer
    lda search_text, x
    beq exec_type_search_next_stage
    jsr copy_basic_char
exec_type_search_end:
    rts
exec_type_search_next_stage:
    lda #<exec_scroll_results_setup
    sta stage_jsr + 1
    lda #>exec_scroll_results_setup
    sta stage_jsr + 2
    rts
exec_type_search_last_key: .byte 41

search_text_pointer:
    .byte 0
search_text:
    .encoding "screencode_upper"
    .text "LATEST NEWS"; .byte 0

// take screen code in register A and copy it to hires sceen. Use ROM character set
copy_basic_char:
    // calculate source, offset in the character memory char_offset = char*8
    asl  // x8 because there are 8 bytes per lookup address
    asl
    asl
    tax
    ldy #$00
!:
    lda font_rom+0, x  // lo nibble of font offset
copy_basic_char_trg:
    sta search_topleft + 42*8
    inc copy_basic_char_trg + 1
    inx
    iny
    cpy #$08
    bne !-
    rts

// switch to empty text screen
// one by one, like loading from web, display search bar, then Hondani text logo, then search articles one by one until whole screen is filled
exec_scroll_results_setup:
.const search_header_offfset = $0428

    clear_color_memory(LIGHT_BLUE, YELLOW)

    lda #$18  // font $8000, screen $8800
    sta $d018

    lda $d011  
    and #$df    // Bit 5 disable gfx mode
    sta $d011
    // copy logo and left part of search
    ldx #$00
esr1:
    lda #$d0
    sta search_header_offfset, x
esr2:
    lda #$e0
    sta search_header_offfset + 40, x
esr3:
    lda #$f0
    sta search_header_offfset + 80, x
    inc esr1 + 1
    inc esr2 + 1
    inc esr3 + 1
    inx
    cpx #$0a
    bne esr1
    // copy middle empty part of search
!:
    lda #$da
    sta search_header_offfset, x
    lda #$fa
    sta search_header_offfset + 80, x
    inx
    cpx #$1c
    bne !-
    // copy right part of search
esr4:
    lda #$db
    sta search_header_offfset, x
esr5:
    lda #$eb
    sta search_header_offfset + 40, x
esr6:
    lda #$fb
    sta search_header_offfset + 80, x
    inc esr4 + 1
    inc esr5 + 1
    inc esr6 + 1
    inx
    cpx #$21
    bne esr4

    lda #<exec_scroll_results_scroll
    sta stage_jsr + 1
    lda #>exec_scroll_results_scroll
    sta stage_jsr + 2
    rts

exec_scroll_results_scroll:
    // dec $d020
    // fine vertical scroll
// up _new_line:
// up_new_line_src:
//     lda #$28
// !:  lda $a000,x
//     sta $07c0,x
//     dex
//     bpl !-
//     inc up_new_line_src + 2
//     rts


// up_copy_screen:
// . for (var i=0;i<40*24;i++) {
//     lda $0400+40 + i
//     sta $0400 + i
// }
// rts
    // hardscroll
    rts

screen_pos:
.word search_topleft +0*40*8, search_topleft + 1*40*8, search_topleft + 2*40*8
.word search_topleft +0*40*8 +straight_line_len*8, search_topleft + 1*40*8 +straight_line_len*8, search_topleft + 2*40*8 +straight_line_len*8
show_search:
    ldy #$00
    lda #<(search_hires -3*8)
    sta p02 + 1
nex_line:
    lda screen_pos, y
    sta p01 + 1
    iny
    lda screen_pos, y
    sta p01 + 2
    iny
    lda p02 + 1  //
    clc
    adc #3*8
    sta p02 + 1
    ldx #$00
!:
p02:lda search_hires,x
p01:sta $2000,x
    inx
    cpx #3*8  // copy 3 characters in this row
    bne !-
    cpy #12
    bne nex_line
    // draw straigth lines
    lda #$ff
    .for (var i = 0; i < straight_line_len-3; i++) {
        sta search_topleft + 3*8 + i*8 + 6
        sta search_topleft + 3*8 + i*8 + 0 + 2*40*8
    }
    lda #screen_color(WHITE, LIGHT_GRAY)
    .for (var i = 0; i < straight_line_len+3; i++) {
        sta color_memory + search_x + search_y*40 + i
        sta color_memory + search_x + (search_y+1)*40 + i
        sta color_memory + search_x + (search_y+2)*40 + i
    }
    rts


// In matrix of 4x4 big chars on screen, calculate address in hires memory and copy character from font memory
.macro copy_bmp_3x4() {
    // calculate source, offset in the character memory char_offset = char3x4_offset + char*3*4*8
    ldy #$00
    lda (TMP_PTR), y  // char
    asl  // x8 because there are 8 bytes per lookup address
    asl
    asl
    tax
    lda font3x4_lookup+0, x  // lo nibble of font offset
    sta s1 + 1  // +0
    lda font3x4_lookup+1, x
    sta s1 + 2
    lda font3x4_lookup+2, x
    sta s2 + 1  // +24
    lda font3x4_lookup+3, x
    sta s2 + 2
    lda font3x4_lookup+4, x
    sta s3 + 1  // +48
    lda font3x4_lookup+5, x
    sta s3 + 2
    lda font3x4_lookup+6, x
    sta s4 + 1  // +96
    lda font3x4_lookup+7, x
    sta s4 + 2

    // calculate destination, offset in the hires memory as y4*8*40 + x3*8
    // get y position in hires memory at beginning of the line
    ldy #$02
    lda (TMP_PTR), y  // Y
    asl
    asl  // y4*4
    asl  // times 2 because of 2 bytes per lookup address
    sta color_y + 1
    tax
    lda multiply_320_hires_memory, x  //lo nibble of hires offset
    sta d1 + 1
    lda multiply_320_hires_memory + 1, x  //hi nibble of hires offset
    sta d1 + 2
    // get x offset
    ldy #$01
    lda (TMP_PTR), y  // X
    sta color_x + 1
    asl  // x3*2 because of 2 bytes per lookup address
    tax
    lda x3_offset, x
    clc
    adc d1 + 1
    sta d1 + 1
    bcc !+
    inc d1 + 2
!:
    lda x3_offset + 1, x
    clc
    adc d1 + 2
    sta d1 + 2
    
    // add 8*40 to each following line
    lda d1 + 2
    sta d2 + 2
    inc d2 + 2  // +1 because 320 is added (256+64)
    lda d1 + 1  // add remaining 64
    clc
    adc #$40
    sta d2 + 1
    bcc !+
    inc d2 + 2
!:
    lda d2 + 2
    sta d3 + 2
    inc d3 + 2
    lda d2 + 1
    clc
    adc #$40
    sta d3 + 1
    bcc !+
    inc d3 + 2
!:
    lda d3 + 2
    sta d4 + 2
    inc d4 + 2
    lda d3 + 1
    clc
    adc #$40
    sta d4 + 1
    bcc !+
    inc d4 + 2
!:
    // loop 3chars (3*8=24bytes)
    ldx #$17
loop:
s1: lda $4444, x
d1: sta $2888, x
s2: lda $4444, x
d2: sta $2888, x
s3: lda $4444, x
d3: sta $2888, x
s4: lda $4444, x
d4: sta $2888, x
    dex
    bpl loop  // loop if not negative

    // set colors for character
    // 3x4 big character at color memory $0400
color_y:
    lda #$ff
    tax
    lda y_multiply_40_plus_400, x
    sta TMP_PTR2
    lda y_multiply_40_plus_400 + 1, x
    sta TMP_PTR2 + 1
color_x:
    lda #$ff
    // multiply accumulator with 3
    tax  // save for +1*a
    asl  // *2
    sta color_x + 1
    txa
    clc
    adc color_x + 1  // accu contains X*3 now
    adc TMP_PTR2  // carry is assumed clear
    sta TMP_PTR2
    bcc !+
    inc TMP_PTR2 + 1
!:

    ldx #FONT_CHAR_HEIGHT
    ldy #$03
    lda (TMP_PTR), y  // colors
    ldy #$00
!:
    sta (TMP_PTR2), y
    iny
    sta (TMP_PTR2), y
    iny
    sta (TMP_PTR2), y
    pha
    tya
    clc
    adc #40-FONT_CHAR_WIDTH+1
    tay
    pla
    dex
    bne !-
    


}

.macro init_irq() {
    sei
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    asl $d019
    lda #$7b
    sta $dc0d
    lda #$81
    sta $d01a
    lda #$80
    sta $d012
    cli
}

irq1:
    asl $d019
    jsr music.play 
    inc update_counter
    lda update_counter
    cmp #$01  // 04 speed of putting new chars on screen
    bne end_irq
stage_jsr:
    jsr exec_update_bigchar  // later overriden to next phase of the program
    // jsr exec_show_search
    // jsr exec_scroll_results_setup
    lda #$00
    sta update_counter
end_irq:
    pla
    tay
    pla
    tax
    pla
    rti
update_counter: .byte 0



.macro set_background_color(color) {
    lda #color
    sta $d020
}

.macro set_border_color(color) {
    lda #color
    sta $d021
}

.macro start_music() {
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init
}

.macro hires_on() {
    lda $d018  
    ora #$08    // Bit 3, screen memory at $2000
    sta $d018
    lda $d011  
    ora #$20    // Bit 5
    sta $d011
}

.macro hires_off_1c00() {
    lda $d018  
    ora #$74    // Bit 3, screen memory at $2000
    sta $d018
    lda $d011  
    and #$df    // Bit 5
    sta $d011
}

.macro clear_screen() {
    // fill $2000-$4000 with 0 (hires memory)
    lda #$00
    ldx #$00   
    ldy #$00
!:
    sta $2000,x
    dex              
    bne !-   // inner loop
    iny      // outer loop
    inc *-5  // Hi-byte im Bitmap-Speicher erhöhen 
    cpy #$20 // 32*256 Byte = 8 Kbyte
    bne !-    
}

.macro clear_color_memory(fg_color, bg_color) {
    // fill $0400-$800 with color
    lda #fg_color
    asl
    asl
    asl
    asl
    clc
    adc #bg_color
    ldx #$00
!:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    dex
    bne !-
}

}  // end of namespace PART2_ns