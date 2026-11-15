"""Compose a restaurant interior background from the pixelinterior kit.

Run from the project root: python tools/build_interior.py
Output: assets/sprites/restaurant/interior.png (1280x720)
"""
from PIL import Image
import os

PACK = "assets/art_source/pixelinterior"
OUT = "assets/sprites/restaurant/interior.png"
W, H = 1280, 720
WALL_H = 158
TRIM = (91, 58, 41, 255)

floors = Image.open(f"{PACK}/floorswalls_LRK.png").convert("RGBA")
kitchen = Image.open(f"{PACK}/kitchen_LRK.png").convert("RGBA")
doors = Image.open(f"{PACK}/doorswindowsstairs_LRK.png").convert("RGBA")

# Clean 32x32 stone floor tile, plus the dominant cream wall colour.
floor_tile = floors.crop((88, 162, 120, 194))
wall_px = floors.getpixel((40, 40))

canvas = Image.new("RGBA", (W, H), (*wall_px[:3], 255))

# Wall band and skirting.
canvas.paste(Image.new("RGBA", (W, WALL_H), (*wall_px[:3], 255)), (0, 0))
canvas.paste(Image.new("RGBA", (W, 8), TRIM), (0, WALL_H))
canvas.paste(Image.new("RGBA", (W, 6), (60, 45, 38, 255)), (0, WALL_H + 8))

# Tiled floor.
for y in range(WALL_H + 14, H, floor_tile.height):
    for x in range(0, W, floor_tile.width):
        canvas.alpha_composite(floor_tile, (x, y))

# Furniture: counter behind the cutting board, cabinet run left, door, fridge.
def put(sheet, box, pos, scale=2):
    piece = sheet.crop(box)
    piece = piece.resize((piece.width * scale, piece.height * scale), Image.NEAREST)
    canvas.alpha_composite(piece, pos)


put(kitchen, (23, 11, 168, 76), (400, 30))       # counter with sink
put(kitchen, (16, 75, 137, 122), (70, 42))       # lower cabinet run
put(doors, (113, 16, 143, 64), (880, 14), scale=3)  # closed door
put(kitchen, (345, 259, 396, 320), (1070, 34))   # fridge

canvas.save(OUT)
print("wrote", OUT, canvas.size)
