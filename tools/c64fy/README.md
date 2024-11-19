# Convert RGB PNG files

Save as RGB PNG file in Gimp and convert to `planety_bmpdata.a`
```
./c64fy.py -hires 1 planety.png
```

Then, move `planety_bmpdata.asm` to <project root folder, next to scroller.asm>/planety_bmpdata.asm`

Edit the file to get such structure:
```asm
.segment PLANET_BITMAP []
*=$2000
planety_bitmapdata:
.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
...

.segment PLANET_COLOR []
*=$0400
planety_chardata:
.byte $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
...
.file [name="planet_bitmap.prg", segments="PLANET_BITMAP"]
.file [name="planet_color.prg", segments="PLANET_COLOR"]


```


C64fy python script comes from: https://github.com/thojor79/bacillus_c64/tree/master/convert
Gimp palette is downloaded from: https://github.com/denilsonsa/gimp-palettes/blob/master/palettes/HW-Commodore-64-pepto.gpl