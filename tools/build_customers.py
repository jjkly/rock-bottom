"""Build 6 seated customer variants from the chef's idle frame.

Recolours three regions only, so outline and shoes stay black:
  - hair: black pixels in the top two rows (the cap)
  - eyes: black pixels at rows 3 and 5
  - shirt: the grey body colour
Run from the project root: python tools/build_customers.py
"""
from PIL import Image
import os

SRC = "assets/sprites/characters/player/idle_0.png"
OUT = "assets/sprites/characters/customers"
os.makedirs(OUT, exist_ok=True)

BLACK = (0, 0, 0, 255)
GREY = (119, 119, 119, 255)

# hair, eyes, shirt
VARIANTS = [
    ((26, 26, 26), (59, 110, 165), (74, 111, 165)),
    ((107, 62, 38), (63, 125, 79), (163, 75, 75)),
    ((217, 180, 91), (74, 123, 181), (79, 138, 91)),
    ((181, 72, 60), (122, 74, 42), (106, 74, 138)),
    ((61, 90, 128), (90, 90, 90), (176, 106, 47)),
    ((154, 154, 154), (45, 45, 45), (47, 127, 127)),
]


def build(im, hair, eyes, shirt):
    out = im.copy()
    px = out.load()
    top = next(y for y in range(im.height)
               if any(px[x, y][3] for x in range(im.width)))
    hair_rows = {top, top + 1, top + 2}
    eye_rows = {top + 3, top + 5}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if (r, g, b) == GREY[:3]:
                px[x, y] = (*shirt, 255)
            elif (r, g, b) == BLACK[:3]:
                if y in hair_rows:
                    px[x, y] = (*hair, 255)
                elif y in eye_rows:
                    px[x, y] = (*eyes, 255)
    return out


base = Image.open(SRC).convert("RGBA")
for i, (hair, eyes, shirt) in enumerate(VARIANTS, 1):
    out = build(base, hair, eyes, shirt)
    path = os.path.join(OUT, f"customer_{i}.png")
    out.save(path)
    print("wrote", path)
