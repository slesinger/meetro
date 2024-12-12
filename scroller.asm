//used assembler Kickassembler

//this is the example code of 3d dot scroll on the c64
//no irq, without msx, no doubble buffering this is only sample
//i very like this art on this computer
//the rule is simple - on the 3d trajectory data of charset are writting
//the trajectory was prepared in my program created in delphi

//=======================
//= c64 3d dot scroll   =
//= by wegi /bs/smr/ftm =
//= https://codebase64.org/doku.php?id=base:3d_dot_scroll =
//=======================

.namespace PART5_ns {
#import "fm_const.asm"
#import "loadersymbols-c64.inc"
#import "cml_bmpdata.asm"
//--------
.const countlines = 8 //8 lines in char
.const countchar = 16 //16 chars to shift
.const lenloop = $62  //length loop for speedcode iteration
.const CHECK_DISK_TURN_EVERY_JIFFY = 32

.const storeplot = $04  //4 vector for store misc data
.const vectr1    = $06
.const vectr2    = $08
.const vectr3    = $0a

.const screen    = $2000 //screen addres
//of course speedcode from $4000 to $7d03 still over here         
.const speedcode = $4000 //unroled code addres for display data
.const speedclear = speedcode + ( countchar * lenloop * countlines)+1
//speed clear all 1024 plot

.const char1     = $20  //char to shift (on zp)
.const char2     = char1  + countchar
.const char3     = char2  + countchar
.const char4     = char3  + countchar
.const char5     = char4  + countchar
.const char6     = char5  + countchar
.const char7     = char6  + countchar
.const char8     = char7  + countchar
.const cset2     = char8  + countchar

#if RUNNING_COMPLETE
    // Started as whole compilation of parts
#else
    // This has to happen only when starting separately
    *= install "loader_install" // same as install jsr
    .var installer_c64 = LoadBinary("install-c64.prgx", BF_C64FILE)
    installer_ptr: .fill installer_c64.getSize(), installer_c64.get(i)

    *= loadraw "loader_resident" // this will be moved to 9000 (loadraw)
    .var loader_c64 = LoadBinary("loader-c64.prgx", BF_C64FILE)
    loader_ptr: .fill loader_c64.getSize(), loader_c64.get(i)

    BasicUpstart2(start)
#endif
//---
*= $9b00 "Part5_code"
start:
#if RUNNING_COMPLETE
#else
    jsr install
    bcs load_error
    clc
    ldx #<file_music  // Vector pointing to a string containing loaded file name
    ldy #>file_music
    jsr loadcompd
    bcs load_error
#endif 
    jmp cont1
file_music:.text "MUSIC"  //filename on diskette
          .byte $00
pbtmp:    .text "PBTMP"  //filename on diskette
          .byte $00
pcolr:    .text "PCOLR"  //filename on diskette
          .byte $00
load_error:
    sta $0400  // display error screen code
    lda #$04
    sta $d020
    sta $d021
    jmp *

cont1:
    // copy CML to $e000
    ldy #$00
loop01:
    ldx #$00
loop02:
    lda $4000,x
loop03:
    sta $e000,x
    inx
    bne loop02
    inc loop02+2
    inc loop03+2
    iny
    cpy #$1f
    bne loop01
!:  ldx #$00
!:  lda $5f00,x
    sta $ff00,x
    inx
    cpx #$40
    bne !-
    // load bitmap
    clc
    ldx #<pbtmp  // Vector pointing to a string containing loaded file name
    ldy #>pbtmp
    jsr loadcompd
    bcs load_error
    // load color data
    clc
    ldx #<pcolr  // Vector pointing to a string containing loaded file name
    ldy #>pcolr
    jsr loadraw
    bcc !+
    jmp load_error
!:
#if RUNNING_COMPLETE
#else
    // start music
    ldx #0
    ldy #0
    lda #0
    jsr $1000
    lda #$36
    sta $01
#endif 
    // set colors
    lda #BLACK  // black large empty space
    sta $d020
    sta $d021   // does not have real effect due to 0400 color memory
    lda $d011
    and #%11101111   // disable screen
    sta $d011
    //  jsr fillchar  //fill char
    jsr settbadr  //help proc. for prepare data
    jsr makespeedcode //make long and borning code for dotscroll
                    //and setting plots for wait look
    jsr makespeedclear //like before for clear plots and set plots
    cld
    jsr clearchar 
    jsr speedclear //clear plots
    sta posscroll  //start scrol from zero pos.
    jsr initgraph //enable hires etc.
    lda $d011
    ora #%00010000  // enable screen
    sta $d011

    // init irq
    sei
    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315

    asl $d019
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d
    lda #$81
    sta $d01a
    lda #$e0  // where raster interrupt will be triggered
    sta $d012
    cli

    // monitor space key
retry_detect_sideb:
    lda #$ef
    cmp $dc01 //space?
    beq show_space
    // jmp retry_detect_sideb

    // check if disk is turned
    lda my_jiffy_clock
    bne hide_space
    lda #CHECK_DISK_TURN_EVERY_JIFFY
    sta my_jiffy_clock
    clc
    ldx #<file_sideb
    ldy #>file_sideb
    // jsr fileexists
    jmp retry_detect_sideb  // branch on file not found or error, bcs
    // file exists > disk is turned, continue with next part
    sei
    lda #<irq0
    sta $0314
    lda #>irq0
    sta $0315
    cli
    clc
    ldx #<file_vidfont  // Vector pointing to a string containing loaded file name
    ldy #>file_vidfont
    jsr loadcompd
    bcc !+
    jmp load_error
!:  clc
    ldx #<file_font6
    ldy #>file_font6
    jsr loadcompd
    bcc !+
    jmp load_error
!:  clc
    ldx #<file_titles
    ldy #>file_titles
    jsr loadcompd
    bcc !+
    jmp load_error
!:  
    jmp $9300  // jump to next part titles

show_space:
    // set hires screen to $8000
    lda #$00
    sta $dd00
    lda $d018
    ora #$08  // $e000-$ffe7 bitmap data
    sta $d018
    lda $d016
    ora #$10  // multicolor bitmap
    sta $d016
    ldx #$00
ssp1:
    lda $c000,x
    sta $d800,x
    lda $c100,x
    sta $d900,x
    lda $c200,x
    sta $da00,x
    lda $c2e7,x
    sta $dae7,x
    inx
    bne ssp1
    jmp retry_detect_sideb
hide_space:
    // set hires screen to $8000
    lda #$03
    sta $dd00
    lda #$18  // bitmap data
    sta $d018
    lda #$c8  // hires bitmap
    sta $d016
    jmp retry_detect_sideb

my_jiffy_clock: .byte 0
irq0:
    asl $d019
    jsr $1003
    jmp irq2_end

irq2:
    asl $d019   // ack irq
    jsr rolchar //shift data for dot scroll
    jsr speedclear //clear plots on the bitmap
    jsr speedcode  //display plots of chars on 3d trajectory
    // play music
    jsr $1003
    
irq2_end:
    dec my_jiffy_clock
    pla
    tay
    pla
    tax
    pla
    rti
file_sideb:
    .text "C0"  // filename on side b
    .byte $00
file_vidfont:
    .text "VF"  // font for video
    .byte $00
file_font6:
    .text "F6"  // font for titles
    .byte $00
file_titles:
    .text "TI"  // font for titles
    .byte $00


//==============
//clear or fill char data
//==============
clearchar:
         lda #$00
         .byte $2c
fillchar:         
         lda #$ff
initchar:
         ldx #$00

!:
         sta char1,x
         inx
         cpx #countchar*8+8
         bcc !-

         rts
//================         
rolchar:
//=======
//shift all bits for dot scroll
//data on zero page for speed
//=======

      asl cset2    
           
      rol  char1  + countchar-1
      rol  char1  + countchar-2
      rol  char1  + countchar-3      
      rol  char1  + countchar-4
      rol  char1  + countchar-5
      rol  char1  + countchar-6
      rol  char1  + countchar-7            
      rol  char1  + countchar-8      
      rol  char1  + countchar-9
      rol  char1  + countchar-10
      rol  char1  + countchar-11      
      rol  char1  + countchar-12
      rol  char1  + countchar-13
      rol  char1  + countchar-14
      rol  char1  + countchar-15           
      rol  char1       
      
      asl cset2+1    
           
      rol  char2  + countchar-1
      rol  char2  + countchar-2
      rol  char2  + countchar-3      
      rol  char2  + countchar-4
      rol  char2  + countchar-5
      rol  char2  + countchar-6
      rol  char2  + countchar-7            
      rol  char2  + countchar-8      
      rol  char2  + countchar-9
      rol  char2  + countchar-10
      rol  char2  + countchar-11      
      rol  char2  + countchar-12
      rol  char2  + countchar-13
      rol  char2  + countchar-14
      rol  char2  + countchar-15           
      rol  char2       

      asl cset2+2    
           
      rol  char3  + countchar-1
      rol  char3  + countchar-2
      rol  char3  + countchar-3      
      rol  char3  + countchar-4
      rol  char3  + countchar-5
      rol  char3  + countchar-6
      rol  char3  + countchar-7            
      rol  char3  + countchar-8      
      rol  char3  + countchar-9
      rol  char3  + countchar-10
      rol  char3  + countchar-11      
      rol  char3  + countchar-12
      rol  char3  + countchar-13
      rol  char3  + countchar-14
      rol  char3  + countchar-15           
      rol  char3       

      asl cset2+3
           
      rol  char4  + countchar-1
      rol  char4  + countchar-2
      rol  char4  + countchar-3      
      rol  char4  + countchar-4
      rol  char4  + countchar-5
      rol  char4  + countchar-6
      rol  char4  + countchar-7            
      rol  char4  + countchar-8      
      rol  char4  + countchar-9
      rol  char4  + countchar-10
      rol  char4  + countchar-11      
      rol  char4  + countchar-12
      rol  char4  + countchar-13
      rol  char4  + countchar-14
      rol  char4  + countchar-15           
      rol  char4       

      asl cset2+4
           
      rol  char5  + countchar-1
      rol  char5  + countchar-2
      rol  char5  + countchar-3      
      rol  char5  + countchar-4
      rol  char5  + countchar-5
      rol  char5  + countchar-6
      rol  char5  + countchar-7            
      rol  char5  + countchar-8      
      rol  char5  + countchar-9
      rol  char5  + countchar-10
      rol  char5  + countchar-11      
      rol  char5  + countchar-12
      rol  char5  + countchar-13
      rol  char5  + countchar-14
      rol  char5  + countchar-15           
      rol  char5       

      asl cset2+5    
           
      rol  char6  + countchar-1
      rol  char6  + countchar-2
      rol  char6  + countchar-3      
      rol  char6  + countchar-4
      rol  char6  + countchar-5
      rol  char6  + countchar-6
      rol  char6  + countchar-7            
      rol  char6  + countchar-8      
      rol  char6  + countchar-9
      rol  char6  + countchar-10
      rol  char6  + countchar-11      
      rol  char6  + countchar-12
      rol  char6  + countchar-13
      rol  char6  + countchar-14
      rol  char6  + countchar-15           
      rol  char6       

      asl cset2+6
           
      rol  char7  + countchar-1
      rol  char7  + countchar-2
      rol  char7  + countchar-3      
      rol  char7  + countchar-4
      rol  char7  + countchar-5
      rol  char7  + countchar-6
      rol  char7  + countchar-7            
      rol  char7  + countchar-8      
      rol  char7  + countchar-9
      rol  char7  + countchar-10
      rol  char7  + countchar-11      
      rol  char7  + countchar-12
      rol  char7  + countchar-13
      rol  char7  + countchar-14
      rol  char7  + countchar-15           
      rol  char7
             
      asl cset2+7
           
      rol  char8  + countchar-1
      rol  char8  + countchar-2
      rol  char8  + countchar-3      
      rol  char8  + countchar-4
      rol  char8  + countchar-5
      rol  char8  + countchar-6
      rol  char8  + countchar-7            
      rol  char8  + countchar-8      
      rol  char8  + countchar-9
      rol  char8  + countchar-10
      rol  char8  + countchar-11      
      rol  char8  + countchar-12
      rol  char8  + countchar-13
      rol  char8  + countchar-14
      rol  char8  + countchar-15           
      rol  char8
       
      inc cntrol
      lda cntrol
      and #$07     //if all char was shifted then scroll next char
      beq myscrol
      rts
//=================
myscrol:      
//===========
//simple scroll routine (max 256 char!!!)
//===========
      ldx posscroll
      lda txtscrol,x
      bne !+
      sta posscroll
      lda txtscrol
!:
      and #$3f
      asl
      asl
      asl        //char multiply 8 for addres in the chargen
      sta vectr1
      lda #$00
      adc #$d0
      sta vectr1+1      
      php        //status register save
      ldy #$07
      sei
      lda $01
      pha      //save $01
      lda #$33 //here is used chargen from c64 rom
      sta $01  //you can used something own
!:
      lda (vectr1),y
      sta cset2,y
      dey
      bpl !-
            
      pla     //recall $01
      sta $01
      plp     //recall status register for "i" (interrupts was blocked?)
      inc posscroll
      rts


//==============
posscroll: .byte 0
cntrol:    .byte 0
txtscrol:  .text "hondani meetro 2024   dan je guma honza je guma ondra je taky guma. vsichni jsme gumy    do not forget to give credits to wegi/bs/smr/ftm         "
          .byte 0
//==============

//======================================================
//after init all data and proc. below can be erase
//======================================================
// #if RUNNING_COMPLETE
*= $a000 "initgraph"
// #else
// *= $c000 "initgraph"  // melo by byt od $9c00, ale koliduje to s bejzikem
// #endif 

initgraph:
//==============
//enable hires, fill collor, clear bitmap
//==============
        lda #$03
        sta $dd00

        lda #$18
        sta $d018

        lda $d011
        ora #$21
        sta $d011
        rts
//===========
//calculate tb row address in the bitmap
//===========
settbadr:
        ldx #$00
        lda #>screen
        stx vectr1
        sta vectr1+1
!:
        lda vectr1
        sta tbadlo,x
        lda vectr1+1
        sta tbadhi,x

        lda vectr1
        clc
        adc #$40
        sta vectr1

        lda vectr1+1
        adc #$01
        sta vectr1+1
        inx
        cpx #25
        bcc !-
        rts
//--------
tbbit:
        .byte %10000000
        .byte %01000000
        .byte %00100000
        .byte %00010000
        .byte %00001000
        .byte %00000100
        .byte %00000010
        .byte %00000001
//---
tbadlo:
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
//---
tbadhi:
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
        .byte 0,0,0,0,0
//--------
xposs:       .byte 0,0
yposs:       .byte 0
//--------
calcplotadd:
//==============================
//convert data from xposs lo hi and ypos (bitmap poss.) and return
//to acc #<plot addres, yreg #>plot addres, xreg bit poss.
//==============================
         lda yposs
         lsr
         lsr
         lsr
         tax

         lda yposs
         and #$07
         tay

         lda xposs
         and #$f8
         clc
         adc tbadlo,x
         sta storeplot

         lda tbadhi,x
         adc xposs+1
         sta storeplot+1

         lda xposs
         and #$07
         tax

//set plot this is not necessary only for wait look
         lda (storeplot),y
         eor tbbit,x
         sta (storeplot),y
//        rts
//or this is only eor plot procedure
         tya
         clc
         adc storeplot
         sta storeplot
         bcc !+
         inc storeplot+1
!:
         lda tbbit,x
         tax
         lda storeplot
         ldy storeplot+1
//in acc #<plot addres, yreg #>plot addres, xreg bit poss.         
         rts
//===========================
makespeedcode:
//===========================
//iterator for generate unrolled code
//from speedcode base
//===========================
          lda #<speedcode
          sta vectr3
          lda #>speedcode
          sta vectr3+1
          

          ldy #$00
          sty cntrcolumn
          
          
          lda #<char1
          sta cntchar  

mcod0:            
          lda #<plots
          sta vectr1
          lda #>plots
          sta vectr1+1
          lda cntrcolumn
          asl
          adc cntrcolumn
          adc vectr1
          sta vectr1
          bcc !+
          inc vectr1+1
!:
          ldy #$00
          sty cntrlines
          jsr storedata
          
mcod1:          
          jsr calcplotadd //in acc #<plot addres, yreg #>plot addres, xreg bit poss.
          sta dot8+1
          sta dot8+5+1
          sty dot8+1+1
          sty dot8+6+1
          stx dot8+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot7+1
          sta dot7+5+1
          sty dot7+1+1
          sty dot7+6+1
          stx dot7+3+1

          jsr nextrow
          jsr calcplotadd
          sta dot6+1
          sta dot6+5+1
          sty dot6+1+1
          sty dot6+6+1
          stx dot6+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot5+1
          sta dot5+5+1
          sty dot5+1+1
          sty dot5+6+1
          stx dot5+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot4+1
          sta dot4+5+1
          sty dot4+1+1
          sty dot4+6+1
          stx dot4+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot3+1
          sta dot3+5+1
          sty dot3+1+1
          sty dot3+6+1
          stx dot3+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot2+1
          sta dot2+5+1
          sty dot2+1+1
          sty dot2+6+1
          stx dot2+3+1
          
          jsr nextrow
          jsr calcplotadd
          sta dot1+1
          sta dot1+5+1
          sty dot1+1+1
          sty dot1+6+1
          stx dot1+3+1
          
          jsr nextrow
          lda cntchar
          sta litera1+1
          inc cntchar

          
          ldy #$00
!:
          lda fcod,y
          sta (vectr3),y
          iny
          cpy #lenloop+1
          bne !-
          lda vectr3
          clc
          adc #lenloop
          sta vectr3
          bcc !+
          inc vectr3+1
!:
          
          
          
          inc cntrlines
          lda cntrlines
          cmp #countchar
          beq !+
          jmp mcod1
!:
          inc cntrcolumn
          lda cntrcolumn
          cmp #countlines
          beq !+
          jmp mcod0
!:
          rts          
//=================
//make sta $address plot for fast clear all 1024 bits
//not super optimize!!! cos don't elliminated this same addres for
//any plots          
//=================
makespeedclear:
          
          lda #<speedclear
          sta vectr3
          lda #>speedclear
          sta vectr3+1
          
          lda #<plots
          sta vectr1
          lda #>plots
          sta vectr1+1
          
          lda #$a9
          ldy #$00
          sta (vectr3),y
          tya
          iny
          sta (vectr3),y
          lda vectr3
          clc
          adc #$02
          sta vectr3
          bcc !+
          inc vectr3+1
!:
ll1:
          ldy #$00
          lda #$8d
          sta (vectr3),y
          ldy #$03
          lda #$60
          sta (vectr3),y
          
          jsr storedata
          jsr calcplotadd
          tax
          tya
          ldy #$02
          sta (vectr3),y
          txa
          dey
          sta (vectr3),y
          lda vectr1
          clc
          adc #$03
          sta vectr1
          bcc !+
          inc vectr1+1
!:
          lda vectr3
          clc
          adc #$03
          sta vectr3
          bcc !+
          inc vectr3+1
!:

          lda vectr1+1
          cmp #>eplot
          bne ll1
          lda vectr1
          cmp #<eplot
          bne ll1
          
          rts 
//========
//next 8 dot's
//========
nextrow:
          lda vectr1
          clc
          adc #24
          sta vectr1
          bcc !+
          inc vectr1+1
!:
storedata:
          ldy #$00
          lda (vectr1),y
          sta xposs
          iny
          lda (vectr1),y
          sta yposs
          iny
          lda (vectr1),y
          sta xposs+1
          rts	
//===========================
cntrlines:   .byte 0	
cntrcolumn:  .byte 0
cntchar:     .byte 0
//===========================
//below is the speedcode base for iteration
//===========================
 
fcod:
litera1:

	 lda $77
	 asl        //why asl and tax? cos lowest bit in nybbles not working
	 tax        //in illegal opcode $8b (ane... anx) so after asl
	 and #$10   //hi bit in carry lowest bit is second save acc to xreg
	 beq !+      //and check the lowest bit in hi nybble (and #$10)

dot4:
	 lda $1000  //here will be overwrite addres of plot
	 eor #$10   //and here bit poss. of plot
	 sta $1000
!:
	 bcc !+
dot8:
	 lda $1000
	 eor #$10
	 sta $1000
!:
	 .byte $8b , $80 //anx #$80
	 beq !+
dot7:
	 lda $1000   //and like before...
	 eor #$10
	 sta $1000
!:
	 .byte $8b , $40 //anx #$40 you understand i hoppe
	 beq !+
dot6:
	 lda $1000
	 eor #$10
	 sta $1000
!:
	 .byte $8b , $20
	 beq !+           //if bit is set so set bit on the bitmap
dot5:
	 lda $1000
	 eor #$10
	 sta $1000
!:
	 .byte $8b , $08  //if bit is not set go to the next 
	 beq !+
dot3:
	 lda $1000
	 eor #$10
	 sta $1000
!:
	 .byte $8b , $04
	 beq !+
dot2:
	 lda $1000
	 eor #$10
	 sta $1000
!:     
	 .byte $8b , $02
	 beq !+
dot1:
	 lda $1000
	 eor #$10
	 sta $1000
!:
     rts
//==============
//main trajectory 1024 plot poss. in the hires screen
//==============
plots:
#import "data/scroller_data.inc"
eplot:
.text "end of data"
}