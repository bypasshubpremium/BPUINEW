--[[
    BPUI example 1: the smallest useful script.

    Structure is always the same four levels:
        Window  ->  Tab  ->  Section  ->  elements (toggles, sliders, ...)
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. the window (one per script)
local Window = BPUI:CreateWindow({
    Title = "My Hub",          -- keep this the same every run: re-running replaces the old window
    Subtitle = "Universal",
    Icon = "zap",
})

-- 2. a tab in the sidebar
local Main = Window:CreateTab({ Name = "Main", Icon = "home" })

-- 3. a section (a titled card) on that tab
local Movement = Main:CreateSection("Movement")

-- 4. elements inside the section
Movement:AddSlider({
    Name = "Walk speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Flag = "WalkSpeed",        -- give it a Flag and it is saved in configs
    Callback = function(value)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = value end
    end,
})

Movement:AddButton({
    Name = "Reset character",
    Callback = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.Health = 0 end
    end,
})
