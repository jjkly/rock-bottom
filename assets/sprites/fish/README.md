# Fish sprites

File name **must** match `SpeciesDef.id` in `data/species/<id>.tres`.
Override the PNG in place, then open the `.tres` and confirm `sprite` is set
(the starter data leaves it empty on purpose).

| File | Size | Added |
|---|---|---|
| lean_tuna.png | 32x24 | starter |
| salmon.png | 32x20 | starter |
| sea_bream.png | 32x28 | starter |
| mackerel.png | 32x18 | starter |
| eel.png | 44x16 | starter |
| meguro.png | 32x22 | TODO |
| bream_gold.png | 32x26 | TODO |

Origin: bottom-centre when placed in a scene. Draw fish facing **right**.
Neutral colours only — modifiers tint them (`data/modifiers/*.tres`) so Golden
and Chroma work without extra art.
