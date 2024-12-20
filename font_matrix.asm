.namespace PART2_ns {

#import "fm_lookups.asm"
#import "fm_const.asm"
#import "loadersymbols-c64.inc"

#if RUNNING_COMPLETE
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
    #if RUNNING_COMPLETE
    #else 
        jsr install
        bcc !+
        jmp load_error
        !:
        lda #$36
        sta $01
        clc
        ldx #<file_music  // Vector pointing to a string containing loaded file name
        ldy #>file_music
        jsr loadraw
        bcc !+
        jmp load_error
        !:
        jmp end_of_not_running_complete
        file_music:   .text "MUSIC"  //filename on diskette
                .byte $00
        file_fontm:   .text "FONTM"  //filename on diskette
                .byte $00
        end_of_not_running_complete:
    #endif

    // set background colors
    set_background_color(WHITE)
    set_border_color(WHITE)
    start_music()

    hires_on()
    #if RUNNING_COMPLETE
        clear_screen()
        clear_color_0400memory(LIGHT_GRAY, WHITE)  // becomes background color for individual characters
    #endif
    // init update script
    ldx #$00
    lda #<updates
    sta TMP_PTR
    lda #>updates
    sta TMP_PTR + 1
    init_irq()
lload_loop:
    lda what_to_load
    beq lload_loop
    cmp #$01
    bne !+
    clc
    ldx #<file_font  // Vector pointing to a string containing loaded file name
    ldy #>file_font
    jsr loadcompd
    bcs load_error
    lda #$02
    sta what_to_load
    jmp lload_loop
!:  cmp #$02
    bne !+
    clc
    ldx #<file_texts  // Vector pointing to a string containing loaded file name
    ldy #>file_texts
    jsr loadcompd
    bcs load_error
    clc
    ldx #<file_verts  // Vector pointing to a string containing loaded file name
    ldy #>file_verts
    jsr loadcompd
    bcs load_error
    lda #$00
    sta what_to_load
    jmp lload_loop
!:  cmp #$03
    bne !+
    clc
    ldx #<file_video_code  // Vector pointing to a string containing loaded file name
    ldy #>file_video_code
    jsr loadcompd
    bcs load_error
    lda #$00
    sta what_to_load
    jmp lload_loop
!:  cmp #$04
    bne lload_loop
    clc
    ldx #<file_fryba  // Vector pointing to a string containing loaded file name
    ldy #>file_fryba
    jsr loadcompd
    bcs load_error
    lda #$00
    sta what_to_load
    jmp lload_loop
upd_count: .byte 0
what_to_load: .byte 0  // 0:wait, 1:RFONT, 2:RESTX
file_font:   .text "RFONT"  //filename on diskette
          .byte $00
file_texts:   .text "RESTX"  //filename on diskette
          .byte $00
file_verts:   .text "VERTX"  //filename on diskette
          .byte $00
file_video_code:   .text "VIDEO"  //filename on diskette
          .byte $00
file_fryba:   .text "F5"  //filename on diskette
          .byte $00
load_error:
    sta $0400  // display error screen code
    lda #$04
    sta $d020
    jmp *



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
music_paused: .byte 0

exec_show_search:
    dec exec_show_search_counter
    bne exec_show_search_end
    jsr show_search
    // pause music
    lda #$01
    sta music_paused
    // set next vector for typing search text
    lda #<exec_type_search
    sta stage_jsr + 1
    lda #>exec_type_search
    sta stage_jsr + 2
exec_show_search_end:
    rts
exec_show_search_counter: .byte 20  // How long to wait before showing search
key_repeat_countdown: .byte 0
exec_type_search:
.const font_rom = $d000
    // read key
    lda #$00
    sta $dc00
    ldx $dc01
    cpx #$ff
    bne !+
    // key not pressed
    lda #$00  // unblock
    sta key_repeat_countdown
    jmp exec_type_search_end
!:  // key pressed
    lda key_repeat_countdown  // was it pressed before?
    cmp #$00   // 0: ready to read next key
    bne exec_type_search_end  // it was pressed before, do nothing
    lda #$01  // block reading next key without releasing first
    sta key_repeat_countdown
    // render char
    ldx search_text_pointer
    inc search_text_pointer
    lda search_text, x
    beq exec_type_search_next_stage
    jsr copy_basic_char
exec_type_search_end:
    rts
exec_type_search_next_stage:
    // pause music
    lda #$00
    sta music_paused
    // set next vector for showing results
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
    .text SEARCH_TEXT; .byte 0

// take screen code in register A and copy it to hires sceen. Use ROM character set
copy_basic_char:
    // calculate source, offset in the character memory char_offset = char*8
    asl  // x8 because there are 8 bytes per lookup address
    asl
    asl
    tax
    bcc !+  // overflow not set
    lda #$d1   // compiler sucks(>font_rom+1) // for chars $20-$3f, overlfow set
    sta cvc_loop + 2
    jmp !++
!:  lda #(>font_rom+0) // for chars $00-$1f, overflow not set
    sta cvc_loop + 2
!:
    lda $01
    and #%11111011
    sta $01
    ldy #$00
cvc_loop:
    lda font_rom+0, x  // lo nibble of font offset
copy_basic_char_trg:
    sta search_topleft + 42*8
    inc copy_basic_char_trg + 1
    inx
    iny
    cpy #$08
    bne cvc_loop
    lda $01
    ora #%00000100
    sta $01
    rts


// switch to empty text screen
// one by one, like loading from web, display search bar, then Hondani text logo, then search articles one by one until whole screen is filled
exec_scroll_results_setup:
    wait_frames_rts()
esr_jmp_stages:
    jmp esr_stage1  // will be overriden by set_next_esr_stage

esr_stage1:   //clear screen
    clear_color_0400memory(RED, BLACK)  // fill screen memory by $20 (spaces)
    clear_color_d800memory(GRAY, BLACK)
    set_hondani_small_logo_colors()
    lda #$18  // font $2000, screen $0400
    sta $d018
    lda #$1b  // enable text mode
    sta $d011
    lda #$01  // load font RFONT
    sta what_to_load
    set_next_esr_stage(esr_stage2)
    set_wait_frames(16)   // wait 0 before displaynig logo
    rts

esr_stage2:  // copy logo and search
    // copy logo and left part of search
    .const search_header_offfset = $0400
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
!:  lda #$da
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
    // copy searched text
    ldx #$00
!:  lda search_text, x
    beq esr7
    sta search_header_offfset + 50, x
    inx
    jmp !-
esr7:
    set_next_esr_stage(esr_stage3)
    set_wait_frames(20/4)  // wait before displaying All News Videos Tools tabs
    rts

esr_stage3:  // copy tabs
    lda what_to_load
    beq !+
    set_wait_frames(0)   // wait 0 before displaynig logo
    rts
!:
    // copy first screen of results
    .const esr_text_source = $5a00
    ldx #$50
!:  lda esr_text_source, x
    sta $0478, x
    dex
    bne !-
    set_next_esr_stage(esr_stage4)
    set_wait_frames(60/4)  // wait befire top story
    rts


esr_stage4:  // copy top story
    ldx #$c8
!:  lda esr_text_source + $50, x
    sta $0478 + $50, x
    dex
    bne !-
    set_next_esr_stage(esr_stage5)
    set_wait_frames(40/4)  // wait before article 1
    lda #$03  // load font VIDEO
    sta what_to_load
    rts


esr_stage5:  // copy article 1
    ldx #$0
!:  lda esr_text_source + $50 + $c8, x
    sta $0478 + $50 + $c8, x
    dex
    bne !-
    ldx #$38
!:  lda esr_text_source + $50 + $c8 + $100-1, x
    sta $0478 + $50 + $c8 + $100-1, x
    dex
    bne !-
    set_next_esr_stage(esr_stage6)
    set_wait_frames(80/4)  // wait before article 2
    rts


esr_stage6:  // copy article 2 and Hoooondani
    ldx #$f0
!:  lda esr_text_source + 16*40, x
    sta $0478 + 16*40, x
    dex
    bne !-
    set_next_esr_stage(esr_stage7)
    set_wait_frames(100/4)
    rts
 

esr_stage7:  // wait and switch irq jsr to next stage
    lda #$04
    sta what_to_load
    set_wait_frames(0)
    // switch to next phase
    lda #<exec_scroll_results_scroll
    sta stage_jsr + 1
    lda #>exec_scroll_results_scroll
    sta stage_jsr + 2
    unet_hondani_small_logo_colors()
    rts

//verticaler
exec_scroll_results_scroll:
    // key pressed to pause the scroll?
    lda #$00
    sta $dc00
    ldx $dc01
    cpx #$ff
    bne esr7_end  // paused, just exit
    lda esr7_hard_scroll_flag
    beq skip_corrupt_font
    // corrupt font
    lda seed
    beq doEor
    asl
    bcc noEor
doEor:
    eor #$1d
noEor:
    sta seed  // pseudo-random number generated
    // and #$fe  // do not clear odd chars
    sta seed_sta + 1
    sta seed_sta + 4
    sta seed_sta + 7
    inc seed_sta + 4
    inc seed_sta + 7
    lda #$00 // clear a line in a character font
seed_sta:
    sta $2000
    sta $2000
    sta $2000
skip_corrupt_font:
    // hard vertical scroll
    jsr scroll_up
    lda esr7_hard_scroll_counter  // $51ec
    cmp #$d0  // $ff minus after how many lines the scroll will speed up
    bne esr7a
    lda #$02
    sta speed_control + 1  // there is cmp there
esr7a:
    dec esr7_hard_scroll_counter
    lda esr7_hard_scroll_counter
esr7b:
    cmp #50  // how many lines (256-x) to scroll up in first round, will get overwritten to 0 for second run
    bne esr7_end
    lda esr7_hard_scroll_flag
    bne esr7_nextpart
    inc esr7_hard_scroll_flag
    lda #$00
    sta esr7_hard_scroll_counter
    sta esr7b + 1
    sta copy_loop + 1
    lda #$98
    sta copy_loop + 2
    jmp esr7_end
esr7_nextpart:
    // end this part and execute Video part
    jmp $9300 // video.prg
esr7_end:
    rts
esr7_hard_scroll_counter: .byte 0  // how many times to scroll up and populate screen line 25. 0 mean 256 lines
esr7_hard_scroll_flag: .byte 0  // 0: normal scroll, 1: corrupting font
seed: .byte 24

scroll_up:
    ldy #$00  // rows
vscroll_loop:
    lda screen_column0_hi, y
    sta su_dst + 2
    lda screen_column0_lo, y
    sta su_dst + 1
    iny
    lda screen_column0_hi, y
    sta su_src + 2
    lda screen_column0_lo, y
    sta su_src + 1
    ldx #$27
su_src:
    lda $ffff, x
su_dst:
    sta $ffff, x
    dex
    bpl su_src
    cpy #24
    bne vscroll_loop

    // copy new content to line 24
    ldx #$00
copy_loop:
    lda $9800
    sta $07c0, x
    inc copy_loop + 1
    bne !+
    inc copy_loop + 2
!:  inx
    cpx #$28
    bne copy_loop
    rts
screen_column0_hi: .byte $04, $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07, $07
screen_column0_lo: .byte $00, $28, $50, $78, $A0, $C8, $F0, $18, $40, $68, $90, $B8, $E0, $08, $30, $58, $80, $A8, $D0, $F8, $20, $48, $70, $98, $C0


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
    lda music_paused
    bne iskip_music  // skip music if paused
    lda $d418
    ora #$0f
    sta $d418  // set volume to 16
    jsr $1003 // jsr music.play 
    jmp !+
iskip_music:
    lda $d418
    and #$f0
    sta $d418  // set volume to 0
!:
    inc update_counter
    lda update_counter
speed_control:
    #if HURRY_UP
        cmp #$01
    #else 
        cmp #$04  // 04 speed of putting new chars on screen
    #endif
    bne end_irq
    lda #$00
    sta update_counter
stage_jsr:
    jsr exec_update_bigchar  // later overriden to next phase of the program
    // jsr exec_show_search
    // jsr exec_scroll_results_setup
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
    sta $d021
}

.macro set_border_color(color) {
    lda #color
    sta $d020
}

.macro start_music() {
    ldx #0
    ldy #0
    lda #0  // lda #music.startSong-1
    jsr $1000  // jsr music.init
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

.macro set_hondani_small_logo_colors() {
    // Customize Hondani logo colors
    .const shslc = $d800
    lda #$0e  // Ho
    sta shslc + 0
    sta shslc + 1
    sta shslc + 2
    sta shslc + 40
    sta shslc + 41
    sta shslc + 42
    lda #$0a  // n
    sta shslc + 3
    sta shslc + 43
    lda #$05  // dan
    sta shslc + 4
    sta shslc + 5
    sta shslc + 6
    sta shslc + 7
    sta shslc + 44
    sta shslc + 45
    sta shslc + 46
    sta shslc + 47
    lda #$04  // i
    sta shslc + 8
    sta shslc + 48
}

.macro unet_hondani_small_logo_colors() {
    // Hondani logo colors back to gray
    .const shslc = $d800
    lda #$2c
    ldx #$09
!:  sta shslc + 0, x
    sta shslc + 40, x
    dex
    bpl !-
}

.macro clear_color_0400memory(fg_color, bg_color) {
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

.macro clear_color_d800memory(char_color, bg_color) {
    // fill $0400-$800 with color
    lda #bg_color
    asl
    asl
    asl
    asl
    clc
    adc #char_color
    ldx #$00
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    dex
    bne !-
}

.macro set_next_esr_stage(next_stage_addr) {
    lda #<next_stage_addr
    sta esr_jmp_stages + 1
    lda #>next_stage_addr
    sta esr_jmp_stages + 2
}

set_wait_frames_counter: .byte 1
// set wait frames counter to number of frames
// settint 0 wait time is valid and will continue immediately
.macro set_wait_frames(frames) {
    lda #frames+1
    sta set_wait_frames_counter
}
.macro wait_frames_rts() {
    dec set_wait_frames_counter
    lda set_wait_frames_counter
    cmp #$00
    beq !+
    rts
!:
}

}  // end of namespace PART2_ns