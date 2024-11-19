.PHONY: clean video scroller build-loader

KICKASS = /usr/bin/java -jar /home/honza/projects/c64/pc-tools/kickass/KickAss.jar
D64_FILE = meetro.d64

clean:
	rm -f *.dbg *.prg *.sym *.vs .source.txt chunk.tmp *.vsf meetro.din $(D64_FILE)

build-loader:
    EXTCONFIGPATH=`pwd` && \
    cp -f loaderconfig.inc tools/krill194/loader/include/config.inc && \
    cd tools/krill194/loader/src && \
    make prg INSTALL=0e00 RESIDENT=9000 ZP=57 && \
    cp ../build/install-c64.prg ../../../../install-c64.prgx && \
    cp ../build/loader-c64.prg ../../../../loader-c64.prgx && \
    cd ${EXTCONFIGPATH}

keyb:
	$(KICKASS) keyb.asm

fontm:
	$(KICKASS) font_matrix.asm

video:
	$(KICKASS) video.asm

scroller:
	$(KICKASS) scroller.asm

prgs: keyb fontm video scroller

disk: clean prgs
	rm -f $(D64_FILE)
	# python3 tools/krill194/loader/tools/tscrunch/tscrunch.py -x '$$0810'  keyb.prg keyb.prg
	# python3 tools/krill194/loader/tools/tscrunch/tscrunch.py font_matrix.prg font_matrix.prg
	# python3 tools/krill194/loader/tools/tscrunch/tscrunch.py video.prg video.prg
	c1541 -format ' - hondani - ,2024' d64 $(D64_FILE)
	c1541 -attach $(D64_FILE) -write keyb.prg keyb
	c1541 -attach $(D64_FILE) -write font_matrix.prg fontm
	c1541 -attach $(D64_FILE) -write data/ucieczka.music music
	c1541 -attach $(D64_FILE) -write video.prg video
	c1541 -attach $(D64_FILE) -write scroller.prg scrll
	c1541 -attach $(D64_FILE) -write data/video_font.bin vfont
	c1541 -attach $(D64_FILE) -write data/search-font.bin rfont
	c1541 -attach $(D64_FILE) -write data/results-text.bin restx
	c1541 -attach $(D64_FILE) -write data/results-vert.bin vertx
	c1541 -attach $(D64_FILE) -write data/F5.bin f5
	c1541 -attach $(D64_FILE) -write data/BA.bin ba
	c1541 -attach $(D64_FILE) -write data/BB.bin bb
	c1541 -attach $(D64_FILE) -write data/BC.bin bc
	c1541 -attach $(D64_FILE) -write data/BD.bin bd
	c1541 -attach $(D64_FILE) -write data/BE.bin be
	c1541 -attach $(D64_FILE) -write data/BF.bin bf
	c1541 -attach $(D64_FILE) -write data/BG.bin bg
	c1541 -attach $(D64_FILE) -write data/BH.bin bh
	c1541 -attach $(D64_FILE) -write data/BI.bin bi
	c1541 -attach $(D64_FILE) -write data/BJ.bin bj
	c1541 -attach $(D64_FILE) -write data/BK.bin bk
	c1541 -attach $(D64_FILE) -write data/BL.bin bl
	c1541 -attach $(D64_FILE) -write data/BM.bin bm
	c1541 -attach $(D64_FILE) -write data/BN.bin bn
