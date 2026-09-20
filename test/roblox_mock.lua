-- Minimal Roblox API mock so BPUI.lua can be executed under plain Lua.
-- Not pixel-accurate: it just makes every call the library performs resolvable.

local M = {}

---------------------------------------------------------------- typeof
local function typeof(v)
    local t = type(v)
    if t == "table" then
        local mt = getmetatable(v)
        if mt and mt.__type then
            return mt.__type
        end
    end
    return t
end
_G.typeof = typeof

---------------------------------------------------------------- Signal
local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({ _handlers = {} }, Signal)
end
function Signal:Connect(fn)
    local conn = { _fn = fn, Connected = true }
    self._handlers[#self._handlers + 1] = conn
    function conn:Disconnect()
        self.Connected = false
        self._fn = nil
    end
    return conn
end
function Signal:Fire(...)
    local snapshot = {}
    for i, c in ipairs(self._handlers) do
        snapshot[i] = c
    end
    for _, c in ipairs(snapshot) do
        if c.Connected and c._fn then
            local ok, err = pcall(c._fn, ...)
            if not ok then
                error("handler error: " .. tostring(err), 0)
            end
        end
    end
    -- compact
    local alive = {}
    for _, c in ipairs(self._handlers) do
        if c.Connected then
            alive[#alive + 1] = c
        end
    end
    self._handlers = alive
end
function Signal:Wait()
    return nil
end
M.Signal = Signal

---------------------------------------------------------------- Vector2
local Vector2 = {}
Vector2.__index = Vector2
Vector2.__type = "Vector2"
function Vector2.new(x, y)
    return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end
Vector2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2.__mul = function(a, b)
    if type(a) == "number" then return Vector2.new(a * b.X, a * b.Y) end
    if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end
    return Vector2.new(a.X * b.X, a.Y * b.Y)
end
Vector2.__div = function(a, b) return Vector2.new(a.X / b, a.Y / b) end
Vector2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2.__index = function(t, k)
    if k == "Magnitude" then
        return math.sqrt(t.X * t.X + t.Y * t.Y)
    end
    return Vector2[k]
end
_G.Vector2 = Vector2

---------------------------------------------------------------- UDim / UDim2
local UDim = {}
UDim.__index = UDim
UDim.__type = "UDim"
function UDim.new(s, o) return setmetatable({ Scale = s or 0, Offset = o or 0 }, UDim) end
_G.UDim = UDim

local UDim2 = {}
UDim2.__index = UDim2
UDim2.__type = "UDim2"
function UDim2.new(xs, xo, ys, yo)
    return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UDim2)
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
UDim2.__add = function(a, b)
    return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end
UDim2.__sub = function(a, b)
    return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end
UDim2.__eq = function(a, b)
    return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end
_G.UDim2 = UDim2

---------------------------------------------------------------- Color3
local Color3 = {}
Color3.__index = Color3
Color3.__type = "Color3"
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3) end
function Color3.fromRGB(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHSV(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    local r, g, b
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return Color3.new(r, g, b)
end
function Color3.toHSV(c)
    local r, g, b = c.R, c.G, c.B
    local maxC, minC = math.max(r, g, b), math.min(r, g, b)
    local d = maxC - minC
    local h = 0
    if d > 0 then
        if maxC == r then h = ((g - b) / d) % 6
        elseif maxC == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    local s = maxC > 0 and d / maxC or 0
    return h, s, maxC
end
function Color3:ToHSV() return Color3.toHSV(self) end
Color3.__eq = function(a, b)
    return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6
end
_G.Color3 = Color3

---------------------------------------------------------------- sequences / tween info
_G.NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
_G.NumberSequence = { new = function(kp) return setmetatable({ Keypoints = kp }, { __type = "NumberSequence" }) end }
_G.ColorSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
_G.ColorSequence = { new = function(kp) return setmetatable({ Keypoints = kp }, { __type = "ColorSequence" }) end }
_G.TweenInfo = { new = function(t, s, d) return setmetatable({ Time = t, Style = s, Direction = d }, { __type = "TweenInfo" }) end }

---------------------------------------------------------------- Enum
local enumCache = {}
local EnumItemMT = { __type = "EnumItem", __tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end }
local function getEnumItem(enumType, name)
    enumCache[enumType] = enumCache[enumType] or {}
    local item = enumCache[enumType][name]
    if not item then
        item = setmetatable({ Name = name, EnumType = enumType, Value = 0 }, EnumItemMT)
        enumCache[enumType][name] = item
    end
    return item
end
_G.Enum = setmetatable({}, {
    __index = function(_, enumType)
        return setmetatable({}, {
            __index = function(_, name)
                if type(name) ~= "string" then error("bad enum") end
                return getEnumItem(enumType, name)
            end,
        })
    end,
})

---------------------------------------------------------------- Instance
local Instance = {}
local InstanceMT = {}
InstanceMT.__type = "Instance"

local EVENT_NAMES = {
    InputBegan = true, InputChanged = true, InputEnded = true, MouseEnter = true, MouseLeave = true,
    Activated = true, MouseButton1Click = true, MouseButton1Down = true, MouseButton1Up = true,
    Focused = true, FocusLost = true, Changed = true, AncestryChanged = true, ChildAdded = true,
    ChildRemoved = true, Destroying = true, MouseMoved = true, TouchTap = true, CharacterAdded = true,
}

local GUI_CLASSES = {
    Frame = true, TextLabel = true, TextButton = true, TextBox = true, ImageLabel = true,
    ImageButton = true, ScrollingFrame = true, ScreenGui = true,
}

function Instance.new(className)
    local self = {}
    local props = {
        ClassName = className,
        Name = className,
        Parent = nil,
        Visible = true,
        Text = "",
        Rotation = 0,
        BackgroundTransparency = 0,
        AbsolutePosition = Vector2.new(0, 0),
        AbsoluteSize = GUI_CLASSES[className] and (className == "ScreenGui" and Vector2.new(1280, 720) or Vector2.new(200, 40)) or nil,
        TextBounds = (className == "TextLabel" or className == "TextBox" or className == "TextButton") and Vector2.new(100, 14) or nil,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 100, 0, 100),
        Scale = 1,
    }
    local children = {}
    local events = {}
    local changedSignals = {}
    local destroyed = false

    local function detach()
        local parent = props.Parent
        if parent then
            local list = rawget(parent, "_children")
            for i = #list, 1, -1 do
                if list[i] == self then
                    table.remove(list, i)
                end
            end
        end
    end

    local methods = {}
    function methods.Destroy(_)
        if destroyed then return end
        detach()
        props.Parent = nil
        destroyed = true
        for _, child in ipairs({ table.unpack(children) }) do
            child:Destroy()
        end
    end
    function methods.GetChildren(_)
        local copy = {}
        for i, c in ipairs(children) do copy[i] = c end
        return copy
    end
    function methods.FindFirstChild(_, name)
        for _, c in ipairs(children) do
            if c.Name == name then return c end
        end
        return nil
    end
    function methods.FindFirstChildOfClass(_, cls)
        for _, c in ipairs(children) do
            if c.ClassName == cls then return c end
        end
        return nil
    end
    function methods.WaitForChild(s, name)
        return s:FindFirstChild(name)
    end
    function methods.GetPropertyChangedSignal(_, prop)
        changedSignals[prop] = changedSignals[prop] or Signal.new()
        return changedSignals[prop]
    end
    function methods.IsA(_, cls)
        return props.ClassName == cls
    end
    function methods.GetDescendants(_)
        local out = {}
        local function walk(inst)
            for _, c in ipairs(inst:GetChildren()) do
                out[#out + 1] = c
                walk(c)
            end
        end
        walk(self)
        return out
    end
    function methods.SetAttribute(_, k, v) props["@" .. k] = v end
    function methods.GetAttribute(_, k) return props["@" .. k] end

    rawset(self, "_children", children)
    rawset(self, "_props", props)

    return setmetatable(self, {
        __type = "Instance",
        __tostring = function() return props.Name end,
        __index = function(_, key)
            if methods[key] then return methods[key] end
            if EVENT_NAMES[key] then
                events[key] = events[key] or Signal.new()
                return events[key]
            end
            local v = props[key]
            if v ~= nil then return v end
            -- child lookup by name (Roblox behaviour)
            for _, c in ipairs(children) do
                if c.Name == key then return c end
            end
            return nil
        end,
        __newindex = function(_, key, value)
            if key == "Parent" then
                if destroyed then error("The Parent property of " .. props.Name .. " is locked") end
                detach()
                props.Parent = value
                if value then
                    table.insert(rawget(value, "_children"), self)
                end
                return
            end
            local old = props[key]
            props[key] = value
            if changedSignals[key] and old ~= value then
                changedSignals[key]:Fire()
            end
        end,
    })
end
_G.Instance = Instance

---------------------------------------------------------------- task / time
local clock = 0
local scheduled = {}
_G.tick = function() return clock end
_G.os = _G.os or {}
_G.os.clock = function() return clock end

local task = {}
function task.spawn(fn, ...)
    local co = coroutine.create(fn)
    local ok, err = coroutine.resume(co, ...)
    if not ok then error(err, 0) end
    return co
end
task.defer = task.spawn
function task.delay(t, fn, ...)
    local args = { ... }
    scheduled[#scheduled + 1] = { at = clock + (t or 0), fn = fn, args = args }
end
local function runDue()
    table.sort(scheduled, function(a, b) return a.at < b.at end)
    local i = 1
    while i <= #scheduled do
        local item = scheduled[i]
        if item.at <= clock then
            table.remove(scheduled, i)
            local ok, err = pcall(item.fn, table.unpack(item.args))
            if not ok then error("delayed error: " .. tostring(err), 0) end
        else
            i = i + 1
        end
    end
end
function task.wait(t)
    clock = clock + (t or 0.03)
    runDue()
    if coroutine.isyieldable() then
        coroutine.yield()
    end
    return t or 0.03
end
function M.advance(t)
    clock = clock + (t or 1)
    runDue()
end
_G.task = task
_G.wait = task.wait

---------------------------------------------------------------- Services
local function serialize(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "table" then
        local parts = {}
        local isArray = #v > 0
        for k, val in pairs(v) do
            if isArray then
                parts[#parts + 1] = serialize(val, depth + 1)
            else
                parts[#parts + 1] = "[" .. string.format("%q", k) .. "]=" .. serialize(val, depth + 1)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    elseif t == "string" then
        return string.format("%q", v)
    else
        return tostring(v)
    end
end

local UserInputService = {
    TouchEnabled = false,
    MouseEnabled = true,
    KeyboardEnabled = true,
    InputBegan = Signal.new(),
    InputChanged = Signal.new(),
    InputEnded = Signal.new(),
    _focused = nil,
}
function UserInputService:GetFocusedTextBox() return self._focused end

local TweenService = {}
function TweenService:Create(inst, info, props)
    local tw = { Completed = Signal.new() }
    function tw:Play()
        for k, v in pairs(props) do inst[k] = v end
    end
    function tw:Cancel() end
    return tw
end

local HttpService = {}
function HttpService:JSONEncode(data) return serialize(data) end
function HttpService:JSONDecode(text)
    local fn = load("return " .. text)
    return fn()
end

local CoreGui = Instance.new("CoreGui")
local Players = { LocalPlayer = Instance.new("Player") }
local playerGui = Instance.new("PlayerGui")
playerGui.Parent = Players.LocalPlayer
local RunService = { RenderStepped = Signal.new(), Heartbeat = Signal.new() }

local services = {
    UserInputService = UserInputService,
    TweenService = TweenService,
    HttpService = HttpService,
    CoreGui = CoreGui,
    Players = Players,
    RunService = RunService,
}
_G.game = { GetService = function(_, name) return services[name] end }
M.UserInputService = UserInputService
M.CoreGui = CoreGui
M.services = services

-- extra surface used by the example / hub scripts (not by the library itself)
function M.extendGame(librarySource)
    _G.loadstring = function(src, name) return load(src, name) end
    game.PlaceId = 0
    game.HttpGet = function(_, url)
        if url:find("BPUI%.lua") then return librarySource end
        error("mock: no such url " .. url)
    end
    Players.PlayerAdded = Signal.new()
    Players.PlayerRemoving = Signal.new()
    function Players:GetPlayers() return { self.LocalPlayer } end
    Players.LocalPlayer.Name = "TestPlayer"
    game.Players = Players
    services.MarketplaceService = { GetProductInfo = function() return { Name = "Mock Game" } end }
    services.TeleportService = { Teleport = function() end }
    services.StarterGui = { SetCore = function() end }
end

---------------------------------------------------------------- misc globals
_G.warn = function(...) print("[warn]", ...) end

-- Input object factory for tests
function M.input(userInputType, keyCode, position)
    return {
        UserInputType = getEnumItem("UserInputType", userInputType),
        KeyCode = getEnumItem("KeyCode", keyCode or "Unknown"),
        Position = position or Vector2.new(0, 0),
        UserInputState = getEnumItem("UserInputState", "Begin"),
        Changed = Signal.new(),
    }
end
M.getEnumItem = getEnumItem

-- in-memory executor file system (installed on demand)
function M.installFileSystem()
    local files = {}
    local folders = {}
    _G.writefile = function(path, content) files[path] = content end
    _G.readfile = function(path)
        if files[path] == nil then error("file not found: " .. path) end
        return files[path]
    end
    _G.isfile = function(path) return files[path] ~= nil end
    _G.isfolder = function(path) return folders[path] == true end
    _G.makefolder = function(path) folders[path] = true end
    _G.delfile = function(path) files[path] = nil end
    _G.listfiles = function(folder)
        local out = {}
        for path in pairs(files) do
            if path:sub(1, #folder + 1) == folder .. "/" then out[#out + 1] = path end
        end
        return out
    end
    _G.setclipboard = function(text) M.clipboard = text end
    return files
end

-- find helper
function M.find(root, predicate)
    for _, c in ipairs(root:GetChildren()) do
        if predicate(c) then return c end
        local found = M.find(c, predicate)
        if found then return found end
    end
    return nil
end

function M.findAll(root, predicate, out)
    out = out or {}
    for _, c in ipairs(root:GetChildren()) do
        if predicate(c) then out[#out + 1] = c end
        M.findAll(c, predicate, out)
    end
    return out
end

return M
