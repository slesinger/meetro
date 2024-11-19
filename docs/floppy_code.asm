// This code has to be compiled before all other parts that do use this fastloader.
// This code is not imported anywhere because it is included in other asm files as binary, 
// split by 32 bytes chunks. Chunks are the uploaded to floppy.

.file [name="floppy_code.floppy_prg", type="bin", segments="FLOPPYCODE"]

.segment FLOPPYCODE [start=$0400]  // this address is floppy memory address. $0300 ba is  as buffer for data

.const F_CLK_OUT  = $08
.const sec_index = $05

.pseudopc $0400 {

start1541:
    lda #F_CLK_OUT
    sta $1800 // fast code is running!

    lda #0 // sector
    sta sec_index
    sta $f9 // buffer $0300 for the read data
    lda track
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
    beq read_loop  // is beq here to save 1byte compared to jmp?

end:
    // rts  // try rts as better suggestion
    jmp *  // all is read, floppy will hang

enc_tab:
    .byte %1111, %0111, %1101, %0101, %1011, %0011, %1001, %0001
    .byte %1110, %0110, %1100, %0100, %1010, %0010, %1000, %0000

// The remainder of code is always uploaded fresh from the C64 before loading starts (actually full last chunk $0460-047ff)
track: .byte 9
sector_table:
    .byte 0,1,2,3,4,5,6,7  // this is always uploaded fresh from the C64 before loading starts
    // TODO pozor do floppy se neprenesou posledni 2 bajty
sector_table_end:  // end is needed here because it calulates the size of the sector_table
useless_filler: .byte $ff, $ff, $ff, $ff, $ff, $ff
}
