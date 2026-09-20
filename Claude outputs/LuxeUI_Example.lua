--[[
    ═══════════════════════════════════════════════════════════════
        LUXEUI - Premium Example Showcase
        Demonstrates all luxury components and effects
    ═══════════════════════════════════════════════════════════════
]]

local LuxeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/LuxeUI.lua"))()

-- Create main window
local window = LuxeUI:CreateWindow({
    Title = "LuxeUI Premium",
    Subtitle = "Ultra-Premium UI Showcase",
    Theme = "Obsidian",
    Size = UDim2.new(0, 900, 0, 700)
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 1: DASHBOARD
-- ═══════════════════════════════════════════════════════════════

local dashTab = window:CreateTab("Dashboard")

dashTab:AddButton("🎨 Show Premium Notification", function()
    LuxeUI:Notify({
        Title = "✨ Welcome",
        Content = "Experience the premium UI system",
        Type = "Success",
        Duration = 4
    })
end)

dashTab:AddButton("🌙 Dark Mode Applied", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Updated",
        Content = "Switched to Obsidian luxury theme",
        Duration = 3
    })
end)

dashTab:AddButton("⚡ High Performance", function()
    LuxeUI:Notify({
        Title = "⚙️ System Status",
        Content = "All systems running at optimal performance",
        Type = "Success"
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- TAB 2: CONTROLS
-- ═══════════════════════════════════════════════════════════════

local controlsTab = window:CreateTab("Controls")

controlsTab:AddToggle({
    Name = "Premium Visuals",
    Default = true,
    Callback = function(state)
        print("Premium Visuals: " .. tostring(state))
    end
})

controlsTab:AddToggle({
    Name = "Glassmorphism Effects",
    Default = true,
    Callback = function(state)
        print("Glass Effects: " .. tostring(state))
    end
})

controlsTab:AddToggle({
    Name = "Smooth Animations",
    Default = true,
    Callback = function(state)
        print("Animations: " .. tostring(state))
    end
})

controlsTab:AddToggle({
    Name = "Dynamic Shadows",
    Default = true,
    Callback = function(state)
        print("Shadows: " .. tostring(state))
    end
})

controlsTab:AddSlider({
    Name = "UI Opacity",
    Min = 0,
    Max = 100,
    Default = 80,
    Callback = function(value)
        print("Opacity: " .. value .. "%")
    end
})

controlsTab:AddSlider({
    Name = "Animation Speed",
    Min = 1,
    Max = 100,
    Default = 60,
    Callback = function(value)
        print("Speed: " .. value .. "%")
    end
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 3: THEMES
-- ═══════════════════════════════════════════════════════════════

local themeTab = window:CreateTab("Themes")

themeTab:AddButton("🌑 Obsidian (Dark Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Obsidian luxury dark theme",
        Type = "Success"
    })
end)

themeTab:AddButton("✨ Platinum (Light Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Platinum luxury light theme",
        Type = "Success"
    })
end)

themeTab:AddButton("🌙 Midnight (Deep Blue)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Midnight luxury theme",
        Type = "Success"
    })
end)

themeTab:AddButton("💜 Amethyst (Purple Luxury)", function()
    LuxeUI:Notify({
        Title = "🎨 Theme Changed",
        Content = "Applied Amethyst luxury theme",
        Type = "Success"
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- TAB 4: SETTINGS
-- ═══════════════════════════════════════════════════════════════

local settingsTab = window:CreateTab("Settings")

settingsTab:AddToggle({
    Name = "Auto-Save Config",
    Default = true
})

settingsTab:AddToggle({
    Name = "Startup Notifications",
    Default = true
})

settingsTab:AddToggle({
    Name = "Sound Effects",
    Default = false
})

settingsTab:AddToggle({
    Name = "Motion Blur",
    Default = true
})

settingsTab:AddSlider({
    Name = "UI Scale",
    Min = 50,
    Max = 150,
    Default = 100
})

settingsTab:AddSlider({
    Name = "Notification Timeout",
    Min = 1,
    Max = 10,
    Default = 4
})

-- ═══════════════════════════════════════════════════════════════
-- Show window
-- ═══════════════════════════════════════════════════════════════

window:Show()

-- Success notification
LuxeUI:Notify({
    Title = "✨ LuxeUI v2.0 Loaded",
    Content = "Premium UI system ready - Rayfield & Fluent UI beaten 🎉",
    Type = "Success",
    Duration = 5
})

print("[LuxeUI] Premium UI system loaded successfully!")
print("[LuxeUI] Features: Glassmorphism | Luxury Animations | Premium Design")
print("[LuxeUI] Themes: Obsidian | Platinum | Midnight | Amethyst")
