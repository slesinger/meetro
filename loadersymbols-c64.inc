// repository version 194, built on Sat, 19 Oct 2024 10:53:45 +0200 for project "loader" using
// make PLATFORM=c64 prg INSTALL=2800 RESIDENT=9000 ZP=90 PROJECT=

// configuration
.const config_ALLOW_2_MHZ_ON_C128      = 0
.const config_DECOMPRESSOR             = 0// NONE
.const config_DIRTRACK                 = 18
.const config_DIRTRACK81               = 40
.const config_END_ADDRESS_API          = 0
.const config_FILENAME_MAXLENGTH       = 16
.const config_FILE_EXISTS_API          = 0
.const config_INTERNAL                 = 0
.const config_LOAD_COMPD_API           = 0
.const config_LOAD_RAW_API             = 1
.const config_LOAD_TO_API              = 0
.const config_LOAD_UNDER_D000_DFFF     = 0
.const config_LOAD_VIA_KERNAL_FALLBACK = 0
.const config_MEM_DECOMP_API           = 0
.const config_MEM_DECOMP_TO_API        = 0
.const config_NTSC_COMPATIBILITY       = 0
.const config_ONLY_1541_AND_COMPATIBLE = 0
.const config_PREFER_SPEED_OVER_SIZE   = 0
.const config_UNINSTALL_API            = 0

// status codes
.const status_OK                       = $00
.const status_DEVICE_INCOMPATIBLE      = $fb
.const status_TOO_MANY_DEVICES         = $fc
.const status_GENERIC_KERNAL_ERROR     = $fd
.const status_DEVICE_NOT_PRESENT       = $fe
.const status_FILE_NOT_FOUND           = $ff

// zeropage $90-$95
.const loader_zp_first                 = $90
.const loadaddrlo                      = $90
.const loadaddrhi                      = $91
.const loader_zp_last                  = $94

// install $2800-$4353
.const install                         = $2800

// resident $9000-$90e0
.const loadraw                         = $9000
