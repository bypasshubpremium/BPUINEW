--[[
    BPUI Universal Loader
    ---------------------
    Users execute this single line:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/Loader.lua"))()

    The loader downloads BPUI.lua once, then picks the script for the current
    game (by PlaceId) or falls back to Hub.lua. Every download is retried and
    every failure is reported with a readable message instead of a raw error.

    Repo layout this loader expects:
        BPUI.lua
        Loader.lua
        Hub.lua                 <- universal hub (used when no game script matches)
        games/<Name>.lua        <- one script per game

    This file is the ONLY place your project talks to the network.
]]

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------
local REPO = "https://raw.githubusercontent.com/<user>/<repo>/main/"

-- PlaceId -> script path (relative to REPO). Add one line per supported game.
local GAMES = {
    -- [286090429] = "games/Arsenal.lua",
    -- [2753915549] = "games/BloxFruits.lua",
}

local FALLBACK = "Hub.lua"   -- used when the PlaceId is not listed
local RETRIES = 3
local RETRY_DELAY = 1.5

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function notify(title, text, seconds)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = seconds or 5,
        })
    end)
    print("[Loader] " .. title .. ": " .. text)
end

local function httpGet(url)
    -- try every request function the executor might expose
    local getters = {
        function() return game:HttpGet(url) end,
        function() return game:HttpGetAsync(url) end,
        function()
            local fn = (type(request) == "function" and request)
                or (type(http_request) == "function" and http_request)
                or (type(syn) == "table" and syn.request)
            if not fn then error("no request function") end
            local res = fn({ Url = url, Method = "GET" })
            if type(res) == "table" and res.Body then return res.Body end
            error("bad response")
        end,
    }
    local lastError = "unknown"
    for attempt = 1, RETRIES do
        for _, getter in ipairs(getters) do
            local ok, body = pcall(getter)
            if ok and type(body) == "string" and #body > 0 and not body:find("^404") then
                return body
            end
            if not ok then
                lastError = tostring(body)
            end
        end
        task.wait(RETRY_DELAY * attempt)
    end
    return nil, lastError
end

local function run(path, label)
    local source, err = httpGet(REPO .. path)
    if not source then
        notify("Load failed", "Could not download " .. path .. " (" .. tostring(err) .. ")", 8)
        return nil
    end
    local fn, compileError = loadstring(source, "=" .. (label or path))
    if not fn then
        notify("Load failed", path .. " has a syntax error: " .. tostring(compileError), 8)
        return nil
    end
    local ok, result = pcall(fn)
    if not ok then
        notify("Script error", path .. ": " .. tostring(result), 8)
        return nil
    end
    return result
end

---------------------------------------------------------------------------
-- 1) Library (shared through getgenv so game scripts can reuse it)
---------------------------------------------------------------------------
local env = nil
pcall(function() env = getgenv() end)
env = env or _G

local BPUI = env.BPUI
if type(BPUI) ~= "table" or type(BPUI.CreateWindow) ~= "function" then
    BPUI = run("BPUI.lua", "BPUI")
    if not BPUI then
        return
    end
    env.BPUI = BPUI
end

---------------------------------------------------------------------------
-- 2) Game script or universal hub
---------------------------------------------------------------------------
local placeId = 0
pcall(function() placeId = game.PlaceId end)

local target = GAMES[placeId] or FALLBACK
print("[Loader] PlaceId " .. tostring(placeId) .. " -> " .. target)
run(target)
