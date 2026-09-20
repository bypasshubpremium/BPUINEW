

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()




local Window = BPUI:CreateWindow({
    Title = "BP Hub",                      
    Subtitle = "Premium",                  
    Icon = nil,                            
    Theme = "Dark",                        
    Accent = Color3.fromRGB(10, 132, 255), 
    Size = UDim2.fromOffset(640, 440),     
    ToggleKey = Enum.KeyCode.RightShift,   
    FloatingButton = nil,                  
    ConfigFolder = "BPHub",                
    ShowSettings = true,                   
    CloseBehavior = "Destroy",             
    ConfirmClose = true,                   
    Resizable = nil,                       
    Search = true,                         
    WelcomeNotification = true,
    KeySystem = {
        Enabled = true,
        Title = "BP Hub | Key System",
        Subtitle = "Enter your key to continue",
        Note = "Get your key from our Discord server.",
        Keys = { "BPHUB-FREE-KEY" },       
        CaseSensitive = false,
        SaveKey = true,                    
        GetKeyLink = "https://discord.gg/yourserver", 
        
        
    },
    OnDestroy = function()
        print("UI unloaded")
    end,
})




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
    Mode = "Toggle",              
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


PlayerTab:AddButton({
    Name = "Reset Character",
    Callback = function()
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end,
})




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


local playerList = Info:AddDropdown({
    Name = "Players",
    Options = {},
    Callback = function(name)
        print("Picked player:", name)
    end,
})
local function refreshPlayers()
    local names = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        names[#names + 1] = player.Name
    end
    playerList:Refresh(names, true)
end
refreshPlayers()
game.Players.PlayerAdded:Connect(refreshPlayers)
game.Players.PlayerRemoving:Connect(refreshPlayers)




local Control = VisualsTab:CreateSection("Window")

local premium = Control:AddToggle({
    Name = "Premium Feature",
    Description = "Locked until you press Unlock",
    Callback = function(state)
        print("Premium:", state)
    end,
})
premium:Lock()

Control:AddButton({
    Name = "Unlock Premium Feature",
    Callback = function()
        premium:Unlock()
        BPUI:Notify({ Title = "Unlocked", Content = "The toggle above is now usable.", Type = "Success" })
    end,
})

Control:AddButton({
    Name = "Show Dialog",
    Callback = function()
        Window:Dialog({
            Title = "Reset everything?",
            Content = "This is what a confirmation dialog looks like.",
            Buttons = {
                { Text = "Cancel" },
                { Text = "Reset", Style = "Danger", Callback = function()
                    BPUI:Notify({ Title = "Dialog", Content = "You pressed Reset.", Type = "Warning" })
                end },
            },
        })
    end,
})

Control:AddButton({
    Name = "Minimize Window",
    Description = "Same as the button in the top bar",
    Callback = function()
        Window:Minimize()
    end,
})

Control:AddButton({
    Name = "Switch to Light Theme",
    Callback = function()
        BPUI:SetTheme("Light")
    end,
})




BPUI:Notify({ Title = "BP Hub", Content = "Loaded successfully.", Type = "Success", Duration = 4 })









