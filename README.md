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
- collapsible sections
- toggle, slider, dropdown, input, keybind, colorpicker, button, label, paragraph
- ~340 lucide icons built in
- 8 built in themes + custom themes
- config save/load/autoload
- key system
- notifications and dialogs
- watermark with fps/ping
- search, mobile support, streamer mode

## sub tabs

```lua
local farm = Window:CreateGroup({ Name = "Farming", Icon = "swords", Open = true })
local auto = farm:CreateTab({ Name = "Auto Farm", Icon = "repeat" })
local world = farm:CreateTab({ Name = "World", Icon = "map" })
```

## collapsible sections

add `Collapsible = true` and the header becomes clickable. add `Open = false` if u want it to start closed

```lua
local combat = Tab:CreateSection({ Name = "Combat", Collapsible = true, Open = false })
combat:AddToggle({ Name = "Auto Attack", Callback = function(v) end })

combat:Open()
combat:Close()
combat:Toggle()
combat:SetOpen(true)
print(combat:IsOpen())
```

- sections without a name cant collapse
- stuff hidden with SetVisible(false) stays hidden when the section opens again
- search opens a closed section if something inside matches, closes it again when u clear the search
- open/closed state isnt saved to configs
- `combat:Toggle({...})` with a table still adds a toggle like before, only the empty call collapses

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
