

local BPUI = (getgenv and getgenv().BPUI)
if not BPUI then
    BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/BPUI.lua"))()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = BPUI:CreateWindow({
    Title = "BP Hub",
    Subtitle = "Universal",
    ConfigFolder = "BPHub/Universal",
    ToggleKey = Enum.KeyCode.RightShift,
    ConfirmClose = true,
    KeySystem = {
        Enabled = false,           
        Title = "BP Hub | Key System",
        Note = "Get your key from our Discord server.",
        Keys = { "BPHUB-KEY" },
        GetKeyLink = "https://discord.gg/yourserver",
    },
})




local PlayerTab = Window:CreateTab({ Name = "Player" })
local Movement = PlayerTab:CreateSection("Movement")

local function humanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local walkSpeed = Movement:AddSlider({
    Name = "Walk Speed",
    Min = 16, Max = 250, Default = 16, Increment = 1,
    Flag = "WalkSpeed",
    Callback = function(value)
        local h = humanoid()
        if h then h.WalkSpeed = value end
    end,
})

local jumpPower = Movement:AddSlider({
    Name = "Jump Power",
    Min = 50, Max = 400, Default = 50, Increment = 5,
    Flag = "JumpPower",
    Callback = function(value)
        local h = humanoid()
        if h then
            h.UseJumpPower = true
            h.JumpPower = value
        end
    end,
})


LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    walkSpeed:Set(walkSpeed.Value, false)
    jumpPower:Set(jumpPower.Value, false)
end)




local InfoTab = Window:CreateTab({ Name = "Info" })
local Game = InfoTab:CreateSection("Game")

local gameName = "Unknown"
pcall(function()
    gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

Game:AddParagraph({
    Title = gameName,
    Content = "PlaceId: " .. tostring(game.PlaceId) .. "\nNo dedicated script for this game yet, so the universal hub was loaded.",
})

Game:AddButton({
    Name = "Copy PlaceId",
    Description = "Useful when adding this game to the loader",
    Callback = function()
        if BPUI.CopyToClipboard(tostring(game.PlaceId)) then
            BPUI:Notify({ Title = "Copied", Content = "PlaceId copied to clipboard.", Type = "Success" })
        else
            BPUI:Notify({ Title = "PlaceId", Content = tostring(game.PlaceId), Type = "Info", Duration = 8 })
        end
    end,
})

BPUI:Notify({ Title = "BP Hub", Content = "Universal hub loaded.", Type = "Success" })
