// Instructions
// Build all prg depejndencies
// To support autostart, find 2 empty sectors in the same track

// c1541 -attach {DISK_IMAGE} -bwrite floppy_code.floppy_prg {track} {sector}")  25 0

// start quick 
//    /usr/bin/x64sc -8 meetro.d64 keyb.prg

.disk [filename="meetro.d64", name="HONDANI MEETRO", id="2025!", interleave=10]
{
    // [name="START", type="prf142g", prgFiles="autostart.prg" ],

    [name="KEYBD", type="prg", prgFiles="keyb.prg" ],
    [name="FONTM", type="prg", prgFiles="font_matrix.prg" ],
    [name="MUSIC", type="prg", prgFiles="data/ucieczka.music" ],
    [name="VIDEO", type="prg", prgFiles="video.prg" ],
    [name="VIDFT", type="prg", prgFiles="data/video_font.bin" ],
    [name="RESFT", type="prg", prgFiles="data/search-font.bin" ],
    // [name="SCROL", type="prg", prgFiles="scroller.prg" ],
    [name="RESTX", type="prg", prgFiles="data/results-text.bin" ],
    [name="F5", type="prg", prgFiles="data/F5.bin" ],
    [name="BA", type="prg", prgFiles="data/BA.bin" ],
    [name="BB", type="prg", prgFiles="data/BB.bin" ],
    [name="BC", type="prg", prgFiles="data/BC.bin" ],
    [name="BD", type="prg", prgFiles="data/BD.bin" ],
    [name="BE", type="prg", prgFiles="data/BE.bin" ],
    [name="BF", type="prg", prgFiles="data/BF.bin" ],
    [name="BG", type="prg", prgFiles="data/BG.bin" ],
    [name="BH", type="prg", prgFiles="data/BH.bin" ],
    [name="BI", type="prg", prgFiles="data/BI.bin" ],
    [name="BJ", type="prg", prgFiles="data/BJ.bin" ],   // disabled because disk is full
    [name="BK", type="prg", prgFiles="data/BK.bin" ],
    [name="BL", type="prg", prgFiles="data/BL.bin" ],
    [name="BM", type="prg", prgFiles="data/BM.bin" ],
    [name="BN", type="prg", prgFiles="data/BN.bin" ],
}