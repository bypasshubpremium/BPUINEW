--[[
    BPUI example 5: changing the UI while the script runs.

    Every Add* call returns an object. Keep it in a variable and you can
    read it, change it, hide it or lock it at any time.
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()
local Players = game:GetService("Players")

local Window = BPUI:CreateWindow({ Title = "Live UI", Icon = "activity" })
local Tab = Window:CreateTab({ Name = "Players", Icon = "users", Badge = 0 })
local Section = Tab:CreateSection("Target")

-- a status line you rewrite whenever something happens
local status = Section:AddParagraph({ Title = "Status", Content = "Pick a player." })

-- a dropdown whose options are filled in (and refreshed) by the script
local function playerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local picker = Section:AddDropdown({
    Name = "Player",
    Icon = "user",
    Options = playerNames(),
    Callback = function(name)
        status:SetContent("Selected " .. tostring(name))
    end,
})

local function refresh()
    picker:Refresh(playerNames(), true)       -- true: keep the current pick if still in the server
    Tab:SetBadge(#playerNames())              -- the number next to the tab name
end
Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
refresh()

-- a toggle that only makes sense once something is selected
local follow = Section:AddToggle({ Name = "Follow player", Callback = function(on) print("follow", on) end })
follow:Lock()                                  -- greyed out, can't be clicked
Section:AddButton({
    Name = "Unlock follow",
    Callback = function()
        if picker.Value then follow:Unlock() else status:SetContent("Select a player first.") end
    end,
})

-- hide and show rows or whole sections
local advanced = Tab:CreateSection("Advanced")
advanced:AddSlider({ Name = "Follow distance", Min = 2, Max = 20, Default = 5 })
advanced:SetVisible(false)
Section:AddToggle({
    Name = "Show advanced options",
    Callback = function(on) advanced:SetVisible(on) end,
})

-- rename things
Section:AddButton({
    Name = "Rename this tab",
    Callback = function() Tab:SetName("Targets") Tab:SetSubtitle("Renamed at runtime") end,
})

-- read any flagged value from anywhere, even from another script
Section:AddSlider({ Name = "Range", Min = 0, Max = 500, Default = 100, Flag = "Range" })
print("Range is", BPUI:GetFlag("Range"))
BPUI:SetFlag("Range", 250)                     -- moves the slider and runs its callback
