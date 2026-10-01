# BPUI

clean dark ui lib for roblox. works on pc and mobile, no http requests, works on low level executors too

## load

```lua
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
```

## example

```lua
local Window = BPUI:CreateWindow({ Title = "My Hub", Subtitle = "v1.0" })
local Tab = Window:CreateTab({ Name = "Main", Icon = "home" })
local Section = Tab:CreateSection("Player")

Section:AddToggle({
    Name = "Infinite Jump",
    Flag = "InfJump",
    Callback = function(state) print(state) end,
})
```

## features

- tabs, groups (sub tabs), sections
- toggle, slider, dropdown, input, keybind, colorpicker, button, label, paragraph
- ~340 lucide icons built in
- 8 built in themes + custom themes
- config save/load/autoload
- key system
- notifications and dialogs
- watermark with fps/ping
- search, mobile support, streamer mode

## elements

| element | config | callback |
|---|---|---|
| AddButton | Style | - |
| AddToggle | Default | state |
| AddSlider | Min Max Default Increment Suffix | number |
| AddDropdown | Options Default Multi Searchable | option/table |
| AddInput | Placeholder Default Numeric MaxLength | text |
| AddKeybind | Default Mode | depends on mode |
| AddColorPicker | Default | Color3 |

all elements have: Set, Get, SetVisible, SetName, Lock, Unlock, Destroy

## notify

```lua
BPUI:Notify({ Title = "Saved", Content = "done", Type = "Success", Duration = 4 })
```

## themes

```lua
BPUI:SetTheme("Nord")
BPUI:SetAccent(Color3.fromRGB(255, 120, 60))
```

feel free to use it, credit appreciated
