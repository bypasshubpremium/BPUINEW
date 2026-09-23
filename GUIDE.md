# BPUI Guide

This guide covers everything you need to build a script with BPUI: loading the library, your first window, every element, saving settings, and fixing the problems people run into most. You don't need any other UI library experience.

If you only read one part, read **[The four levels](#1-the-four-levels)**. Most "my tab is empty" problems come from skipping a level.

**Contents**

1. [The four levels](#1-the-four-levels)
2. [Loading BPUI](#2-loading-bpui)
3. [Your first script](#3-your-first-script)
4. [The window](#4-the-window)
5. [Tabs and groups](#5-tabs-and-groups)
6. [Sections](#6-sections)
7. [Elements](#7-elements)
8. [Changing the UI from your script](#8-changing-the-ui-from-your-script)
9. [Flags and configs](#9-flags-and-configs)
10. [Notifications and dialogs](#10-notifications-and-dialogs)
11. [Key system](#11-key-system)
12. [Icons](#12-icons)
13. [Themes](#13-themes)
14. [How to lay out a real script](#14-how-to-lay-out-a-real-script)
15. [Coming from another library](#15-coming-from-another-library)
16. [Troubleshooting](#16-troubleshooting)
17. [Writing scripts with an AI](#17-writing-scripts-with-an-ai)
18. [Cheat sheet](#18-cheat-sheet)

Complete, runnable scripts are in [`docs/examples`](docs/examples):

| File | What it shows |
| --- | --- |
| [`01-minimal.lua`](docs/examples/01-minimal.lua) | The smallest useful script |
| [`02-every-element.lua`](docs/examples/02-every-element.lua) | Every element with its options |
| [`03-real-hub.lua`](docs/examples/03-real-hub.lua) | How a full hub is organised: state, loops, cleanup |
| [`04-key-system.lua`](docs/examples/04-key-system.lua) | A key screen before the hub opens |
| [`05-updating-the-ui.lua`](docs/examples/05-updating-the-ui.lua) | Changing text, options, badges, locking and hiding while the script runs |
| [`06-from-rayfield.lua`](docs/examples/06-from-rayfield.lua) | Moving a Rayfield script over |

---

## 1. The four levels

Every BPUI script builds the same tree, top to bottom:

```
Window                 BPUI:CreateWindow({...})      one per script
 └─ Tab                Window:CreateTab({...})       a page in the sidebar
     └─ Section        Tab:CreateSection("Name")     a titled card on that page
         └─ Element    Section:AddToggle({...})      a toggle, slider, button...
```

Each call returns the object for the next level, so you keep them in variables:

```lua
local Window  = BPUI:CreateWindow({ Title = "My Hub" })
local Main    = Window:CreateTab({ Name = "Main" })
local Player  = Main:CreateSection("Player")
Player:AddToggle({ Name = "Infinite jump", Callback = function(on) end })
```

Two rules that save a lot of time:

- **Use a colon (`:`) not a dot (`.`)** when calling methods: `Window:CreateTab(...)`, not `Window.CreateTab(...)`.
- **Elements go on a section.** You *can* call `Main:AddToggle(...)` straight on a tab, and BPUI puts it in the tab's last section (or makes an untitled one). It's still clearer to make sections yourself.

---

## 2. Loading BPUI

Put this line at the very top of your script:

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
```

That downloads the newest version every time. GitHub caches the file for a few minutes, so a brand-new update can take up to 5 minutes to show up.

Your executor needs `loadstring` and `game:HttpGet`. Almost every executor has both. If yours doesn't, paste the contents of `BPUI.lua` at the top of your script instead of the loader line.

Check which version you got:

```lua
print(BPUI.Version)
```

---

## 3. Your first script

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
local player = game:GetService("Players").LocalPlayer

local Window = BPUI:CreateWindow({
    Title = "My Hub",
    Subtitle = "Universal",
    Icon = "zap",
})

local Main = Window:CreateTab({ Name = "Main", Icon = "home" })
local Movement = Main:CreateSection("Movement")

Movement:AddSlider({
    Name = "Walk speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Flag = "WalkSpeed",
    Callback = function(value)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = value end
    end,
})
```

Run it and you get:

- **A window** with a sidebar and a "Main" page holding a slider.
- **A built-in Settings tab** with theme, accent colour, background image, configs, watermark and privacy options.
- **A menu button** in the top-left corner that opens and closes the window. Players on mobile use this button.
- **A watermark** showing FPS and ping.
- **RightShift** to hide or show the window on PC.

Everything is saved automatically: the theme, the window size, and every element that has a `Flag`.

---

## 4. The window

```lua
local Window = BPUI:CreateWindow({
    Title = "My Hub",                  -- sidebar title; also the config folder name
    Subtitle = "Steal An Egg",         -- small line under the title
    Icon = "egg",                      -- see Icons
    Theme = "Void",                    -- see Themes
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "MyHub",            -- files go to BPUI/MyHub/
})
```

**Keep `Title` the same on every run.** When your script runs again, BPUI finds the old window by its title and removes it first. If the title changes, you get two windows.

The options you'll use most:

| Option | What it does |
| --- | --- |
| `Title`, `Subtitle`, `Icon` | What the sidebar header shows |
| `Theme`, `Accent` | Colours (`Accent = Color3.fromRGB(...)`) |
| `ToggleKey` | PC hotkey to show and hide the window (default RightShift) |
| `Size` | `UDim2.fromOffset(760, 520)` by default. It shrinks automatically on small screens |
| `ShowSettings = false` | Removes the built-in Settings tab |
| `ShowConfig = false` | Keeps Settings but hides its Save/Load section |
| `Watermark = false` | No FPS/ping watermark |
| `MenuButton = false` | No open/close button (not recommended for mobile users) |
| `CloseBehavior = "Hide"` | The X button hides the window instead of unloading the script |
| `ConfirmClose = true` | Asks before unloading |
| `OnDestroy = function() end` | Runs when the user closes the hub. Stop your loops here |
| `KeySystem = {...}` | See [Key system](#11-key-system) |

The full list is in the [README](README.md#bpuicreatewindowconfig--window).

Useful window methods:

```lua
Window:Show()          Window:Hide()          Window:Toggle()
Window:Minimize()      Window:SelectTab("Main")
Window:SetTitle("New title")
Window:Destroy()       -- unload everything
```

---

## 5. Tabs and groups

A tab is a page with a button in the sidebar.

```lua
local Main = Window:CreateTab({
    Name = "Main",
    Icon = "home",
    Subtitle = "Shown under the page title",   -- optional
    Badge = 3,                                 -- optional number or short text on the right
})
```

`Window:CreateTab("Main")` with only a name also works.

**Groups** fold several tabs under one collapsible header:

```lua
local Combat = Window:CreateGroup({ Name = "Combat", Icon = "sword", Open = true })
local Aimbot = Combat:CreateTab({ Name = "Aimbot", Icon = "crosshair" })
local ESP    = Combat:CreateTab({ Name = "ESP", Icon = "eye" })
```

The first tab you create opens automatically. Tabs appear in the order you create them, and Settings is always last.

Tab methods: `Select()`, `SetName(text)`, `SetSubtitle(text)`, `SetIcon(icon)`, `SetBadge(value or nil)`, `Destroy()`.

---

## 6. Sections

A section is a titled card on a page. Elements live inside sections.

```lua
local Targeting = Aimbot:CreateSection("Targeting")
local Visuals   = Aimbot:CreateSection("Visuals")
```

Make as many as you like. They stack top to bottom in the order you create them.

Section methods: `SetTitle(text)`, `SetVisible(bool)` (hide a whole group of options), and `Destroy()`.

---

## 7. Elements

Every element takes a table. These keys work on all of them:

| Key | Meaning |
| --- | --- |
| `Name` | The row's label |
| `Description` | A smaller second line under the name |
| `Icon` | Icon at the left of the row (see [Icons](#12-icons)) |
| `Flag` | A unique id. The value is saved in configs and readable with `BPUI:GetFlag` |
| `Callback` | Your function. BPUI calls it when the value changes |
| `Tooltip` | Text shown when the mouse rests on the row (PC only) |

Every element returns an object, and every object has these:

```lua
local t = Section:AddToggle({ Name = "Example" })

print(t.Value)           -- the current value
t:Set(true)              -- change it (runs the callback)
t:Set(true, true)        -- change it silently (no callback)
t:SetVisible(false)      -- hide the row
t:Lock()   t:Unlock()    -- grey it out / enable it again
t:SetName("New name")    t:SetDescription("New description")
t:Destroy()
```

### Button

```lua
Section:AddButton({
    Name = "Teleport to spawn",
    Description = "Optional second line",
    Style = "Default",                -- "Default", "Accent" or "Danger"
    Callback = function()
        print("clicked")
    end,
})
```

The callback gets nothing. `button:Click()` runs it from code.

### Toggle

```lua
local godMode = Section:AddToggle({
    Name = "God mode",
    Default = false,
    Flag = "GodMode",
    Callback = function(on)
        print("God mode:", on)       -- true or false
    end,
})
```

If `Default = true`, the callback runs once when the toggle is created, so your feature starts in the right state. Add `FireOnCreate = false` to stop that.

### Slider

```lua
Section:AddSlider({
    Name = "Field of view",
    Min = 30,
    Max = 120,
    Default = 70,
    Increment = 1,            -- step size: 1 for whole numbers, 0.1 for one decimal
    Suffix = "°",             -- text after the number
    Flag = "FOV",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})
```

Users can drag the slider or click the number to type an exact value. The callback doesn't run on creation. Add `FireOnCreate = true` if you want it to. `slider:SetRange(min, max)` changes the limits later.

### Dropdown

Single choice. The callback gets a **string**:

```lua
local part = Section:AddDropdown({
    Name = "Target part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Flag = "TargetPart",
    Callback = function(option)
        print("Aiming at", option)
    end,
})
```

Multiple choice. The callback gets a **table of strings**:

```lua
Section:AddDropdown({
    Name = "Eggs to hatch",
    Options = { "Common", "Rare", "Epic", "Legendary" },
    Multi = true,
    Default = { "Rare", "Epic" },
    Flag = "Eggs",
    Callback = function(list)
        print(table.concat(list, ", "))
    end,
})
```

Lists longer than six options get a search box automatically. To change the options later, for example after scanning the map:

```lua
part:Refresh({ "Head", "UpperTorso", "LowerTorso" }, true)   -- true keeps the current choice if it's still there
```

### Input (text box)

```lua
Section:AddInput({
    Name = "Jump power",
    Placeholder = "50",
    Default = "",
    Numeric = true,           -- only digits, "." and "-" can be typed
    MaxLength = 4,
    Flag = "JumpPower",
    Callback = function(text, enterPressed)
        local n = tonumber(text)
        if n then print("Jump power", n) end
    end,
})
```

The callback runs when the box loses focus. `text` is always a string, so use `tonumber` for numbers. `CallbackOnChange = true` runs it on every keystroke instead.

### Keybind

```lua
Section:AddKeybind({
    Name = "Fly",
    Default = Enum.KeyCode.F,     -- or "F"
    Mode = "Toggle",
    Flag = "FlyKey",
    Callback = function(on)
        print("Fly", on)
    end,
})
```

| `Mode` | When the callback runs | What it gets |
| --- | --- | --- |
| `"Press"` (default) | Every key press | nothing |
| `"Toggle"` | Every key press | `true`, then `false`, then `true`... |
| `"Hold"` | Key down and key up | `true` while held, `false` on release |

Users click the pill and press a new key to rebind it. Esc cancels and Backspace clears. Right and middle mouse buttons work too. Key presses are ignored while the user is typing in a chat box or text field.

### Colour picker

```lua
Section:AddColorPicker({
    Name = "ESP colour",
    Default = Color3.fromRGB(255, 80, 80),
    Flag = "EspColor",
    Callback = function(color)
        print(color)             -- a Color3
    end,
})
```

### Label

A line of text with no control.

```lua
local status = Section:AddLabel({ Text = "Status: idle", Style = "Sub" })
status:Set("Status: running")
```

`Style` can be `"Default"`, `"Accent"`, `"Sub"` (dimmer), `"Success"`, `"Warning"` or `"Error"`. `Center = true` centres it, and `Bold = true` makes it bold. `Section:AddLabel("text")` works too.

### Paragraph

A title with wrapped body text. Use it for instructions, credits, or a status box.

```lua
local info = Section:AddParagraph({
    Title = "How to use",
    Content = "Pick a target, then turn on Auto Farm. Long text wraps onto as many lines as it needs.",
})
info:SetContent("Farming... 12 eggs collected")
info:SetTitle("Status")
```

### Divider

```lua
Section:AddDivider()
```

---

## 8. Changing the UI from your script

Keep the object that `Add...` returns and change it whenever you need to.

```lua
local status = Section:AddParagraph({ Title = "Status", Content = "Waiting..." })
local target = Section:AddDropdown({ Name = "Player", Options = {} })
local follow = Section:AddToggle({ Name = "Follow" })

status:SetContent("Found 3 players")          -- rewrite text
target:Refresh({ "Alice", "Bob", "Carl" })    -- new options
follow:Lock()                                 -- greyed out until ready
follow:Unlock()
follow:Set(true)                              -- flip it from code
Section:SetVisible(false)                     -- hide the whole section
Main:SetBadge(3)                              -- number next to the tab name
```

Callbacks run on their own thread, so a `task.wait` inside one doesn't block the rest of the UI. Work that never ends, such as an auto-farm loop, belongs in `task.spawn`:

```lua
local farming = false

Section:AddToggle({
    Name = "Auto farm",
    Callback = function(on)
        farming = on
        if not on then return end
        task.spawn(function()
            while farming do
                -- one round of farming here
                task.wait(0.5)
            end
        end)
    end,
})
```

[`05-updating-the-ui.lua`](docs/examples/05-updating-the-ui.lua) shows all of this working together.

---

## 9. Flags and configs

Give an element a `Flag` and its value becomes part of the user's config:

```lua
Section:AddToggle({ Name = "Auto farm", Flag = "AutoFarm" })
```

- **Flags must be unique.** Two elements with the same flag overwrite each other.
- **Users manage configs in Settings → Configuration.** They can Save, Load, Delete and set one config to auto-load.
- **Files live in your executor's workspace** under `BPUI/<ConfigFolder>/configs/`.

From code:

```lua
print(BPUI:GetFlag("AutoFarm"))     -- read any flagged value
BPUI:SetFlag("AutoFarm", true)      -- change it (runs the callback)

Window:SaveConfig("pvp")
Window:LoadConfig("pvp")
Window:SetAutoLoad("pvp")           -- loads automatically next time
```

`BPUI.Flags.AutoFarm` is the element object itself, so `BPUI.Flags.AutoFarm:Set(false)` works too.

If your executor has no file functions, configs are switched off, the Configuration section says so, and everything else keeps working.

---

## 10. Notifications and dialogs

```lua
BPUI:Notify({
    Title = "Done",
    Content = "Collected 25 eggs.",
    Type = "Success",      -- "Info", "Success", "Warning" or "Error"
    Duration = 4,          -- seconds; 0 keeps it until clicked
})
```

This works before a window exists, which makes it handy for "loading..." messages. `BPUI:Notify` returns the toast, so `toast:SetContent("...")` updates it and `toast:Dismiss()` closes it.

A dialog asks the user something inside the window:

```lua
Window:Dialog({
    Title = "Reset everything?",
    Content = "All options go back to their defaults.",
    Buttons = {
        { Text = "Cancel" },
        { Text = "Reset", Style = "Danger", Callback = function()
            print("reset")
        end },
    },
})
```

---

## 11. Key system

```lua
local Window = BPUI:CreateWindow({
    Title = "My Hub",
    KeySystem = {
        Title = "My Hub | Key System",
        Subtitle = "Get a key in our Discord.",
        Keys = { "KEY-123", "KEY-456" },
        SaveKey = true,                                -- remember a valid key
        GetKeyLink = "https://discord.gg/yourserver",  -- the Get Key button copies this
        -- Validate = function(key) return checkKeySomehow(key) end,
    },
})
if not Window then return end
```

`CreateWindow` shows the key screen and **waits** until a correct key is entered, so the rest of your script only runs for verified users. If the user gives up, it returns `nil`, which is why the `if not Window then return end` line is there.

Keys written inside the script can be read by anyone who opens the script. For real protection, check keys in `Validate` against something you control.

---

## 12. Icons

Tabs, groups, the window and every element accept `Icon`:

```lua
Icon = "crosshair"                 -- a Lucide icon name (recommended)
Icon = "🎯"                        -- an emoji
Icon = "rbxassetid://1234567890"   -- your own image
```

About 340 [Lucide](https://lucide.dev/icons) icons are built in. Common ones:

```
home user users settings sliders search eye eye-off crosshair target sword shield skull
zap flame star heart trophy crown gift coins banknote shopping-cart package egg paw-print
map map-pin compass globe rocket plane car footprints arrow-up refresh-cw repeat timer clock
bell lock key wrench hammer bug code terminal palette brush image camera music volume-2
list layers grid-2x2 bar-chart-3 activity trending-up info circle-help triangle-alert
```

Common guesses work too: `house`, `player`, `teleport`, `shop`, `aimbot`, `lightning` and `coin` all map to the right icon. The full list is in `BPUI.Icons`:

```lua
for name in pairs(BPUI.Icons) do print(name) end
```

**If you use a name that doesn't exist, no icon is shown** and the console prints `[BPUI] Unknown icon "..."`. The label moves left, so there's no empty gap. An `rbxassetid` that fails to load is hidden the same way.

`Colored = true` tints a named icon with the accent colour, and `IconColor = Color3.fromRGB(...)` gives it a fixed colour.

---

## 13. Themes

`Void` (default), `Nocturne`, `FluentDark`, `FluentLight`, `Obsidian`, `Midnight`, `Nord`, `Crimson`.

```lua
BPUI:CreateWindow({ Title = "My Hub", Theme = "Nord" })
BPUI:SetTheme("FluentLight")                   -- switch any time
BPUI:SetAccent(Color3.fromRGB(255, 120, 60))   -- highlight colour
```

Users can change both in Settings, and their choice wins over the script's default on later runs. To make your own theme, see [Themes in the README](README.md#themes).

---

## 14. How to lay out a real script

When scripts grow, keeping this order makes them easy to fix:

1. **Load BPUI and get services** at the top.
2. **Keep a `state` table** for everything your features read: speeds, toggles and targets.
3. **Write each feature as a plain function** that reads `state`, with no UI code inside.
4. **Build the UI last.** Each callback only updates `state` and calls a feature.
5. **Start loops with `task.spawn`**, and have each loop check a flag so it can stop.
6. **Clean up in `OnDestroy`**: set the stop flag, disconnect events, and undo changes such as walk speed or lighting.

```lua
local state = { speed = 16, running = true }

local function applySpeed()
    local h = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = state.speed end
end

local Window = BPUI:CreateWindow({
    Title = "My Hub",
    OnDestroy = function()
        state.running = false
        state.speed = 16
        applySpeed()
    end,
})

local Movement = Window:CreateTab({ Name = "Movement", Icon = "footprints" }):CreateSection("Speed")
Movement:AddSlider({
    Name = "Walk speed", Min = 16, Max = 200, Default = 16, Flag = "Speed",
    Callback = function(v) state.speed = v applySpeed() end,
})
```

[`03-real-hub.lua`](docs/examples/03-real-hub.lua) is a complete hub written this way.

---

## 15. Coming from another library

BPUI understands the method names and option names of Rayfield, Orion, Fluent, WindUI, Linoria and Kavo. A script written for one of them usually runs after you replace the loader line. Anything BPUI had to skip is printed in the console as a `[BPUI]` line and shown as a red note in that section, so the rest of the script still runs.

Renaming things to BPUI's own words is still worth it, because then the code matches this guide:

| You wrote | BPUI name |
| --- | --- |
| `Window:Tab`, `AddTab`, `MakeTab` | `Window:CreateTab` |
| `Tab:Section`, `AddSection`, `AddLeftGroupbox` | `Tab:CreateSection` |
| `CreateToggle`, `Toggle`, `NewToggle` | `Section:AddToggle` (the same pattern for every element) |
| `Textbox`, `AddTextbox`, `NewTextBox` | `AddInput` |
| `Bind`, `AddBind`, `AddKeyPicker` | `AddKeybind` |
| `CreateText`, `NewLabel` | `AddParagraph` / `AddLabel` |
| `Title`, `name`, `Text` (for the row label) | `Name` |
| `Desc` | `Description` |
| `CurrentValue`, `Value`, `value` | `Default` |
| `Range = {0, 100}` | `Min = 0, Max = 100` |
| `Values`, `options` | `Options` |
| `MultipleOptions`, `multiSelect` | `Multi` |
| `CurrentOption = {"A"}` | `Default = "A"` |
| `CurrentKeybind` | `Default` |
| `PlaceholderText` | `Placeholder` |
| `Rayfield:Notify`, `MakeNotification` | `BPUI:Notify` |

One behaviour difference: a single-choice BPUI dropdown gives your callback a **string** (`"Head"`), while Rayfield gives a table (`{"Head"}`). Scripts that pass Rayfield's `CurrentOption` key still get a table, so they keep working. In new code, use `Default` and expect a string.

[`06-from-rayfield.lua`](docs/examples/06-from-rayfield.lua) shows a before-and-after conversion.

---

## 16. Troubleshooting

Open the developer console with **F9** (or type `/console` in chat). BPUI prints every problem it finds on a line starting with `[BPUI]`.

**My tab is empty.**
Your script stopped with an error after the tab was created. Check the console.
- **Most often:** a method name BPUI didn't recognise. Since 2.15 these are skipped with a `[BPUI]` warning and a red note on the page, and the rest runs.
- **Otherwise:** an error in your own code between creating the tab and adding elements, such as a nil character or a typo in a variable name. While testing, set `BPUI.SafeMode = false` right after the loader line to get the full error with a line number.

**Nothing appears at all.**
The loader line failed.
- Check the URL for typos.
- Run `print(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"):sub(1, 100))` to see if your executor can download it.
- If you used a key system, `CreateWindow` is waiting for a key, and the key screen may be behind another GUI.

**The tab or row has a blank space where the icon should be.**
Update BPUI (2.15+ removes the gap). Then fix the icon: the console prints `Unknown icon "..."` for names that don't exist, and a failed-to-load line for asset ids that don't load.

**`attempt to call a nil value (method 'Something')`**
You're calling something that doesn't exist on that object. Check the name against the [cheat sheet](#18-cheat-sheet), and check you used `:` not `.`.

**`attempt to index nil with 'CreateTab'`**
`Window` is nil. Either the key screen was closed (see [Key system](#11-key-system)), or `CreateWindow` was misspelled.

**My callback doesn't run.**
- Check the key is spelled `Callback` (capital C, though lowercase works too).
- Sliders and dropdowns don't run their callback on creation. Toggles with `Default = true` do.
- Set the value with `:Set(value)`, not `:Set(value, true)`; the second argument means "silently".

**The toggle turns my feature on when the script starts.**
That happens because `Default = true` (or a saved config) runs the callback once. Add `FireOnCreate = false` if you don't want that.

**My dropdown callback gets a string, but my code expects a table (or the reverse).**
Single choice gives a string, and `Multi = true` gives a table. See [Dropdown](#dropdown).

**Settings don't save.**
- Your executor needs `writefile`/`readfile`. Settings → Configuration says "unavailable" if it doesn't have them.
- Elements are only saved if they have a `Flag`.

**Two windows appear when I re-run.**
The `Title` changed between runs. Keep it constant.

**My loops keep running after closing the hub.**
Stop them in `OnDestroy` (see [section 14](#14-how-to-lay-out-a-real-script)).

**It looks too small or too big.**
The window fits itself to the screen. `Scale = 1.1` in `CreateWindow` makes it a bit bigger, and users can resize it with the corner grip on PC.

**Mobile players can't open it again after closing.**
Keep the menu button on (it's on by default). If you want the X button to only hide the window, use `CloseBehavior = "Hide"`.

**I want to hide the red notes BPUI adds when something is skipped.**
Set `BPUI.ShowErrors = false`. It's better to fix the line the note points at.

---

## 17. Writing scripts with an AI

AI assistants often mix up UI libraries. Paste the prompt from [`AI-PROMPT.md`](AI-PROMPT.md) at the start of the chat and they'll write BPUI code that follows this guide.

---

## 18. Cheat sheet

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local Window  = BPUI:CreateWindow({ Title = "", Subtitle = "", Icon = "", Theme = "Void", ToggleKey = Enum.KeyCode.RightShift })
local Group   = Window:CreateGroup({ Name = "", Icon = "", Open = true })
local Tab     = Window:CreateTab({ Name = "", Icon = "", Subtitle = "", Badge = nil })   -- or Group:CreateTab
local Section = Tab:CreateSection("")

Section:AddButton({      Name = "", Description = "", Icon = "", Style = "Default", Callback = function() end })
Section:AddToggle({      Name = "", Default = false, Flag = "", Callback = function(on) end })
Section:AddSlider({      Name = "", Min = 0, Max = 100, Default = 50, Increment = 1, Suffix = "", Flag = "", Callback = function(n) end })
Section:AddDropdown({    Name = "", Options = {}, Default = nil, Multi = false, Flag = "", Callback = function(v) end })
Section:AddInput({       Name = "", Placeholder = "", Default = "", Numeric = false, Flag = "", Callback = function(text, enter) end })
Section:AddKeybind({     Name = "", Default = Enum.KeyCode.F, Mode = "Press", Flag = "", Callback = function(state) end })
Section:AddColorPicker({ Name = "", Default = Color3.new(1, 1, 1), Flag = "", Callback = function(color) end })
Section:AddLabel({       Text = "", Style = "Default" })
Section:AddParagraph({   Title = "", Content = "" })
Section:AddDivider()

-- every element:  .Value  :Set(v, silent)  :SetVisible(b)  :Lock()  :Unlock()  :SetName(s)  :SetDescription(s)  :Destroy()
-- dropdown:       :Refresh(options, keepValue)
-- paragraph:      :SetTitle(s)  :SetContent(s)        label: :Set(s)
-- section:        :SetTitle(s)  :SetVisible(b)        tab: :Select()  :SetName(s)  :SetBadge(v)

BPUI:Notify({ Title = "", Content = "", Type = "Info", Duration = 4 })
Window:Dialog({ Title = "", Content = "", Buttons = { { Text = "OK" } } })
BPUI:GetFlag("Flag")   BPUI:SetFlag("Flag", value)
BPUI:SetTheme("Nord")  BPUI:SetAccent(Color3.fromRGB(255, 120, 60))
Window:Destroy()
```
