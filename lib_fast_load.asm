/* 

Example of using the fast loader

#import "lib_fast_load.asm"  // at $9000
    fastloader_init()  // call this only once to upload code to the floppy
    fastloader_load($28, 2, 8)  // load from track 2, 8 sectors in total and store to memory $2800

*/

.namespace LIBFASTLOAD {

*=$9000 "fastloader"
.label _track = memory_write4 + $11 + 6  // refer to floppy_code.floppy_prg $60 + $11
.label sectors = memory_write4 + $12  // exactly 8 values
.label _sector_count = sector_cnt+1
.label target_page = target_mem+2


.macro @fastloader_init() {
    jsr loader_init  // call this only once to upload code to the floppy
}

    
.macro @fastloader_load(target_mem_page, track, sector_count) {
    // set target memory page for loading, low nybble is always $00
    lda #target_mem_page  // target_mem_page $28 will result in $2800 address
    sta target_page
    // set track to load from
    lda #track
    sta _track
    // set sectors to load from
      // ! skipping for now, assuming sectors start from 0 which is pre-set in the floppy code
    // set number of sectors to load
    lda #sector_count
    sta _sector_count
    jsr loader
}


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
rts                                                  //! rts TADY NEZABIRA, NELIBI SE MU NECO VYS
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