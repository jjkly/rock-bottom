# For a teammate who doesn't code

You will not write code. You will move things in the Godot editor, replace
placeholder images, and drag buttons around. This page is everything needed to
get the project running on a fresh machine, and how not to break it.

Work time estimate: **15 minutes** the first time, then about 1 minute a day.

---

## What you need (install once)

| Thing | Where | Notes |
|---|---|---|
| Godot **4.7.2** | https://godotengine.org/download/windows/ | Download the **.NET-free "Standard"** build, not "Mono". Unzip it anywhere. |
| GitHub account | https://github.com/signup | Send your username to the project owner. |
| A folder to keep the project | e.g. `C:\Projects\` | Must not be inside OneDrive or a synced folder. |

You do **not** need: Git, a terminal, Visual Studio, Python, or the command line.
The only terminal step is optional and listed at the end.

---

## Step 1 — Accept the invite

Check your email for "invited you to collaborate on jjkly/sashimi-debt" and
click **Accept invitation**. Without this, GitHub will say the repo does not
exist — that is what a private repo looks like to someone without access.

---

## Step 2 — Download the project

Use the **GitHub Desktop** app (a normal program with buttons, not a terminal):

1. Install GitHub Desktop: https://desktop.github.com
2. Sign in with your GitHub account.
3. **File → Clone repository → GitHub.com** → pick `jjkly/sashimi-debt`.
4. Set *Local path* to `C:\Projects\sashimi-debt`. **Clone.**

You now have the project. Later updates are one button (see Step 6).

> Prefer no extra software? On the repo page click **Code → Download ZIP**,
> unzip it. You can play, but you cannot take updates without re-downloading
> the whole thing, so GitHub Desktop is worth the 2 minutes.

---

## Step 3 — Open the project in Godot

**Do not open `project.godot` by double-clicking** — that opens the wrong Godot
if you have more than one installed. Instead:

1. Run the Godot 4.7.2 `.exe` you downloaded.
2. In the Project Manager click **Import**.
3. Navigate to `C:\Projects\sashimi-debt` and choose **`project.godot`**.
4. Click **Import & Edit**.

The first open will spend up to a minute importing images. That is normal.

If Godot says *"This project was last edited in a newer version"*, you downloaded
the wrong Godot version. It must be 4.7.x.

---

## Step 4 — Press Play

Press **F5** (or the ▶ button, top right).

You should land on a dark screen that says **"Day 1 of 7"**.

Controls: **P1** `WASD` + `E`, **P2** arrow keys + `Enter`. Fishing/shop use the mouse and `Space`.

If you see a red "Errors" toast at the bottom, copy the text and paste it in the
group chat. Do not click things randomly to fix it.

---

## Step 5 — Do your work (this is the part you are here for)

Open your scene from the **FileSystem** panel (bottom left) by double-clicking
it in `scenes/`. The **Scene** panel (top left) lists everything in it.

| You want to… | Do this |
|---|---|
| Swap a placeholder image for real art | Drag your PNG into the right folder in `assets/sprites/…`, then in the Scene panel click the `Sprite` node and change **Texture** in the Inspector (right side) to your file. |
| Move a button or label | Click it in the Scene panel, then drag it in the 2D view, or edit **offset_left/top/right/bottom** in the Inspector. |
| Change text | Click the node, edit **text** in the Inspector. |
| Change a colour | Inspector → **theme_override_colors/font_color**. |
| Make something bigger | Inspector → **theme_override_font_sizes/font_size**. |

Save with **Ctrl+S** after every change. Save often.

The files you should touch, and who owns them, are in `docs/PLAN.md`
(§ Who does what). Short version: **you own the scene you were assigned. Do not
open anyone else's `.tscn`.** That single rule is what stops two edits from
destroying each other.

---

## Step 6 — Get updates and share your work

In **GitHub Desktop**:

**Getting updates** (do this first thing, every session):
click **Fetch origin** → if it says "Pull origin", click it. That is the whole
update process.

**Sharing your work** (at the end of your session):

1. GitHub Desktop shows your changed files on the left. **Uncheck anything you
   did not mean to change.**
2. Bottom left, type a short description: `Sushi sprites for 5 fish`.
3. Click **Commit to main**.
4. Click **Push origin** (top right).

That is push. No terminal.

**Rules so nothing gets lost:**

- Pull at the start, push at the end. Never sit on unsaved work for days.
- If GitHub Desktop says *"a file changed on GitHub"* and offers to pull, pull.
- If it shows a **conflict** (red file), stop and ask. Do not guess.
- Close Godot before pulling. It locks files and the pull will fail.
- Never use **Discard changes** unless you are sure — it deletes your work.

---

## Step 7 — Optional: build together live (Team Create)

The project includes the *Team Create* plugin, which lets two people edit the
same project in real time.

1. Open the project in Godot.
2. The plugin appears as a dock/tab called **Team Create**.
3. **To host:** click **Host LAN**, note the IP address it shows.
4. **To join:** type the host's IP in the box, click **Join**.

Both people must be on the same network (same house / same Wi-Fi), or the host
needs port forwarding. Everyone still owns their own scene — live editing does
not make two people in one `.tscn` safe.

---

## If something is wrong

| Symptom | Fix |
|---|---|
| "Project not found" during clone | Invite not accepted yet (Step 1). |
| Godot asks to upgrade the project | Wrong Godot version. Use 4.7.x. |
| Everything is pink/magenta squares | That is the placeholder art, not a bug. |
| Text is unreadable / missing | You may have edited a `theme_override` — undo with Ctrl+Z and ask. |
| "Cannot open file, resource busy" | Godot is open. Close it, retry the pull. |
| Scene opens blank / empty | You are looking at a phase scene's root — its contents are children; click the arrow to expand. |
| You broke something | GitHub Desktop → right-click the file → **Discard changes**. Only works if you have not committed. |

---

## For the curious: what the terminal version looks like

Only if you ever want it — the buttons above do exactly this.

```bash
git clone https://github.com/jjkly/sashimi-debt.git
cd sashimi-debt
git pull        # get updates
git add -A      # stage your changes
git commit -m "sushi sprites"
git push        # share
```
