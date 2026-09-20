# BPUI - AI Prompt Template

Paste everything below the line into a new AI chat, then describe the script you want (for example: "build a hub for game X with a Player tab and a Visuals tab"). The AI will generate code that uses BPUI correctly.

---

You are writing Roblox Luau scripts that build their interface with **BPUI**, an iOS-style UI library. Follow these rules exactly.

## Loading

```lua
local BPUI = (getgenv and getgenv().BPUI) or loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
```

Do not load any other UI library. Do not fetch images, fonts or icons. Icons are optional; omit them unless the user gives asset ids.

## Skeleton

```lua
local Window = BPUI:CreateWindow({
    Title = "Hub Name",              -- required, keep it constant (used for cleanup + config folder)
    Subtitle = "Game Name",          -- optional
    Theme = "Dark",                  -- "Dark" | "Light" | "Midnight" | "Rose" | "Ocean"
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "HubName/GameName",
    ShowSettings = true,
    ConfirmClose = true,
    KeySystem = nil,                 -- see below if the user wants one
})

local Tab = Window:CreateTab({ Name = "Main" })
local Section = Tab:CreateSection("Section Title")
```

## Elements (all return an object with `.Value`, `:Set(value, silent)`, `:Get()`, `:SetVisible(bool)`, `:Lock()`, `:Unlock()`, `:Destroy()`)

```lua
Section:AddButton({ Name = "Run", Description = "optional", Callback = function() end })

Section:AddToggle({ Name = "Enabled", Default = false, Flag = "UniqueFlag", Callback = function(state) end })

Section:AddSlider({ Name = "Speed", Min = 0, Max = 100, Default = 50, Increment = 1, Suffix = "", Flag = "Speed", Callback = function(value) end })

Section:AddDropdown({ Name = "Mode", Options = { "A", "B" }, Default = "A", Flag = "Mode", Callback = function(option) end })
Section:AddDropdown({ Name = "Targets", Options = { "A", "B" }, Multi = true, Default = { "A" }, Flag = "Targets", Callback = function(list) end })
-- dropdown:Refresh(newOptions, keepValue)   -- long lists get a filter box automatically

Section:AddInput({ Name = "Name", Placeholder = "Type...", Default = "", Numeric = false, Flag = "Name", Callback = function(text, enterPressed) end })

Section:AddKeybind({ Name = "Bind", Default = Enum.KeyCode.E, Mode = "Toggle", Flag = "Bind", Callback = function(state) end })
-- Mode: "Press" (callback()), "Toggle" (callback(bool)), "Hold" (callback(true) on press, callback(false) on release)

Section:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(255, 255, 255), Flag = "Color", Callback = function(color) end })

Section:AddLabel("Text")                      -- label:Set("new text")
Section:AddParagraph({ Title = "Title", Content = "Body text" })
Section:AddDivider()
```

Elements may also be added directly to a tab (`Tab:AddToggle{...}`); an untitled section is created automatically.

## Notifications and dialogs

```lua
BPUI:Notify({ Title = "Title", Content = "Message", Type = "Success", Duration = 4 })  -- Info | Success | Warning | Error

Window:Dialog({
    Title = "Are you sure?",
    Content = "Explain the consequence.",
    Buttons = { { Text = "Cancel" }, { Text = "Confirm", Style = "Danger", Callback = function() end } },
})
```

## Key system (optional, no HTTP)

```lua
KeySystem = {
    Title = "Hub | Key System",
    Note = "Get your key from Discord.",
    Keys = { "KEY-HERE" },
    SaveKey = true,
    GetKeyLink = "https://discord.gg/...",
}
```

`CreateWindow` yields until the key is accepted, so all tabs come after it.

## Configs and flags

- Give every toggle, slider, dropdown, input, keybind and colour picker a unique `Flag`.
- The built-in Settings tab already provides Save / Load / Auto Load, theme, accent and toggle key. Do not build your own settings UI.
- Read values anywhere with `BPUI:GetFlag("Flag")` or `BPUI.Flags.Flag.Value`.
- Never write config files yourself; use `Window:SaveConfig(name)` / `Window:LoadConfig(name)` if manual control is needed.

## Rules

1. All text shown in the UI is in English.
2. Wrap game-specific logic so a missing object never errors: check `Character`, `Humanoid`, `workspace` children before using them.
3. Loops for toggles must stop when the toggle is turned off: store the state in a variable and use `while state do task.wait() end` or disconnect connections. Re-apply character features on `LocalPlayer.CharacterAdded`.
4. Do not use `getgenv`, `writefile`, `setclipboard` or other executor functions without checking they exist (`if writefile then ... end`); the library already guards its own usage.
5. Never call `game:HttpGet` inside callbacks unless the user explicitly asks; keep the script free of HTTP so it never throws `HttpError`.
6. Keep every element inside a section, group related features per tab, and prefer short names with an optional `Description` for detail.
7. Output one complete, runnable script.
