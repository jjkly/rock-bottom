"""Slice emma's character sheets into frames + generate SpriteFrames resources.

Run from the project root:
    python tools/build_character.py
"""
from PIL import Image
import os

SRC = "assets/sprites/characters"
OUT_P = os.path.join(SRC, "player")
OUT_F = os.path.join(SRC, "fishing")
os.makedirs(OUT_P, exist_ok=True)
os.makedirs(OUT_F, exist_ok=True)


def frames(path, pitch, count, w, h):
    im = Image.open(path).convert("RGBA")
    return [im.crop((i * pitch, 0, i * pitch + w, h)) for i in range(count)]


def save(imgs, outdir, anim, pad=None):
    paths = []
    for i, fr in enumerate(imgs):
        if pad:
            canvas = Image.new("RGBA", pad, (0, 0, 0, 0))
            canvas.alpha_composite(fr, ((pad[0] - fr.width) // 2, pad[1] - fr.height))
            fr = canvas
        p = os.path.join(outdir, f"{anim}_{i}.png")
        fr.save(p)
        paths.append(p)
    return paths


# Player states share a 12x18 canvas so feet stay planted across animations.
idle = save(frames(f"{SRC}/idle.png", 8, 7, 7, 16), OUT_P, "idle", (12, 18))
walk = save(frames(f"{SRC}/walk.png", 8, 4, 7, 18), OUT_P, "walk", (12, 18))
hold_idle = save(frames(f"{SRC}/holdidle.png", 11, 7, 10, 18), OUT_P, "hold_idle", (12, 18))
hold_walk = save(frames(f"{SRC}/hold walk.png", 11, 4, 10, 18), OUT_P, "hold_walk", (12, 18))

fishing_idle = save(frames(f"{SRC}/fishing idle.png", 29, 5, 28, 16), OUT_F, "fishing_idle")
fishing_bite = save(frames(f"{SRC}/fishing bite v2.png", 29, 2, 28, 16), OUT_F, "fishing_bite")
fishing_initiate = save([Image.open(f"{SRC}/fishing1.png").convert("RGBA")], OUT_F, "fishing_initiate")


def write_frames(path, animations):
    ext = []
    for anim in animations:
        for p in anim["files"]:
            ext.append(p)
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(ext) + 1} format=3]', ""]
    ids = {}
    for i, p in enumerate(ext):
        rid = f"{i + 1}_{os.path.basename(p).replace('.', '_')}"
        ids[p] = rid
        lines.append(f'[ext_resource type="Texture2D" path="res://{p.replace(os.sep, "/")}" id="{rid}"]')
    lines += ["", "[resource]", "animations = ["]
    blocks = []
    for anim in animations:
        fr = ",\n".join(
            '{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}' % ids[p] for p in anim["files"]
        )
        blocks.append(
            '{\n"frames": [\n%s\n],\n"loop": true,\n"name": &"%s",\n"speed": %.1f\n}'
            % (fr, anim["name"], anim["speed"])
        )
    lines.append(",\n".join(blocks))
    lines.append("]")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    print("wrote", path)


write_frames(
    os.path.join(OUT_P, "player_frames.tres"),
    [
        {"name": "idle", "speed": 5.0, "files": idle},
        {"name": "walk", "speed": 8.0, "files": walk},
        {"name": "hold idle", "speed": 5.0, "files": hold_idle},
        {"name": "hold walk", "speed": 8.0, "files": hold_walk},
    ],
)
write_frames(
    os.path.join(OUT_F, "fishing_frames.tres"),
    [
        {"name": "fishing idle", "speed": 5.0, "files": fishing_idle},
        {"name": "fishing bite", "speed": 5.0, "files": fishing_bite},
        {"name": "fishing initiate", "speed": 5.0, "files": fishing_initiate},
    ],
)
print("player frames:", len(idle) + len(walk) + len(hold_idle) + len(hold_walk))
