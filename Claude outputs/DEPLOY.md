# Deploying BPUI on GitHub

This guide takes you from the files in this folder to a single line that anyone can execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/Loader.lua"))()
```

## 1. Recommended repository layout

```
<repo>/
  BPUI.lua              the library (do not edit unless you are changing the UI itself)
  Loader.lua            entry point: loads BPUI, then the right script for the game
  Hub.lua               universal hub, used when the game has no dedicated script
  games/
    ExampleGame.lua     one file per game, registered in Loader.lua by PlaceId
  README.md
```

Everything except `Loader.lua` is optional. If you only want one script, put it in `Hub.lua` and leave the `GAMES` table empty.

## 2. Create the repository

1. Sign in at github.com and click **New repository** (the "+" in the top-right).
2. Name it, for example `BPUI` or `BPHub`. Choose **Public**. Raw links of private repositories need a token and will not work from an executor.
3. Leave "Add a README" unchecked (you already have one) and click **Create repository**.

## 3. Upload the files

Web upload (no tools needed):

1. On the empty repository page click **uploading an existing file**.
2. Drag `BPUI.lua`, `Loader.lua`, `Hub.lua`, `README.md`, `PROMPT.md`, `DEPLOY.md` into the page.
3. To create the `games` folder, upload `games/ExampleGame.lua` by dragging the whole `games` folder, or later use **Add file -> Create new file** and type `games/ExampleGame.lua` as the name (the slash creates the folder).
4. Write a commit message such as `Initial upload` and click **Commit changes**.

Git command line (if installed):

```bash
cd C:\Users\73x37\Desktop\BPUINEW
git init
git add .
git commit -m "Initial upload"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

GitHub Desktop works as well: File -> Add local repository -> choose the folder -> Publish repository.

## 4. Get the raw URL

Open any file on GitHub and click **Raw**. The address bar shows:

```
https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua
```

`<user>` is your GitHub username, `<repo>` the repository name, `main` the branch. Use exactly this pattern for every file.

## 5. Fill in the placeholders

Search all files for `<user>/<repo>` and replace it with your real path:

- `Loader.lua` -> `REPO = "https://raw.githubusercontent.com/<user>/<repo>/main/"`
- `Hub.lua`, `games/*.lua`, `Example.lua` -> the fallback `loadstring` line (only used when a file is run on its own)
- `README.md` / `PROMPT.md` -> the loading snippet you give to users

Commit the change. Your public one-liner is now:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/Loader.lua"))()
```

## 6. Adding a game

1. Join the game, open the hub, go to **Info -> Copy PlaceId** (or read it from the game's URL: `roblox.com/games/<PlaceId>/...`).
2. Create `games/<Name>.lua` from `games/ExampleGame.lua`.
3. Register it in `Loader.lua`:

```lua
local GAMES = {
    [286090429] = "games/Arsenal.lua",
}
```

4. Commit. Users do not need a new link; the loader always fetches the latest files.

## 7. Updating

- Edit files directly on GitHub (pencil icon) or push again. The raw URL serves the new content within a few minutes (GitHub caches raw files for up to 5 minutes).
- To force a fresh copy while testing, append a throw-away query string: `.../Loader.lua?v=3`.
- Users keep the same link forever.

## 8. Stable versions (optional but recommended)

Branch links (`/main/`) always serve the newest commit. If a broken commit lands, every user gets it immediately. For safety:

1. Go to **Releases -> Draft a new release**, tag it `v1.1.0`, publish.
2. Point production users at the tag instead of the branch:

```
https://raw.githubusercontent.com/<user>/<repo>/v1.1.0/Loader.lua
```

3. Keep `/main/` for your own testing. When a version is verified, create the next tag.

## 9. jsDelivr CDN (optional)

Faster in some regions and never rate limited:

```
https://cdn.jsdelivr.net/gh/<user>/<repo>@main/BPUI.lua
https://cdn.jsdelivr.net/gh/<user>/<repo>@v1.1.0/BPUI.lua
```

Branch links on jsDelivr can be cached for up to 12 hours; purge with `https://purge.jsdelivr.net/gh/<user>/<repo>@main/BPUI.lua` after an update, or use tags.

## 10. Test checklist before sharing

- PC executor: run the one-liner, open/close with the toggle key, drag, resize, minimise, search.
- Mobile executor: floating button opens the window, sliders and colour picker respond to touch, text boxes open the keyboard.
- Settings tab: save a config, reload the script, confirm auto-load restored the values.
- Re-execute the script while the UI is open: the old window must disappear.
- Run once on an executor without file support: the Configuration section should say "unavailable" and nothing else should break.

## 11. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `HttpError` / `Http requests are not enabled` | The executor's `HttpGet` failed (blocked domain, rate limit, wrong URL, private repo) | Check the raw URL in a browser, make the repo public, retry; the library itself never makes requests |
| `attempt to call a nil value (global 'loadstring')` | Executor has no `loadstring` | Paste `BPUI.lua` directly above your script instead of loading it |
| Nothing appears | GUI container blocked | The library falls back from `gethui` to `CoreGui` to `PlayerGui` automatically; check the console for `[BPUI]` warnings |
| Key screen never appears again | A valid key was saved | Delete `BPUI/<ConfigFolder>/key.txt` in the executor workspace |
| Old UI stays after re-running | Different `Title` between runs | Keep the window `Title` constant; that is the cleanup key |
| Element missing, console shows `[BPUI] Failed to create ...` | Safe mode caught an error in that element | Read the message; set `BPUI.SafeMode = false` while developing to get a full stack trace |

## 12. Obfuscation

Not required. If you obfuscate, obfuscate only your hub/game scripts and leave `BPUI.lua` readable: heavy obfuscators sometimes break `loadstring` on low-level executors, and the library has nothing secret in it.
