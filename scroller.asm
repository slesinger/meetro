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


//--------
.const countlines = 8 //8 lines in char
.const countchar = 16 //16 chars to shift
.const lenloop = $62  //length loop for speedcode iteration


.const storeplot = $04  //4 vector for store misc data
.const vectr1    = $06
.const vectr2    = $08
.const vectr3    = $0a

.const screen    = $2000 //screen addres
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
    .var music = LoadSid("Ucieczka_z_Tropiku.sid")  // music is loaded in previous part. Separately is disabled
    *=music.location "Part2_music"
    .fill music.size, music.getData(i)
#endif
//---
BasicUpstart2(start)

start:
        // start music
        ldx #0
        ldy #0
        lda #0
        jsr $1000

        // init irq
        sei
        cld
        ldx #$fb
        txs
        lda #$37
        sta $01
        jsr $fda3
        jsr $fd15
        jsr $e3bf
        jsr $ff5b
        sei
        lda #<draw
        sta $0318
        sta $fffa
        sta $fffe
        lda #>draw
        sta $0319
        sta $fffb
        sta $ffff

        // set colors
        lda #$0f
        sta $d020
        sta $d021
        lda $d011
        and #%11101111   // disable screen
        sta $d011
        //  jsr fillchar  //fill char
        jsr settbadr  //help proc. for prepare data
        jsr makespeedcode //make long and borning code for dotscroll
                           //and setting plots for wait look
        //  jsr speedcode //now plots will be clear
        //  jsr clearchar //now char be clear
        jsr makespeedclear //like before for clear plots and set plots
        //  jsr speedclear //ok now clear plots

        jsr initgraph //enable hires etc.
        lda $d011
        ora #%00010000  // enable screen
        sta $d011

//==========
//here is irq nmi and brk for neverending loop
//in this sample we don't work in the irq
//==========         
draw:

         sei
         cld
         ldx #$fb  //stack init
         txs
         lda #$38  //show all 64 ram (in this sample not necessary)
         sta $01
         jsr clearchar 
         jsr speedclear //clear plots
         sta posscroll  //start scrol from zero pos.


//after init and make speedcode here is mainlop
//and all necessary routines to work dot scroll
//really not that big //-)
//from $0801 to $0a29
//of course speedcode from $4000 to $7d03 still over here         

mainloop:
         jsr rolchar //shift data for dot scroll
         lda #$35    //show i/o
         sta $01
         
         ldx #$c8
         cpx $d012
         bne *-3

        //  inc $d020
         lda #$38  //show all ram
         sta $01
         jsr speedclear //clear plots on the bitmap
         jsr speedcode  //display plots of chars on 3d trajectory
         lda #$35       //show i/o vic etc.
         sta $01
        //  dec $d020
        
        // play music
        jsr $1003

         lda #$ef
         cmp $dc01 //space?
         bne mainloop
         cmp $dc01
         beq *-3
         lda #$38
         sta $01
         brk //go to draw of course

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
posscroll:  .byte 0
cntrol:    .byte 0
txtscrol:  .text "hondani meetro 2024   dan je guma honza je guma ondra je taky guma. vsichni jsme gumy    do not forget to give credits to wegi/bs/smr/ftm         "
          .byte 0
//==============
//======================================================
//after init all data and proc. below can be erase
//======================================================
*= $8000
initgraph:
//==============
//enable hires, fill collor, clear bitmap
//==============
         
         lda #$18
         sta $d018

         lda $d011
         ora #$21
         sta $d011


         ldx #$00
         lda #(BLACK<<4)+LIGHT_GREY
         
!:
         sta $0400,x
         sta $0500,x
         sta $0600,x
         sta $06f8,x
         inx
         bne !-
         stx posscroll

         ldx #>screen
         stx vectr1+1
         ldy #$00
         sty vectr1


         lda #$00
!:
         sta (vectr1),y
         iny
         bne !-
         inc vectr1+1
         dex
         bne !-
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

 // low x pos, y pos, hi x pos ...
 .byte 13 , 56 , 0 , 13 , 57 , 0 , 13 , 58 , 0 , 13 , 59 , 0 , 13 , 61 , 0 , 13 , 62 , 0 , 13 , 63 , 0 , 13 , 64 , 0
 .byte 14 , 56 , 0 , 14 , 57 , 0 , 14 , 58 , 0 , 14 , 59 , 0 , 14 , 61 , 0 , 14 , 62 , 0 , 14 , 63 , 0 , 14 , 64 , 0
 .byte 15 , 56 , 0 , 15 , 57 , 0 , 15 , 58 , 0 , 15 , 59 , 0 , 15 , 60 , 0 , 15 , 62 , 0 , 15 , 63 , 0 , 15 , 64 , 0
 .byte 16 , 55 , 0 , 16 , 57 , 0 , 16 , 58 , 0 , 16 , 59 , 0 , 16 , 60 , 0 , 16 , 62 , 0 , 16 , 63 , 0 , 16 , 64 , 0
 .byte 18 , 55 , 0 , 18 , 57 , 0 , 18 , 58 , 0 , 18 , 59 , 0 , 18 , 60 , 0 , 18 , 61 , 0 , 18 , 63 , 0 , 18 , 64 , 0
 .byte 19 , 55 , 0 , 19 , 56 , 0 , 19 , 58 , 0 , 19 , 59 , 0 , 19 , 60 , 0 , 19 , 61 , 0 , 19 , 63 , 0 , 19 , 64 , 0
 .byte 20 , 55 , 0 , 20 , 56 , 0 , 20 , 57 , 0 , 20 , 59 , 0 , 20 , 60 , 0 , 20 , 61 , 0 , 20 , 62 , 0 , 20 , 64 , 0
 .byte 21 , 55 , 0 , 21 , 56 , 0 , 21 , 57 , 0 , 21 , 58 , 0 , 21 , 60 , 0 , 21 , 61 , 0 , 21 , 62 , 0 , 21 , 63 , 0
 .byte 22 , 54 , 0 , 22 , 56 , 0 , 22 , 57 , 0 , 22 , 58 , 0 , 22 , 59 , 0 , 22 , 61 , 0 , 22 , 62 , 0 , 22 , 63 , 0
 .byte 23 , 54 , 0 , 23 , 55 , 0 , 23 , 57 , 0 , 23 , 58 , 0 , 23 , 59 , 0 , 23 , 60 , 0 , 23 , 62 , 0 , 23 , 63 , 0
 .byte 24 , 54 , 0 , 24 , 55 , 0 , 24 , 56 , 0 , 24 , 58 , 0 , 24 , 59 , 0 , 24 , 60 , 0 , 24 , 61 , 0 , 24 , 63 , 0
 .byte 24 , 54 , 0 , 24 , 55 , 0 , 24 , 56 , 0 , 24 , 57 , 0 , 24 , 59 , 0 , 24 , 60 , 0 , 24 , 61 , 0 , 24 , 62 , 0
 .byte 25 , 53 , 0 , 25 , 54 , 0 , 25 , 56 , 0 , 25 , 57 , 0 , 25 , 58 , 0 , 25 , 60 , 0 , 25 , 61 , 0 , 25 , 62 , 0
 .byte 26 , 53 , 0 , 26 , 54 , 0 , 26 , 55 , 0 , 26 , 57 , 0 , 26 , 58 , 0 , 26 , 59 , 0 , 26 , 60 , 0 , 26 , 62 , 0
 .byte 27 , 52 , 0 , 27 , 54 , 0 , 27 , 55 , 0 , 27 , 56 , 0 , 27 , 58 , 0 , 27 , 59 , 0 , 27 , 60 , 0 , 27 , 61 , 0
 .byte 28 , 52 , 0 , 28 , 53 , 0 , 28 , 55 , 0 , 28 , 56 , 0 , 28 , 57 , 0 , 28 , 58 , 0 , 28 , 60 , 0 , 28 , 61 , 0
 .byte 29 , 52 , 0 , 29 , 53 , 0 , 29 , 54 , 0 , 29 , 55 , 0 , 29 , 57 , 0 , 29 , 58 , 0 , 29 , 59 , 0 , 29 , 61 , 0
 .byte 30 , 51 , 0 , 30 , 52 , 0 , 30 , 54 , 0 , 30 , 55 , 0 , 30 , 56 , 0 , 30 , 58 , 0 , 30 , 59 , 0 , 30 , 60 , 0
 .byte 31 , 51 , 0 , 31 , 52 , 0 , 31 , 53 , 0 , 31 , 54 , 0 , 31 , 56 , 0 , 31 , 57 , 0 , 31 , 58 , 0 , 31 , 60 , 0
 .byte 31 , 50 , 0 , 31 , 51 , 0 , 31 , 53 , 0 , 31 , 54 , 0 , 31 , 55 , 0 , 31 , 57 , 0 , 31 , 58 , 0 , 31 , 59 , 0
 .byte 32 , 49 , 0 , 32 , 51 , 0 , 32 , 52 , 0 , 32 , 53 , 0 , 32 , 55 , 0 , 32 , 56 , 0 , 32 , 57 , 0 , 32 , 59 , 0
 .byte 33 , 49 , 0 , 33 , 50 , 0 , 33 , 52 , 0 , 33 , 53 , 0 , 33 , 54 , 0 , 33 , 56 , 0 , 33 , 57 , 0 , 33 , 58 , 0
 .byte 34 , 48 , 0 , 34 , 50 , 0 , 34 , 51 , 0 , 34 , 52 , 0 , 34 , 54 , 0 , 34 , 55 , 0 , 34 , 57 , 0 , 34 , 58 , 0
 .byte 35 , 48 , 0 , 35 , 49 , 0 , 35 , 51 , 0 , 35 , 52 , 0 , 35 , 53 , 0 , 35 , 55 , 0 , 35 , 56 , 0 , 35 , 57 , 0
 .byte 35 , 47 , 0 , 35 , 49 , 0 , 35 , 50 , 0 , 35 , 51 , 0 , 35 , 53 , 0 , 35 , 54 , 0 , 35 , 56 , 0 , 35 , 57 , 0
 .byte 36 , 47 , 0 , 36 , 48 , 0 , 36 , 49 , 0 , 36 , 51 , 0 , 36 , 52 , 0 , 36 , 54 , 0 , 36 , 55 , 0 , 36 , 56 , 0
 .byte 37 , 46 , 0 , 37 , 47 , 0 , 37 , 49 , 0 , 37 , 50 , 0 , 37 , 52 , 0 , 37 , 53 , 0 , 37 , 55 , 0 , 37 , 56 , 0
 .byte 38 , 45 , 0 , 38 , 47 , 0 , 38 , 48 , 0 , 38 , 50 , 0 , 38 , 51 , 0 , 38 , 53 , 0 , 38 , 54 , 0 , 38 , 56 , 0
 .byte 39 , 45 , 0 , 39 , 46 , 0 , 39 , 48 , 0 , 39 , 49 , 0 , 39 , 51 , 0 , 39 , 52 , 0 , 39 , 54 , 0 , 39 , 55 , 0
 .byte 39 , 44 , 0 , 39 , 46 , 0 , 39 , 47 , 0 , 39 , 49 , 0 , 39 , 50 , 0 , 39 , 52 , 0 , 39 , 53 , 0 , 39 , 55 , 0
 .byte 40 , 44 , 0 , 40 , 45 , 0 , 40 , 47 , 0 , 40 , 48 , 0 , 40 , 50 , 0 , 40 , 51 , 0 , 40 , 53 , 0 , 40 , 54 , 0
 .byte 41 , 43 , 0 , 41 , 45 , 0 , 41 , 46 , 0 , 41 , 48 , 0 , 41 , 49 , 0 , 41 , 51 , 0 , 41 , 52 , 0 , 41 , 54 , 0
 .byte 42 , 43 , 0 , 42 , 44 , 0 , 42 , 46 , 0 , 42 , 47 , 0 , 42 , 49 , 0 , 42 , 50 , 0 , 42 , 52 , 0 , 42 , 53 , 0
 .byte 43 , 42 , 0 , 43 , 44 , 0 , 43 , 45 , 0 , 43 , 47 , 0 , 43 , 48 , 0 , 43 , 50 , 0 , 43 , 51 , 0 , 43 , 53 , 0
 .byte 44 , 41 , 0 , 44 , 43 , 0 , 44 , 45 , 0 , 44 , 46 , 0 , 44 , 48 , 0 , 44 , 49 , 0 , 44 , 51 , 0 , 44 , 53 , 0
 .byte 44 , 41 , 0 , 44 , 43 , 0 , 44 , 44 , 0 , 44 , 46 , 0 , 44 , 47 , 0 , 44 , 49 , 0 , 44 , 51 , 0 , 44 , 52 , 0
 .byte 45 , 40 , 0 , 45 , 42 , 0 , 45 , 44 , 0 , 45 , 45 , 0 , 45 , 47 , 0 , 45 , 49 , 0 , 45 , 50 , 0 , 45 , 52 , 0
 .byte 46 , 40 , 0 , 46 , 42 , 0 , 46 , 43 , 0 , 46 , 45 , 0 , 46 , 47 , 0 , 46 , 48 , 0 , 46 , 50 , 0 , 46 , 52 , 0
 .byte 47 , 39 , 0 , 47 , 41 , 0 , 47 , 43 , 0 , 47 , 45 , 0 , 47 , 46 , 0 , 47 , 48 , 0 , 47 , 50 , 0 , 47 , 51 , 0
 .byte 48 , 39 , 0 , 48 , 41 , 0 , 48 , 42 , 0 , 48 , 44 , 0 , 48 , 46 , 0 , 48 , 48 , 0 , 48 , 49 , 0 , 48 , 51 , 0
 .byte 49 , 39 , 0 , 49 , 40 , 0 , 49 , 42 , 0 , 49 , 44 , 0 , 49 , 46 , 0 , 49 , 47 , 0 , 49 , 49 , 0 , 49 , 51 , 0
 .byte 50 , 38 , 0 , 50 , 40 , 0 , 50 , 42 , 0 , 50 , 44 , 0 , 50 , 45 , 0 , 50 , 47 , 0 , 50 , 49 , 0 , 50 , 51 , 0
 .byte 51 , 38 , 0 , 51 , 40 , 0 , 51 , 42 , 0 , 51 , 43 , 0 , 51 , 45 , 0 , 51 , 47 , 0 , 51 , 49 , 0 , 51 , 51 , 0
 .byte 52 , 38 , 0 , 52 , 40 , 0 , 52 , 41 , 0 , 52 , 43 , 0 , 52 , 45 , 0 , 52 , 47 , 0 , 52 , 49 , 0 , 52 , 51 , 0
 .byte 53 , 38 , 0 , 53 , 39 , 0 , 53 , 41 , 0 , 53 , 43 , 0 , 53 , 45 , 0 , 53 , 47 , 0 , 53 , 49 , 0 , 53 , 51 , 0
 .byte 55 , 37 , 0 , 55 , 39 , 0 , 55 , 41 , 0 , 55 , 43 , 0 , 55 , 45 , 0 , 55 , 47 , 0 , 55 , 49 , 0 , 55 , 51 , 0
 .byte 56 , 37 , 0 , 56 , 39 , 0 , 56 , 41 , 0 , 56 , 43 , 0 , 56 , 45 , 0 , 56 , 47 , 0 , 56 , 49 , 0 , 56 , 51 , 0
 .byte 57 , 37 , 0 , 57 , 39 , 0 , 57 , 41 , 0 , 57 , 43 , 0 , 57 , 45 , 0 , 57 , 47 , 0 , 57 , 49 , 0 , 57 , 51 , 0
 .byte 58 , 37 , 0 , 58 , 39 , 0 , 58 , 41 , 0 , 58 , 43 , 0 , 58 , 45 , 0 , 58 , 48 , 0 , 58 , 50 , 0 , 58 , 52 , 0
 .byte 60 , 37 , 0 , 60 , 40 , 0 , 60 , 42 , 0 , 60 , 44 , 0 , 60 , 46 , 0 , 60 , 48 , 0 , 60 , 50 , 0 , 60 , 52 , 0
 .byte 61 , 38 , 0 , 61 , 40 , 0 , 61 , 42 , 0 , 61 , 44 , 0 , 61 , 46 , 0 , 61 , 48 , 0 , 61 , 50 , 0 , 61 , 53 , 0
 .byte 63 , 38 , 0 , 63 , 40 , 0 , 63 , 42 , 0 , 63 , 44 , 0 , 63 , 47 , 0 , 63 , 49 , 0 , 63 , 51 , 0 , 63 , 53 , 0
 .byte 64 , 38 , 0 , 64 , 41 , 0 , 64 , 43 , 0 , 64 , 45 , 0 , 64 , 47 , 0 , 64 , 49 , 0 , 64 , 52 , 0 , 64 , 54 , 0
 .byte 66 , 39 , 0 , 66 , 41 , 0 , 66 , 43 , 0 , 66 , 46 , 0 , 66 , 48 , 0 , 66 , 50 , 0 , 66 , 52 , 0 , 66 , 55 , 0
 .byte 68 , 39 , 0 , 68 , 42 , 0 , 68 , 44 , 0 , 68 , 46 , 0 , 68 , 49 , 0 , 68 , 51 , 0 , 68 , 53 , 0 , 68 , 56 , 0
 .byte 69 , 40 , 0 , 69 , 42 , 0 , 69 , 45 , 0 , 69 , 47 , 0 , 69 , 50 , 0 , 69 , 52 , 0 , 69 , 54 , 0 , 69 , 57 , 0
 .byte 71 , 41 , 0 , 71 , 43 , 0 , 71 , 46 , 0 , 71 , 48 , 0 , 71 , 51 , 0 , 71 , 53 , 0 , 71 , 55 , 0 , 71 , 58 , 0
 .byte 73 , 42 , 0 , 73 , 44 , 0 , 73 , 47 , 0 , 73 , 49 , 0 , 73 , 52 , 0 , 73 , 54 , 0 , 73 , 57 , 0 , 73 , 59 , 0
 .byte 75 , 43 , 0 , 75 , 45 , 0 , 75 , 48 , 0 , 75 , 50 , 0 , 75 , 53 , 0 , 75 , 56 , 0 , 75 , 58 , 0 , 75 , 61 , 0
 .byte 78 , 44 , 0 , 78 , 46 , 0 , 78 , 49 , 0 , 78 , 52 , 0 , 78 , 54 , 0 , 78 , 57 , 0 , 78 , 60 , 0 , 78 , 62 , 0
 .byte 80 , 45 , 0 , 80 , 48 , 0 , 80 , 50 , 0 , 80 , 53 , 0 , 80 , 56 , 0 , 80 , 59 , 0 , 80 , 61 , 0 , 80 , 64 , 0
 .byte 83 , 46 , 0 , 83 , 49 , 0 , 83 , 52 , 0 , 83 , 55 , 0 , 83 , 58 , 0 , 83 , 60 , 0 , 83 , 63 , 0 , 83 , 66 , 0
 .byte 85 , 48 , 0 , 85 , 51 , 0 , 85 , 54 , 0 , 85 , 57 , 0 , 85 , 59 , 0 , 85 , 62 , 0 , 85 , 65 , 0 , 85 , 68 , 0
 .byte 88 , 50 , 0 , 88 , 53 , 0 , 88 , 56 , 0 , 88 , 59 , 0 , 88 , 61 , 0 , 88 , 64 , 0 , 88 , 67 , 0 , 88 , 70 , 0
 .byte 91 , 52 , 0 , 91 , 55 , 0 , 91 , 58 , 0 , 91 , 61 , 0 , 91 , 64 , 0 , 91 , 67 , 0 , 91 , 70 , 0 , 91 , 73 , 0
 .byte 94 , 54 , 0 , 94 , 57 , 0 , 94 , 60 , 0 , 94 , 63 , 0 , 94 , 66 , 0 , 94 , 69 , 0 , 94 , 72 , 0 , 94 , 75 , 0
 .byte 97 , 56 , 0 , 97 , 59 , 0 , 97 , 62 , 0 , 97 , 65 , 0 , 97 , 68 , 0 , 97 , 72 , 0 , 97 , 75 , 0 , 97 , 78 , 0
 .byte 101 , 58 , 0 , 101 , 61 , 0 , 101 , 65 , 0 , 101 , 68 , 0 , 101 , 71 , 0 , 101 , 74 , 0 , 101 , 78 , 0 , 101 , 81 , 0
 .byte 105 , 60 , 0 , 105 , 64 , 0 , 105 , 67 , 0 , 105 , 71 , 0 , 105 , 74 , 0 , 105 , 77 , 0 , 105 , 81 , 0 , 105 , 84 , 0
 .byte 108 , 63 , 0 , 108 , 67 , 0 , 108 , 70 , 0 , 108 , 74 , 0 , 108 , 77 , 0 , 108 , 80 , 0 , 108 , 84 , 0 , 108 , 87 , 0
 .byte 112 , 66 , 0 , 112 , 69 , 0 , 112 , 73 , 0 , 112 , 77 , 0 , 112 , 80 , 0 , 112 , 84 , 0 , 112 , 87 , 0 , 112 , 91 , 0
 .byte 117 , 69 , 0 , 117 , 73 , 0 , 117 , 76 , 0 , 117 , 80 , 0 , 117 , 84 , 0 , 117 , 87 , 0 , 117 , 91 , 0 , 117 , 95 , 0
 .byte 121 , 72 , 0 , 121 , 76 , 0 , 121 , 80 , 0 , 121 , 83 , 0 , 121 , 87 , 0 , 121 , 91 , 0 , 121 , 95 , 0 , 121 , 98 , 0
 .byte 126 , 75 , 0 , 126 , 79 , 0 , 126 , 83 , 0 , 126 , 87 , 0 , 126 , 91 , 0 , 126 , 95 , 0 , 126 , 98 , 0 , 126 , 102 , 0
 .byte 131 , 79 , 0 , 131 , 83 , 0 , 131 , 87 , 0 , 131 , 91 , 0 , 131 , 95 , 0 , 131 , 98 , 0 , 131 , 102 , 0 , 131 , 106 , 0
 .byte 136 , 82 , 0 , 136 , 86 , 0 , 136 , 90 , 0 , 136 , 94 , 0 , 136 , 98 , 0 , 136 , 103 , 0 , 136 , 107 , 0 , 136 , 111 , 0
 .byte 141 , 86 , 0 , 141 , 90 , 0 , 141 , 94 , 0 , 141 , 98 , 0 , 141 , 103 , 0 , 141 , 107 , 0 , 141 , 111 , 0 , 141 , 115 , 0
 .byte 147 , 90 , 0 , 147 , 94 , 0 , 147 , 98 , 0 , 147 , 102 , 0 , 147 , 107 , 0 , 147 , 111 , 0 , 147 , 115 , 0 , 147 , 120 , 0
 .byte 153 , 93 , 0 , 153 , 98 , 0 , 153 , 102 , 0 , 153 , 107 , 0 , 153 , 111 , 0 , 153 , 115 , 0 , 153 , 120 , 0 , 153 , 124 , 0
 .byte 159 , 97 , 0 , 159 , 102 , 0 , 159 , 106 , 0 , 159 , 111 , 0 , 159 , 115 , 0 , 159 , 120 , 0 , 159 , 124 , 0 , 159 , 129 , 0
 .byte 165 , 101 , 0 , 165 , 106 , 0 , 165 , 110 , 0 , 165 , 115 , 0 , 165 , 120 , 0 , 165 , 124 , 0 , 165 , 129 , 0 , 165 , 134 , 0
 .byte 171 , 105 , 0 , 171 , 110 , 0 , 171 , 115 , 0 , 171 , 119 , 0 , 171 , 124 , 0 , 171 , 129 , 0 , 171 , 134 , 0 , 171 , 138 , 0
 .byte 178 , 109 , 0 , 178 , 114 , 0 , 178 , 119 , 0 , 178 , 124 , 0 , 178 , 128 , 0 , 178 , 133 , 0 , 178 , 138 , 0 , 178 , 143 , 0
 .byte 185 , 113 , 0 , 185 , 118 , 0 , 185 , 123 , 0 , 185 , 128 , 0 , 185 , 133 , 0 , 185 , 138 , 0 , 185 , 143 , 0 , 185 , 147 , 0
 .byte 191 , 117 , 0 , 191 , 122 , 0 , 191 , 127 , 0 , 191 , 132 , 0 , 191 , 137 , 0 , 191 , 142 , 0 , 191 , 147 , 0 , 191 , 152 , 0
 .byte 198 , 121 , 0 , 198 , 126 , 0 , 198 , 131 , 0 , 198 , 136 , 0 , 198 , 141 , 0 , 198 , 146 , 0 , 198 , 151 , 0 , 198 , 156 , 0
 .byte 205 , 124 , 0 , 205 , 129 , 0 , 205 , 135 , 0 , 205 , 140 , 0 , 205 , 145 , 0 , 205 , 150 , 0 , 205 , 155 , 0 , 205 , 161 , 0
 .byte 212 , 128 , 0 , 212 , 133 , 0 , 212 , 138 , 0 , 212 , 143 , 0 , 212 , 149 , 0 , 212 , 154 , 0 , 212 , 159 , 0 , 212 , 164 , 0
 .byte 219 , 131 , 0 , 219 , 136 , 0 , 219 , 141 , 0 , 219 , 147 , 0 , 219 , 152 , 0 , 219 , 157 , 0 , 219 , 163 , 0 , 219 , 168 , 0
 .byte 226 , 134 , 0 , 226 , 139 , 0 , 226 , 144 , 0 , 226 , 150 , 0 , 226 , 155 , 0 , 226 , 161 , 0 , 226 , 166 , 0 , 226 , 171 , 0
 .byte 233 , 136 , 0 , 233 , 142 , 0 , 233 , 147 , 0 , 233 , 153 , 0 , 233 , 158 , 0 , 233 , 164 , 0 , 233 , 169 , 0 , 233 , 174 , 0
 .byte 240 , 138 , 0 , 240 , 144 , 0 , 240 , 150 , 0 , 240 , 155 , 0 , 240 , 161 , 0 , 240 , 166 , 0 , 240 , 172 , 0 , 240 , 177 , 0
 .byte 246 , 140 , 0 , 246 , 146 , 0 , 246 , 152 , 0 , 246 , 157 , 0 , 246 , 163 , 0 , 246 , 168 , 0 , 246 , 174 , 0 , 246 , 179 , 0
 .byte 253 , 142 , 0 , 253 , 148 , 0 , 253 , 153 , 0 , 253 , 159 , 0 , 253 , 164 , 0 , 253 , 170 , 0 , 253 , 175 , 0 , 253 , 181 , 0
 .byte 3 , 143 , 1 , 3 , 149 , 1 , 3 , 154 , 1 , 3 , 160 , 1 , 3 , 166 , 1 , 3 , 171 , 1 , 3 , 177 , 1 , 3 , 182 , 1
 .byte 9 , 144 , 1 , 9 , 149 , 1 , 9 , 155 , 1 , 9 , 161 , 1 , 9 , 166 , 1 , 9 , 172 , 1 , 9 , 177 , 1 , 9 , 183 , 1
 .byte 14 , 144 , 1 , 14 , 150 , 1 , 14 , 155 , 1 , 14 , 161 , 1 , 14 , 167 , 1 , 14 , 172 , 1 , 14 , 178 , 1 , 14 , 183 , 1
 .byte 19 , 144 , 1 , 19 , 150 , 1 , 19 , 155 , 1 , 19 , 161 , 1 , 19 , 166 , 1 , 19 , 172 , 1 , 19 , 178 , 1 , 19 , 183 , 1
 .byte 24 , 144 , 1 , 24 , 149 , 1 , 24 , 155 , 1 , 24 , 160 , 1 , 24 , 166 , 1 , 24 , 171 , 1 , 24 , 177 , 1 , 24 , 182 , 1
 .byte 28 , 143 , 1 , 28 , 148 , 1 , 28 , 154 , 1 , 28 , 159 , 1 , 28 , 165 , 1 , 28 , 170 , 1 , 28 , 176 , 1 , 28 , 181 , 1
 .byte 32 , 141 , 1 , 32 , 147 , 1 , 32 , 152 , 1 , 32 , 158 , 1 , 32 , 163 , 1 , 32 , 169 , 1 , 32 , 174 , 1 , 32 , 179 , 1
 .byte 35 , 139 , 1 , 35 , 145 , 1 , 35 , 150 , 1 , 35 , 156 , 1 , 35 , 161 , 1 , 35 , 166 , 1 , 35 , 172 , 1 , 35 , 177 , 1
 .byte 38 , 137 , 1 , 38 , 143 , 1 , 38 , 148 , 1 , 38 , 153 , 1 , 38 , 159 , 1 , 38 , 164 , 1 , 38 , 169 , 1 , 38 , 175 , 1
 .byte 41 , 135 , 1 , 41 , 140 , 1 , 41 , 145 , 1 , 41 , 151 , 1 , 41 , 156 , 1 , 41 , 161 , 1 , 41 , 166 , 1 , 41 , 172 , 1
 .byte 43 , 132 , 1 , 43 , 137 , 1 , 43 , 142 , 1 , 43 , 148 , 1 , 43 , 153 , 1 , 43 , 158 , 1 , 43 , 163 , 1 , 43 , 168 , 1
 .byte 45 , 129 , 1 , 45 , 134 , 1 , 45 , 139 , 1 , 45 , 144 , 1 , 45 , 149 , 1 , 45 , 155 , 1 , 45 , 160 , 1 , 45 , 165 , 1
 .byte 46 , 126 , 1 , 46 , 131 , 1 , 46 , 136 , 1 , 46 , 141 , 1 , 46 , 146 , 1 , 46 , 151 , 1 , 46 , 156 , 1 , 46 , 161 , 1
 .byte 47 , 122 , 1 , 47 , 127 , 1 , 47 , 132 , 1 , 47 , 137 , 1 , 47 , 142 , 1 , 47 , 147 , 1 , 47 , 152 , 1 , 47 , 157 , 1
 .byte 47 , 119 , 1 , 47 , 123 , 1 , 47 , 128 , 1 , 47 , 133 , 1 , 47 , 138 , 1 , 47 , 143 , 1 , 47 , 147 , 1 , 47 , 152 , 1
 .byte 48 , 115 , 1 , 48 , 119 , 1 , 48 , 124 , 1 , 48 , 129 , 1 , 48 , 134 , 1 , 48 , 138 , 1 , 48 , 143 , 1 , 48 , 148 , 1
 .byte 47 , 111 , 1 , 47 , 115 , 1 , 47 , 120 , 1 , 47 , 125 , 1 , 47 , 129 , 1 , 47 , 134 , 1 , 47 , 139 , 1 , 47 , 143 , 1
 .byte 47 , 107 , 1 , 47 , 111 , 1 , 47 , 116 , 1 , 47 , 120 , 1 , 47 , 125 , 1 , 47 , 129 , 1 , 47 , 134 , 1 , 47 , 138 , 1
 .byte 46 , 103 , 1 , 46 , 107 , 1 , 46 , 112 , 1 , 46 , 116 , 1 , 46 , 120 , 1 , 46 , 125 , 1 , 46 , 129 , 1 , 46 , 134 , 1
 .byte 46 , 99 , 1 , 46 , 103 , 1 , 46 , 107 , 1 , 46 , 112 , 1 , 46 , 116 , 1 , 46 , 120 , 1 , 46 , 124 , 1 , 46 , 129 , 1
 .byte 44 , 95 , 1 , 44 , 99 , 1 , 44 , 103 , 1 , 44 , 107 , 1 , 44 , 111 , 1 , 44 , 116 , 1 , 44 , 120 , 1 , 44 , 124 , 1
 .byte 43 , 91 , 1 , 43 , 95 , 1 , 43 , 99 , 1 , 43 , 103 , 1 , 43 , 107 , 1 , 43 , 111 , 1 , 43 , 115 , 1 , 43 , 119 , 1
 .byte 42 , 87 , 1 , 42 , 91 , 1 , 42 , 95 , 1 , 42 , 99 , 1 , 42 , 102 , 1 , 42 , 106 , 1 , 42 , 110 , 1 , 42 , 114 , 1
 .byte 40 , 83 , 1 , 40 , 87 , 1 , 40 , 90 , 1 , 40 , 94 , 1 , 40 , 98 , 1 , 40 , 102 , 1 , 40 , 106 , 1 , 40 , 110 , 1
 .byte 38 , 79 , 1 , 38 , 83 , 1 , 38 , 86 , 1 , 38 , 90 , 1 , 38 , 94 , 1 , 38 , 98 , 1 , 38 , 101 , 1 , 38 , 105 , 1
 .byte 37 , 75 , 1 , 37 , 79 , 1 , 37 , 82 , 1 , 37 , 86 , 1 , 37 , 90 , 1 , 37 , 93 , 1 , 37 , 97 , 1 , 37 , 101 , 1
 .byte 35 , 71 , 1 , 35 , 75 , 1 , 35 , 79 , 1 , 35 , 82 , 1 , 35 , 86 , 1 , 35 , 89 , 1 , 35 , 93 , 1 , 35 , 96 , 1
 .byte 33 , 68 , 1 , 33 , 71 , 1 , 33 , 75 , 1 , 33 , 78 , 1 , 33 , 82 , 1 , 33 , 85 , 1 , 33 , 89 , 1 , 33 , 92 , 1
 .byte 31 , 65 , 1 , 31 , 68 , 1 , 31 , 71 , 1 , 31 , 75 , 1 , 31 , 78 , 1 , 31 , 81 , 1 , 31 , 85 , 1 , 31 , 88 , 1
 .byte 29 , 61 , 1 , 29 , 65 , 1 , 29 , 68 , 1 , 29 , 71 , 1 , 29 , 74 , 1 , 29 , 78 , 1 , 29 , 81 , 1 , 29 , 84 , 1
 .byte 27 , 58 , 1 , 27 , 61 , 1 , 27 , 65 , 1 , 27 , 68 , 1 , 27 , 71 , 1 , 27 , 74 , 1 , 27 , 77 , 1 , 27 , 81 , 1
 .byte 25 , 55 , 1 , 25 , 58 , 1 , 25 , 61 , 1 , 25 , 65 , 1 , 25 , 68 , 1 , 25 , 71 , 1 , 25 , 74 , 1 , 25 , 77 , 1
 .byte 23 , 52 , 1 , 23 , 55 , 1 , 23 , 58 , 1 , 23 , 61 , 1 , 23 , 64 , 1 , 23 , 68 , 1 , 23 , 71 , 1 , 23 , 74 , 1
 .byte 21 , 50 , 1 , 21 , 53 , 1 , 21 , 56 , 1 , 21 , 59 , 1 , 21 , 61 , 1 , 21 , 64 , 1 , 21 , 67 , 1 , 21 , 70 , 1



eplot:

.text "end of data"