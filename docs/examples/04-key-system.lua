--[[
    BPUI example 4: a key system.

    CreateWindow shows the key screen first and only returns once a valid
    key is entered, so everything after it runs for verified users only.
    If the user closes the key screen, CreateWindow returns nil.
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

local Window = BPUI:CreateWindow({
    Title = "My Hub",
    Subtitle = "Premium",
    KeySystem = {
        Title = "My Hub | Key System",
        Subtitle = "Join the Discord to get a key.",
        Keys = { "MYHUB-1234", "MYHUB-5678" },   -- anyone can read keys written here
        CaseSensitive = false,
        SaveKey = true,                         -- remember a valid key for next time
        GetKeyLink = "https://discord.gg/yourserver",
        MaxAttempts = 5,
        -- For keys you check yourself (a server, a rotating key...), return true/false:
        -- Validate = function(key) return key:sub(1, 6) == "MYHUB-" end,
    },
})

if not Window then return end   -- key screen closed or failed

local Main = Window:CreateTab({ Name = "Main", Icon = "home" })
Main:CreateSection("Welcome"):AddParagraph({
    Title = "You're in",
    Content = "The key is saved, so next time the window opens straight away.",
})
