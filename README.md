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

Near-black glass. Two soft coloured lights sit in the top corners — by default the accent and a hue-shifted sibling — and a huge, faint version of your logo leans across the bottom-right of the page. The sidebar and every card are translucent, so that light bleeds through them. On the left: the brand mark under a glow, a search field, tabs with emoji icons and count badges, and collapsible groups with chevrons. On the right: tracked small-caps section headers with an accent tick, a page title underlined by a fading accent hairline, and one rounded card per setting. Toggles glow when on; a pulse in the footer keeps it alive. Pressing anything ripples from the point of contact; switching tabs slides the page in.

All of it is configurable from the built-in Settings tab: theme, accent, both glow colours, the watermark, and a tiled background image of your own. The user's choices persist.

Tabs, groups and rows all take an `Icon`. The recommended form is a **named icon** — `Icon = "eye"` — a bold filled pictogram (not a thin outline glyph), drawn from frames in the theme's colour so it is always crisp, always tinted to match, and can never come back as a missing-glyph box. It stays flat monochrome by default; pass `Colored = true` alongside it to opt any single icon into a two-tone accent tint instead (see **Icons** below). Emoji (`Icon = "🎯"`, rendered in colour by Roblox, but newer emoji are missing from its font) and `rbxassetid` images (tinted) also work.

Nothing is fetched to draw it. Every icon — the close cross, the chevrons, the checkmarks, the magnifier, the toast badges — is composed from rotated frames, and the shadows are stacked frames rather than an image. No asset can fail to load, and no glyph can come back as a missing-character box.

---

## Why it will not throw `HttpError`

The library never calls `HttpGet`, `request`, `syn.request` or anything like them. It loads no external images and no external fonts — icons are drawn from frames, fonts are Roblox built-ins, and JSON goes through `HttpService:JSONEncode/Decode`, which is a local operation with no network involved.

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
| `Icon` | string/number | — | Named icon, emoji or `rbxassetid`; drawn bare next to the title and used as the page watermark |
| `IconColored` | bool | `false` | Two-tone accent color for the brand mark's named icon (see Icons) |
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
| `Transparency` | number | `0.02` | Window background transparency |
| `Background` | table | see Background | Ambient glow, watermark, texture |
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

Takes `{ Name = "Main", Subtitle = "shown in the header", Icon = "🏠", Colored = false, Badge = 3 }`, or just a string. `Icon` is a named icon, emoji or an `rbxassetid`; `Colored` opts a named icon into the two-tone accent look (see Icons); `Badge` is a count or short text shown in a pill at the right.

Methods: `CreateSection(name)` · `Select()` · `SetName(text)` · `SetSubtitle(text)` · `SetIcon(icon, colored)` · `SetBadge(value|nil)` · `Destroy()`. Every `Add*` element method also exists directly on a tab — an untitled section is created for you.

### `Window:CreateGroup(config)` → Group

A collapsible header in the sidebar with tabs nested under it. Also takes `Colored` alongside `Icon`.

```lua
local combat = Window:CreateGroup({ Name = "Combat", Icon = "cpu", Open = true })
local aim = combat:CreateTab({ Name = "Aimbot", Icon = "crosshair" })
local esp = combat:CreateTab({ Name = "ESP", Icon = "eye" })
```

Clicking the header folds the group with an animation and rotates its chevron. Selecting a tab inside a closed group opens it. Methods: `CreateTab(config)` · `Open()` · `Close()` · `Toggle()` · `SetOpen(bool)` · `IsOpen()` · `SetName(text)` · `Destroy()`. Search hides a group whose tabs have no matches.

### Icons

119 named icons ship inside the library — bold filled pictograms in the style of a modern emoji/glyph set, not thin Lucide-style outlines, all drawn from frames, dots, filled shapes and "donut" bands on a 24-unit grid:

```
activity alert anchor arrow-down arrow-left arrow-right arrow-up battery bell bolt book
bookmark box bug calendar camera chart check chevron-down chevron-right clock code coins
compass config cpu crosshair crown database diamond dice door download droplet egg esp
eye filter fire flag flask folder fps gamepad gauge gear gem ghost gift globe grid
hammer heart home hourglass info key keyboard layers leaf link list lock magnet mail
map medal minus money monitor mouse orbit palette pause paw percent phone pin play plus
power question radar refresh repeat rocket save search send server settings shield
skull sliders sparkles star sun sword tag target terminal thumbsup timer tool tornado
trash trending-up trophy upload user users volume wallet wand warning wifi wrench x zap
```

Names are case-insensitive and may be prefixed `lucide:`. `terminal`/`code`, `gear`/`settings`, `gem`/`diamond` and `warning`/`alert` are aliases for the same icon.

By default every icon renders flat monochrome, tinted to match the theme (or the row's hover/selected state) exactly like before. Pass `Colored = true` next to any `Icon` — on `CreateWindow` (the brand mark), `CreateTab`, `CreateGroup`, any row's `Add*` config, or `Background = { WatermarkColored = true }` for the page watermark — to opt that one icon into a two-tone look: a hue-shifted accent color on its secondary shapes, layered over the base color. `SetIcon(icon, colored)` on a tab, group or element changes both the icon and its colored flag together at runtime. Monochrome stays the default everywhere, so nothing changes unless you ask for color.

`BPUI.Icons` is the table, so you can add your own: `BPUI.Icons.myicon = function(d) d.fill(3, 3, 18, 18, 4) d.dot(12, 12, 3, "dim") end`. Every drawing call takes an optional trailing **role**: omitted/`"primary"` is the base color; `"accent"` is the secondary hue in `Colored` mode (identical to primary otherwise — use it for a part that should merge into one silhouette when uncolored); `"dim"` is always shifted for contrast against whatever it sits on, in both modes — use it for a "cut-in" void detail (a pupil, a keyhole, a clock hand) that must stay visible regardless of theme or color mode. Primitives, all on the same 24-unit grid: `d.line(x1,y1,x2,y2,role)`, `d.thick(x1,y1,x2,y2,width,role)`, `d.dot(cx,cy,r,role)`, `d.ring(cx,cy,r,role)` (thin stroke), `d.band(cx,cy,r,width,role)` (thick "donut" stroke), `d.rect(x,y,w,h,radius,role)` (outline), `d.fill(x,y,w,h,radius,role)` (filled). Draw a role-tagged "hole" or accent detail *after* the base shape it sits on top of — later calls paint over earlier ones.

### `Tab:CreateSection(name)` → Section

A grouped card with a spaced uppercase header. Methods: `SetTitle(text)` · `SetVisible(bool)` · `Destroy()` plus the element constructors. `Add*` and `Create*` are interchangeable.

### Elements

Shared keys: `Name`, `Description`, `Flag` (config key — must be unique), `Callback`, `Icon` (a named icon, emoji or `rbxassetid`, drawn at the left of the row, like Windows 11 Settings), `Colored` (two-tone accent tint for a named `Icon`, see Icons), `Tooltip` (shows after hovering half a second, PC only).

Shared methods: `Set(value, silent)` (aliases `SetValue`, `Update`) · `Get()` · `SetVisible(bool)` · `SetName(text)` · `SetDescription(text)` · `SetCallback(fn)` · `SetTooltip(text)` · `SetIcon(icon, colored)` · `SetLocked(bool)` / `Lock()` / `Unlock()` · `Destroy()`. The current value is always on `.Value`.

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

```lua
Background = {
    Ambient = true,                        -- the two corner glows
    Orb1 = Color3.fromRGB(190, 50, 130),   -- omit to follow the accent
    Orb2 = Color3.fromRGB(110, 70, 220),   -- omit to follow a hue-shifted accent
    OrbSize = 620, OrbOpacity = 0.26,
    Watermark = true,                      -- giant faint brand icon / initials
    WatermarkAlpha = 0.955,
    WatermarkColored = false,              -- true tints it with the icon's two-tone accent hue instead of flat monochrome
    Image = 123456789,                     -- optional tiled texture (rbxassetid)
    ImageAlpha = 0.92, ImageTileSize = 96,
}
```

`Window:SetBackground(partial)` changes any of these live and remembers the result; pass `Orb1 = false` to hand a glow back to the accent. The Settings tab exposes the same controls to the user.

### Themes

`Void` (default — near-black glass with an orchid accent), `Nocturne` (deep blue-black), `FluentDark` and `FluentLight` (the Windows 11 system palettes), `Obsidian`, `Midnight`, `Nord`, `Crimson`.

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
