// This is PART 1

#import "fm_const.asm"

.namespace PART1_ns {

BasicUpstart2(start)

*= $0810 "Part1_code"
start:
              jmp PART2_begin
    // print t_error1
    lda #<t_error1
    sta TMP_PTR
    lda #>t_error1
    sta TMP_PTR+1
    ldx #$00
    // print initial error message
!:
    lda t_error1,x
    beq init
    jsr $ffd2    // If the routine fools with Y, be sure to save and restore it.
    inx
    cpx #95  // length of t_error1
    bne !-       // (65C02 would normally use BRA, but BNE will work here.)

    // lda #$01
    // sta $cf

init:
    init_irq()
    jmp *



.macro init_irq() {
    sei
    lda #<irq0
    sta $0314
    lda #>irq0
    sta $0315
    asl $d019
    lda #$7b
    sta $dc0d
    lda #$81
    sta $d01a
    lda #$1b
    sta $d011
    lda #$80
    sta $d012
    cli
}

irq0:
    asl $d019
    // tick cursor
    inc cursor_tick
    // blink cursor on screen
    lda #$10
    ldy $d3
    bit cursor_tick
    beq !+
    lda ($d1), y
    and #$7f
    jmp !++
!:
    lda ($d1), y
    ora #$80
!:
    sta ($d1), y

    // AI or kyeboard input?
    lda ai_mode
    cmp #$01
    beq keyb_input
    // ai_input
       // wait random time
    jmp prnt_char

    // read keyboard
keyb_input:
    jsr $ffe4        // Calling KERNAL GETIN
          jmp prnt_char             // disable this for production
    beq irq0_end
prnt_char:
    // print character on screen
t_conv1_ptr:
    lda t_conv1
    cmp #$01  // switch to keyboard mode?
    bne !+
    sta ai_mode
    // clear keyboard buffer
    lda #$00
    sta $c6
    jmp just_increase
!:
    cmp #$02  // switch to AI mode?
    bne !+
    sta ai_mode
    jmp just_increase
!:
    cmp #$03  // end of conversation?
    bne !+
    jmp PART2_start
!:
    cmp #$0d // new line? make sure cursor is off
    bne !+
    lda ($d1), y
    and #$7f                                           // MA BYT 7f
    sta ($d1), y     // ta pozice je nejaka divna, takze to zatim neresim
    lda #$0d    
!:
    jsr $ffd2        // Calling KERNAL CHROUT
    // increase text pointer
just_increase:
    inc t_conv1_ptr+1
    bne !+
    inc t_conv1_ptr+2
!:
irq0_end:
    jmp $ea31


cursor_tick: .byte 0  // increase every frame, bit 4 tells if cursor should be displayed
ai_mode: .byte 1  // 1 - keyboard input, 2 - AI input

t_error1:
    .text "TRACEBACK (MOST RECENT CALL LAST):"; .byte $0d
    .text @"  FILE \"MAIN.PY\" LINE 55"; .byte $0d
    .text "HTTP EXCEPTION: HOST NOT FOUND"; .byte $0d
    .text ">>> "
t_conv1:
    // human input
    .text "LOAD AI"; .byte $0d, $02
    .text "> "; .byte $01  // machine input
    // human input
    .text "CREATE A COOL DEMO"; .byte $0d, $02
    // AI input
    .text "AI: SURE. WHAT THEME DO YOU WANT?"; .byte $0d
    .text "> "; .byte $01
    // human input
    .text "MEETING MY SCENE FRIENDS"; .byte $0d, $02
    // AI input
    .text "AI: A MEETRO? OK. SEARCHING SCENE DB..."; .byte $0d
    .text "AI: CODE IS READY. $1000-$47FF"; .byte $0d
    .text "READY."; .byte $0d, $01
    // human input
    .text "RUN"; .byte $03  // indicate end of conversation
    









PART2_begin:
    // disable basic $a000-$bfff
    lda $01
    and #%11111110
    sta $01

    // ** Example of using the fast loader
.const track = memory_write4 + $11 + 6  // refer to floppy_code.floppy_prg $60 + $11
.const sectors = memory_write4 + $12  // exactly 8 values
.const target_page = target_mem+2
    jsr loader_init  // call this only once to upload code to the floppy
    // set target memory page for loading, low nybble is always $00
    lda #$28  // $2800 address
    sta target_page
    // set track to load from
    lda #$02
    sta track
    // set sectors to load from
      // ! skipping for now, assuming sectors start from 0 which is pre-set in the floppy code
    // set number of sectors to load
    lda #$08
    sta sector_cnt+1
    jsr loader
!:
    inc $d020
    jmp !-




// TODO move this to import
loader_init:
    // load fastloader to floppy memory from 19:0
    lda #$0f
    sta $b9  // Secondary address of current file.
    sta $b8  // Logical number of current file.
    ldx #<memory_write1
    ldy #>memory_write1
    lda #memory_write1_end - memory_write1
    jsr $fdf9 // filename
    jsr $f34a // open
    lda #$0f
    jsr $ffc3

    ldx #<memory_write2
    ldy #>memory_write2
    lda #memory_write2_end - memory_write2
    jsr $fdf9 // filename
    jsr $f34a // open
    lda #$0f
    jsr $ffc3

    ldx #<memory_write3
    ldy #>memory_write3
    lda #memory_write3_end - memory_write3
    jsr $fdf9 // filename
    jsr $f34a // open
    lda #$0f
    jsr $ffc3
    rts

// TODO move this to import as a namespace
loader:
.const DATA_OUT = $20 // bit 5
.const VIC_OUT  = $03 // bits need to be on to keep VIC happy
.const seccnt = $02  // address for sector count in zero page

    inc $d020
    ldx #<memory_write4
    ldy #>memory_write4
    lda #$20 //#memory_write4_end - memory_write4
    jsr $fdf9 // filename
    jsr $f34a // open
    lda #$0f
    jsr $ffc3

    // execute in floppy memory
    lda #$0f
    sta $b9  // Secondary address of current file.
    sta $b8  // Logical number of current file.
    ldx #<memory_execute
    ldy #>memory_execute
    lda #memory_execute_end - memory_execute
    jsr $fdf9 // filname
    jsr $f34a // open

    sei
    lda #VIC_OUT | DATA_OUT // CLK=0 DATA=1
    sta $DD00 // we're not ready to receive

// wait until floppy code is active
wait_fast:
    //  sem to dojde jednou a pak to zuchne
    bit $DD00
    bvs wait_fast // wait for CLK=1 (inverted read!)

sector_cnt:
    lda #$01 // number of sectors
    sta seccnt
    ldy #0
get_rest_loop:  
    bit $DD00  // tady se to vzdycky zasekne, kdyz ocekavam vic dat, ale floppyna uz nedava
    bvc get_rest_loop // wait for CLK=0 (inverted read!)
// wait for raster
wait_raster:
    lda $D012
    cmp #50
    bcc wait_raster_end
    and #$07
    cmp #$02
    beq wait_raster
wait_raster_end:

    lda #VIC_OUT // CLK=0 DATA=0
    sta $DD00 // we're ready, start sending!
    pha // 3 cycles
    pla // 4 cycles
    bit $00 // 3 cycles
    lda $DD00 // get 2 bits into bits 6&7
    lsr
    lsr // move down by 2 (bits 4&5)
    eor $DD00 // get 2 more bits
    lsr
    lsr // move everything down (bits 2-5)
    eor $DD00// get 2 more bits
    lsr
    lsr // move everything down (bits 0-5)
    eor $DD00 // get last 2 bits, now 0-7 are populated

    ldx #VIC_OUT | DATA_OUT // CLK=0 DATA=1
    stx $DD00 // not ready any more, don't start sending

target_mem:
    sta $ff00,y  // parametrized high nybble of address
    iny
    bne get_rest_loop

    inc target_mem+2
    dec seccnt
    bne get_rest_loop

    dec $d020
    rts   // jump to the start of the newly loaded code

sector_table:
    .byte 0,1,2,3,4,5,6,7     ,8,9 // staci max 8 sectoru naraz// TODO interleave
    // TODO pozor do floppy se neprenesou posledni 2 bajty
sector_table_end:  // end is needed here because it calulates the size of the sector_table






.var floader_bin = LoadBinary("floppy_code.floppy_prg")
memory_write1:
    .byte $4d, $2d, $57  // "M-W"
    .word $0400 + $00  // floppy memory address
    .byte memory_write1_end - memory_write1  // number of bytes of data
    .fill 32, floader_bin.get(i + $00)
memory_write1_end:

memory_write2:
    .byte $4d, $2d, $57  // "M-W"
    .word $0400 + $20  // floppy memory address
    .byte memory_write2_end - memory_write2  // number of bytes of data
    .fill 32, floader_bin.get(i + $20)
memory_write2_end:

memory_write3:
    .byte $4d, $2d, $57  // "M-W"
    .word $0400 + $40  // floppy memory address
    .byte memory_write3_end - memory_write3  // number of bytes of data
    .fill 32, floader_bin.get(i + $40)
memory_write3_end:

memory_write4:
    .byte $4d, $2d, $57  // "M-W"
    .word $0400 + $60  // floppy memory address
    // .byte memory_write4_end - memory_write4  // number of bytes of data
    // .fill 32, floader_bin.get(i + $60)
    .byte floader_bin.getSize()-$60 // number of bytes of data
    .fill floader_bin.getSize()-$60, floader_bin.get(i + $60)
memory_write4_end:

memory_execute:  // this will be sent to the floppy and executed
     .byte $4d, $2d, $45  // "M-E"
     .word $0400
memory_execute_end:

}
