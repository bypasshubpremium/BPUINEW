--[[
    LUXEUI - Universal Hub Template
    Edit this to create your premium hub
]]

local LuxeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/LuxeUI.lua"))()

-- Create main window
local window = LuxeUI:CreateWindow({
    Title = "Premium Hub",
    Subtitle = "Ultra-Luxury Edition",
    Theme = "Obsidian",
    Size = UDim2.new(0, 950, 0, 700)
})

-- ═══════════════════════════════════════════════════════════════
-- MAIN TAB - Core Features
-- ═══════════════════════════════════════════════════════════════

local mainTab = window:CreateTab("Main")

mainTab:AddButton("🎯 Execute Feature 1", function()
    LuxeUI:Notify({
        Title = "✨ Feature Executed",
        Content = "Feature 1 is now active",
        Type = "Success"
    })
end)

mainTab:AddButton("⚡ Execute Feature 2", function()
    LuxeUI:Notify({
        Title = "✨ Feature Executed",
        Content = "Feature 2 is now active",
        Type = "Success"
    })
end)

mainTab:AddButton("🚀 Execute Feature 3", function()
    LuxeUI:Notify({
        Title = "✨ Feature Executed",
        Content = "Feature 3 is now active",
        Type = "Success"
    })
end)

mainTab:AddToggle({
    Name = "Auto Execute",
    Default = false,
    Callback = function(state)
        if state then
            LuxeUI:Notify({
                Title = "🔄 Auto Mode",
                Content = "Automatic execution enabled",
                Type = "Success"
            })
        end
    end
})

mainTab:AddSlider({
    Name = "Execution Speed",
    Min = 1,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Speed set to: " .. value .. "%")
    end
})

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════

local settingsTab = window:CreateTab("Settings")

settingsTab:AddToggle({
    Name = "Premium Visuals",
    Default = true,
    Callback = function(state)
        print("Premium Visuals: " .. tostring(state))
    end
})

settingsTab:AddToggle({
    Name = "Smooth Animations",
    Default = true,
    Callback = function(state)
        print("Animations: " .. tostring(state))
    end
})

settingsTab:AddToggle({
    Name = "Sound Effects",
    Default = false,
    Callback = function(state)
        print("Sound: " .. tostring(state))
    end
})

settingsTab:AddToggle({
    Name = "Show Notifications",
    Default = true
})

settingsTab:AddSlider({
    Name = "UI Opacity",
    Min = 0,
    Max = 100,
    Default = 80,
    Callback = function(value)
        print("Opacity: " .. value .. "%")
    end
})

settingsTab:AddSlider({
    Name = "Notification Duration",
    Min = 1,
    Max = 10,
    Default = 4,
    Callback = function(value)
        print("Duration: " .. value .. "s")
    end
})

-- ═══════════════════════════════════════════════════════════════
-- THEMES TAB
-- ═══════════════════════════════════════════════════════════════

local themesTab = window:CreateTab("Themes")

themesTab:AddButton("🌑 Obsidian (Dark Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Obsidian luxury dark theme",
        Type = "Success"
    })
    print("Theme: Obsidian")
end)

themesTab:AddButton("✨ Platinum (Light Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Platinum luxury light theme",
        Type = "Success"
    })
    print("Theme: Platinum")
end)

themesTab:AddButton("🌙 Midnight (Deep Blue)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Midnight luxury theme",
        Type = "Success"
    })
    print("Theme: Midnight")
end)

themesTab:AddButton("💜 Amethyst (Purple Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Amethyst luxury theme",
        Type = "Success"
    })
    print("Theme: Amethyst")
end)

-- ═══════════════════════════════════════════════════════════════
-- INFO TAB
-- ═══════════════════════════════════════════════════════════════

local infoTab = window:CreateTab("Info")

infoTab:AddButton("❓ About LuxeUI", function()
    LuxeUI:Notify({
        Title = "About LuxeUI v2.0",
        Content = "Ultra-premium UI library with glassmorphism design",
        Type = "Info",
        Duration = 5
    })
end)

infoTab:AddButton("📝 Documentation", function()
    LuxeUI:Notify({
        Title = "📖 Docs Available",
        Content = "Check GitHub repository for full docs",
        Type = "Info"
    })
end)

infoTab:AddButton("🐛 Report Bug", function()
    LuxeUI:Notify({
        Title = "🐛 Bug Report",
        Content = "Please report issues on GitHub",
        Type = "Warning",
        Duration = 4
    })
end)

infoTab:AddButton("✨ More Features", function()
    LuxeUI:Notify({
        Title = "🚀 Coming Soon",
        Content = "More luxury components arriving soon!",
        Type = "Warning",
        Duration = 3
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- Show window
-- ═══════════════════════════════════════════════════════════════

window:Show()

-- Welcome notification
LuxeUI:Notify({
    Title = "✨ Welcome to LuxeUI",
    Content = "Ultra-premium UI system ready - Experience luxury! 💎",
    Type = "Success",
    Duration = 5
})

print("[LuxeUI Hub] Premium hub loaded successfully!")
print("[LuxeUI Hub] Theme: Obsidian | Version: 2.0 | Status: Ready")
