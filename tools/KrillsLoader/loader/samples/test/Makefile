
ifeq ($(PLATFORM),)
_PLATFORM_     = c64
else ifeq ($(PLATFORM),c116)
_PLATFORM_     = c16
else ifeq ($(PLATFORM),plus4)
_PLATFORM_     = c16
else
_PLATFORM_     = $(PLATFORM)
endif

ifeq ($(NO_VICE),)
NO_VICE        = 0
endif


ifneq ($(_PLATFORM_),c64)
ifneq ($(_PLATFORM_),c16)
$(error invalid platform $(_PLATFORM_) specified)
endif
endif


ARCH           = $(shell uname | tr "[a-z]" "[A-Z]" | tr -c -d "[A-Z]")

ifneq ($(findstring CYGWINNT,$(ARCH)),)
    ifeq (CYGWINNT,$(ARCH))
ARCH           = WIN32
    else
ARCH           = WIN64
    endif    
endif
ifneq ($(findstring DARWIN,$(ARCH)),)
ARCH           = MACOSX
endif


ifeq ($(_PLATFORM_),c16)
    ifneq ($(NO_VICE),0)
        ifneq ($(findstring WIN,$(ARCH)),)
USE_PLUS4EMU   = 0
USE_YAPE       = 1
        else
USE_PLUS4EMU   = 1
USE_YAPE       = 0
        endif
    else
USE_PLUS4EMU   = 0
USE_YAPE       = 0
    endif
else
USE_PLUS4EMU   = 0
USE_YAPE       = 0
endif


ifeq ($(_PLATFORM_),c16)
    ifeq ($(ARCH),MACOSX)
    # MacOSX, these programs must be installed as applications
VICE           = /Applications/VICE/xplus4.app/Contents/MacOS/xplus4
VICE128        = $(VICE)
PLUS4EMU       = /Applications/plus4emu.app/Contents/MacOS/plus4emu
    else    
VICE           = xplus4
PLUS4EMU       = plus4emu
        ifeq ($(ARCH),WIN64)
YAPE           = YapeWin64
        else
YAPE           = Yape
        endif
    endif
else ifeq ($(ARCH),MACOSX)
    # MacOSX, these programs must be installed as applications
VICE           = /Applications/VICE/x64.app/Contents/MacOS/x64
VICE128        = /Applications/VICE/x128.app/Contents/MacOS/x128
else
VICE           = x64
VICE128        = x128
endif

ifeq ($(_PLATFORM_),c16)
# for testing, VICE only
DRIVE9TYPE     = 1551
else
DRIVE9TYPE     = 0
endif

ifneq ($(USE_PLUS4EMU),0)
EMU41          = $(PLUS4EMU) floppy.a.driveType=0 floppy.b.driveType=1 -disk
EMU51          = $(PLUS4EMU) floppy.a.driveType=1 floppy.b.driveType=1 -disk # C-16 only
else
EMU41          = $(VICE) -drive8type 1541 -drive9type $(DRIVE9TYPE) -autostart
EMU51          = $(VICE) -drive8type 1551 -drive9type $(DRIVE9TYPE) -autostart # C-16 only
endif
# the following mode is only supported by VICE and YAPE
EMU81          = $(VICE) -drive8type 1581 -drive9type $(DRIVE9TYPE) -autostart
# the following modes are only supported by VICE
EMU42          = $(VICE) -drive8type 1542 -drive9type $(DRIVE9TYPE) -autostart # 1541-II
EMU70          = $(VICE) -drive8type 1570 -drive9type $(DRIVE9TYPE) -autostart
EMU71          = $(VICE) -drive8type 1571 -drive9type $(DRIVE9TYPE) -autostart
EMU7141        = $(VICE) -drive8type 1571 -drive9type $(DRIVE9TYPE) -autostart # 1571 with .d64
EMU73          = $(VICE128) -drive8type 1573 -drive9type 0 -autostart # 1571CR
EMU7341        = $(VICE128) -drive8type 1573 -drive9type 0 -autostart # 1571CR with .d64
EMU2000        = $(VICE) -drive8type 2000 -drive9type 0 -autostart
EMU4000        = $(VICE) -drive8type 4000 -drive9type 0 -autostart
EMU1001        = $(VICE) -drive8type 1001 -drive9type $(DRIVE9TYPE) -autostart

ifneq ($(USE_PLUS4EMU),0)
EMU941         = $(PLUS4EMU) floppy.a.driveType=0 floppy.b.driveType=0 -disk
EMU951         = $(PLUS4EMU) floppy.a.driveType=1 floppy.b.driveType=0 -disk # C-16 only
else
EMU941         = $(VICE) -drive8type 1541 -drive9type 1541 -autostart
EMU951         = $(VICE) -drive8type 1551 -drive9type 1541 -autostart # C-16 only
endif
# the following modes are only supported by VICE
EMU942         = $(VICE) -drive8type 1542 -drive9type 1541 -autostart # 1541-II
EMU970         = $(VICE) -drive8type 1570 -drive9type 1541 -autostart
EMU971         = $(VICE) -drive8type 1571 -drive9type 1541 -autostart
EMU97141       = $(VICE) -drive8type 1571 -drive9type 1541 -autostart # 1571 with .d64
EMU973         = $(VICE128) -drive8type 1573 -drive9type 1541 -autostart # 1571CR
EMU97341       = $(VICE128) -drive8type 1573 -drive9type 1541 -autostart # 1571CR with .d64
EMU981         = $(VICE) -drive8type 1581 -drive9type 1541 -autostart
EMU92000       = $(VICE) -drive8type 2000 -drive9type 1541 -autostart
EMU94000       = $(VICE) -drive8type 4000 -drive9type 1541 -autostart
EMU91001       = $(VICE) -drive8type 1001 -drive9type 1541 -autostart


SVNVERSION     = svnversion
ifneq ($(wildcard ../../../.svn/format),)
VERSION        = $(shell $(SVNVERSION) | tr -d [:cntrl:])
else
VERSION        =
endif

ECHO           = echo
PRINTF         = printf
HEAD           = head

MAKE           = make
CP             = cp
MV             = mv
RM             = rm -f
MKDIR          = mkdir
ifeq ($(ARCH),MACOSX)
RMDIR          = rmdir # XXX TODO xargs to remove .DS_Store
else
RMDIR          = rmdir
endif
TOUCH          = touch
CAT            = cat

AS             = ca65
LD             = ld65
C1541          = c1541

CC1541         = ../../tools/cc1541

EXO            = exomizer
PU             = pucrunch
BB             = BB
DOYNAX_LZ      = lz # aka Doynamite

# CRUSH.EXE is a DOS program to which no source has been published
ifneq ($(findstring WIN,$(ARCH)),)
    ifeq (WIN64,$(ARCH))
            # WIN64, no native DOS support
DOSBOX         = DOSBox
LC             = ..\..\tools\crush $(LCSPEED)
    else
            # WIN32, CRUSH.EXE does not understand "/" instead of "\"
LC             = ../../tools/crush $(LCSPEED)
    endif
else ifeq ($(ARCH),MACOSX)
    # MacOSX, DOSBox must be installed as an application
DOSBOX         = /Applications/DOSBox.app/Contents/MacOS/DOSBox
LC             = ..\..\tools\crush $(LCSPEED)
else
    # default: use wine to run CRUSH.EXE
LC             = wine ../../tools/crush $(LCSPEED) # XXX TODO try dosemu
endif
LCSPEED        = 6

JAVAC          = javac
JAVA           = java
CONVPATH       = ../../tools
CONVNAME       = CompressedFileConverter
CONV           = $(JAVA) -cp $(CONVPATH) $(CONVNAME)


LOADER         = ../../src
LDRBIN         = ../../build
LDRINC         = ../../include

BUILDDIR       = ../../build
INTERMDIR      = ../../build/interm

RESOURCESDIR   = ../resources


AS_FLAGS       = -I $(LDRINC) -I ../../../shared
PU_FLAGS       = -d -l 0x1000 -x 0x1000 -i 0
ifeq ($(_PLATFORM_),c16)
AS_FLAGS      += -t c16 -D PLATFORM=16
PU_FLAGS      += -c16
else
AS_FLAGS      += -t c64 -D PLATFORM=64
PU_FLAGS      += -c64 -g 0x37
endif


default: all

tellarch:
	@$(ECHO) $(ARCH)


$(BUILDDIR):
	$(MKDIR) $(BUILDDIR)

$(INTERMDIR):
	$(MKDIR) $(INTERMDIR)


SHAREDDEPS     = $(LOADER)/Makefile \
                 $(LDRINC)/common-features.inc \
                 $(LDRINC)/config.inc

LOADERDEPS     = $(SHAREDDEPS) $(BUILDDIR) $(INTERMDIR) \
                 $(LOADER)/decompress/exodecomp.s $(LOADER)/decompress/pudecomp.s $(LOADER)/decompress/doynaxdecomp.s $(LOADER)/decompress/lcdecomp.s $(LOADER)/decompress/bbdecomp.s \
                 $(LOADER)/drives/drivecode1541-kernel.inc $(LOADER)/drives/drivecode1541.s $(LOADER)/drives/drivecode1541-loadfile.s $(LOADER)/drives/drivecode1571.s $(LOADER)/drives/drivecode1581.s \
                 $(LOADER)/hal/hal.inc $(LOADER)/hal/hal-c64.inc $(LOADER)/hal/hal-c16.inc \
                 $(LOADER)/install/install.s \
                 $(LOADER)/resident/resident.s $(LOADER)/resident/decompress.s $(LOADER)/resident/zp-resident.s \
                 $(LDRINC)/resident-jumptable.inc $(LDRINC)/install-jumptable.inc $(LDRINC)/loader.inc $(LDRINC)/diskio.inc

MODULE1541DEPS = $(SHAREDDEPS) \
                 $(LOADER)/drives/drivecode1541-kernel.inc $(LOADER)/drives/drivecode1541.s $(LOADER)/drives/drivecode1541-loadfile.s \
                 $(INTERMDIR)/kernelsymbols1541.inc

DISKIMAGEDEPS  = Makefile $(CC1541) \
                 $(INTERMDIR)/test-$(_PLATFORM_).prg $(LDRBIN)/loader-$(_PLATFORM_).so \
                 $(INTERMDIR)/sheba.prg   $(INTERMDIR)/prlogo.prg \
				 $(INTERMDIR)/shebahi.prg $(INTERMDIR)/prlogohi.prg \
				 $(INTERMDIR)/sheba.exo   $(INTERMDIR)/prlogo.exo \
				 $(INTERMDIR)/shebahi.exo $(INTERMDIR)/prlogohi.exo \
				 $(INTERMDIR)/bothgfx.exo $(INTERMDIR)/bothgfxhi.exo \
				 $(INTERMDIR)/sheba.pu    $(INTERMDIR)/prlogo.pu \
				 $(INTERMDIR)/shebahi.pu  $(INTERMDIR)/prlogohi.pu \
				 $(INTERMDIR)/bothgfx.pu  $(INTERMDIR)/bothgfxhi.pu \
				 $(INTERMDIR)/sheba.dnx   $(INTERMDIR)/prlogo.dnx \
				 $(INTERMDIR)/bothgfx.dnx $(INTERMDIR)/bothgfxhi.dnx \
				 $(INTERMDIR)/shebahi.dnx $(INTERMDIR)/prlogohi.dnx \
				 $(INTERMDIR)/sheba.bb    $(INTERMDIR)/prlogo.bb \
				 $(INTERMDIR)/shebahi.bb  $(INTERMDIR)/prlogohi.bb \
				 $(INTERMDIR)/bothgfx.bb  $(INTERMDIR)/bothgfxhi.bb \
				 $(INTERMDIR)/sheba.lc    $(INTERMDIR)/prlogo.lc \
				 $(INTERMDIR)/shebahi.lc  $(INTERMDIR)/prlogohi.lc \
                 $(INTERMDIR)/bothgfx.lc  $(INTERMDIR)/bothgfxhi.lc


all: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64 \
     $(BUILDDIR)/loadertest-$(_PLATFORM_).d71 \
	 $(BUILDDIR)/loadertest-$(_PLATFORM_).d81


$(LDRBIN)/loader-$(_PLATFORM_).a: $(LOADERDEPS) $(LOADER)/install/dynlink.s $(LOADER)/decompress/exostreamdecr1.s $(LDRBIN)/loader-$(_PLATFORM_).so
	$(MAKE) -C $(LOADER) DEBUG=1 lib-full

$(LDRBIN)/loader-$(_PLATFORM_).so: $(LOADERDEPS)
	$(MAKE) -C $(LOADER) DEBUG=1 so-full

$(LDRBIN)/drivecode1541-loadfile.prg: $(MODULE1541DEPS)
	$(MAKE) -C $(LOADER) DEBUG=1 mods

$(INTERMDIR)/kernelsymbols1541.inc: $(LOADER)/drives/drivecode1541.s $(LOADER)/drives/drivecode1541-loadfile.s
	$(MAKE) -C $(LOADER) ../build/interm/kernelsymbols1541.inc # no usage of $(INTERMDIR) to match the path as seen from loader/src


../../../.svn/entries:
ifeq ($(VERSION),)
	$(MKDIR) ../../../.svn
	$(TOUCH) $@
endif

../../version.inc: ../../../.svn/entries
	$(MAKE) -C ../.. version.inc


$(INTERMDIR)/test-$(_PLATFORM_).o: test.s zp.inc $(LOADERDEPS) $(LOADER)/install/dynlink.s ../../version.inc Makefile
	$(AS) $(AS_FLAGS) -o $@ $<

$(INTERMDIR)/test-$(_PLATFORM_)-uncompressed.prg: Linkfile $(INTERMDIR)/test-$(_PLATFORM_).o $(LDRBIN)/loader-$(_PLATFORM_).a
	$(LD) -o $@ $(INTERMDIR)/test-$(_PLATFORM_).o -C Linkfile -vm -m $@.map -Ln $@.lbl $(LDRBIN)/loader-$(_PLATFORM_).a

$(INTERMDIR)/test-$(_PLATFORM_).prg: $(INTERMDIR)/test-$(_PLATFORM_)-uncompressed.prg
	$(PU) $(PU_FLAGS) $? $@


$(INTERMDIR)/shebahi.prg: $(RESOURCESDIR)/sheba.bin
	$(PRINTF) "\x00\xC0" | $(CAT) - $? > $@

$(INTERMDIR)/prlogohi.prg: $(RESOURCESDIR)/prlogo.bin
	$(PRINTF) "\x00\xC0" | $(CAT) - $? > $@

$(INTERMDIR)/%.prg: $(RESOURCESDIR)/%.bin
	$(PRINTF) "\x00\x40" | $(CAT) - $? > $@

$(CONVPATH)/$(CONVNAME).class: $(CONVPATH)/$(CONVNAME).java
	$(JAVAC) $^

$(INTERMDIR)/%.exo: $(INTERMDIR)/%.prg
	$(EXO) mem -f $? -o $@

$(INTERMDIR)/%.pu: $(INTERMDIR)/%.prg
	$(PU) -c0 -x 0 $? $@

$(INTERMDIR)/%.dnx: $(CONVPATH)/$(CONVNAME).class $(INTERMDIR)/%.prg
	$(DOYNAX_LZ) -o $@ $(filter-out $<, $^)
	$(CONV) dnx $(filter-out $<, $^) $@ $@

$(INTERMDIR)/%.bb: $(CONVPATH)/$(CONVNAME).class $(INTERMDIR)/%.prg
	$(BB) $(filter-out $<, $^)
	$(MV) $(filter-out $<, $^).bb $@
	$(CONV) bb $(filter-out $<, $^) $@ $@

ifeq ($(DOSBOX),)
$(INTERMDIR)/%.lc: $(CONVPATH)/$(CONVNAME).class $(INTERMDIR)/%.prg
	$(LC) $(filter-out $<, $^) out
	$(MV) out $@
	$(CONV) lc $(filter-out $<, $^) $@ $@
else
$(INTERMDIR)/%.lc: $(CONVPATH)/$(CONVNAME).class $(INTERMDIR)/%.prg
	export SDL_VIDEODRIVER=dummy && $(DOSBOX) -noconsole -c "MOUNT C ../.." -c "C:" -c "cd build\interm" -c "..\$(LC) $(notdir $(filter-out $<, $^)) out" -c "exit"
	$(MV) $(INTERMDIR)/OUT $@
	$(CONV) lc $(filter-out $<, $^) $@ $@
endif

$(INTERMDIR)/bothgfx.%: $(INTERMDIR)/sheba.% $(INTERMDIR)/prlogo.%
	$(CAT) $^ > $@

$(INTERMDIR)/bothgfxhi.%: $(INTERMDIR)/shebahi.% $(INTERMDIR)/prlogohi.%
	$(CAT) $^ > $@


# NAME T/S on the .d64 when using cc1541
# TB-SHEBAHI.BIN     7/0
# QB-PRLOGOHI.BIN    9/0
# SE-SHEBA.EXO      11/0
# PE-PRLOGO.EXO      8/2
# BE-BOTHGFX.EXO    12/0
# TE-SHEBAHI.EXO    13/0
# QE-PRLOGOHI.EXO    8/3
# CE-BOTHGFXHI.EXO  14/0
# SP-SHEBA.PU       15/0
# PP-PRLOGO.PU      10/2
# BP-BOTHGFX.PU     16/0
# TP-SHEBAHI.PU     17/0
# QP-PRLOGOHI.PU    11/1
# CP-BOTHGFXHI.PU   19/0
# SV-SHEBA.BB       20/0
# PV-PRLOGO.BB      13/1
# BV-BOTHGFX.BB     21/0
# TV-SHEBAHI.BB     22/0
# QV-PRLOGOHI.BB    15/1
# CV-BOTHGFXHI.BB   23/0
# SL-SHEBA.LC       24/0
# PL-PRLOGO.LC      17/1
# BL-BOTHGFX.LC     25/0
# TL-SHEBAHI.LC     26/0
# QL-PRLOGOHI.LC    20/3
# CL-BOTHGFXHI.LC   27/0
# TD-SHEBAHI.DNX    28/0
# QD-PRLOGOHI.DNX   22/3
# CD-BOTHGFXHI.DNX  29/0
# BD-BOTHGFX.DNX    30/0
# SD-SHEBA.DNX      31/0
# PD-PRLOGO.DNX     31/1
# SB-SHEBA.BIN      32/0
# PB-PRLOGO.BIN     34/0

$(BUILDDIR)/loadertest-$(_PLATFORM_).d64: $(DISKIMAGEDEPS) $(LDRBIN)/drivecode1541-loadfile.prg
	$(CC1541) -n "NORMAL IS BORING" -i PLUSH -S 4 \
	 \
	 -f "LOADER TEST"             -w $(INTERMDIR)/test-$(_PLATFORM_).prg \
	 -f "LOADER.SO"               -w $(LDRBIN)/loader-$(_PLATFORM_).so \
	 -f "LOADER DRIVECODE"        -w $(LDRBIN)/drivecode1541-loadfile.prg \
	  \
	 -f TB-SHEBAHI.BIN   -r 7  -E -w $(INTERMDIR)/shebahi.prg \
	 -f QB-PRLOGOHI.BIN  -r 7  -E -w $(INTERMDIR)/prlogohi.prg \
	  \
	 -f SE-SHEBA.EXO     -r 7  -E -w $(INTERMDIR)/sheba.exo \
	 -f PE-PRLOGO.EXO    -r 7  -E -w $(INTERMDIR)/prlogo.exo \
	 -f BE-BOTHGFX.EXO   -r 7  -E -w $(INTERMDIR)/bothgfx.exo \
	 -f TE-SHEBAHI.EXO   -r 7  -E -w $(INTERMDIR)/shebahi.exo \
	 -f QE-PRLOGOHI.EXO  -r 7  -E -w $(INTERMDIR)/prlogohi.exo \
	 -f CE-BOTHGFXHI.EXO -r 7  -E -w $(INTERMDIR)/bothgfxhi.exo \
	  \
	 -f SP-SHEBA.PU      -r 7  -E -w $(INTERMDIR)/sheba.pu \
	 -f PP-PRLOGO.PU     -r 7  -E -w $(INTERMDIR)/prlogo.pu \
	 -f BP-BOTHGFX.PU    -r 7  -E -w $(INTERMDIR)/bothgfx.pu \
	 -f TP-SHEBAHI.PU    -r 7  -E -w $(INTERMDIR)/shebahi.pu \
	 -f QP-PRLOGOHI.PU   -r 7  -E -w $(INTERMDIR)/prlogohi.pu \
	 -f CP-BOTHGFXHI.PU  -r 7  -E -w $(INTERMDIR)/bothgfxhi.pu \
	  \
	 -f SV-SHEBA.BB      -r 7  -E -w $(INTERMDIR)/sheba.bb \
	 -f PV-PRLOGO.BB     -r 7  -E -w $(INTERMDIR)/prlogo.bb \
	 -f BV-BOTHGFX.BB    -r 7  -E -w $(INTERMDIR)/bothgfx.bb \
	 -f TV-SHEBAHI.BB    -r 7  -E -w $(INTERMDIR)/shebahi.bb \
	 -f QV-PRLOGOHI.BB   -r 7  -E -w $(INTERMDIR)/prlogohi.bb \
	 -f CV-BOTHGFXHI.BB  -r 7  -E -w $(INTERMDIR)/bothgfxhi.bb \
	  \
	 -f SL-SHEBA.LC      -r 7  -E -w $(INTERMDIR)/sheba.lc \
	 -f PL-PRLOGO.LC     -r 7  -E -w $(INTERMDIR)/prlogo.lc \
	 -f BL-BOTHGFX.LC    -r 7  -E -w $(INTERMDIR)/bothgfx.lc \
	 -f TL-SHEBAHI.LC    -r 7  -E -w $(INTERMDIR)/shebahi.lc \
	 -f QL-PRLOGOHI.LC   -r 7  -E -w $(INTERMDIR)/prlogohi.lc \
	 -f CL-BOTHGFXHI.LC  -r 7  -E -w $(INTERMDIR)/bothgfxhi.lc \
	  \
	 -f TD-SHEBAHI.DNX   -r 7  -E -w $(INTERMDIR)/shebahi.dnx \
	 -f QD-PRLOGOHI.DNX  -r 7  -E -w $(INTERMDIR)/prlogohi.dnx \
	 -f CD-BOTHGFXHI.DNX -r 7  -E -w $(INTERMDIR)/bothgfxhi.dnx \
	 -f BD-BOTHGFX.DNX   -r 7  -E -w $(INTERMDIR)/bothgfx.dnx \
	 -f SD-SHEBA.DNX     -r 31 -E -w $(INTERMDIR)/sheba.dnx \
	 -f PD-PRLOGO.DNX    -r 31 -E -w $(INTERMDIR)/prlogo.dnx \
	  \
	 -f SB-SHEBA.BIN     -r 31 -E -w $(INTERMDIR)/sheba.prg \
	 -f PB-PRLOGO.BIN    -r 31 -E -w $(INTERMDIR)/prlogo.prg \
	  \
	 -f LF-LOOPFILE.PRG           -l SD-SHEBA.DNX \
	 \
	$@

# TB-SHEBAHI.BIN     7/0
# QB-PRLOGOHI.BIN    8/0
# SE-SHEBA.EXO       9/0
# PE-PRLOGO.EXO     44/0
# BE-BOTHGFX.EXO    10/0
# TE-SHEBAHI.EXO    45/0
# QE-PRLOGOHI.EXO   11/0
# CE-BOTHGFXHI.EXO  46/0
# SP-SHEBA.PU       12/0
# PP-PRLOGO.PU      47/0
# BP-BOTHGFX.PU     13/0
# TP-SHEBAHI.PU     48/0
# QP-PRLOGOHI.PU    14/0
# CP-BOTHGFXHI.PU   49/0
# SV-SHEBA.BB       15/0
# PV-PRLOGO.BB      50/0
# BV-BOTHGFX.BB     16/0
# TV-SHEBAHI.BB     51/0
# QV-PRLOGOHI.BB    17/0
# CV-BOTHGFXHI.BB   52/0
# SL-SHEBA.LC       19/0
# PL-PRLOGO.LC      54/0
# BL-BOTHGFX.LC     20/0
# TL-SHEBAHI.LC     55/0
# QL-PRLOGOHI.LC    21/0
# CL-BOTHGFXHI.LC   56/0
# TD-SHEBAHI.DNX    22/0
# QD-PRLOGOHI.DNX   57/0
# CD-BOTHGFXHI.DNX  23/0
# BD-BOTHGFX.DNX    58/0
# SD-SHEBA.DNX      31/0
# PD-PRLOGO.DNX     66/0
# SB-SHEBA.BIN      32/0
# PB-PRLOGO.BIN     33/0

$(BUILDDIR)/loadertest-$(_PLATFORM_).d71: $(DISKIMAGEDEPS)
	$(CC1541) -n "NORMAL IS BORING" -i PLUSH -S 3 \
	 -f "LOADER TEST"                -w $(INTERMDIR)/test-$(_PLATFORM_).prg \
	 -f "LOADER.SO"                  -w $(LDRBIN)/loader-$(_PLATFORM_).so \
	 \
	 -f TB-SHEBAHI.BIN   -r 7  -e -c -w $(INTERMDIR)/shebahi.prg \
	 -f QB-PRLOGOHI.BIN  -r 7  -e -c -w $(INTERMDIR)/prlogohi.prg \
	  \
	 -f SE-SHEBA.EXO     -r 7  -e -c -w $(INTERMDIR)/sheba.exo \
	 -f PE-PRLOGO.EXO    -r 7  -e -c -w $(INTERMDIR)/prlogo.exo \
	 -f BE-BOTHGFX.EXO   -r 7  -e -c -w $(INTERMDIR)/bothgfx.exo \
	 -f TE-SHEBAHI.EXO   -r 7  -e -c -w $(INTERMDIR)/shebahi.exo \
	 -f QE-PRLOGOHI.EXO  -r 7  -e -c -w $(INTERMDIR)/prlogohi.exo \
	 -f CE-BOTHGFXHI.EXO -r 7  -e -c -w $(INTERMDIR)/bothgfxhi.exo \
	  \
	 -f SP-SHEBA.PU      -r 7  -e -c -w $(INTERMDIR)/sheba.pu \
	 -f PP-PRLOGO.PU     -r 7  -e -c -w $(INTERMDIR)/prlogo.pu \
	 -f BP-BOTHGFX.PU    -r 7  -e -c -w $(INTERMDIR)/bothgfx.pu \
	 -f TP-SHEBAHI.PU    -r 7  -e -c -w $(INTERMDIR)/shebahi.pu \
	 -f QP-PRLOGOHI.PU   -r 7  -e -c -w $(INTERMDIR)/prlogohi.pu \
	 -f CP-BOTHGFXHI.PU  -r 7  -e -c -w $(INTERMDIR)/bothgfxhi.pu \
	  \
	 -f SV-SHEBA.BB      -r 7  -e -c -w $(INTERMDIR)/sheba.bb \
	 -f PV-PRLOGO.BB     -r 7  -e -c -w $(INTERMDIR)/prlogo.bb \
	 -f BV-BOTHGFX.BB    -r 7  -e -c -w $(INTERMDIR)/bothgfx.bb \
	 -f TV-SHEBAHI.BB    -r 7  -e -c -w $(INTERMDIR)/shebahi.bb \
	 -f QV-PRLOGOHI.BB   -r 7  -e -c -w $(INTERMDIR)/prlogohi.bb \
	 -f CV-BOTHGFXHI.BB  -r 7  -e -c -w $(INTERMDIR)/bothgfxhi.bb \
	  \
	 -f SL-SHEBA.LC      -r 7  -e -c -w $(INTERMDIR)/sheba.lc \
	 -f PL-PRLOGO.LC     -r 7  -e -c -w $(INTERMDIR)/prlogo.lc \
	 -f BL-BOTHGFX.LC    -r 7  -e -c -w $(INTERMDIR)/bothgfx.lc \
	 -f TL-SHEBAHI.LC    -r 7  -e -c -w $(INTERMDIR)/shebahi.lc \
	 -f QL-PRLOGOHI.LC   -r 7  -e -c -w $(INTERMDIR)/prlogohi.lc \
	 -f CL-BOTHGFXHI.LC  -r 7  -e -c -w $(INTERMDIR)/bothgfxhi.lc \
	  \
	 -f TD-SHEBAHI.DNX   -r 7  -e -c -w $(INTERMDIR)/shebahi.dnx \
	 -f QD-PRLOGOHI.DNX  -r 7  -e -c -w $(INTERMDIR)/prlogohi.dnx \
	 -f CD-BOTHGFXHI.DNX -r 7  -e -c -w $(INTERMDIR)/bothgfxhi.dnx \
	 -f BD-BOTHGFX.DNX   -r 7  -e -c -w $(INTERMDIR)/bothgfx.dnx \
	 -f SD-SHEBA.DNX     -r 31 -e -c -w $(INTERMDIR)/sheba.dnx \
	 -f PD-PRLOGO.DNX    -r 31 -e -c -w $(INTERMDIR)/prlogo.dnx \
	  \
	 -f SB-SHEBA.BIN     -r 31 -e -c -w $(INTERMDIR)/sheba.prg \
	 -f PB-PRLOGO.BIN    -r 31 -e -c -w $(INTERMDIR)/prlogo.prg \
	  \
	 -f LF-LOOPFILE.PRG              -l SD-SHEBA.DNX \
	 \
	$@

# NAME T/S on the .d81 when using c1541
# SB-SHEBA.BIN      $27/$00
# PB-PRLOGO.BIN     $27/$20
# TB-SHEBAHI.BIN    $29/$00
# QB-PRLOGOHI.BIN   $29/$20
# SE-SHEBA.EXO      $26/$18
# PE-PRLOGO.EXO     $26/$23
# BE-BOTHGFX.EXO    $2a/$18
# TE-SHEBAHI.EXO    $25/$00
# QE-PRLOGOHI.EXO   $25/$0b
# CE-BOTHGFXHI.EXO  $25/$10
# SP-SHEBA.PU       $25/$20
# PP-PRLOGO.PU      $2b/$00
# BP-BOTHGFX.PU     $2b/$06
# TP-SHEBAHI.PU     $2b/$16
# QP-PRLOGOHI.PU    $2b/$21
# CP-BOTHGFXHI.PU   $2b/$27
# SV-SHEBA.BB       $24/$03
# PV-PRLOGO.BB      $24/$0f
# BV-BOTHGFX.BB     $24/$15
# TV-SHEBAHI.BB     $24/$26
# QV-PRLOGOHI.BB    $2c/$0f
# CV-BOTHGFXHI.BB   $2c/$15
# SL-SHEBA.LC       $2c/$26
# PL-PRLOGO.LC      $23/$0a
# BL-BOTHGFX.LC     $23/$10
# TL-SHEBAHI.LC     $23/$22
# QL-PRLOGOHI.LC    $2d/$0a
# CL-BOTHGFXHI.LC   $2d/$10
# SD-SHEBA.DNX      $2d/$22
# PD-PRLOGO.DNX     $22/$06
# BD-BOTHGFX.DNX    $22/$0c
# TD-SHEBAHI.DNX    $22/$1d
# QD-PRLOGOHI.DNX   $2e/$05
# CD-BOTHGFXHI.DNX  $2e/$0b

$(BUILDDIR)/loadertest-$(_PLATFORM_).d81 $(BUILDDIR)/loadertest-$(_PLATFORM_).d82: $(DISKIMAGEDEPS)
	$(C1541) -format "normal is boring,+h" $(subst .,,$(suffix $@)) $@
	$(C1541) -attach $@ \
	 -write $(INTERMDIR)/sheba.prg              "sb-sheba.bin" \
	 -write $(INTERMDIR)/prlogo.prg             "pb-prlogo.bin" \
	 -write $(INTERMDIR)/shebahi.prg            "tb-shebahi.bin" \
	 -write $(INTERMDIR)/prlogohi.prg           "qb-prlogohi.bin" \
	  \
	 -write $(INTERMDIR)/sheba.exo              "se-sheba.exo" \
	 -write $(INTERMDIR)/prlogo.exo             "pe-prlogo.exo" \
	 -write $(INTERMDIR)/bothgfx.exo            "be-bothgfx.exo" \
	 -write $(INTERMDIR)/shebahi.exo            "te-shebahi.exo" \
	 -write $(INTERMDIR)/prlogohi.exo           "qe-prlogohi.exo" \
	 -write $(INTERMDIR)/bothgfxhi.exo          "ce-bothgfxhi.exo" \
	  \
	 -write $(INTERMDIR)/sheba.pu               "sp-sheba.pu" \
	 -write $(INTERMDIR)/prlogo.pu              "pp-prlogo.pu" \
	 -write $(INTERMDIR)/bothgfx.pu             "bp-bothgfx.pu" \
	 -write $(INTERMDIR)/shebahi.pu             "tp-shebahi.pu" \
	 -write $(INTERMDIR)/prlogohi.pu            "qp-prlogohi.pu" \
	 -write $(INTERMDIR)/bothgfxhi.pu           "cp-bothgfxhi.pu" \
	  \
	 -write $(INTERMDIR)/sheba.bb               "sv-sheba.bb" \
	 -write $(INTERMDIR)/prlogo.bb              "pv-prlogo.bb" \
	 -write $(INTERMDIR)/bothgfx.bb             "bv-bothgfx.bb" \
	 -write $(INTERMDIR)/shebahi.bb             "tv-shebahi.bb" \
	 -write $(INTERMDIR)/prlogohi.bb            "qv-prlogohi.bb" \
	 -write $(INTERMDIR)/bothgfxhi.bb           "cv-bothgfxhi.bb" \
	  \
	 -write $(INTERMDIR)/sheba.lc               "sl-sheba.lc" \
	 -write $(INTERMDIR)/prlogo.lc              "pl-prlogo.lc" \
	 -write $(INTERMDIR)/bothgfx.lc             "bl-bothgfx.lc" \
	 -write $(INTERMDIR)/shebahi.lc             "tl-shebahi.lc" \
	 -write $(INTERMDIR)/prlogohi.lc            "ql-prlogohi.lc" \
	 -write $(INTERMDIR)/bothgfxhi.lc           "cl-bothgfxhi.lc" \
	  \
	 -write $(INTERMDIR)/sheba.dnx              "sd-sheba.dnx" \
	 -write $(INTERMDIR)/prlogo.dnx             "pd-prlogo.dnx" \
	 -write $(INTERMDIR)/bothgfx.dnx            "bd-bothgfx.dnx" \
	 -write $(INTERMDIR)/shebahi.dnx            "td-shebahi.dnx" \
	 -write $(INTERMDIR)/prlogohi.dnx           "qd-prlogohi.dnx" \
	 -write $(INTERMDIR)/bothgfxhi.dnx          "cd-bothgfxhi.dnx" \
	  \
	 -write $(LDRBIN)/loader-$(_PLATFORM_).so   "loader.so" \
	 -write $(INTERMDIR)/test-$(_PLATFORM_).prg "loader test"


ifneq ($(USE_YAPE),0)
run run41 run51: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(YAPE) "..\..\build\loadertest-$(_PLATFORM_).d64"
else
run run41: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU41) $^

run51: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU51) $^
endif

run41ii run42: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU42) $^

run70: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU70) $^

run71: $(BUILDDIR)/loadertest-$(_PLATFORM_).d71
	$(EMU71) $^

run7141: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU7141) $^

run73: $(BUILDDIR)/loadertest-$(_PLATFORM_).d71
	$(EMU73) $^

run7341: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU7341) $^

ifneq ($(USE_YAPE),0)
run81: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(YAPE) "..\..\build\loadertest-$(_PLATFORM_).d81"
else
run81: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU81) "$^:loader test"
endif

run2000: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU2000) "$^:loader test"

run4000: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU4000) "$^:loader test"

run1001: $(BUILDDIR)/loadertest-$(_PLATFORM_).d82
	$(EMU1001) "$^:loader test"

ifneq ($(USE_YAPE),0)
run9 run941 run951: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(YAPE) /DISK9:"..\..\build\loadertest-$(_PLATFORM_).d64" "..\..\build\loadertest-$(_PLATFORM_).d64"
else
run9 run941: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU941) $^

run951: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU951) $^
endif

run941ii run942: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU942) $^

run970: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU970) $^

run971: $(BUILDDIR)/loadertest-$(_PLATFORM_).d71
	$(EMU971) $^

run97141: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU97141) $^

run973: $(BUILDDIR)/loadertest-$(_PLATFORM_).d71
	$(EMU973) $^

run97341: $(BUILDDIR)/loadertest-$(_PLATFORM_).d64
	$(EMU97341) $^

ifneq ($(USE_YAPE),0)
run981: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(YAPE) /DISK9:"..\..\build\loadertest-$(_PLATFORM_).d81" "..\..\build\loadertest-$(_PLATFORM_).d81"
else
run981: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU981) "$^:loader test"
endif

run92000: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU92000) "$^:loader test"

run94000: $(BUILDDIR)/loadertest-$(_PLATFORM_).d81
	$(EMU94000) "$^:loader test"

run91001: $(BUILDDIR)/loadertest-$(_PLATFORM_).d82
	$(EMU91001) "$^:loader test"

	
clean:
	-$(RM) \
	 $(INTERMDIR)/test-$(_PLATFORM_).o $(INTERMDIR)/test-$(_PLATFORM_)-uncompressed.prg $(INTERMDIR)/test-$(_PLATFORM_).prg \
	 $(INTERMDIR)/test-$(_PLATFORM_)-uncompressed.prg.map $(INTERMDIR)/test-$(_PLATFORM_)-uncompressed.prg.lbl \
	 $(INTERMDIR)/*.prg  $(INTERMDIR)/*.exo $(INTERMDIR)/*.pu $(INTERMDIR)/*.dnx $(INTERMDIR)/*.bb $(INTERMDIR)/*.lc
	-$(RMDIR) $(INTERMDIR)

distclean:
	$(MAKE) -C $(LOADER) clean
	$(MAKE) -C $(CC1541)_source clean

wipe: distclean clean


$(CC1541): $(CC1541)_source/cc1541.cpp
	$(MAKE) -C $(CC1541)_source
