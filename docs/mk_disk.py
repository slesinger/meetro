#!/usr/bin/python3


# This gets obsolete by build-floppy.asm


import os

DISK_IMAGE = "meetro.d64"

files = [
    {
        "filename": "floppy_code.floppy_prg",
        "start_track": 25,
        "start_sector": 0,
    },
    {
        "filename": "keyb.prg",
        "start_track": 1,
        "start_sector": 0,
    },
    {
        "filename": "font_matrix.prg",
        "start_track": 2,
        "start_sector": 0,
    },
]

# Track	  # Sectors	Speed Zone	µs/Byte	Raw Kbit/Track
#  1 – 17	21  	3	        26	    60.0
# 18 – 24	19	    2	        28	    55.8
# 25 – 30	18	    1	        30	    52.1
# 31 – 35	17	    0	        32	    48.8


# TODO interleave sectors by 4
class DiskLayout:
    # Define the maximum sectors per track
    MAX_SECTORS_PER_TRACK = {
        1: 21, 2: 21, 3: 21, 4: 21, 5: 21, 6: 21, 7: 21, 8: 21, 9: 21, 10: 21,
        11: 21, 12: 21, 13: 21, 14: 21, 15: 21, 16: 21, 17: 21, 18: 19, 19: 19,
        20: 19, 21: 19, 22: 19, 23: 19, 24: 19, 25: 18, 26: 18, 27: 18, 28: 18,
        29: 18, 30: 18, 31: 17, 32: 17, 33: 17, 34: 17, 35: 17, 36: 17, 37: 17,
        38: 17, 39: 17, 40: 17
    }

    def set_start(self, start_track, start_sector):
        self.track = start_track
        self.sector = start_sector
        return (self.track, self.sector)

    def get_next_sector(self):
        self.sector += 1
        max_sectors = self.MAX_SECTORS_PER_TRACK.get(self.track, None)
        if max_sectors is None:
            raise ValueError(f"Track {self.track} not found in disk layout")
        if self.sector >= max_sectors:
            self.sector = 0
            self.track += 1
        return self.track, self.sector


# Delete old disk image
if os.path.exists(DISK_IMAGE):
    os.remove(DISK_IMAGE)

# Create a new disk image
os.system("c1541 -format ' - hondani - ,2025' d64 " + DISK_IMAGE)

# Put fastloader on it as the only visible file in directory
# os.system(f"c1541 -attach {DISK_IMAGE} -write fastloader.prg fastloader")
# os.system(f"c1541 -attach {DISK_IMAGE} -write keyb.prg keyb")
os.system(f"c1541 -attach {DISK_IMAGE} -write verticaler.prg verticaler")

# Iterate over files in list
for file in files:
    filename = file["filename"]
    layout = DiskLayout()
    (track, sector) = layout.set_start(
        file["start_track"], file["start_sector"])

    # Read the file
    with open(filename, "rb") as f:
        data = f.read()
        # if .prg file, skip first 2 bytes
        if filename.endswith(".prg"):
            data = data[2:]

        # split file into 256 byte chunks
        chunks = [data[i:i + 256] for i in range(0, len(data), 256)]

        # write each chunk to disk to track and sector
        for chunk in chunks:
            # If chunk is less than 256 bytes, pad with zeros
            if len(chunk) < 256:
                chunk += b"\x00" * (256 - len(chunk))
            # Write chunk to temporary file
            with open("chunk.tmp", "wb") as tmp:
                tmp.write(chunk)
            print(f"writting {filename}\t\t{track}:{sector}")
            os.system(f"c1541 -attach {DISK_IMAGE} -bwrite chunk.tmp {track} \
                      {sector}")
            (track, sector) = layout.get_next_sector()
