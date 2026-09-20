

local BPUI = (getgenv and getgenv().BPUI)
if not BPUI then
    BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
end

local Window = BPUI:CreateWindow({
    Title = "BP Hub",
    Subtitle = "Example Game",
    ConfigFolder = "BPHub/ExampleGame",   
})

local Main = Window:CreateTab({ Name = "Main" })
local Farm = Main:CreateSection("Farming")

local autoFarm = false
Farm:AddToggle({
    Name = "Auto Farm",
    Description = "Example loop that stops when the toggle is off",
    Flag = "AutoFarm",
    Callback = function(state)
        autoFarm = state
        task.spawn(function()
            while autoFarm do
                
                task.wait(1)
            end
        end)
    end,
})

Farm:AddDropdown({
    Name = "Target",
    Options = { "Nearest", "Weakest", "Strongest" },
    Default = "Nearest",
    Flag = "FarmTarget",
    Callback = function(option)
        print("Target mode:", option)
    end,
})

local Misc = Window:CreateTab({ Name = "Misc" })
Misc:AddButton({
    Name = "Rejoin",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end,
})

BPUI:Notify({ Title = "BP Hub", Content = "Example Game script loaded.", Type = "Success" })
