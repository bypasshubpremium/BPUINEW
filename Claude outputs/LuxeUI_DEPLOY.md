# Deploying LuxeUI on GitHub

> Ultra-Premium UI Library - Ready to Ship

This guide takes you from local files to a working one-liner that executes LuxeUI globally.

---

## 1. Repository Structure

```
<repo>/
  LuxeUI.lua              -- Core library (the library itself)
  LuxeUI_Loader.lua       -- Entry point (one-liner loads this)
  LuxeUI_Example.lua      -- Example showcase
  Hub.lua                 -- Universal hub template
  games/
    ExampleGame.lua       -- Template per-game script
  README.md               -- Full documentation
  DEPLOY.md               -- This file
```

---

## 2. Create GitHub Repository

1. Go to **github.com** and click **+** (top-right) → **New repository**
2. Name: `LuxeUI` or `PremiumHub`
3. Select **Public** (important - private repos need a token)
4. Click **Create repository**

---

## 3. Upload Files

### Option A: Web Upload (Easiest)

1. Click **uploading an existing file**
2. Drag all files into the page:
   - `LuxeUI.lua`
   - `LuxeUI_Loader.lua`
   - `LuxeUI_Example.lua`
   - `Hub.lua`
   - `README.md`
   - `DEPLOY.md`
3. For `games/` folder: drag the entire `games` folder or create it manually
4. Write commit message: `Initial LuxeUI release`
5. Click **Commit changes**

### Option B: Git Command Line

```bash
cd C:\Users\73x37\Desktop\LuxeUI
git init
git add .
git commit -m "Initial LuxeUI release"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/LuxeUI.git
git push -u origin main
```

---

## 4. Get Raw URLs

On GitHub, click any file → **Raw** button. You'll get:

```
https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI.lua
```

Pattern: `https://raw.githubusercontent.com/<user>/<repo>/main/<file>`

---

## 5. The One-Liner

Users load LuxeUI with:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI_Loader.lua"))()
```

That's it. The loader handles everything else.

---

## 6. Update Placeholders

Search and replace `bypasshubpremium` → your GitHub username:

In **LuxeUI_Loader.lua**:
```lua
local REPO = "https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/"
```

In **Hub.lua**, **games/ExampleGame.lua**, **LuxeUI_Example.lua**:
```lua
local LuxeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI.lua"))()
```

---

## 7. Test Checklist

- [ ] Repository is **Public** (not private)
- [ ] All files uploaded successfully
- [ ] Raw URLs work in browser (not 404)
- [ ] One-liner loads without errors
- [ ] Window appears with luxury styling
- [ ] Animations are smooth (0.35s tweens)
- [ ] Tabs and buttons work
- [ ] Notifications display correctly
- [ ] Mobile detection works (touch optimized)

---

## 8. Sharing

Give users this line to copy:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI_Loader.lua"))()
```

They paste it into their Roblox executor and LuxeUI loads instantly.

---

## 9. Versioning (Optional)

For stable releases:

1. Go to **Releases** → **Draft a new release**
2. Tag: `v2.0.0`
3. Title: `LuxeUI v2.0 - Ultra-Premium Release`
4. Publish

Then share this tag-based URL (always stable):

```
https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/v2.0.0/LuxeUI_Loader.lua
```

---

## 10. Updates

- Edit files directly on GitHub (pencil icon) or push new versions
- GitHub caches raw files for up to 5 minutes
- Use `?v=1` query string to bypass cache while testing:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI_Loader.lua?v=1"))()
```

---

## 11. Troubleshooting

| Problem | Solution |
|---------|----------|
| `HttpError` | Repo is private - make it Public |
| Raw URL shows 404 | Check spelling, repository name, file name |
| Old version loads | GitHub caching - wait 5 min or use `?v=X` |
| Animations lag | Network issue - check executor speed |
| Mobile broken | Ensure TouchEnabled detection works |

---

## 🚀 You're Ready!

Your ultra-premium LuxeUI is now live on GitHub.

**Final One-Liner:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/LuxeUI/main/LuxeUI_Loader.lua"))()
```

Share and dominate! 💎✨
