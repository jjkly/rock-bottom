# Filling out the itch.io page

Every field on the *Edit game* screen, in the order itch.io shows it, with the
value to paste. Copy-ready text is in the fenced blocks; rules come from
itch.io's HTML5 and quality-guideline pages.

The page must exist before butler can push to it, so fill this in first.

---

## 0. Before you open the form

- [ ] Build both exports and delete `build/` afterwards (it is git-ignored):
      `godot --headless --path . --export-release "Windows Desktop" build/windows/RockBottom.exe`
      and `godot --headless --path . --export-release "Web" build/web/index.html`
- [ ] Have a cover image (630×500, PNG or GIF) ready. Screenshots: 2–4 at
      1280×720. The game's own `assets/sprites/restaurant/interior.png` and a
      crate-reveal screenshot are the two that sell it.
- [ ] Decide the address (`user/rock-bottom`). The game name "Rock Bottom" is
      common; if `rock-bottom` is taken, pick `rockbottom-debt` or similar.
      **The address is permanent and butler pushes to it.**

---

## 1. Page basics

| Field | Value |
|---|---|
| **Title** | `Rock Bottom` |
| **Project URL** | `https://<your-user>.itch.io/<address>` — the page must exist before butler pushes |
| **Short description / tagline** | *(field is labelled "Tagline" under the game name)* `One week. One debt. One shot.` |
| **Classification / Kind of game** | **HTML** (browser-playable). Windows is a download channel on the same page. |
| **Release status** | `In development` |
| **Pricing** | `No payments` — HTML pages can only take donations, so a paid release would have to be Downloadable. Keep it free for the jam build. |
| **Visibility** | `Draft` until the page is finished. Draft/Restricted pages never enter *Most Recent*; the **first public publish** is the only one that does. |

---

## 2. Page content

**Description** (the rich-text box). Paste and then re-add the headings, the
list and the two links, because the editor strips pasted formatting:

```
You lost the week at the tables. The loan shark gives you seven days and a run-down sashimi counter: fish the food yourself, serve it, and pay what you can before dawn on day eight.

The same gamble that ruined you is the only way to reach the best plates. The crate has negative expected value. Golden and Chroma fish only come out of it. Use it in measured doses, or stay poor.

**Three phases a day**
- **Morning.** Read the weather and the newspaper, then go out on the boat.
- **Fishing.** A reel bar decides how big the fish is; a CS:GO-style crate decides what it is. Rares: Golden, Chroma, Ice Cold, Double Serving.
- **Evening.** Cut at the board, carry plates to tables, match what each table wants for +20%, beat a 45-second patience clock.
- **Night.** Pay the installment. Spend the rest on a better rod, a sharper knife, a bigger tank, or a little luck.

**One week, seven installments.** 100, 150, 200, 250, 300, 300, and a $700 balloon on night seven. Miss the minimum and the week is over. Score is the share of the debt you cleared.

Three difficulties, replay rewind on Easy and Medium, run-scoped upgrades, no meta power creep.

Made in Godot 4.7.2. Reported playtime: 20-30 minutes for one week.

**Controls:** WASD to walk, E to take and serve plates, Space to cast and stop the reel. Mouse for the fishing screen and the shop. Esc pauses.

Music by Leonardo Paz (Seaside Village, CC BY 4.0). Sound effects from Freesound and Pixabay; full credits are in the in-game Settings panel under Credits.
```

**Download/embed section** — after the first `butler push`:

| Channel | File on the page | Setting |
|---|---|---|
| `html` | Web build | Tick **This file will be played in the browser** |
| `windows` | `RockBottom.exe` | Leave unticked (native download) |

- **Embed options → Embed in page**, viewport **1280 × 720**.
- Leave **Mobile Friendly** off: the game needs keyboard and mouse.
- **Fullscreen button** on. **Scrollbars** off. **Click to play** on.
- If the embed stays blank: confirm *Kind of game* is **HTML** and that the
  `html` channel is the one ticked for browser play. Both are required.

---

## 3. Metadata tab

| Field | Value |
|---|---|
| **Genre** | Simulation (add *Strategy* only if you want it; pick one primary) |
| **Tags** | `roguelike`, `fishing`, `cooking`, `restaurant`, `pixel-art`, `management`, `godot`, `singleplayer`, `quota`, `gambling` |
| **Platforms** | **Windows** only. Do not tick macOS or Linux: neither has been built or tested. |
| **Input** | Keyboard, Mouse |
| **Multiplayer** | None |
| **Accessibility** | Skip animations is available in Settings (fishing animation); no other claim. Do not select "No text". |
| **Languages** | English only |
| **AI disclosure** | **Yes.** One sound effect (the installment chime) is generative AI. Everything else is human-made or procedurally drawn. |
| **Adult content / Classification** | None. The theme is gambling debt; there is no nudity or gore, so no classification is needed. |
| **Version** | `0.9.0` (matches `--userversion` on the push) |
| **Playtime** | 20–30 minutes per run |
| **Status** | In development |

Tag rules: use these exact suggested tags where they exist, do not add synonyms
(`roquelike`/`rogue-like`), and do not tag platforms you have not tested. Adding
every tag is treated as spam.

---

## 4. Media

| Asset | Spec | What to use |
|---|---|---|
| **Cover image** | 630×500, PNG/GIF | The menu with the letter title, or a service screenshot. Keep text off the edges; itch crops on some layouts. |
| **Screenshots** | 1280×720 | (1) title/settings credits, (2) fishing crate mid-reveal with a rare frame, (3) evening service with tables and plates, (4) shop. |
| **Video** | Optional | Only if you have a 20–30 s capture; not required. |

No animated cover with flashing effects (photosensitivity rule).

---

## 5. Community and visibility

| Field | Value |
|---|---|
| **Comments** | On |
| **Visibility** | Draft while filling in, then Public once the builds are attached and tested logged out |
| **Price** | Free |

---

## 6. After the page exists: push and verify

```bash
butler login
butler push build/windows <user>/<game>:windows --userversion 0.9.0
butler push build/web     <user>/<game>:html    --userversion 0.9.0
butler status <user>/<game>
```

- [ ] `butler status` shows both channels at `0.9.0`.
- [ ] Open the page in a private window, logged out: the game starts in the
      browser, and the Windows download unpacks and runs.
- [ ] The share image on social previews is the cover, not a blank square.

Butler only diffs against the last build on the same channel; keep channel
names (`windows`, `html`) fixed forever, since a typo creates a second
download entry on the page.

---

## 7. Things that will get the page delisted

- Publishing before the builds and screenshots are attached.
- Ticking macOS/Linux/Android without a tested build for them.
- Tagging every genre, or every language.
- Describing content that is not in the build (for example a bestiary that is
  still an idea in the GDD).
- An AI disclosure that says "no" while an AI-generated asset ships.
- Recreating the page later to "boost" it. Edit this one instead.

---

## 8. Known gaps to fix before you call the page final

These are visible to players and are easy to read as unfinished:

- The restaurant ambience music has no verifiable licence. Confirm the source
  or swap it before a commercial release.
- No bestiary, no meta unlocks, no mid-run save. Do not advertise them.
- Player art is front-facing only; customers do not walk in.
- Version string on the menu still reads `v0.9`; bump it with the build.
