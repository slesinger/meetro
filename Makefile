.PHONY: clean video scroller build-loader

KICKASS = /usr/bin/java -jar /home/honza/projects/c64/pc-tools/kickass/KickAss.jar
D64_FILE = meetro.d64

clean:
	rm -f *.dbg *.prg *.sym *.vs .source.txt chunk.tmp *.vsf meetro.din $(D64_FILE)
	rm -rf data-compressed

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
	$(KICKASS) planety_bmpdata.asm

prgs: keyb fontm video scroller

disk: clean prgs
	rm -f $(D64_FILE)
	mkdir -p data-compressed
	tools/tscrunch.py -p -x 0810 keyb.prg keyb.prg
	tools/tscrunch.py -i data/BA.bin data-compressed/BA.bin
	tools/tscrunch.py -i data/BB.bin data-compressed/BB.bin
	tools/tscrunch.py -i data/BC.bin data-compressed/BC.bin
	tools/tscrunch.py -i data/BD.bin data-compressed/BD.bin
	tools/tscrunch.py -i data/BE.bin data-compressed/BE.bin
	tools/tscrunch.py -i data/BF.bin data-compressed/BF.bin
	tools/tscrunch.py -i data/BG.bin data-compressed/BG.bin
	tools/tscrunch.py -i data/BH.bin data-compressed/BH.bin
	tools/tscrunch.py -i data/BI.bin data-compressed/BI.bin
	tools/tscrunch.py -i data/BJ.bin data-compressed/BJ.bin
	tools/tscrunch.py -i data/BK.bin data-compressed/BK.bin
	tools/tscrunch.py -i data/BL.bin data-compressed/BL.bin
	tools/tscrunch.py -i data/BM.bin data-compressed/BM.bin
	tools/tscrunch.py -i data/BN.bin data-compressed/BN.bin
	tools/tscrunch.py -i data/F5.bin data-compressed/F5.bin
	tools/tscrunch.py -i font_matrix.prg font_matrix.prg
	tools/tscrunch.py -i data/ucieczka.music data-compressed/ucieczka.music
	tools/tscrunch.py -i video.prg video.prg
	tools/tscrunch.py -i scroller.prg scroller.prg
	tools/tscrunch.py -i planet_bitmap.prg planet_bitmap.prg
	# tools/tscrunch.py -i planet_color.prg planet_color.prg
	tools/tscrunch.py -i data/video_font.bin data-compressed/video_font.bin
	tools/tscrunch.py -i data/search-font.bin data-compressed/search-font.bin
	tools/tscrunch.py -i data/results-text.bin data-compressed/results-text.bin
	tools/tscrunch.py -i data/results-vert.bin data-compressed/results-vert.bin
	c1541 -format ' - hondani - ,2024' d64 $(D64_FILE)
	c1541 -attach $(D64_FILE) -write keyb.prg 'the demo'
	c1541 -attach $(D64_FILE) -write data-compressed/BA.bin ba
	c1541 -attach $(D64_FILE) -write data-compressed/BB.bin bb
	c1541 -attach $(D64_FILE) -write data-compressed/BC.bin bc
	c1541 -attach $(D64_FILE) -write data-compressed/BD.bin bd
	c1541 -attach $(D64_FILE) -write data-compressed/BE.bin be
	c1541 -attach $(D64_FILE) -write data-compressed/BF.bin bf
	c1541 -attach $(D64_FILE) -write data-compressed/BG.bin bg
	c1541 -attach $(D64_FILE) -write data-compressed/BH.bin bh
	c1541 -attach $(D64_FILE) -write data-compressed/BI.bin bi
	c1541 -attach $(D64_FILE) -write data-compressed/BJ.bin bj
	c1541 -attach $(D64_FILE) -write data-compressed/BK.bin bk
	c1541 -attach $(D64_FILE) -write data-compressed/BL.bin bl
	c1541 -attach $(D64_FILE) -write data-compressed/BM.bin bm
	c1541 -attach $(D64_FILE) -write data-compressed/BN.bin bn
	c1541 -attach $(D64_FILE) -write data-compressed/F5.bin f5
	c1541 -attach $(D64_FILE) -write font_matrix.prg fontm
	c1541 -attach $(D64_FILE) -write data-compressed/ucieczka.music music
	c1541 -attach $(D64_FILE) -write video.prg video
	c1541 -attach $(D64_FILE) -write scroller.prg scrll
	c1541 -attach $(D64_FILE) -write planet_bitmap.prg pbtmp
	c1541 -attach $(D64_FILE) -write planet_color.prg pcolr
	c1541 -attach $(D64_FILE) -write data-compressed/video_font.bin vfont
	c1541 -attach $(D64_FILE) -write data-compressed/search-font.bin rfont
	c1541 -attach $(D64_FILE) -write data-compressed/results-text.bin restx
	c1541 -attach $(D64_FILE) -write data-compressed/results-vert.bin vertx
