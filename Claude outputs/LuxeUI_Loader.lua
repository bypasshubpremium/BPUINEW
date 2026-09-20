--[[
    LUXEUI LOADER - Premium One-Liner Entry Point

    Usage:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/LuxeUI_Loader.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/bypasshubpremium/BPUINEW/main/"
local GAMES = {
    -- Register game-specific scripts by PlaceId
    -- Example: [286090429] = "games/Arsenal.lua",
}

-- Cache BPUI in global state to avoid re-downloading
if getgenv and getgenv().LuxeUI then
    print("[LuxeUI] Already loaded, using cached version")
    return getgenv().LuxeUI
end

-- Attempt to load with retries
local function LoadFile(url, retries)
    retries = retries or 3

    for i = 1, retries do
        local success, data = pcall(function()
            return game:HttpGet(url)
        end)

        if success and data and #data > 0 then
            return data
        end

        if i < retries then
            wait(0.5)
        end
    end

    return nil
end

-- Get PlaceId for game routing
local PlaceId = game.PlaceId
local GameScript = GAMES[PlaceId]

-- Load main library
local LuxeUICode = LoadFile(REPO .. "LuxeUI.lua")

if not LuxeUICode then
    warn("[LuxeUI] Failed to load main library after 3 retries")
    return nil
end

-- Execute library
local LuxeUI = loadstring(LuxeUICode)()

-- Cache for reuse
if getgenv then
    getgenv().LuxeUI = LuxeUI
end

print("[LuxeUI] ✨ Premium UI system loaded successfully!")
print("[LuxeUI] Version: " .. LuxeUI.Version)

-- If game has a dedicated script, load it
if GameScript then
    print("[LuxeUI] Loading game-specific script: " .. GameScript)
    local GameCode = LoadFile(REPO .. GameScript)
    if GameCode then
        loadstring(GameCode)()
    else
        print("[LuxeUI] Failed to load game script, using Hub.lua")
        local HubCode = LoadFile(REPO .. "Hub.lua")
        if HubCode then
            loadstring(HubCode)()
        end
    end
else
    -- Load universal hub
    print("[LuxeUI] Loading universal hub...")
    local HubCode = LoadFile(REPO .. "Hub.lua")
    if HubCode then
        loadstring(HubCode)()
    end
end

return LuxeUI
