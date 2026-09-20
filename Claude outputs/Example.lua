--[[
    BPUI Example
    ------------
    Shows every component the library offers. Replace the print() calls
    with your own logic. Everything below works on PC and Mobile.

    Loading the library:
      1) Paste BPUI.lua above this script and use the returned table, or
      2) Host BPUI.lua on GitHub (raw) and load it:
           local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua"))()
         (The HttpGet here is your choice - the library itself never makes requests.)
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua"))()

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local Window = BPUI:CreateWindow({
    Title = "BP Hub",                      -- shown in the sidebar and used for the config folder
    Subtitle = "Premium",                  -- optional
    Icon = nil,                            -- optional rbxassetid number (icons are optional everywhere)
    Theme = "Dark",                        -- "Dark" | "Light" | "Midnight" | custom table
    Accent = Color3.fromRGB(10, 132, 255), -- optional accent override
    Size = UDim2.fromOffset(640, 440),     -- optional, auto scales down on small screens
    ToggleKey = Enum.KeyCode.RightShift,   -- PC open/close key (changeable from Settings)
    FloatingButton = nil,                  -- nil = auto (mobile only), true = always, false = never
    ConfigFolder = "BPHub",                -- files land in BPUI/BPHub/
    ShowSettings = true,                   -- built-in Settings tab (theme, accent, configs, unload)
    CloseBehavior = "Destroy",             -- "Destroy" | "Hide" for the X button
    WelcomeNotification = true,
    KeySystem = {
        Enabled = true,
        Title = "BP Hub | Key System",
        Subtitle = "Enter your key to continue",
        Note = "Get your key from our Discord server.",
        Keys = { "BPHUB-FREE-KEY" },       -- one or more accepted keys
        CaseSensitive = false,
        SaveKey = true,                    -- remembers a valid key (when the executor supports files)
        GetKeyLink = "https://discord.gg/yourserver", -- copied to the clipboard by the Get Key button
        -- Validate = function(key) return key == "custom-logic" end, -- optional custom validator
        -- MaxAttempts = 5,
    },
    OnDestroy = function()
        print("UI unloaded")
    end,
})

---------------------------------------------------------------------------
-- Tabs and sections
---------------------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Main" })
local PlayerTab = Window:CreateTab({ Name = "Player" })
local VisualsTab = Window:CreateTab({ Name = "Visuals" })

local General = MainTab:CreateSection("General")

General:AddParagraph({
    Title = "Welcome",
    Content = "This example shows every BPUI component. Everything you see is fully usable on both PC and Mobile.",
})

General:AddButton({
    Name = "Say Hello",
    Description = "Sends a notification",
    Callback = function()
        BPUI:Notify({ Title = "Hello", Content = "Buttons work!", Type = "Success", Duration = 3 })
    end,
})

General:AddToggle({
    Name = "Example Toggle",
    Description = "Saved in configs through its Flag",
    Default = false,
    Flag = "ExampleToggle",
    Callback = function(state)
        print("Toggle:", state)
    end,
})

General:AddSlider({
    Name = "Example Slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Suffix = "%",
    Flag = "ExampleSlider",
    Callback = function(value)
        print("Slider:", value)
    end,
})

General:AddDropdown({
    Name = "Single Select",
    Options = { "Alpha", "Beta", "Gamma" },
    Default = "Alpha",
    Flag = "SingleSelect",
    Callback = function(option)
        print("Selected:", option)
    end,
})

local multi = General:AddDropdown({
    Name = "Multi Select",
    Options = { "Red", "Green", "Blue" },
    Multi = true,
    Default = { "Red" },
    Flag = "MultiSelect",
    Callback = function(options)
        print("Selected:", table.concat(options, ", "))
    end,
})

General:AddInput({
    Name = "Text Input",
    Placeholder = "Type something...",
    Default = "",
    Flag = "TextInput",
    Callback = function(text, enterPressed)
        print("Input:", text, "enter:", enterPressed)
    end,
})

General:AddKeybind({
    Name = "Example Keybind",
    Description = "Press the key to trigger",
    Default = Enum.KeyCode.G,
    Mode = "Toggle",              -- "Press" | "Toggle" | "Hold"
    Flag = "ExampleBind",
    Callback = function(state)
        print("Keybind state:", state)
    end,
})

General:AddColorPicker({
    Name = "Example Color",
    Default = Color3.fromRGB(10, 132, 255),
    Flag = "ExampleColor",
    Callback = function(color)
        print("Color:", color)
    end,
})

General:AddLabel("A simple label")
General:AddDivider()
General:AddLabel({ Text = "Accent styled label", Style = "Accent" })

---------------------------------------------------------------------------
-- Player tab: a practical example
---------------------------------------------------------------------------
local Movement = PlayerTab:CreateSection("Movement")

local function getHumanoid()
    local character = game.Players.LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

Movement:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Flag = "WalkSpeed",
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end,
})

Movement:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Increment = 5,
    Flag = "JumpPower",
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end,
})

-- Elements can be added straight to a tab (an untitled section is created)
PlayerTab:AddButton({
    Name = "Reset Character",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end,
})

---------------------------------------------------------------------------
-- Visuals tab: dynamic updates
---------------------------------------------------------------------------
local Info = VisualsTab:CreateSection("Live Info")

local fpsLabel = Info:AddLabel("FPS: --")
local frames, last = 0, tick()
game:GetService("RunService").RenderStepped:Connect(function()
    frames = frames + 1
    if tick() - last >= 1 then
        fpsLabel:Set("FPS: " .. frames)
        frames, last = 0, tick()
    end
end)

Info:AddButton({
    Name = "Refresh Multi Dropdown",
    Description = "Replaces the options at runtime",
    Callback = function()
        multi:Refresh({ "Cyan", "Magenta", "Yellow" })
        BPUI:Notify({ Title = "Dropdown", Content = "Options refreshed.", Type = "Info" })
    end,
})

---------------------------------------------------------------------------
-- Notifications and config helpers
---------------------------------------------------------------------------
BPUI:Notify({ Title = "BP Hub", Content = "Loaded successfully.", Type = "Success", Duration = 4 })

-- Manual config control (the Settings tab already provides buttons for this)
-- Window:SaveConfig("myconfig")
-- Window:LoadConfig("myconfig")
-- Window:LoadAutoConfig()   -- call at the end if you disabled AutoLoad in CreateWindow

-- Reading a value anywhere in your script:
-- print(BPUI:GetFlag("WalkSpeed"))
-- print(BPUI.Flags.WalkSpeed.Value)
