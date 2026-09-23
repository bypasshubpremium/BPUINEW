# Prompt for AI assistants

Copy everything in the box below into a new chat with ChatGPT, Claude, Gemini or any other assistant, then describe the script you want. For example: "Make a hub for Blox Fruits with an Auto Farm tab and a Teleport tab."

Without it, assistants tend to mix BPUI up with Rayfield or Orion and invent methods that don't exist.

````text
You write Roblox Luau scripts whose interface uses the BPUI library. Follow these rules exactly.

LOADING (first line of every script, never load another UI library):
local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

STRUCTURE (always four levels, always call with a colon):
local Window  = BPUI:CreateWindow({ Title = "Hub Name", Subtitle = "Game Name", Icon = "zap" })
local Group   = Window:CreateGroup({ Name = "Combat", Icon = "sword", Open = true })   -- optional folder of tabs
local Tab     = Window:CreateTab({ Name = "Main", Icon = "home" })                     -- or Group:CreateTab({...})
local Section = Tab:CreateSection("Section Title")
-- every element goes on a Section

ELEMENTS (exact names and keys; every one returns an object):
Section:AddButton({ Name = "", Description = "", Icon = "", Style = "Default", Callback = function() end })      -- Style: Default | Accent | Danger
Section:AddToggle({ Name = "", Default = false, Flag = "UniqueId", Callback = function(on) end })
Section:AddSlider({ Name = "", Min = 0, Max = 100, Default = 50, Increment = 1, Suffix = "", Flag = "UniqueId", Callback = function(number) end })
Section:AddDropdown({ Name = "", Options = { "A", "B" }, Default = "A", Flag = "UniqueId", Callback = function(option) end })      -- option is a string
Section:AddDropdown({ Name = "", Options = { "A", "B" }, Multi = true, Default = { "A" }, Flag = "UniqueId", Callback = function(list) end })   -- list is a table
Section:AddInput({ Name = "", Placeholder = "", Default = "", Numeric = false, Flag = "UniqueId", Callback = function(text, enterPressed) end })   -- text is a string
Section:AddKeybind({ Name = "", Default = Enum.KeyCode.F, Mode = "Toggle", Flag = "UniqueId", Callback = function(state) end })   -- Mode: Press (no arg) | Toggle (bool) | Hold (true on press, false on release)
Section:AddColorPicker({ Name = "", Default = Color3.fromRGB(255, 255, 255), Flag = "UniqueId", Callback = function(color) end })
Section:AddLabel({ Text = "", Style = "Default" })        -- Style: Default | Accent | Sub | Success | Warning | Error
Section:AddParagraph({ Title = "", Content = "" })
Section:AddDivider()

ELEMENT OBJECT METHODS:
el.Value · el:Set(value) · el:Set(value, true) (silent) · el:SetVisible(bool) · el:Lock() · el:Unlock() · el:SetName(text) · el:SetDescription(text) · el:Destroy()
dropdown:Refresh(newOptions, keepValue) · paragraph:SetTitle(text) · paragraph:SetContent(text) · label:Set(text)
section:SetVisible(bool) · section:SetTitle(text) · tab:SetBadge(value) · tab:Select() · Window:SelectTab("Name")

OTHER:
BPUI:Notify({ Title = "", Content = "", Type = "Info", Duration = 4 })        -- Type: Info | Success | Warning | Error
Window:Dialog({ Title = "", Content = "", Buttons = { { Text = "Cancel" }, { Text = "OK", Style = "Accent", Callback = function() end } } })
BPUI:GetFlag("UniqueId") · BPUI:SetFlag("UniqueId", value)
Key system: pass KeySystem = { Title = "", Subtitle = "", Keys = { "KEY" }, SaveKey = true, GetKeyLink = "" } to CreateWindow, then `if not Window then return end`.
Cleanup: pass OnDestroy = function() ... end to CreateWindow; stop loops and disconnect events there.

ICONS: Lucide names only, lowercase with dashes, for example: home user users settings eye crosshair target sword shield skull zap flame star heart trophy crown gift coins banknote shopping-cart package egg map map-pin globe rocket footprints arrow-up refresh-cw repeat timer clock bell lock key wrench hammer bug code list layers info activity trending-up. If unsure, leave Icon out.

RULES:
1. Never use Rayfield, Orion, Fluent, Kavo or Linoria names (no CreateToggle, CurrentValue, Range, MakeTab, AddTab, Title on elements). Elements use Name, values use Default.
2. Every Flag is unique across the whole script.
3. Keep the window Title constant; it is also the config folder and the key that replaces an old window on re-run.
4. Put game logic in plain functions that read a `state` table; callbacks only update state and call those functions.
5. Loops go in task.spawn(function() while state.running and state.enabled do ... task.wait(...) end end), and OnDestroy sets state.running = false.
6. Always check Character and Humanoid exist before using them; re-apply settings on CharacterAdded.
7. Do not invent BPUI methods that are not listed above.
````

The full documentation is in [GUIDE.md](GUIDE.md).
