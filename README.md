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

### Section emoji

```lua
local sec = tab:CreateSection({ Name = "Live", Emoji = "🥚" })
sec:SetEmoji("⭐")
sec:SetEmoji(nil)
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
## Details (UI decorations)

Every small decoration in the window can now be turned on or off, and some can be recoloured.
Everything is on by default, so existing scripts look the same as before.

| Key         | Type    | What it controls                                          |
|-------------|---------|-----------------------------------------------------------|
| `Search`    | boolean | Search bar at the top of the sidebar                      |
| `Footer`    | boolean | Profile footer (avatar, name, version) at the bottom      |
| `Ticks`     | boolean | Small accent bar next to section titles                   |
| `TickColor` | Color3  | Colour of that bar (default: theme accent)                |
| `Tree`      | boolean | Branch lines that connect tabs inside a group             |
| `TreeColor` | Color3  | Colour of the branch lines (the active tab keeps accent)  |
| `Chevrons`  | boolean | Arrow on the right side of buttons                        |

### Defaults when creating the window

```lua
local win = BPUI:CreateWindow({
    Title = "My Hub",
    Details = {
        Footer = false,
        TickColor = Color3.fromRGB(240, 175, 70),
        TreeColor = Color3.fromRGB(60, 60, 70),
    },
})
```

### Changing them at runtime

```lua
win:SetDetail("Search", false)
win:SetDetail("Chevrons", false)
win:SetDetail("TickColor", Color3.fromRGB(255, 80, 80))
win:ResetDetails()
```

- `SetDetail(key, value)` applies the change right away and saves it.
- `ResetDetails()` clears every saved detail and goes back to the `Details` config, or to the defaults if there is none.
- If the user has changed a detail, that saved value wins over the `Details` config.
- Custom colours stay after a theme or accent change.

### Settings tab

With `ShowSettings = true`, the built-in Settings tab has a new **Details** section with all of these controls and a **Reset details** button. Users can change them without any extra code.


feel free to use it, credit appreciated
