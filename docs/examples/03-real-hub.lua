--[[
    BPUI example 3: how a real script is laid out.

      1. services and state at the top
      2. the features as plain functions (no UI code inside them)
      3. the UI at the bottom, wiring elements to those functions
      4. loops started with task.spawn, stopped through a flag
      5. everything cleaned up in OnDestroy when the user closes the hub

    Works in any game.
]]

local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/BPUI.lua"))()

---------------------------------------------------------------- 1. services and state
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local state = {
    walkSpeed = 16,
    jumpPower = 50,
    infiniteJump = false,
    noclip = false,
    antiAfk = true,
    running = true,          -- false once the hub is closed; loops check it
    connections = {},
}

local function humanoid()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

---------------------------------------------------------------- 2. features
local function applyMovement()
    local h = humanoid()
    if not h then return end
    h.WalkSpeed = state.walkSpeed
    h.UseJumpPower = true
    h.JumpPower = state.jumpPower
end

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
}
local function setFullbright(on)
    if on then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        for k, v in pairs(originalLighting) do Lighting[k] = v end
    end
end

-- re-apply movement after respawning
table.insert(state.connections, player.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyMovement()
end))

-- infinite jump
table.insert(state.connections, UserInputService.JumpRequest:Connect(function()
    if state.infiniteJump then
        local h = humanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- noclip: a loop that runs while the hub is open
task.spawn(function()
    while state.running do
        if state.noclip and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        RunService.Stepped:Wait()
    end
end)

-- anti afk
table.insert(state.connections, player.Idled:Connect(function()
    if state.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

---------------------------------------------------------------- 3. the UI
local Window = BPUI:CreateWindow({
    Title = "My Hub",
    Subtitle = "Universal",
    Icon = "zap",
    OnDestroy = function()
        -- 5. cleanup: stop loops, disconnect events, undo changes
        state.running = false
        for _, c in ipairs(state.connections) do c:Disconnect() end
        setFullbright(false)
        state.walkSpeed, state.jumpPower = 16, 50
        applyMovement()
    end,
})

-- Tabs can sit inside a collapsible group in the sidebar
local PlayerGroup = Window:CreateGroup({ Name = "Player", Icon = "user", Open = true })
local MovementTab = PlayerGroup:CreateTab({ Name = "Movement", Icon = "footprints", Subtitle = "Speed, jumps and collisions" })
local WorldTab = Window:CreateTab({ Name = "World", Icon = "globe" })
local MiscTab = Window:CreateTab({ Name = "Misc", Icon = "wrench" })

-- Movement
local Speed = MovementTab:CreateSection("Speed")
Speed:AddSlider({
    Name = "Walk speed", Icon = "footprints",
    Min = 16, Max = 200, Default = 16, Flag = "WalkSpeed",
    Callback = function(v) state.walkSpeed = v applyMovement() end,
})
Speed:AddSlider({
    Name = "Jump power", Icon = "arrow-up",
    Min = 50, Max = 300, Default = 50, Flag = "JumpPower",
    Callback = function(v) state.jumpPower = v applyMovement() end,
})

local Abilities = MovementTab:CreateSection("Abilities")
Abilities:AddToggle({
    Name = "Infinite jump", Description = "Jump again while in the air.",
    Flag = "InfiniteJump",
    Callback = function(on) state.infiniteJump = on end,
})
Abilities:AddToggle({
    Name = "Noclip", Description = "Walk through walls.",
    Flag = "Noclip",
    Callback = function(on) state.noclip = on end,
})

-- World
local Visuals = WorldTab:CreateSection("Visuals")
Visuals:AddToggle({ Name = "Fullbright", Icon = "sun", Flag = "Fullbright", Callback = setFullbright })
Visuals:AddSlider({
    Name = "Field of view", Icon = "eye",
    Min = 30, Max = 120, Default = 70, Flag = "FOV",
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

-- Misc
local Server = MiscTab:CreateSection("Server")
Server:AddToggle({
    Name = "Anti AFK", Description = "Stops the 20 minute idle kick.",
    Default = true, Flag = "AntiAfk",
    Callback = function(on) state.antiAfk = on end,
})
Server:AddButton({
    Name = "Rejoin", Icon = "refresh-cw",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

local Info = MiscTab:CreateSection("Info")
local statusLabel = Info:AddLabel({ Text = "Players: ...", Style = "Sub" })

-- keep a label up to date
task.spawn(function()
    while state.running do
        statusLabel:Set("Players: " .. #Players:GetPlayers())
        task.wait(2)
    end
end)

BPUI:Notify({ Title = "My Hub", Content = "Loaded. RightShift hides the window.", Type = "Success" })
