# BPUI

Premium UI library for Roblox scripts. Runs on PC and mobile, makes **zero HTTP requests** of its own, and every executor-specific function it touches is optional and guarded — so it works on low-level executors too.

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

A dark glass window with a tab sidebar on the left and grouped cards on the right. Every surface is lit from above with a gradient, edges catch light along the top, and the window floats on a soft shadow. Pressing anything sends a ripple out from the point of contact; switching tabs slides the page in while an accent pill glides to the new tab. Six palettes ship with it and the accent colour is yours to set.

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
| `Icon` | number/string | — | `rbxassetid` shown in the sidebar and the mobile bubble |
| `Theme` | string/table | `"Obsidian"` | See Themes |
| `Accent` | Color3 | theme accent | Highlight colour |
| `Size` | UDim2/Vector2 | 720×480 (540×360 mobile) | Auto-fitted to the screen |
| `Scale` | number | `1` | Multiplier applied after the auto-fit |
| `RememberSize` | bool | `true` | Restore the last resized size |
| `SidebarWidth` | number | 196 (150 mobile) | |
| `ToggleKey` | KeyCode/string | `RightShift` | Show/hide key on PC |
| `FloatingButton` | bool | mobile only | Force the bubble on PC too |
| `FloatingText` | string | first two letters | Text inside the bubble |
| `Resizable` | bool | PC only | Bottom-right resize grip |
| `Search` | bool | `true` | Search field that filters every element in every tab |
| `Transparency` | number | `0.02` | Window background transparency |
| `ConfigFolder` | string | Title | Files live in `BPUI/<ConfigFolder>/` |
| `ShowSettings` | bool | `true` | Built-in Settings tab |
| `SettingsName` | string | `"Settings"` | Rename that tab |
| `CloseBehavior` | string | `"Destroy"` | `"Hide"` makes the X hide instead |
| `ConfirmClose` | bool | `false` | Ask before unloading |
| `AutoLoad` | bool | `true` | Apply the auto-load config shortly after launch |
| `AutoLoadDelay` | number | `1` | Seconds to wait first |
| `WelcomeNotification` | bool | `true` | "Press X to toggle" toast |
| `KeySystem` | table | — | See Key system |
| `OnDestroy` | function | — | Called when the window unloads |
| `Footer` | string | `BPUI vX` | Bottom of the sidebar |

**Methods**

`CreateTab(config)` · `SelectTab(tabOrName)` · `Show()` · `Hide()` · `Toggle()` · `SetVisible(bool)` · `Minimize(state?)` · `Search(text)` · `Dialog(config)` · `SetTitle(text)` · `SetSubtitle(text)` · `SetToggleKey(key)` · `SetFloatingButtonVisible(bool)` · `Notify(config)` · `SaveConfig(name)` · `LoadConfig(name)` · `GetConfigs()` · `DeleteConfig(name)` · `SetAutoLoad(name|nil)` · `GetAutoLoad()` · `LoadAutoConfig()` · `Destroy()`

### `Window:CreateTab(config)` → Tab

Takes `{ Name = "Main", Subtitle = "shown in the header", Icon = 123456 }`, or just a string.

Methods: `CreateSection(name)` · `Select()` · `SetName(text)` · `SetSubtitle(text)` · `Destroy()`. Every `Add*` element method also exists directly on a tab — an untitled section is created for you.

### `Tab:CreateSection(name)` → Section

A grouped card with a spaced uppercase header. Methods: `SetTitle(text)` · `SetVisible(bool)` · `Destroy()` plus the element constructors. `Add*` and `Create*` are interchangeable.

### Elements

Shared keys: `Name`, `Description`, `Flag` (config key — must be unique), `Callback`.

Shared methods: `Set(value, silent)` (aliases `SetValue`, `Update`) · `Get()` · `SetVisible(bool)` · `SetName(text)` · `SetDescription(text)` · `SetCallback(fn)` · `SetLocked(bool)` / `Lock()` / `Unlock()` · `Destroy()`. The current value is always on `.Value`.

| Element | Extra config | Callback gets | `.Value` |
| --- | --- | --- | --- |
| `AddButton` | — | nothing | — |
| `AddToggle` | `Default` | `state` | boolean |
| `AddSlider` | `Min` `Max` `Default` `Increment` `Suffix` `Typeable` | number | number |
| `AddDropdown` | `Options` `Default` `Multi` `Searchable` | option or table | string / table |
| `AddInput` | `Placeholder` `Default` `Numeric` `MaxLength` `Width` `ClearOnFocus` `CallbackOnChange` `RemoveTextAfterFocusLost` | `text, enterPressed` | string |
| `AddKeybind` | `Default` `Mode` (`Press`/`Toggle`/`Hold`) `OnChanged` | Press: nothing · Toggle: `state` · Hold: `true`/`false` | key name |
| `AddColorPicker` | `Default` (Color3 / hex / `{r,g,b}`) | Color3 | Color3 |
| `AddLabel` | `Text` `Style` (`Accent`/`Sub`/`Success`/`Warning`/`Error`) `Center` `Bold` `TextSize` | — | string |
| `AddParagraph` | `Title` `Content` | — | string |
| `AddDivider` | height | — | — |

Extras: `Dropdown:Refresh(options, keepValue)` · `Dropdown:Open()/Close()` · `Slider:SetRange(min, max)` · `Keybind:GetKeyCode()` · `ColorPicker:Open()/Close()` · `Paragraph:SetTitle()/SetContent()` · `Button:Click()`.

Notes worth knowing: sliders can be dragged or tapped to type an exact number; dropdowns past six options grow a filter box on their own; keybinds take keyboard keys plus the right and middle mouse buttons, Backspace clears and Escape cancels; locked elements dim, stop accepting input and stop accepting typed text, while `Set` still works from code.

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

`Style` is `Default`, `Accent` or `Danger`.

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

### Themes

`Obsidian` (default), `Porcelain`, `Onyx`, `Velvet`, `Abyss`, `Crimson`.

```lua
BPUI:SetTheme("Velvet")
BPUI:SetAccent(Color3.fromRGB(255, 120, 60))
```

Every window repaints live and the choice is remembered. A custom theme is a table with any of these keys; anything you leave out falls back to Obsidian:

```
Backdrop Window Sidebar Surface SurfaceHover Element ElementHover
Stroke StrokeSoft Text SubText Muted Accent AccentText
Success Warning Danger Track Knob Dark
```

```lua
BPUI.Themes.Lime = {
    Accent = Color3.fromRGB(150, 230, 90),
    AccentText = Color3.fromRGB(10, 25, 5),
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
