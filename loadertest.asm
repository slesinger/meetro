.disk [filename="meetro.d64", name="HONDANI MEETRO", id="2025!", showInfo] {
    [name="LOADER", type="prg", prgFiles="loadertest.prg"],
    [name="KEYB", type="prg", prgFiles="keyb.prg"],
    [name="----------------", type="rel"],
    [name="DATA1", type="prg", prgFiles="data/video_screens.bin_3_a000-bc00.bin"],
}

// KickAssembler > Emulator > Options
// -autostartprgmode 1 -autostart ${kickassembler:buildFilename} -moncommands ${kickassembler:viceSymbolsFilename}

.namespace PARTL_ns {
BasicUpstart2(PARTL_ns.start)

*= $1c00 "Part4_code"
start:
    inc $d020
    jmp start
}