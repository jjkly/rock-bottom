# Characters — the minimum, not a sprite sheet

You need **12 files**, no more:

```
player_down_0.png  .. player_down_3.png   32x48   walk toward camera
player_up_0.png    .. player_up_3.png     32x48   walk away
player_side_0.png  .. player_side_3.png   32x48   walk facing right
```

- **Left** is the side frames mirrored. Don't draw a left set.
- **Idle** is frame `_0`. Don't draw idle frames.
- Frame order: contact, pass, contact, pass — 8 fps in the `AnimatedSprite2D`.
- Origin: bottom-centre (feet). Collision goes on a separate
  `CollisionShape2D` in the scene, not in the art.

Customers later reuse the same 12-file layout: `customer_<dir>_<n>.png`.

## Fish: one image each

`assets/sprites/fish/<species id>.png` — a single still. The tank bob is a
tween on the sprite, not animation frames. No fish needs more than one PNG.

## Everything else: one image each

`restaurant/` props and `ui/` icons are static. If something must animate
later (a sizzle), add a numbered sequence then, not now.
