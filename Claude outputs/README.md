# BPUI

Premium iOS-style UI library for Roblox scripts. Works on **PC and Mobile**, makes **zero HTTP requests** (no `HttpError`), and runs on **low-level executors** because every executor function it touches is optional and guarded.

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua"))()

local Window = BPUI:CreateWindow({ Title = "My Hub", Subtitle = "v1" })
local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection("Player")

Section:AddToggle({
    Name = "Example",
    Flag = "Example",
    Callback = function(state) print(state) end,
})
```

## Files

| File | Purpose |
| --- | --- |
| `BPUI.lua` | The library. Host it on GitHub raw or paste it at the top of a script. |
| `Example.lua` | Every component in one script. Copy from here. |
| `PROMPT.md` | Paste into an AI chat so it writes scripts that use BPUI correctly. |

## Why it does not throw HttpError

The library never calls `HttpGet`, `request`, `loadstring(HttpGet(...))` or loads external images/fonts. Icons are drawn with frames, fonts are Roblox built-ins, and JSON goes through `HttpService:JSONEncode/Decode` (local, no network). The only `HttpGet` in your project is the one **you** use to load `BPUI.lua` itself, and even that is optional if you paste the file.

## Executor compatibility

Every executor API is detected at runtime and wrapped in `pcall`:

| Feature | Uses | Without it |
| --- | --- | --- |
| GUI parenting | `gethui()` -> `CoreGui` -> `PlayerGui` | falls through the chain |
| Configs, saved key, settings | `writefile` `readfile` `isfile` `isfolder` `makefolder` `listfiles` `delfile` | config UI shows "unavailable", everything else works |
| Get Key button | `setclipboard` / `toclipboard` | shows the link in a notification instead |
| Cleanup on re-execute | `getgenv()` -> `_G` | still works with `_G` |

Nothing else is required: only standard Roblox services (`TweenService`, `UserInputService`, `HttpService` for JSON, `Players`).

## Mobile

- Detected automatically (`TouchEnabled` and no mouse).
- A draggable floating bubble opens/closes the window (on PC it is hidden unless `FloatingButton = true`).
- The window auto-scales to fit the screen (`UIScale`), so the layout is identical on phones.
- Every control accepts touch: sliders, colour picker, dragging the window, text boxes.
- Hover effects are disabled on touch devices to avoid "stuck" highlights.

---

## API

### `BPUI:CreateWindow(config)` -> Window

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | string | `"BPUI"` | Sidebar title, config folder name, cleanup key |
| `Subtitle` | string | `""` | Small text under the title |
| `Icon` | number/string | nil | `rbxassetid` for sidebar + floating button |
| `Theme` | string/table | `"Dark"` | `"Dark"`, `"Light"`, `"Midnight"` or a custom table (see Themes) |
| `Accent` | Color3 | theme accent | Highlight colour |
| `Size` | UDim2/Vector2 | 640x440 | Auto-scaled down on small screens |
| `Scale` | number | 1 | Multiplier applied after auto-fit |
| `ToggleKey` | KeyCode/string | `RightShift` | PC show/hide key |
| `FloatingButton` | bool | mobile only | Show the floating bubble |
| `FloatingText` | string | first two letters | Text inside the bubble |
| `ConfigFolder` | string | Title | `BPUI/<ConfigFolder>/` |
| `ShowSettings` | bool | true | Built-in Settings tab |
| `SettingsName` | string | `"Settings"` | Rename the built-in tab |
| `CloseBehavior` | string | `"Destroy"` | `"Hide"` makes the X button hide instead |
| `AutoLoad` | bool | true | Load the auto-load config ~1s after creation |
| `AutoLoadDelay` | number | 1 | Seconds before auto-load |
| `WelcomeNotification` | bool | true | "Press X to open" toast |
| `KeySystem` | table | nil | See Key system |
| `OnDestroy` | function | nil | Called when the window is unloaded |
| `Footer` | string | `BPUI vX` | Text at the bottom of the sidebar |

**Window methods**

`CreateTab(config)` `SelectTab(tabOrName)` `Show()` `Hide()` `Toggle()` `SetVisible(bool)` `SetTitle(text)` `SetSubtitle(text)` `SetToggleKey(key)` `SetFloatingButtonVisible(bool)` `Notify(config)` `SaveConfig(name)` `LoadConfig(name)` `GetConfigs()` `DeleteConfig(name)` `SetAutoLoad(name|nil)` `GetAutoLoad()` `LoadAutoConfig()` `Destroy()`

### `Window:CreateTab(config)` -> Tab

`{ Name = "Main", Icon = 123456 }` or just `"Main"`.

Tab methods: `CreateSection(nameOrConfig)`, `Select()`, `SetName(text)`, `Destroy()`. Every `Add*` element method also exists directly on a tab (an untitled section is created for you).

### `Tab:CreateSection(name)` -> Section

iOS grouped card with an uppercase header. Methods: `SetTitle(text)`, `SetVisible(bool)`, `Destroy()`, and the element constructors below. `Add*` and `Create*` are interchangeable (`AddToggle` == `CreateToggle`).

### Elements

Common keys: `Name`, `Description` (second line), `Flag` (config key, must be unique), `Callback`.

Common methods: `Set(value, silent)`, `Get()`, `SetVisible(bool)`, `SetName(text)`, `SetDescription(text)`, `SetCallback(fn)`, `Destroy()`. `Value` always holds the current value.

| Element | Extra config | Callback receives | `Value` |
| --- | --- | --- | --- |
| `AddButton` | - | nothing | - |
| `AddToggle` | `Default` | `state` | boolean |
| `AddSlider` | `Min` `Max` `Default` `Increment` `Suffix` | `number` | number |
| `AddDropdown` | `Options` `Default` `Multi` | option or table | string / table |
| `AddInput` | `Placeholder` `Default` `Numeric` `MaxLength` `ClearOnFocus` `CallbackOnChange` `RemoveTextAfterFocusLost` | `text, enterPressed` | string |
| `AddKeybind` | `Default` `Mode` (`Press`/`Toggle`/`Hold`) `OnChanged` | Press: nothing, Toggle: `state`, Hold: `true/false` | key name string |
| `AddColorPicker` | `Default` (Color3 / hex / `{R,G,B}`) | `Color3` | Color3 |
| `AddLabel` | `Text` `Style` (`Accent`/`Sub`) `Center` | - | string |
| `AddParagraph` | `Title` `Content` | - | string |
| `AddDivider` | height | - | - |

Extras: `Dropdown:Refresh(options, keepValue)`, `Dropdown:Open()/Close()`, `Slider:SetRange(min, max)`, `Keybind:GetKeyCode()`, `ColorPicker:Open()/Close()`, `Paragraph:SetTitle()/SetContent()`, `Button:Click()`.

Toggles with `Default = true` fire their callback once on creation so the feature starts enabled.

### Notifications

```lua
BPUI:Notify({ Title = "Saved", Content = "Config written.", Type = "Success", Duration = 4 })
-- Type: "Info" | "Success" | "Warning" | "Error"
```

Works before a window exists. Top-right on PC, top-centre on mobile. Tap to dismiss.

### Key system (no HTTP)

```lua
KeySystem = {
    Title = "My Hub | Key System",
    Subtitle = "Enter your key to continue",
    Note = "Get your key from our Discord.",
    Keys = { "KEY-1", "KEY-2" },              -- accepted keys (or Key = "single")
    CaseSensitive = false,
    SaveKey = true,                           -- remembers a valid key in BPUI/<folder>/key.txt
    GetKeyLink = "https://discord.gg/...",    -- Get Key button copies this
    Validate = function(key) return ... end,  -- optional custom check, runs first
    MaxAttempts = nil,                        -- optional
    OnGetKey = function() end,                -- optional
}
```

`CreateWindow` yields until the key is accepted, so put the rest of your script after it. Keys stored in the script are visible to anyone who reads the file; `Validate` lets you plug in your own logic if you need something stronger.

### Configs

Every element with a `Flag` is saved. Files: `BPUI/<ConfigFolder>/configs/<name>.json`. The built-in Settings tab has Save / Load / Delete / Auto Load controls.

If a config is loaded before some elements exist (for example your script yields), those elements still receive their saved value when they are created.

```lua
Window:SaveConfig("pvp")
Window:LoadConfig("pvp")
Window:SetAutoLoad("pvp")
print(BPUI:GetFlag("WalkSpeed"))
BPUI:SetFlag("WalkSpeed", 50)
```

### Themes

Built in: `Dark`, `Light`, `Midnight`. Switch at runtime with `BPUI:SetTheme("Light")` or `BPUI:SetAccent(Color3)`. The user's choice is remembered in `settings.json`.

Custom theme: pass a table with any of these keys (missing keys fall back to Dark):
`Window Sidebar Card CardHover Element Separator Stroke Text SubText Accent AccentText Success Warning Error Toggle ToggleOff Knob`

```lua
BPUI.Themes.Rose = { Accent = Color3.fromRGB(255, 45, 85), Toggle = Color3.fromRGB(255, 45, 85) }
BPUI:SetTheme("Rose")
```

### Library helpers

`BPUI:Notify()` `BPUI:SetTheme()` `BPUI:SetAccent()` `BPUI:GetFlag()` `BPUI:SetFlag()` `BPUI:Destroy()` `BPUI.Flags` `BPUI.IsMobile` `BPUI.Version` `BPUI.CopyToClipboard(text)` `BPUI.FileSystem.Available`

---

## Hosting

1. Upload `BPUI.lua` to a public GitHub repository.
2. Load it with `loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua"))()`.
3. Build your hub or per-game scripts on top, exactly like `Example.lua`.

Re-running a script that creates a window with the same `Title` automatically removes the previous copy.
