.file [name="autostart.prg", segments="PART2,VECTOR,CMD,START,FCODE", allowOverlap]

// This prg is supposed to be the first file on disk
// When LOAD "*",8,1 is execute, this prg will load, overwrite start vectors and autostart
// The goal is to load minimalistic code of keyb prg part and fastloader.
// Then install fastloader to floppy and copy resident fastloader to 9000

.const TARGET = $0801  // where to load the data to memory
.const TRACK = 1  // 18 what track to load from
  // for sectors, see sector_table at the end

.const DATA_OUT = $20 // bit 5
.const CLK_OUT  = $10 // bit 4
.const VIC_OUT  = $03 // bits need to be on to keep VIC happy

.const seccnt = $02  // variable for sector count in zero page

//----------------------------------------------------------------------
// Hack to generate .PRG file with load address as first word
//----------------------------------------------------------------------
// .segment LOADADDR []
// *=$0188 "LOADADDR"

//----------------------------------------------------------------------
// Send an "M-E" to the 1541 that jumps to floppy code.
// Then receive one block and run it.
// This code lives around $0190.
//----------------------------------------------------------------------
.segment PART2 []
*=$0188 "LOADADDR"
main:
    lda #$0f
    sta $b9
    sta $b8
    ldx #<memory_execute
    ldy #>memory_execute
    lda #memory_execute_end - memory_execute
    jsr $fdf9 // filname
    jsr $f34a // open


    // Upload code to floppy



    sei
    lda #VIC_OUT | DATA_OUT // CLK=0 DATA=1
    sta $DD00 // we're not ready to receive

// wait until floppy code is active
wait_fast:
    bit $DD00
    bvs wait_fast // wait for CLK=1 (inverted read!)

    lda #(sector_table_end - sector_table) // number of sectors  (-1 to accomodat the last $FF)
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

selfmod1:
    sta TARGET,y
    iny
    bne get_rest_loop

    inc selfmod1+2
    dec seccnt
    bne get_rest_loop
inf:
    jmp $0810   // jump to the start of the code

.segment VECTOR [start=$01ED]
// these bytes will be overwritten by the KERNAL stack while loading
// let's set them all to "2" so we have a chance that this will work
// on a modified KERNAL
    .byte 2,2,2,2,2,2,2,2,2,2,2
// This is the vector to the start of the code// RTS will jump to $0203
    .byte 2,2
// These bytes are on top of the return value on the stack. We could use
// them for data// or, fill them with "2" so different versions of KERNAL
// might work
    .byte 2,2,2,2

.segment CMD [start=$01FE]
memory_execute:
     .byte $4d, $2d, $45  // "M-E"
     .word $0480 + 2
memory_execute_end:

//----------------------------------------------------------------------
// Jump to code that receives data.
//----------------------------------------------------------------------
.segment START [start=$0203]
    jmp main

//----------------------------------------------------------------------
//----------------------------------------------------------------------
// C64 -> Floppy: direct
// Floppy -> C64: inverted
//----------------------------------------------------------------------
//----------------------------------------------------------------------

.segment FCODE [start=$0206]
// This code will be used for initial bootstrapping only
// $0206 - $027e
//   - $0200-$0258  Input buffer, storage area for data read from screen (89 bytes).
//   - $0259-$0262  Logical numbers assigned to files (10 bytes, 10 entries).
//   - $0263-$026C  Device numbers assigned to files (10 bytes, 10 entries).
//   - $026D-$0276  Secondary addresses assigned to files (10 bytes, 10 entries).
//   - $0277-$0280  Keyboard buffer (10 bytes, 10 entries).

.const F_DATA_OUT = $02
.const F_CLK_OUT  = $08

.const sec_index = $05
.pseudopc $0482 {
start1541:
    lda #F_CLK_OUT
    sta $1800 // fast code is running!

    lda #0 // sector
    sta sec_index
    sta $f9 // buffer $0300 for the read
    lda #TRACK
    sta $06
read_loop:
    ldx sec_index
    lda sector_table,x
    inc sec_index
    bmi end   // todle je podezrely, protoze je reaguje na negative flag toho inc, ale to je irrelevantni
    sta $07
    cli
    jsr $D586       // read sector
    sei
    
    
    // turn this on if you want to skip 2 <track,sector> bytes from being transmitted from the floppy
    // ldx #$02
    // stx $f9
send_loop:
// we can use $f9 (JOBNUMBER) as the byte counter, since we'll return it to 0
// so it holds the correct buffer number "0" when we read the next sector
    ldx $f9
    lda $0300,x

// first encode
    eor #3 // fix up for receiver side (VIC bank!)
    pha // save original
    lsr
    lsr
    lsr
    lsr // get high nybble
    tax // to X
    ldy enc_tab,x // super-encoded high nybble in Y
    ldx #0
    stx $1800 // DATA=0, CLK=0 -> we're ready to send!
    pla
    and #$0F // lower nybble
    tax
    lda enc_tab,x // super-encoded low nybble in A
// then wait for C64 to be ready
wait_c64:
    ldx $1800
    bne wait_c64// needs all 0

// then send
    sta $1800
    asl
    and #$0F
    sta $1800
    tya
    nop
    sta $1800
    asl
    and #$0F
    sta $1800

    jsr $E9AE // CLK=1 10 cycles later

    inc $f9
    bne send_loop
    beq read_loop

end:
    // rts
    jmp *  // all is read, floppy will hang

enc_tab:
    .byte %1111, %0111, %1101, %0101, %1011, %0011, %1001, %0001
    .byte %1110, %0110, %1100, %0100, %1010, %0010, %1000, %0000

sector_table:
    .byte 0,1     // 4 je prvni, 8 je druha cast keyb
sector_table_end:  // end is needed here because it calulates the size of the sector_table
filler:
    // .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff  // chova se divne, kdyz pretece
}