.PHONY: clean

clean:
	rm -f *.dbg *.prg *.sym *.vs .source.txt chunk.tmp *.vsf meetro.din

build-loader:
	EXTCONFIGPATH=`pwd` && \
	cd tools/krill194/loader/src && \
	make prg INSTALL=0e00 RESIDENT=9000 ZP=90 && \
	cp ../build/install-c64.prg ../../../../install-c64.prgx && \
	cp ../build/loader-c64.prg ../../../../loader-c64.prgx