# BPUI

Windows 11 Fluent UI library for Roblox scripts. Runs on PC and mobile, makes **zero HTTP requests** of its own, and every executor-specific function it touches is optional and guarded — so it works on low-level executors too.

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local Window = BPUI:CreateWindow({ Title = "My Hub", Subtitle = "v1.0" })
local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection("Player")

Section:AddToggle({
    Name = "Infinite Jump",
    Description = "Jump again while already airborne.",
    Flag = "InfJump",
    Callback = function(state) print(state) end,
})
```

That is the whole install. One file, one line.

---

## What it looks like

A flat near-black panel, fully opaque, with nothing behind the page at all — no ambient glow, no giant watermark, no glass. Depth comes from an even tonal ladder instead: the sidebar is the darkest surface, the page a step above it, each row card a step above that, and every card is closed by a hairline a shade lighter again. On the left: the brand mark, a search field, tabs with real icons and count badges, and collapsible groups with chevrons. On the right: tracked small-caps section headers with an accent tick, a page title underlined by a fading accent hairline, and one rounded card per setting. The accent appears only where something is on, selected or focused. A pulse in the footer keeps it alive, pressing anything ripples from the point of contact, and switching tabs slides the page in.

Motion runs on one curve — a fast start with a long, soft settle — from a 130ms hover through to a 280ms page change, so the whole interface moves as one thing rather than a collection of separate animations. The single exception is the nav indicator, which snaps with a small overshoot when you select a tab.

The Settings tab lets the user change theme, accent and a tiled background image of their own, and remembers the choices.

Tabs, groups and rows all take an `Icon`. The recommended form is a **named icon** — `Icon = "eye"` — a real [Lucide](https://lucide.dev) icon, sliced out of a spritesheet baked into the library and rendered as a tinted image, so it's a genuine icon rather than a hand-drawn approximation of one. It stays flat monochrome by default, tinted to match the theme; pass `Colored = true` alongside it to tint that one icon with the theme's accent color instead, or `IconColor = Color3.fromRGB(...)` for a fixed color of your own (see **Icons** below). Emoji (`Icon = "🎯"`, rendered in colour by Roblox, but newer emoji are missing from its font) and `rbxassetid` images (tinted the same way) also work.

The library ships the icon table itself — no lookup is fetched at runtime, unlike libraries that pull their icon list down over HTTP on first load. Internal chrome (the close cross, the chevrons, the checkmarks, the magnifier, the toast badges) stays exactly what it always was: composed from rotated frames, no asset involved, and shadows are stacked frames rather than an image. Named/emoji/`rbxassetid` icons render as ordinary Roblox images, the same way any UI's icon would — an unknown name falls back to rendering the text/emoji itself rather than a missing-glyph box, and a bad custom `rbxassetid` behaves like any bad asset id would anywhere else in Roblox.

---

## Why it will not throw `HttpError`

The library never calls `HttpGet`, `request`, `syn.request` or anything like them — the icon table (~340 names) ships embedded in the file, not fetched on load. Named icons render as ordinary `rbxassetid` images from Roblox's own asset servers, the same way any UI's icon would; fonts are Roblox built-ins, and JSON goes through `HttpService:JSONEncode/Decode`, which is a local operation with no network involved.

The only request in the whole setup is the `HttpGet` **you** write to fetch this file, and that is your executor's request, not the UI's.

---

## Executor compatibility

Everything optional is detected at runtime and wrapped in `pcall`:

| Needs | Used for | Missing it means |
| --- | --- | --- |
| `gethui()` → `CoreGui` → `PlayerGui` | where the UI is parented | falls down the chain automatically |
| `writefile` `readfile` `isfile` `isfolder` `makefolder` `listfiles` `delfile` | configs, remembered settings, saved key | the Configuration section says so; everything else works |
| `setclipboard` / `toclipboard` | the Get Key button | the link is shown in a notification instead |
| `getgenv()` → `_G` | cleanup when the script is re-run | `_G` is used instead |

Nothing else is required beyond standard Roblox services.

---

## Mobile

Detected automatically. The window starts smaller and scales down further on small screens, a draggable bubble opens and closes it, the resize grip is hidden, hover effects are turned off so nothing sticks highlighted, and every control — sliders, the colour wheel, dropdown filters, window dragging — takes touch. A second finger landing somewhere else will not hijack a drag in progress.

---

## API

### `BPUI:CreateWindow(config)` → Window

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | string | `"BPUI"` | Also the config folder name and the re-run cleanup key |
| `Subtitle` | string | — | Small line under the title |
| `Icon` | string/number | — | Named icon, emoji or `rbxassetid`; drawn bare next to the title in the sidebar |
| `IconColored` | bool | `false` | Tint the brand mark's named icon with the accent color instead of the theme default (see Icons) |
| `IconColor` | Color3 | — | Fixed color for the brand mark's icon, overriding both the theme default and `IconColored` |
| `BrandBox` | bool | `false` | Put the brand icon inside an accent-coloured rounded square |
| `Theme` | string/table | `"Void"` | See Themes |
| `Accent` | Color3 | theme accent | Highlight colour |
| `Size` | UDim2/Vector2 | 840×580 (560×400 mobile) | Auto-fitted to the screen |
| `Scale` | number | `1` | Multiplier applied after the auto-fit |
| `RememberSize` | bool | `true` | Restore the last resized size |
| `SidebarWidth` | number | 218 (156 mobile) | |
| `ToggleKey` | KeyCode/string | `RightShift` | Show/hide key on PC |
| `FloatingButton` | bool | mobile only | Force the bubble on PC too |
| `FloatingText` | string | first two letters | Text inside the bubble |
| `Resizable` | bool | PC only | Bottom-right resize grip |
| `Search` | bool | `true` | Search field that filters every element in every tab |
| `Transparency` | number | `0` | Window background transparency. Opaque by default; raise it only if you also turn `Acrylic` on |
| `Background` | table | see Background | Optional tiled texture behind the page |
| `SectionStyle` | string | `"Caps"` | `"Caps"` for tracked uppercase headers, `"Title"` for sentence case |
| `Acrylic` | bool | `false` | Blur the game behind the window while it is open (Windows 11 Mica feel). Off by default so gameplay stays readable |
| `AcrylicStrength` | number | `14` | Blur radius when `Acrylic` is on |
| `ConfigFolder` | string | Title | Files live in `BPUI/<ConfigFolder>/` |
| `ShowSettings` | bool | `true` | Built-in Settings tab |
| `ShowConfig` | bool | `true` | The Save / Load / Delete section inside Settings. Turn it off when your script has its own config system |
| `SettingsIcon` | string/id | `"sliders"` | Icon for the Settings tab |
| `SettingsName` | string | `"Settings"` | Rename that tab |
| `CloseBehavior` | string | `"Destroy"` | `"Hide"` makes the X hide instead |
| `ConfirmClose` | bool | `false` | Ask before unloading |
| `AutoLoad` | bool | `true` | Apply the auto-load config shortly after launch |
| `AutoLoadDelay` | number | `1` | Seconds to wait first |
| `WelcomeNotification` | bool | `true` | "Press X to toggle" toast |
| `KeySystem` | table | — | See Key system |
| `OnDestroy` | function | — | Called when the window unloads |
| `Footer` | string | `BPUI vX` | Bottom of the sidebar |
| `FooterName` | string | player's display name | Shown above the footer text, next to the pulse |

**Methods**

`CreateTab(config)` · `CreateGroup(config)` · `SelectTab(tabOrName)` · `Show()` · `Hide()` · `Toggle()` · `SetVisible(bool)` · `Minimize(state?)` · `Search(text)` · `Dialog(config)` · `SetTitle(text)` · `SetSubtitle(text)` · `SetToggleKey(key)` · `SetFloatingButtonVisible(bool)` · `Notify(config)` · `SaveConfig(name)` · `LoadConfig(name)` · `GetConfigs()` · `DeleteConfig(name)` · `SetAutoLoad(name|nil)` · `GetAutoLoad()` · `LoadAutoConfig()` · `SetBackground(table)` · `Destroy()` (alias `Unload()`)

### `Window:CreateTab(config)` → Tab

Takes `{ Name = "Main", Subtitle = "shown in the header", Icon = "🏠", Colored = false, IconColor = nil, Badge = 3 }`, or just a string. `Icon` is a named icon, emoji or an `rbxassetid`; `Colored` tints a named icon with the accent color, `IconColor` pins it to a fixed color of your own (see Icons); `Badge` is a count or short text shown in a pill at the right.

Methods: `CreateSection(name)` · `Select()` · `SetName(text)` · `SetSubtitle(text)` · `SetIcon(icon, colored, iconColor)` · `SetBadge(value|nil)` · `Destroy()`. Every `Add*` element method also exists directly on a tab — an untitled section is created for you.

### `Window:CreateGroup(config)` → Group

A collapsible header in the sidebar with tabs nested under it. Also takes `Colored` and `IconColor` alongside `Icon`.

```lua
local combat = Window:CreateGroup({ Name = "Combat", Icon = "cpu", Open = true })
local aim = combat:CreateTab({ Name = "Aimbot", Icon = "crosshair" })
local esp = combat:CreateTab({ Name = "ESP", Icon = "eye" })
```

Clicking the header folds the group with an animation and rotates its chevron. Selecting a tab inside a closed group opens it. Methods: `CreateTab(config)` · `Open()` · `Close()` · `Toggle()` · `SetOpen(bool)` · `IsOpen()` · `SetName(text)` · `Destroy()`. Search hides a group whose tabs have no matches.

### Icons

~340 real icons from the [Lucide](https://lucide.dev) set (ISC license) ship inside the library, embedded as sprite-sheet coordinates — the same technique Rayfield and most other UI libraries use, except the table is baked into `BPUI.lua` itself rather than fetched over HTTP on every load. `Icon = "eye"` slices that icon out of the sheet and renders it as a tinted image. A representative slice of what's in there:

```
activity alarm-clock anchor archive arrow-down arrow-left arrow-right arrow-up at-sign award
banknote bell book book-open bookmark box brain bug building bus calendar camera check
chevron-down chevron-right circle-help clipboard clock cloud code coins compass copy cpu
crosshair crown database dices download droplet egg eye eye-off file filter flag flame
flask-conical folder gamepad gauge ghost gift git-branch github globe grid-2x2 hammer
heart home hourglass image info key keyboard layers leaf link list lock mail map medal
menu monitor mouse package palette phone pin play plus power printer refresh-cw rocket
save scan-eye search send server settings shield skull sliders sparkles star sun sword
tag target terminal thumbs-up timer trash trending-up trophy truck upload user users
volume wallet wand-2 wifi wrench x zap
```

That's a taste of ~340 — the full list is `BPUI.Icons` (a `name -> true` set you can `pairs()` over), or just try the [Lucide icon name](https://lucide.dev/icons) you want; if it's a real Lucide icon it's very likely in there. Names are case-insensitive and may be prefixed `lucide:`. A handful of shorter names carried over from earlier versions are kept as aliases onto their closest real icon, so old scripts keep working unchanged: `alert`/`warning` → `triangle-alert`, `chart` → `bar-chart-3`, `config` → `settings`, `gear` → `cog`, `dice` → `dices`, `door` → `door-open`, `esp` → `scan-eye`, `fire` → `flame`, `flask` → `flask-conical`, `fps` → `gauge-circle`, `grid` → `grid-2x2`, `money` → `banknote`, `paw` → `paw-print`, `question` → `circle-help`, `refresh` → `refresh-cw`, `thumbsup` → `thumbs-up`, `tool` → `wrench`. An unrecognized name falls back to rendering as literal text.

By default every icon renders flat monochrome, tinted to match the theme (or the row's hover/selected state). Pass `Colored = true` next to any `Icon` — on `CreateWindow` (the brand mark, as `IconColored`), `CreateTab`, `CreateGroup` or any row's `Add*` config — to tint that one icon with the theme's accent color instead. For a fixed color of your own, regardless of theme, hover or selection, pass `IconColor = Color3.fromRGB(...)` alongside it — it wins over both the theme default and `Colored`, and once set it stays exactly that color through every later theme change, hover or tab selection. `SetIcon(icon, colored, iconColor)` on a tab, group or element updates all three together at runtime; passing `nil` for `colored`/`iconColor` leaves that one as it was. Monochrome stays the default everywhere, so nothing changes unless you ask for color.

Emoji (`Icon = "🎯"`, rendered natively in color by Roblox — though newer emoji are missing from its font) and a plain `rbxassetid` image both still work exactly as before, and both also accept `IconColor` for a tinted override.

**2.8.0** replaced the drawn-pictogram icon set (119 hand-composed frame icons) with the embedded Lucide sprite sheet described above. Every old name still resolves — either directly, as a real Lucide icon, or through the alias table — so existing scripts render real icons unchanged with no code changes required. The one thing that goes away is authoring a fully custom icon by hand (the old `BPUI.Icons.myicon = function(d) ... end` drawing API); a custom icon now goes through `Icon = "rbxassetid://..."` instead.

### `Tab:CreateSection(name)` → Section

A grouped card with a spaced uppercase header. Methods: `SetTitle(text)` · `SetVisible(bool)` · `Destroy()` plus the element constructors. `Add*` and `Create*` are interchangeable.

### Elements

Shared keys: `Name`, `Description`, `Flag` (config key — must be unique), `Callback`, `Icon` (a named icon, emoji or `rbxassetid`, drawn at the left of the row, like Windows 11 Settings), `Colored` (accent tint for a named `Icon`), `IconColor` (fixed color override, see Icons), `Tooltip` (shows after hovering half a second, PC only).

Shared methods: `Set(value, silent)` (aliases `SetValue`, `Update`) · `Get()` · `SetVisible(bool)` · `SetName(text)` · `SetDescription(text)` · `SetCallback(fn)` · `SetTooltip(text)` · `SetIcon(icon, colored, iconColor)` · `SetLocked(bool)` / `Lock()` / `Unlock()` · `Destroy()`. The current value is always on `.Value`.

| Element | Extra config | Callback gets | `.Value` |
| --- | --- | --- | --- |
| `AddButton` | `Style` (`Default`/`Accent`/`Danger`) | nothing | — |
| `AddToggle` | `Default` | `state` | boolean |
| `AddSlider` | `Min` `Max` `Default` `Increment` `Suffix` `Typeable` | number | number |
| `AddDropdown` | `Options` `Default` `Multi` `Searchable` | option or table | string / table |
| `AddInput` | `Placeholder` `Default` `Numeric` `MaxLength` `Width` `ClearOnFocus` `CallbackOnChange` `RemoveTextAfterFocusLost` | `text, enterPressed` | string |
| `AddKeybind` | `Default` `Mode` (`Press`/`Toggle`/`Hold`) `OnChanged` | Press: nothing · Toggle: `state` · Hold: `true`/`false` | key name |
| `AddColorPicker` | `Default` (Color3 / hex / `{r,g,b}`) | Color3 | Color3 |
| `AddLabel` | `Text` `Style` (`Accent`/`Sub`/`Success`/`Warning`/`Error`) `Center` `Bold` `TextSize` | — | string |
| `AddParagraph` | `Title` `Content` | — | string |
| `AddDivider` | height | — | — |

Extras: `Dropdown:Refresh(options, keepValue)` · `Dropdown:Open()/Close()` (a single-select dropdown's `Set` also accepts `{ "value" }` or `{}`, so scripts written for Rayfield gen2 / Luna port without changes) · `Slider:SetRange(min, max)` · `Keybind:GetKeyCode()` · `ColorPicker:Open()/Close()` · `Paragraph:SetTitle()/SetContent()` · `Button:Click()`.

Notes worth knowing: sliders can be dragged anywhere in a 24px band around the rail, or tapped on the value to type an exact number; dropdowns past six options grow a filter box on their own, only one dropdown or colour panel is ever open at a time, and clicking anywhere else closes it; keybinds take keyboard keys plus the right and middle mouse buttons, Backspace clears and Escape cancels; locked elements dim, stop accepting input and stop accepting typed text, while `Set` still works from code.

### Notifications

```lua
local toast = BPUI:Notify({
    Title = "Saved",
    Content = "Config written to disk.",
    Type = "Success",   -- Info | Success | Warning | Error
    Duration = 4,       -- 0 keeps it until dismissed
})
toast:SetContent("Updated")
toast:Dismiss()
```

Works before any window exists. Top-right on PC, top-centre on mobile, tap to dismiss, five on screen at most.

### Dialogs

```lua
Window:Dialog({
    Title = "Reset everything?",
    Content = "Every flag goes back to its default.",
    Buttons = {
        { Text = "Cancel" },
        { Text = "Reset", Style = "Danger", Callback = function() end },
    },
})
```

`Style` is `Default`, `Accent` or `Danger`. Opening a dialog restores a minimised window first.

### Key system

```lua
KeySystem = {
    Title = "My Hub | Key System",
    Subtitle = "Enter your key to continue",
    Keys = { "KEY-ONE", "KEY-TWO" },
    CaseSensitive = false,
    SaveKey = true,
    GetKeyLink = "https://example.com/key",
    Validate = function(key) return key:sub(1, 3) == "VIP" end,
    MaxAttempts = 3,
}
```

`CreateWindow` waits until the key is accepted, so put the rest of your script after it. A valid key is remembered in `BPUI/<folder>/key.txt` unless you turn that off. Keys written into the script are readable by anyone who opens the file — `Validate` is there if you need something stronger.

### Configs

Every element with a `Flag` is saved. Files land in `BPUI/<ConfigFolder>/configs/<name>.json`, and `settings.json` remembers the theme, accent, toggle key, floating button and window size. The built-in Settings tab has Save, Load, Delete and Auto Load wired up already.

```lua
Window:SaveConfig("pvp")
Window:LoadConfig("pvp")
Window:SetAutoLoad("pvp")
print(BPUI:GetFlag("WalkSpeed"))
BPUI:SetFlag("WalkSpeed", 50)
```

If a config loads before some elements exist — because your script yields, say — those elements pick up their saved value when they are created.

### Background

Nothing is drawn behind the page by default. The only thing this table can add is a texture of your own:

```lua
Background = {
    Image = 123456789,                     -- tiled texture (rbxassetid), omit for none
    ImageAlpha = 0.92,                     -- 1 is invisible, 0 is solid
    ImageTileSize = 96,
    ImageTile = false,                     -- false crops one copy instead of tiling
}
```

`Window:SetBackground(partial)` changes any of these live and remembers the result. The Settings tab exposes the same two controls to the user.

The ambient corner glows and the giant page watermark were removed in 2.7.0 along with their config keys (`Ambient`, `Orb1`, `Orb2`, `Orb3`, `OrbSize`, `OrbOpacity`, `Watermark`, `WatermarkAlpha`, `WatermarkColored`). Passing any of them is harmless — they are simply ignored — but nothing will be drawn.

### Themes

`Void` (default — flat near-black with an orchid accent), `Nocturne` (deep blue-black), `FluentDark` and `FluentLight` (the Windows 11 system palettes), `Obsidian`, `Midnight`, `Nord`, `Crimson`.

```lua
BPUI:SetTheme("FluentLight")
BPUI:SetAccent(Color3.fromRGB(255, 120, 60))
```

Every window repaints live and the choice is remembered. A custom theme is a table with any of these keys; anything you leave out falls back to Nocturne (opaque) — set `SidebarAlpha` / `SurfaceAlpha` / `ElementAlpha` between 0 and 1 to make a glass theme:

```
Window Sidebar TitleBar Surface SurfaceHover Element ElementHover
Stroke StrokeSoft Text SubText Muted Accent AccentText
Success Warning Danger Track KnobOn KnobOff Dark
SidebarAlpha SurfaceAlpha ElementAlpha
```

`KnobOn` is the toggle knob while the switch is on (it sits on the accent, so it should contrast with it) and `KnobOff` is the knob while it is off. `Dark` tells the library which way to angle its edge highlights.

```lua
BPUI.Themes.Lime = {
    Accent = Color3.fromRGB(150, 230, 90),
    AccentText = Color3.fromRGB(10, 25, 5),
    KnobOn = Color3.fromRGB(10, 25, 5),
    Dark = true,
}
BPUI:SetTheme("Lime")
```

### Library helpers

`BPUI:Notify()` · `BPUI:SetTheme()` · `BPUI:SetAccent()` · `BPUI:GetThemes()` · `BPUI:GetFlag()` · `BPUI:SetFlag()` · `BPUI:Destroy()` · `BPUI.Flags` · `BPUI.IsMobile` · `BPUI.Version` · `BPUI.SafeMode` · `BPUI.CopyToClipboard(text)` · `BPUI.FileSystem.Available`

### Safe mode

`BPUI.SafeMode` is on by default. If an element constructor throws — an odd executor, a bad config — the library warns and hands back a harmless stub so the rest of your script keeps running. Turn it off while you are developing to get the real error and stack trace.

---

## Re-running

Creating a window with a `Title` that already exists unloads the previous one first: its GUI goes, its input connections are disconnected, its flags are cleared. Keep the title stable between runs and re-executing is always clean.

---

## Loading

```
https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua
```

GitHub caches raw files for a few minutes, so while you are testing add a throwaway query string (`?v=2`) to force a fresh copy. For anything people depend on, tag a release and load from the tag rather than `main` — a bad commit then cannot reach anyone already using it:

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/v2.0.0/BPUI.lua"))()
```
