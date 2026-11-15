# Fish sprites

File name **must** match `SpeciesDef.id` in `data/species/<id>.tres`.
All fish are 16×16 nigiri from the 10-kawaii-sushi pack, copied here under the
species name. Overwrite the PNG in place to change the look; the `.tres`
already points at it.

| File | Species | Preference | Price |
|---|---|---|---|
| lean_tuna.png | Lean Tuna | lean | 28 |
| salmon.png | Salmon | fatty | 22 |
| sea_bream.png | Sea Bream | lean | 26 |
| mackerel.png | Mackerel | cheap | 14 |
| toro.png | Fatty Tuna | fatty | 44 |
| hokkigai.png | Surf Clam | fatty | 30 |
| ebi.png | Sweet Shrimp | lean | 24 |
| tako.png | Octopus | lean | 20 |
| cured_saba.png | Cured Saba | cheap | 18 |
| tamago.png | Tamago | cheap | 12 |
| eel.png | Eel | fatty | 32 (unagi art added) |

Origin: bottom-centre when placed in a scene. Neutral colours only — modifiers
tint them (`data/modifiers/*.tres`) so Golden and Chroma work without extra art.

`SpeciesDef.sprite` is the **nigiri** (after cutting). `SpeciesDef.raw_sprite` is the
**whole fish** shown before cutting in the crate and raw stock rows.

| Raw art | Species |
|---|---|
| tuna.png | Lean Tuna, Fatty Tuna |
| Salmon2.png | Salmon |
| flounder.png | Flounder |
| Mackeral.png | Mackerel, Cured Saba |
| eel2.png | Eel |
| surfclam.png | Surf Clam |
| Shrimp.png | Sweet Shrimp |
| octopus.png | Octopus |

Tamago (egg) has no raw art and falls back to its nigiri. Add a species by duplicating a `.tres`, setting `sprite`,
and dropping a same-named PNG here.
