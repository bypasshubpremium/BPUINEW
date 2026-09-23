--[[
    BPUI example 2: every element, with every option that matters.
    Copy the ones you need.
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local Window = BPUI:CreateWindow({ Title = "Element Gallery", Subtitle = "BPUI", Icon = "layers" })
local Tab = Window:CreateTab({ Name = "Elements", Icon = "list", Subtitle = "Everything BPUI can draw" })

---------------------------------------------------------------- buttons
local Buttons = Tab:CreateSection("Buttons")

Buttons:AddButton({
    Name = "Plain button",
    Description = "A second line explaining what it does.",
    Icon = "play",
    Callback = function()
        BPUI:Notify({ Title = "Clicked", Content = "The plain button ran.", Type = "Success" })
    end,
})
Buttons:AddButton({ Name = "Accent button", Style = "Accent", Callback = function() end })
Buttons:AddButton({
    Name = "Danger button",
    Style = "Danger",
    Callback = function()
        Window:Dialog({
            Title = "Are you sure?",
            Content = "Danger buttons usually ask first.",
            Buttons = {
                { Text = "Cancel" },
                { Text = "Do it", Style = "Danger", Callback = function() print("confirmed") end },
            },
        })
    end,
})

---------------------------------------------------------------- toggles
local Toggles = Tab:CreateSection("Toggles")

local godMode = Toggles:AddToggle({
    Name = "God mode",
    Description = "Callback gets true or false.",
    Icon = "shield",
    Default = false,
    Flag = "GodMode",
    Tooltip = "Hover text (PC only)",
    Callback = function(state)
        print("God mode is now", state)
    end,
})
-- later, from your own code:
-- godMode:Set(true)          -- turns it on and runs the callback
-- godMode:Set(true, true)    -- turns it on silently (no callback)
-- print(godMode.Value)       -- read the current state

---------------------------------------------------------------- sliders
local Sliders = Tab:CreateSection("Sliders")

Sliders:AddSlider({
    Name = "Field of view",
    Icon = "eye",
    Min = 30,
    Max = 120,
    Default = 70,
    Increment = 1,        -- step size; use 0.1 for one decimal
    Suffix = "°",
    Flag = "FOV",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})
Sliders:AddSlider({ Name = "Smoothing", Min = 0, Max = 1, Default = 0.35, Increment = 0.05, Flag = "Smooth" })

---------------------------------------------------------------- dropdowns
local Dropdowns = Tab:CreateSection("Dropdowns")

local target = Dropdowns:AddDropdown({
    Name = "Target part",
    Icon = "crosshair",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Flag = "TargetPart",
    Callback = function(option)           -- single select: a string
        print("Aiming at", option)
    end,
})
Dropdowns:AddDropdown({
    Name = "Eggs to hatch",
    Options = { "Common", "Rare", "Epic", "Legendary" },
    Multi = true,
    Default = { "Rare", "Epic" },
    Flag = "Eggs",
    Callback = function(list)             -- multi select: a table of strings
        print("Hatching", table.concat(list, ", "))
    end,
})
-- change the options later (e.g. after scanning the map):
-- target:Refresh({ "Head", "UpperTorso" }, true)   -- true keeps the current pick if it still exists

---------------------------------------------------------------- text input
local Inputs = Tab:CreateSection("Text input")

Inputs:AddInput({
    Name = "Player name",
    Placeholder = "Type a name...",
    Flag = "TargetName",
    Callback = function(text, enterPressed)
        print("Name:", text, enterPressed)
    end,
})
Inputs:AddInput({
    Name = "Jump power",
    Placeholder = "50",
    Numeric = true,       -- only numbers can be typed
    MaxLength = 4,
    Flag = "JumpPower",
    Callback = function(text)
        local n = tonumber(text)
        if n then print("Jump power", n) end
    end,
})

---------------------------------------------------------------- keybinds
local Keybinds = Tab:CreateSection("Keybinds")

Keybinds:AddKeybind({
    Name = "Toggle fly",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",          -- "Press": callback() · "Toggle": callback(on) · "Hold": callback(true/false)
    Flag = "FlyKey",
    Callback = function(on)
        print("Fly", on)
    end,
})

---------------------------------------------------------------- colours
local Colors = Tab:CreateSection("Colours")

Colors:AddColorPicker({
    Name = "ESP colour",
    Default = Color3.fromRGB(255, 80, 80),
    Flag = "EspColor",
    Callback = function(color)
        print("New colour", color)
    end,
})

---------------------------------------------------------------- text
local Text = Tab:CreateSection("Text")

local status = Text:AddLabel({ Text = "Status: idle", Style = "Sub" })   -- Style: Accent, Sub, Success, Warning, Error
Text:AddParagraph({
    Title = "How to use",
    Content = "Paragraphs wrap long text over as many lines as they need. Use them for instructions or credits.",
})
Text:AddDivider()
Text:AddLabel({ Text = "Made with BPUI", Center = true })

-- update text from your code:
status:Set("Status: running")
