# BPUI
Works on **PC and Mobile**, makes **zero HTTP requests** (no `HttpError`), and runs on **low-level executors** because every executor function it touches is optional and guarded. Version 1.1.0.

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
| `Loader.lua` | One-line entry point: loads the library, then the script for the current game (by PlaceId) or `Hub.lua`. |
| `Hub.lua` | Universal hub template. |
| `games/ExampleGame.lua` | Per-game script template. |
| `Example.lua` | Every component in one script. Copy from here. |
| `DEPLOY.md` | Step-by-step GitHub upload, raw links, versioning, troubleshooting. |
| `PROMPT.md` | Paste into an AI chat so it writes scripts that use BPUI correctly. |
| `test/` | Roblox API mock + automated tests (`lua test/test_bpui.lua`, `lua test/smoke.lua`). Not needed in the executor. |

## Highlights

- Window: drag, resize grip (PC), true minimise to a title bar, search field that filters every element across all tabs, floating open/close bubble for mobile, toggle key for PC, remembered size/theme/accent/key.
- Elements: Button, Toggle, Slider (drag or tap-to-type), Dropdown (single / multi, built-in filter for long lists), Input, Keybind (keyboard + mouse buttons, Press/Toggle/Hold), ColorPicker (HSV + hex), Label, Paragraph, Divider. Every element can be hidden, renamed, locked and destroyed.
- Notifications (max five on screen), modal dialogs, key system without HTTP, config save/load/auto-load through flags, built-in Settings tab.
- Safe mode: a failing element logs a warning and returns a harmless stub instead of killing your script.

## Why it does not throw HttpError

The library never calls `HttpGet`, `request`, `loadstring(HttpGet(...))` or loads external images/fonts. Icons are drawn with frames, fonts are Roblox built-ins, and JSON goes through `HttpService:JSONEncode/Decode` (local, no network). The only `HttpGet` in your project is the one in `Loader.lua` (or the one you use to load `BPUI.lua`), and that is your executor's request, not the UI's.

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
- Smaller base window (560x350) so text stays close to 1:1 on phones; if the screen is still smaller the whole window scales down with `UIScale`.
- A draggable floating bubble opens/closes the window (hidden on PC unless `FloatingButton = true`).
- Every control accepts touch: sliders, colour picker, dragging the window, text boxes, dropdown filters.
- Hover effects are disabled on touch devices to avoid stuck highlights; the resize grip is hidden.

---

## API

### `BPUI:CreateWindow(config)` -> Window

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | string | `"BPUI"` | Sidebar title, config folder name, cleanup key |
| `Subtitle` | string | `""` | Small text under the title |
| `Icon` | number/string | nil | `rbxassetid` for sidebar + floating button |
| `Theme` | string/table | `"Dark"` | `Dark`, `Light`, `Midnight`, `Rose`, `Ocean` or a custom table |
| `Accent` | Color3 | theme accent | Highlight colour |
| `Size` | UDim2/Vector2 | 640x440 (560x350 mobile) | Auto-scaled down on small screens |
| `RememberSize` | bool | true | Restore the last resized size from settings |
| `Scale` | number | 1 | Multiplier applied after auto-fit |
| `SidebarWidth` | number | 176 (150 mobile) | |
| `ToggleKey` | KeyCode/string | `RightShift` | PC show/hide key |
| `FloatingButton` | bool | mobile only | Show the floating bubble |
| `FloatingText` | string | first two letters | Text inside the bubble |
| `Resizable` | bool | PC only | Bottom-right resize grip |
| `Search` | bool | true | Search field in the top bar |
| `ConfigFolder` | string | Title | `BPUI/<ConfigFolder>/` |
| `ShowSettings` | bool | true | Built-in Settings tab |
| `SettingsName` | string | `"Settings"` | Rename the built-in tab |
| `CloseBehavior` | string | `"Destroy"` | `"Hide"` makes the X button hide instead |
| `ConfirmClose` | bool | false | Ask before destroying via the X button |
| `AutoLoad` | bool | true | Load the auto-load config ~1s after creation |
| `AutoLoadDelay` | number | 1 | Seconds before auto-load |
| `WelcomeNotification` | bool | true | "Press X to open" toast |
| `KeySystem` | table | nil | See Key system |
| `OnDestroy` | function | nil | Called when the window is unloaded |
| `Footer` | string | `BPUI vX` | Text at the bottom of the sidebar |

**Window methods**

`CreateTab(config)` `SelectTab(tabOrName)` `Show()` `Hide()` `Toggle()` `SetVisible(bool)` `Minimize(state?)` `SetSize(w, h)` `Search(text)` `Dialog(config)` `SetTitle(text)` `SetSubtitle(text)` `SetToggleKey(key)` `SetFloatingButtonVisible(bool)` `Notify(config)` `SaveConfig(name)` `LoadConfig(name)` `GetConfigs()` `DeleteConfig(name)` `SetAutoLoad(name|nil)` `GetAutoLoad()` `LoadAutoConfig()` `Destroy()`

### `Window:CreateTab(config)` -> Tab

`{ Name = "Main", Icon = 123456 }` or just `"Main"`.

Tab methods: `CreateSection(nameOrConfig)`, `Select()`, `SetName(text)`, `Destroy()`. Every `Add*` element method also exists directly on a tab (an untitled section is created for you).

### Elements

Common keys: `Name`, `Description` (second line), `Flag` (config key, must be unique), `Callback`.

Common methods: `Set(value, silent)` (aliases `SetValue`, `Update`), `Get()`, `SetVisible(bool)`, `SetName(text)`, `SetDescription(text)`, `SetCallback(fn)`, `SetLocked(bool)` / `Lock()` / `Unlock()`, `Destroy()`. `Value` always holds the current value.

| Element | Extra config | Callback receives | `Value` |
| --- | --- | --- | --- |
| `AddButton` | - | nothing | - |
| `AddToggle` | `Default` | `state` | boolean |
| `AddSlider` | `Min` `Max` `Default` `Increment` `Suffix` `Typeable` | `number` | number |
| `AddDropdown` | `Options` `Default` `Multi` `Searchable` | option or table | string / table |
| `AddInput` | `Placeholder` `Default` `Numeric` `MaxLength` `ClearOnFocus` `CallbackOnChange` `RemoveTextAfterFocusLost` | `text, enterPressed` | string |
| `AddKeybind` | `Default` `Mode` (`Press`/`Toggle`/`Hold`) `OnChanged` | Press: nothing, Toggle: `state`, Hold: `true/false` | key name (`"E"`, `"MouseButton2"`) |
| `AddColorPicker` | `Default` (Color3 / hex / `{R,G,B}`) | `Color3` | Color3 |
| `AddLabel` | `Text` `Style` (`Accent`/`Sub`) `Center` | - | string |
| `AddParagraph` | `Title` `Content` | - | string |
| `AddDivider` | height | - | - |

Extras: `Dropdown:Refresh(options, keepValue)`, `Dropdown:Open()/Close()`, `Slider:SetRange(min, max)`, `Keybind:GetKeyCode()`, `ColorPicker:Open()/Close()`, `Paragraph:SetTitle()/SetContent()`, `Button:Click()`.

Notes:
- Toggles with `Default = true` fire their callback once on creation so the feature starts enabled.
- Sliders: drag the knob, or tap the value to type an exact number.
- Dropdowns with more than six options get a filter box automatically (`Searchable = true/false` overrides).
- Keybinds capture keyboard keys and the right/middle mouse buttons; Backspace clears, Escape cancels.
- Locked elements are dimmed and ignore all input; programmatic `Set` still works.

### Notifications

```lua
local toast = BPUI:Notify({ Title = "Saved", Content = "Config written.", Type = "Success", Duration = 4 })
-- Type: "Info" | "Success" | "Warning" | "Error"
toast:SetContent("Updated text")   -- toast:Dismiss()
```

Works before a window exists. Top-right on PC, top-centre on mobile, tap to dismiss, at most five visible (oldest is dismissed first).

### Dialogs

```lua
Window:Dialog({
    Title = "Reset settings?",
    Content = "Every flag goes back to its default value.",
    Buttons = {
        { Text = "Cancel" },
        { Text = "Reset", Style = "Danger", Callback = function() ... end },  -- Style: Default | Accent | Danger
    },
})
```

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

Every element with a `Flag` is saved. Files: `BPUI/<ConfigFolder>/configs/<name>.json`. The built-in Settings tab has Save / Load / Delete / Auto Load controls, and `settings.json` remembers theme, accent, toggle key, floating button and window size.

If a config is loaded before some elements exist (for example your script yields), those elements still receive their saved value when they are created.

```lua
Window:SaveConfig("pvp")
Window:LoadConfig("pvp")
Window:SetAutoLoad("pvp")
print(BPUI:GetFlag("WalkSpeed"))
BPUI:SetFlag("WalkSpeed", 50)
```

### Themes

Built in: `Dark`, `Light`, `Midnight`, `Rose`, `Ocean`. Switch at runtime with `BPUI:SetTheme("Light")` or `BPUI:SetAccent(Color3)`. The user's choice is remembered in `settings.json`.

Custom theme: pass a table with any of these keys (missing keys fall back to Dark):
`Window Sidebar Card CardHover Element Separator Stroke Text SubText Accent AccentText Success Warning Error Toggle ToggleOff Knob`

```lua
BPUI.Themes.Lime = { Accent = Color3.fromRGB(120, 220, 80), AccentText = Color3.fromRGB(0, 0, 0), Toggle = Color3.fromRGB(120, 220, 80) }
BPUI:SetTheme("Lime")
```

### Library helpers

`BPUI:Notify()` `BPUI:SetTheme()` `BPUI:SetAccent()` `BPUI:GetFlag()` `BPUI:SetFlag()` `BPUI:Destroy()` `BPUI.Flags` `BPUI.IsMobile` `BPUI.Version` `BPUI.SafeMode` `BPUI.CopyToClipboard(text)` `BPUI.FileSystem.Available`

### Safe mode

`BPUI.SafeMode` is `true` by default: if an element constructor throws (unexpected executor quirk, bad config), the library prints `[BPUI] Failed to create ...` and returns a stub whose methods do nothing, so the rest of your script keeps running. Set it to `false` while developing to get the raw error and stack trace.

---

## Hosting

See `DEPLOY.md` for the full walkthrough. Short version: upload the folder to a public GitHub repository, replace `<user>/<repo>` in `Loader.lua`, and share

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/Loader.lua"))()
```

Re-running a script that creates a window with the same `Title` automatically removes the previous copy.
