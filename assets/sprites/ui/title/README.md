# Title letters

Drop seven sprites here: `1.png` … `7.png`. The menu lays them in a row at
96px tall (120px for indices 1 and 5 — capital R and B), then bobs them
individually. Any missing file falls back to the plain "Rock Bottom" text, so
the menu works until the set is complete.

Transparent backgrounds, origin centre. If the letter order differs, adjust
`_build_title()` in `scripts/ui/menu.gd`.
