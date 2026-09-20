-- Executes the shipped scripts (Example.lua, Hub.lua, games/ExampleGame.lua)
-- under the mock to make sure they run end to end without errors.
package.path = "./test/?.lua;" .. package.path
local Mock = require("roblox_mock")
Mock.installFileSystem()

local librarySource = assert(io.open("BPUI.lua")):read("a")
Mock.extendGame(librarySource)

local scripts = {
    { path = "Example.lua", key = "BPHUB-FREE-KEY" },
    { path = "Hub.lua" },
    { path = "games/ExampleGame.lua" },
}

local failures = 0
for _, entry in ipairs(scripts) do
    local chunk = assert(loadfile(entry.path))
    local co = coroutine.create(chunk)
    local keyDone = false
    local steps = 0
    local ok, err = true, nil
    while coroutine.status(co) ~= "dead" do
        ok, err = coroutine.resume(co)
        if not ok then break end
        steps = steps + 1
        if steps > 500 then ok, err = false, "timed out" break end
        if entry.key and not keyDone then
            local frame = Mock.find(Mock.CoreGui, function(c) return c.Name == "KeySystem" end)
            if frame then
                local box = Mock.find(frame, function(c) return c.ClassName == "TextBox" end)
                local verify = Mock.find(frame, function(c) return c.ClassName == "TextButton" and c.Text == "Verify" end)
                box.Text = entry.key
                verify.Activated:Fire()
                keyDone = true
            end
        end
    end
    if ok then
        -- let delayed work (auto-load, tweens) run
        Mock.advance(3)
        local windows = Mock.findAll(Mock.CoreGui, function(c) return c.Name:sub(1, 7) == "Window_" end)
        print(string.format("OK    %-24s windows=%d", entry.path, #windows))
    else
        failures = failures + 1
        print("FAIL  " .. entry.path .. ": " .. tostring(err))
        print(debug.traceback(co))
    end
end

if failures > 0 then os.exit(1) end
print("All shipped scripts ran without errors.")
