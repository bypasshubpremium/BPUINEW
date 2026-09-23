--[[
    BPUI example 6: moving a Rayfield script to BPUI.

    Step 1 (instant): swap the loader line. BPUI understands Rayfield's
    names (CreateTab("Main", 4483362458), CreateSection, CreateToggle with
    CurrentValue, CreateSlider with Range, CreateDropdown with CurrentOption,
    CreateKeybind with CurrentKeybind, CreateParagraph, Rayfield:Notify), so
    the script already runs. The console (F9) prints a [BPUI] line for
    anything it had to skip.

    Step 2 (recommended): rename to BPUI's own words, shown below, so the
    code matches the guide and every option is available.
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

---------------------------------------------------------------- before (Rayfield)
--[[
local Window = Rayfield:CreateWindow({ Name = "My Hub", LoadingTitle = "My Hub", ConfigurationSaving = { Enabled = true, FolderName = "MyHub" } })
local Tab = Window:CreateTab("Main", 4483362458)
local Section = Tab:CreateSection("Player")
local Toggle = Tab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump", Callback = function(Value) end })
local Slider = Tab:CreateSlider({ Name = "Speed", Range = {16, 200}, Increment = 1, Suffix = "studs", CurrentValue = 16, Flag = "Speed", Callback = function(Value) end })
local Dropdown = Tab:CreateDropdown({ Name = "Team", Options = {"Red","Blue"}, CurrentOption = {"Red"}, MultipleOptions = false, Flag = "Team", Callback = function(Options) print(Options[1]) end })
Rayfield:Notify({ Title = "Hi", Content = "Loaded", Duration = 5 })
]]

---------------------------------------------------------------- after (BPUI)
local Window = BPUI:CreateWindow({ Title = "My Hub", ConfigFolder = "MyHub" })
local Tab = Window:CreateTab({ Name = "Main", Icon = "home" })
local Section = Tab:CreateSection("Player")          -- elements go ON the section

local Toggle = Section:AddToggle({
    Name = "Infinite Jump",
    Default = false,                                  -- CurrentValue -> Default
    Flag = "InfJump",
    Callback = function(value) end,
})
local Slider = Section:AddSlider({
    Name = "Speed",
    Min = 16, Max = 200,                              -- Range = {16, 200} -> Min / Max
    Increment = 1,
    Suffix = " studs",
    Default = 16,
    Flag = "Speed",
    Callback = function(value) end,
})
local Dropdown = Section:AddDropdown({
    Name = "Team",
    Options = { "Red", "Blue" },
    Default = "Red",                                  -- CurrentOption = {"Red"} -> "Red"
    Flag = "Team",
    Callback = function(option) print(option) end,    -- a string, not a table
})
BPUI:Notify({ Title = "Hi", Content = "Loaded", Duration = 5 })

--[[
    Same idea for other libraries:
      Orion    MakeWindow / MakeTab / AddSection / AddToggle ... work as is
      Fluent   AddTab / AddToggle("Flag", { Title = ... }) / Options.X work as is
      WindUI   Window:Tab / Tab:Section / Tab:Toggle ... work as is
      Linoria  AddTab / AddLeftGroupbox / AddToggle("Flag", { Text = ... }) work as is
      Kavo     CreateLib / NewTab / NewSection / NewToggle ... work as is
]]
