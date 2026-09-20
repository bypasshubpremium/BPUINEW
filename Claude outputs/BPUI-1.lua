--[[
    ================================================================
      BPUI  -  Premium iOS-style UI Library for Roblox
      Version 1.1.0
    ================================================================

      - Works on PC and Mobile (mouse, keyboard and touch)
      - Zero HTTP requests and zero external assets  ->  no HttpError
      - Runs on low-level executors: every executor API is optional
        (gethui, writefile, readfile, setclipboard ... all pcall-guarded)
      - Safe mode: a failing element logs a warning instead of
        killing your script (BPUI.SafeMode = false to debug)
      - Window: drag, resize grip, minimise bar, search field,
        floating open/close bubble (mobile), toggle key (PC),
        remembered size / theme / accent / key, modal dialogs
      - Elements: Button, Toggle, Slider (drag or tap-to-type),
        Dropdown (single / multi, auto filter), Input, Keybind
        (keys + mouse buttons), ColorPicker, Label, Paragraph, Divider
        - every element supports Set / Get / SetVisible / Lock / Destroy
      - Notifications, Key System, Config save / load / auto-load,
        built-in Settings tab

      Usage:
        local BPUI = loadstring(game:HttpGet("<raw url>"))()   -- or paste the file
        local Window = BPUI:CreateWindow({ Title = "My Hub" })
        local Tab = Window:CreateTab({ Name = "Main" })
        local Section = Tab:CreateSection("Player")
        Section:AddToggle({ Name = "Example", Callback = function(v) print(v) end })

      See README.md / Example.lua for the full API.
    ================================================================
]]

local BPUI = {}
BPUI.Version = "1.1.0"
BPUI.Flags = {}
BPUI.Windows = {}
BPUI._connections = {}

---------------------------------------------------------------------
-- Services (all guarded so the library never throws on load)
---------------------------------------------------------------------
local function GetService(name)
    local ok, service = pcall(function()
        return game:GetService(name)
    end)
    if ok then
        return service
    end
    return nil
end

local TweenService = GetService("TweenService")
local UserInputService = GetService("UserInputService")
local RunService = GetService("RunService")
local HttpService = GetService("HttpService")
local Players = GetService("Players")
local CoreGui = GetService("CoreGui")
local LocalPlayer = Players and Players.LocalPlayer

---------------------------------------------------------------------
-- Environment detection
---------------------------------------------------------------------
local IsMobile = false
pcall(function()
    IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end)
BPUI.IsMobile = IsMobile

local function IsFunction(f)
    return typeof(f) == "function"
end

-- Executor file system (optional everywhere)
local FS = {}
FS.Available = IsFunction(writefile) and IsFunction(readfile)

function FS.EnsureFolder(path)
    if IsFunction(isfolder) and IsFunction(makefolder) then
        pcall(function()
            if not isfolder(path) then
                makefolder(path)
            end
        end)
    end
end

function FS.Write(path, content)
    if not FS.Available then
        return false
    end
    local ok = pcall(writefile, path, content)
    return ok
end

function FS.Read(path)
    if not FS.Available then
        return nil
    end
    local ok, content = pcall(readfile, path)
    if ok and type(content) == "string" then
        return content
    end
    return nil
end

function FS.Exists(path)
    if not FS.Available then
        return false
    end
    if IsFunction(isfile) then
        local ok, result = pcall(isfile, path)
        return ok and result == true
    end
    local ok = pcall(readfile, path)
    return ok
end

function FS.List(folder)
    if IsFunction(listfiles) then
        local ok, result = pcall(listfiles, folder)
        if ok and type(result) == "table" then
            return result
        end
    end
    return {}
end

function FS.Delete(path)
    if IsFunction(delfile) then
        return pcall(delfile, path)
    end
    return false
end

BPUI.FileSystem = FS

-- Clipboard (optional)
local function CopyToClipboard(text)
    local ok = pcall(function()
        if IsFunction(setclipboard) then
            setclipboard(text)
        elseif IsFunction(toclipboard) then
            toclipboard(text)
        elseif type(syn) == "table" and IsFunction(syn.write_clipboard) then
            syn.write_clipboard(text)
        else
            error("no clipboard")
        end
    end)
    return ok
end
BPUI.CopyToClipboard = CopyToClipboard

-- Where to parent the ScreenGui
local function GetGuiParent()
    local ok, hui = pcall(function()
        return gethui()
    end)
    if ok and typeof(hui) == "Instance" then
        return hui
    end

    if CoreGui then
        local ok2 = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "BPUI_Probe"
            probe.Parent = CoreGui
            probe:Destroy()
        end)
        if ok2 then
            return CoreGui
        end
    end

    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then
            pcall(function()
                pg = LocalPlayer:WaitForChild("PlayerGui", 5)
            end)
        end
        if pg then
            return pg
        end
    end
    return nil
end

---------------------------------------------------------------------
-- Themes (iOS system colours)
---------------------------------------------------------------------
BPUI.Themes = {
    Dark = {
        Window = Color3.fromRGB(28, 28, 30),
        Sidebar = Color3.fromRGB(22, 22, 24),
        Card = Color3.fromRGB(44, 44, 46),
        CardHover = Color3.fromRGB(58, 58, 61),
        Element = Color3.fromRGB(62, 62, 66),
        Separator = Color3.fromRGB(56, 56, 58),
        Stroke = Color3.fromRGB(70, 70, 74),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(152, 152, 157),
        Accent = Color3.fromRGB(10, 132, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(48, 209, 88),
        Warning = Color3.fromRGB(255, 159, 10),
        Error = Color3.fromRGB(255, 69, 58),
        Toggle = Color3.fromRGB(48, 209, 88),
        ToggleOff = Color3.fromRGB(57, 57, 60),
        Knob = Color3.fromRGB(255, 255, 255),
    },
    Light = {
        Window = Color3.fromRGB(242, 242, 247),
        Sidebar = Color3.fromRGB(232, 232, 237),
        Card = Color3.fromRGB(255, 255, 255),
        CardHover = Color3.fromRGB(235, 235, 240),
        Element = Color3.fromRGB(229, 229, 234),
        Separator = Color3.fromRGB(216, 216, 220),
        Stroke = Color3.fromRGB(205, 205, 210),
        Text = Color3.fromRGB(0, 0, 0),
        SubText = Color3.fromRGB(142, 142, 147),
        Accent = Color3.fromRGB(0, 122, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(52, 199, 89),
        Warning = Color3.fromRGB(255, 149, 0),
        Error = Color3.fromRGB(255, 59, 48),
        Toggle = Color3.fromRGB(52, 199, 89),
        ToggleOff = Color3.fromRGB(229, 229, 234),
        Knob = Color3.fromRGB(255, 255, 255),
    },
    Rose = {
        Accent = Color3.fromRGB(255, 55, 95),
        Toggle = Color3.fromRGB(255, 55, 95),
    },
    Ocean = {
        Accent = Color3.fromRGB(100, 210, 255),
        AccentText = Color3.fromRGB(10, 20, 30),
        Toggle = Color3.fromRGB(100, 210, 255),
    },
    Midnight = {
        Window = Color3.fromRGB(12, 12, 16),
        Sidebar = Color3.fromRGB(8, 8, 12),
        Card = Color3.fromRGB(24, 24, 30),
        CardHover = Color3.fromRGB(36, 36, 44),
        Element = Color3.fromRGB(40, 40, 50),
        Separator = Color3.fromRGB(34, 34, 42),
        Stroke = Color3.fromRGB(48, 48, 58),
        Text = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(140, 140, 150),
        Accent = Color3.fromRGB(94, 92, 230),
        AccentText = Color3.fromRGB(255, 255, 255),
        Success = Color3.fromRGB(48, 209, 88),
        Warning = Color3.fromRGB(255, 159, 10),
        Error = Color3.fromRGB(255, 69, 58),
        Toggle = Color3.fromRGB(94, 92, 230),
        ToggleOff = Color3.fromRGB(44, 44, 54),
        Knob = Color3.fromRGB(255, 255, 255),
    },
}

local Theme = {}
BPUI.Theme = Theme
BPUI.ThemeName = "Dark"

local ThemeBindings = {}   -- { instance, property, themeKey }
local ThemeListeners = {}  -- { fn, owner } called after a theme change; pruned when owner is destroyed

local function Bind(instance, property, key)
    pcall(function()
        instance[property] = Theme[key]
    end)
    ThemeBindings[#ThemeBindings + 1] = { instance, property, key }
    return instance
end

local function OnThemeChanged(fn, owner)
    ThemeListeners[#ThemeListeners + 1] = { fn, owner }
end

local function RefreshTheme(onlyKey)
    for i = #ThemeBindings, 1, -1 do
        local binding = ThemeBindings[i]
        if onlyKey == nil or binding[3] == onlyKey then
            local inst = binding[1]
            local alive = false
            pcall(function()
                alive = inst.Parent ~= nil
            end)
            if not alive then
                table.remove(ThemeBindings, i)
            else
                pcall(function()
                    inst[binding[2]] = Theme[binding[3]]
                end)
            end
        end
    end
    for i = #ThemeListeners, 1, -1 do
        local entry = ThemeListeners[i]
        local owner = entry[2]
        if type(owner) == "table" and owner._destroyed then
            table.remove(ThemeListeners, i)
        else
            pcall(entry[1])
        end
    end
end

function BPUI:SetTheme(themeOrName)
    local source
    if type(themeOrName) == "table" then
        source = themeOrName
        self.ThemeName = "Custom"
    else
        source = self.Themes[tostring(themeOrName)]
        if not source then
            return false
        end
        self.ThemeName = tostring(themeOrName)
    end
    for key, value in pairs(self.Themes.Dark) do
        Theme[key] = value
    end
    for key, value in pairs(source) do
        Theme[key] = value
    end
    RefreshTheme()
    return true
end

function BPUI:SetAccent(color)
    if typeof(color) ~= "Color3" then
        return
    end
    Theme.Accent = color
    RefreshTheme("Accent")
end

-- initialise with Dark before anything is built
for key, value in pairs(BPUI.Themes.Dark) do
    Theme[key] = value
end

---------------------------------------------------------------------
-- Generic helpers
---------------------------------------------------------------------
local FONT = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function Create(className, props, children)
    local inst = Instance.new(className)
    pcall(function()
        inst.BorderSizePixel = 0
    end)
    if className == "TextButton" or className == "ImageButton" then
        pcall(function()
            inst.AutoButtonColor = false
        end)
    end
    if props then
        for key, value in pairs(props) do
            if key ~= "Parent" then
                pcall(function()
                    inst[key] = value
                end)
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function Stroke(parent, themeKey, thickness, transparency)
    local stroke = Create("UIStroke", {
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    if themeKey then
        Bind(stroke, "Color", themeKey)
    end
    return stroke
end

local function Padding(parent, top, right, bottom, left)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = parent,
    })
end

local function ListLayout(parent, padding, horizontal)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function Tween(instance, props, duration, style, direction)
    local ok, tween = pcall(function()
        local info = TweenInfo.new(
            duration or 0.2,
            style or Enum.EasingStyle.Quart,
            direction or Enum.EasingDirection.Out
        )
        local t = TweenService:Create(instance, info, props)
        t:Play()
        return t
    end)
    if not ok then
        for key, value in pairs(props) do
            pcall(function()
                instance[key] = value
            end)
        end
        return nil
    end
    return tween
end

local function Connect(store, signal, fn)
    local ok, connection = pcall(function()
        return signal:Connect(fn)
    end)
    if ok and connection then
        store[#store + 1] = connection
        return connection
    end
    return nil
end

local function DisconnectAll(store)
    for i = #store, 1, -1 do
        pcall(function()
            store[i]:Disconnect()
        end)
        store[i] = nil
    end
end

local function Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

local function Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

local function FormatNumber(value, decimals)
    if math.floor(value) == value then
        return tostring(math.floor(value))
    end
    local text = string.format("%." .. tostring(math.max(decimals or 2, 1)) .. "f", value)
    text = text:gsub("0+$", ""):gsub("%.$", "")
    return text
end

local function ToHex(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function FromHex(text)
    if type(text) ~= "string" then
        return nil
    end
    text = text:gsub("#", ""):gsub("%s", "")
    if #text == 3 then
        text = text:sub(1, 1):rep(2) .. text:sub(2, 2):rep(2) .. text:sub(3, 3):rep(2)
    end
    if #text ~= 6 then
        return nil
    end
    local r = tonumber(text:sub(1, 2), 16)
    local g = tonumber(text:sub(3, 4), 16)
    local b = tonumber(text:sub(5, 6), 16)
    if not (r and g and b) then
        return nil
    end
    return Color3.fromRGB(r, g, b)
end

local function ToColor3(value)
    if typeof(value) == "Color3" then
        return value
    elseif type(value) == "table" then
        local r = value.R or value.r or value[1] or 255
        local g = value.G or value.g or value[2] or 255
        local b = value.B or value.b or value[3] or 255
        if r <= 1 and g <= 1 and b <= 1 and (value.R or value.r or value[1]) then
            -- ambiguous; treat as 0-255 unless explicitly floats with a decimal part
            if r % 1 ~= 0 or g % 1 ~= 0 or b % 1 ~= 0 then
                return Color3.new(r, g, b)
            end
        end
        return Color3.fromRGB(r, g, b)
    elseif type(value) == "string" then
        return FromHex(value)
    end
    return nil
end

local function RGBToHSV(color)
    local r, g, b = color.R, color.G, color.B
    local maxC = math.max(r, g, b)
    local minC = math.min(r, g, b)
    local delta = maxC - minC
    local h = 0
    if delta > 0 then
        if maxC == r then
            h = ((g - b) / delta) % 6
        elseif maxC == g then
            h = (b - r) / delta + 2
        else
            h = (r - g) / delta + 4
        end
        h = h / 6
        if h < 0 then
            h = h + 1
        end
    end
    local s = 0
    if maxC > 0 then
        s = delta / maxC
    end
    return h, s, maxC
end

local function ToKeyCode(value)
    if typeof(value) == "EnumItem" then
        local isKeyCode = false
        pcall(function()
            isKeyCode = tostring(value.EnumType) == "KeyCode"
        end)
        if isKeyCode then
            return value
        end
        return nil
    elseif type(value) == "string" then
        local ok, key = pcall(function()
            return Enum.KeyCode[value]
        end)
        if ok and key then
            return key
        end
    end
    return nil
end

local function PrettyKeyName(name)
    if not name or name == "" or name == "Unknown" then
        return "None"
    end
    if name == "MouseButton2" then
        return "Mouse 2"
    elseif name == "MouseButton3" then
        return "Mouse 3"
    end
    local pretty = name:gsub("(%l)(%u)", "%1 %2")
    return pretty
end

local function SanitizeName(text)
    text = tostring(text or "BPUI")
    text = text:gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        text = "BPUI"
    end
    return text
end

local function IsClickInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMoveInput(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function TextBoxFocused()
    local focused = nil
    pcall(function()
        focused = UserInputService:GetFocusedTextBox()
    end)
    return focused ~= nil
end

local function SafeCall(label, fn, ...)
    if type(fn) ~= "function" then
        return
    end
    local args = { ... }
    local count = select("#", ...)
    task.spawn(function()
        local ok, err = pcall(fn, table.unpack(args, 1, count))
        if not ok then
            warn("[BPUI] " .. tostring(label) .. " callback error: " .. tostring(err))
        end
    end)
end

---------------------------------------------------------------------
-- Vector glyphs (drawn with frames: no image assets, no fonts needed)
---------------------------------------------------------------------
local function GlyphBar(parent, width, height, rotation, themeKey)
    local bar = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(width, height),
        Rotation = rotation or 0,
        BackgroundColor3 = Theme[themeKey or "Text"],
        Parent = parent,
    })
    Corner(bar, math.floor(math.min(width, height) / 2))
    Bind(bar, "BackgroundColor3", themeKey or "Text")
    return bar
end

local function GlyphClose(parent, size, thickness, themeKey)
    local holder = Create("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    GlyphBar(holder, thickness, size, 45, themeKey)
    GlyphBar(holder, thickness, size, -45, themeKey)
    return holder
end

local function GlyphMinus(parent, size, thickness, themeKey)
    local holder = Create("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    GlyphBar(holder, size, thickness, 0, themeKey)
    return holder
end

local function GlyphChevron(parent, size, thickness, themeKey)
    -- a "v" shape; rotate the holder 180 to point up
    local holder = Create("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local armLength = math.floor(size * 0.62)
    local offset = math.floor(size * 0.2)
    local left = GlyphBar(holder, thickness, armLength, -45, themeKey)
    left.Position = UDim2.new(0.5, -offset, 0.5, 0)
    local right = GlyphBar(holder, thickness, armLength, 45, themeKey)
    right.Position = UDim2.new(0.5, offset, 0.5, 0)
    return holder
end

local function GlyphCheck(parent, size, thickness, themeKey)
    local holder = Create("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    local short = GlyphBar(holder, thickness, math.floor(size * 0.45), -45, themeKey)
    short.Position = UDim2.new(0.5, -math.floor(size * 0.22), 0.5, math.floor(size * 0.12))
    local long = GlyphBar(holder, thickness, math.floor(size * 0.8), 45, themeKey)
    long.Position = UDim2.new(0.5, math.floor(size * 0.12), 0.5, -math.floor(size * 0.02))
    return holder
end

---------------------------------------------------------------------
-- Dragging (mouse + touch) with screen clamping
---------------------------------------------------------------------
local function ClampToScreen(target, gui, margin)
    local ok = pcall(function()
        local screen = gui.AbsoluteSize
        if screen.X <= 0 or screen.Y <= 0 then
            return
        end
        local size = target.AbsoluteSize
        local pos = target.AbsolutePosition
        margin = margin or 40
        local minX = -(size.X - margin)
        local maxX = screen.X - margin
        local minY = 0
        local maxY = screen.Y - margin
        local newX = Clamp(pos.X, minX, maxX)
        local newY = Clamp(pos.Y, minY, maxY)
        if newX ~= pos.X or newY ~= pos.Y then
            local anchor = target.AnchorPoint
            target.Position = UDim2.fromOffset(
                math.floor(newX + anchor.X * size.X),
                math.floor(newY + anchor.Y * size.Y)
            )
        end
    end)
    return ok
end

local function MakeDraggable(store, handle, target, gui, onTap, fullyInside)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startAbs = nil
    local moved = false

    Connect(store, handle.InputBegan, function(input)
        if not IsClickInput(input) then
            return
        end
        dragging = true
        moved = false
        dragStart = input.Position
        startAbs = target.AbsolutePosition

        local changed
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                pcall(function()
                    changed:Disconnect()
                end)
                if not moved and onTap then
                    onTap()
                end
            end
        end)
    end)

    Connect(store, handle.InputChanged, function(input)
        if IsMoveInput(input) then
            dragInput = input
        end
    end)

    -- belt and braces: some GUI containers swallow the InputObject.Changed "End" transition
    Connect(store, UserInputService.InputEnded, function(input)
        if dragging and IsClickInput(input) then
            dragging = false
        end
    end)

    Connect(store, UserInputService.InputChanged, function(input)
        if not dragging or input ~= dragInput then
            return
        end
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            moved = true
        end
        if not moved then
            return
        end

        local size = target.AbsoluteSize
        local screen = gui.AbsoluteSize
        local newX = startAbs.X + delta.X
        local newY = startAbs.Y + delta.Y
        if fullyInside then
            newX = Clamp(newX, 0, math.max(0, screen.X - size.X))
            newY = Clamp(newY, 0, math.max(0, screen.Y - size.Y))
        else
            newX = Clamp(newX, -(size.X - 60), screen.X - 60)
            newY = Clamp(newY, 0, screen.Y - 40)
        end
        local anchor = target.AnchorPoint
        target.Position = UDim2.fromOffset(
            math.floor(newX + anchor.X * size.X),
            math.floor(newY + anchor.Y * size.Y)
        )
    end)
end

-- while a slider / colour square is being dragged on touch screens the page
-- must not scroll, so every ScrollingFrame above the hitbox is paused
local function SetAncestorScrolling(instance, enabled)
    pcall(function()
        local current = instance.Parent
        while current do
            if current:IsA("ScrollingFrame") then
                current.ScrollingEnabled = enabled
            end
            current = current.Parent
        end
    end)
end

-- generic press-and-drag helper used by sliders and the colour picker
local function MakeSlidable(store, hitbox, onChange)
    local sliding = false

    Connect(store, hitbox.InputBegan, function(input)
        if IsClickInput(input) then
            sliding = true
            SetAncestorScrolling(hitbox, false)
            onChange(input.Position)
        end
    end)

    Connect(store, UserInputService.InputChanged, function(input)
        if sliding and IsMoveInput(input) then
            onChange(input.Position)
        end
    end)

    Connect(store, UserInputService.InputEnded, function(input)
        if sliding and IsClickInput(input) then
            sliding = false
            SetAncestorScrolling(hitbox, true)
        end
    end)
end

---------------------------------------------------------------------
-- Shared registry: lets a re-executed script clean up its old window
---------------------------------------------------------------------
local function GetSharedRegistry()
    local env = nil
    pcall(function()
        env = getgenv()
    end)
    if type(env) ~= "table" then
        env = _G
    end
    if type(env) ~= "table" then
        return {}
    end
    if type(env.__BPUI_REGISTRY) ~= "table" then
        env.__BPUI_REGISTRY = {}
    end
    return env.__BPUI_REGISTRY
end

---------------------------------------------------------------------
-- ScreenGui management
---------------------------------------------------------------------
function BPUI:_EnsureGui()
    local alive = false
    pcall(function()
        alive = self._gui ~= nil and self._gui.Parent ~= nil
    end)
    if alive then
        return self._gui
    end

    local parent = GetGuiParent()
    local gui = Create("ScreenGui", {
        Name = "BPUI",
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        DisplayOrder = 999,
    })
    pcall(function()
        gui.Parent = parent
    end)
    self._gui = gui
    return gui
end

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
local notifyOrder = 0
local activeToasts = {}
local MAX_TOASTS = 5

function BPUI:_NotifyHolder()
    local alive = false
    pcall(function()
        alive = self._notifyHolder ~= nil and self._notifyHolder.Parent ~= nil
    end)
    if alive then
        return self._notifyHolder
    end

    local gui = self:_EnsureGui()
    local holder
    if IsMobile then
        holder = Create("Frame", {
            Name = "Notifications",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 12),
            Size = UDim2.new(0, 300, 1, -24),
            BackgroundTransparency = 1,
            Parent = gui,
        })
    else
        holder = Create("Frame", {
            Name = "Notifications",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.new(0, 320, 1, -32),
            BackgroundTransparency = 1,
            Parent = gui,
        })
    end
    local layout = ListLayout(holder, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    self._notifyHolder = holder
    return holder
end

function BPUI:Notify(config)
    config = config or {}
    if type(config) == "string" then
        config = { Content = config }
    end

    local holder = self:_NotifyHolder()
    local title = tostring(config.Title or "Notification")
    local content = tostring(config.Content or config.Description or config.Text or "")
    local duration = tonumber(config.Duration) or 4
    local ntype = tostring(config.Type or "Info")
    local accentKey = ({ Info = "Accent", Success = "Success", Warning = "Warning", Error = "Error" })[ntype] or "Accent"

    notifyOrder = notifyOrder + 1

    local wrapper = Create("Frame", {
        Name = "Toast",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
        LayoutOrder = notifyOrder,
        Parent = holder,
    })

    local card = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Position = IsMobile and UDim2.new(0, 0, 0, -90) or UDim2.new(0, 360, 0, 0),
        Size = UDim2.new(1, 0, 0, 60),
        ClipsDescendants = true,
        Parent = wrapper,
    })
    Corner(card, 14)
    Bind(card, "BackgroundColor3", "Card")
    Stroke(card, "Stroke", 1, 0.5)
    Padding(card, 12, 14, 14, 20)

    local bar = Create("Frame", {
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, -12, 0, 2),
        Size = UDim2.new(0, 4, 1, -4),
        BackgroundColor3 = Theme[accentKey],
        Parent = card,
    })
    Corner(bar, 2)
    Bind(bar, "BackgroundColor3", accentKey)

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 18),
        Font = FONT_BOLD,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = title,
        Parent = card,
    })
    Bind(titleLabel, "TextColor3", "Text")

    local contentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, -8, 0, 16),
        Font = FONT,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = content,
        Visible = content ~= "",
        Parent = card,
    })
    Bind(contentLabel, "TextColor3", "SubText")

    local closeHolder = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 4, 0, 2),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Parent = card,
    })
    local closeGlyph = GlyphClose(closeHolder, 10, 2, "SubText")
    closeGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    closeGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)

    local progress = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, -6, 1, 14),
        Size = UDim2.new(1, 6, 0, 2),
        BackgroundColor3 = Theme[accentKey],
        BackgroundTransparency = 0.3,
        Parent = card,
    })
    Corner(progress, 1)
    Bind(progress, "BackgroundColor3", accentKey)

    -- explicit height (no AutomaticSize) so the hit area and progress bar are exact
    local function LayoutToast()
        pcall(function()
            local contentHeight = 0
            if contentLabel.Visible then
                contentHeight = math.max(contentLabel.TextBounds.Y, 14) + 2
                contentLabel.Size = UDim2.new(1, -8, 0, contentHeight - 2)
            end
            local total = 12 + 18 + contentHeight + 14
            card.Size = UDim2.new(1, 0, 0, total)
            wrapper.Size = UDim2.new(1, 0, 0, total)
        end)
    end
    pcall(function()
        contentLabel:GetPropertyChangedSignal("TextBounds"):Connect(LayoutToast)
    end)
    LayoutToast()

    local hit = Create("TextButton", {
        BackgroundTransparency = 1,
        Text = "",
        Position = UDim2.new(0, -20, 0, -12),
        Size = UDim2.new(1, 34, 1, 26),
        ZIndex = 5,
        Parent = card,
    })

    local dismissed = false
    local toast = {}
    local function Dismiss()
        if dismissed then
            return
        end
        dismissed = true
        for i = #activeToasts, 1, -1 do
            if activeToasts[i] == toast then
                table.remove(activeToasts, i)
            end
        end
        Tween(card, {
            Position = IsMobile and UDim2.new(0, 0, 0, -90) or UDim2.new(0, 360, 0, 0),
        }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.28, function()
            pcall(function()
                wrapper:Destroy()
            end)
        end)
    end
    toast.Dismiss = Dismiss
    toast.Instance = wrapper
    activeToasts[#activeToasts + 1] = toast
    while #activeToasts > MAX_TOASTS do
        local oldest = activeToasts[1]
        if oldest and oldest.Dismiss then
            oldest.Dismiss()
        else
            table.remove(activeToasts, 1)
        end
    end

    pcall(function()
        hit.Activated:Connect(Dismiss)
    end)

    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, Dismiss)

    function toast.SetContent(_, newContent)
        contentLabel.Text = tostring(newContent or "")
        contentLabel.Visible = contentLabel.Text ~= ""
    end
    function toast.SetTitle(_, newTitle)
        titleLabel.Text = tostring(newTitle or "")
    end

    return toast
end

---------------------------------------------------------------------
-- Key system (no HTTP: keys list and/or your own Validate function)
---------------------------------------------------------------------
function BPUI:_RunKeySystem(window, ks)
    local gui = self:_EnsureGui()
    local keyFile = window._folderPath .. "/key.txt"
    local caseSensitive = ks.CaseSensitive == true

    local function Validate(key)
        key = tostring(key or "")
        key = key:gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            return false
        end
        if type(ks.Validate) == "function" then
            local ok, result = pcall(ks.Validate, key)
            if ok and result == true then
                return true
            end
        end
        local keys = ks.Keys or {}
        if ks.Key then
            keys = { ks.Key }
        end
        for _, candidate in ipairs(keys) do
            candidate = tostring(candidate)
            if caseSensitive then
                if candidate == key then
                    return true
                end
            else
                if candidate:lower() == key:lower() then
                    return true
                end
            end
        end
        return false
    end

    -- saved key shortcut
    if ks.SaveKey ~= false and FS.Available then
        local saved = FS.Read(keyFile)
        if saved and Validate(saved) then
            return true
        end
    end

    local done = false
    local store = {}

    local frame = Create("Frame", {
        Name = "KeySystem",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(380, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Window,
        Active = true,
        Parent = gui,
    })
    -- let Window:Destroy() clean the prompt up if the script is re-executed meanwhile
    window._keyFrame = frame
    window._keyStore = store
    Corner(frame, 18)
    Bind(frame, "BackgroundColor3", "Window")
    Stroke(frame, "Stroke", 1, 0.4)
    Padding(frame, 22, 22, 22, 22)
    local scale = Create("UIScale", { Scale = 0.9, Parent = frame })
    local fittedScale = 1

    local function Fit(animate)
        pcall(function()
            local screen = gui.AbsoluteSize
            if screen.X <= 0 then
                return
            end
            local s = math.min(1, (screen.X - 24) / 380, (screen.Y - 24) / 330)
            fittedScale = math.max(0.55, s)
            if animate then
                scale.Scale = fittedScale * 0.9
                Tween(scale, { Scale = fittedScale }, 0.3, Enum.EasingStyle.Back)
            else
                scale.Scale = fittedScale
            end
        end)
    end

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = FONT_BOLD,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(ks.Title or (window.Title .. " | Key System")),
        Active = true,
        Parent = frame,
    })
    Bind(titleLabel, "TextColor3", "Text")

    local subtitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 18),
        Font = FONT,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(ks.Subtitle or "Enter your key to continue"),
        Parent = frame,
    })
    Bind(subtitleLabel, "TextColor3", "SubText")

    local noteLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(ks.Note or ""),
        Visible = ks.Note ~= nil and ks.Note ~= "",
        Parent = frame,
    })
    Bind(noteLabel, "TextColor3", "SubText")

    local body = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(1, 0, 0, 96),
        Parent = frame,
    })

    local function LayoutBody()
        local noteHeight = 0
        if noteLabel.Visible then
            noteHeight = noteLabel.TextBounds.Y + 12
        end
        body.Position = UDim2.new(0, 0, 0, 52 + noteHeight)
    end
    Connect(store, noteLabel:GetPropertyChangedSignal("TextBounds"), LayoutBody)
    LayoutBody()

    local inputHolder = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Element,
        Parent = body,
    })
    Corner(inputHolder, 10)
    Bind(inputHolder, "BackgroundColor3", "Element")
    local inputStroke = Stroke(inputHolder, "Stroke", 1, 0.6)

    local input = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = tostring(ks.Placeholder or "Enter key..."),
        Text = "",
        ClearTextOnFocus = false,
        Parent = inputHolder,
    })
    Bind(input, "TextColor3", "Text")
    Bind(input, "PlaceholderColor3", "SubText")

    local verify = Create("TextButton", {
        Position = UDim2.new(0, 0, 0, 52),
        Size = UDim2.new(0.5, -5, 0, 40),
        BackgroundColor3 = Theme.Accent,
        Font = FONT_BOLD,
        TextSize = 14,
        Text = tostring(ks.VerifyText or "Verify"),
        Parent = body,
    })
    Corner(verify, 10)
    Bind(verify, "BackgroundColor3", "Accent")
    Bind(verify, "TextColor3", "AccentText")

    local getKey = Create("TextButton", {
        Position = UDim2.new(0.5, 5, 0, 52),
        Size = UDim2.new(0.5, -5, 0, 40),
        BackgroundColor3 = Theme.Element,
        Font = FONT_MEDIUM,
        TextSize = 14,
        Text = tostring(ks.GetKeyText or "Get Key"),
        Visible = ks.GetKeyLink ~= nil or type(ks.OnGetKey) == "function",
        Parent = body,
    })
    Corner(getKey, 10)
    Bind(getKey, "BackgroundColor3", "Element")
    Bind(getKey, "TextColor3", "Text")
    if not getKey.Visible then
        verify.Size = UDim2.new(1, 0, 0, 40)
    end

    local attempts = 0

    local function Shake()
        local origin = frame.Position
        Tween(frame, { Position = origin + UDim2.fromOffset(10, 0) }, 0.05)
        task.delay(0.05, function()
            Tween(frame, { Position = origin - UDim2.fromOffset(10, 0) }, 0.05)
        end)
        task.delay(0.1, function()
            Tween(frame, { Position = origin + UDim2.fromOffset(6, 0) }, 0.05)
        end)
        task.delay(0.15, function()
            Tween(frame, { Position = origin }, 0.05)
        end)
        inputStroke.Color = Theme.Error
        inputStroke.Transparency = 0
        task.delay(0.6, function()
            pcall(function()
                inputStroke.Color = Theme.Stroke
                inputStroke.Transparency = 0.6
            end)
        end)
    end

    local function Finish()
        done = true
        DisconnectAll(store)
        Tween(scale, { Scale = 0.9 }, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.2, function()
            pcall(function()
                frame:Destroy()
            end)
        end)
    end

    local function Attempt()
        local key = input.Text
        if Validate(key) then
            if ks.SaveKey ~= false and FS.Available then
                FS.EnsureFolder(window._rootPath)
                FS.EnsureFolder(window._folderPath)
                FS.Write(keyFile, key)
            end
            self:Notify({ Title = "Key System", Content = tostring(ks.SuccessMessage or "Key accepted. Welcome!"), Type = "Success", Duration = 3 })
            Finish()
        else
            attempts = attempts + 1
            Shake()
            self:Notify({ Title = "Key System", Content = tostring(ks.FailMessage or "Invalid key, please try again."), Type = "Error", Duration = 3 })
            if ks.MaxAttempts and attempts >= ks.MaxAttempts then
                task.delay(0.5, function()
                    pcall(function()
                        frame:Destroy()
                    end)
                    DisconnectAll(store)
                    done = "failed"
                end)
            end
        end
    end

    Connect(store, verify.Activated, Attempt)
    Connect(store, input.FocusLost, function(enterPressed)
        if enterPressed then
            Attempt()
        end
    end)
    Connect(store, input.Focused, function()
        inputStroke.Color = Theme.Accent
        inputStroke.Transparency = 0
    end)
    Connect(store, getKey.Activated, function()
        if type(ks.OnGetKey) == "function" then
            SafeCall("KeySystem.OnGetKey", ks.OnGetKey)
        end
        if ks.GetKeyLink then
            if CopyToClipboard(tostring(ks.GetKeyLink)) then
                self:Notify({ Title = "Key System", Content = "Link copied to your clipboard.", Type = "Success", Duration = 3 })
            else
                self:Notify({ Title = "Get Key", Content = tostring(ks.GetKeyLink), Type = "Info", Duration = 8 })
            end
        end
    end)
    Connect(store, gui:GetPropertyChangedSignal("AbsoluteSize"), function()
        Fit(false)
    end)

    -- title/subtitle area acts as a drag handle
    MakeDraggable(store, titleLabel, frame, gui, nil, false)

    Fit(true)

    while not done and not window._destroyed do
        task.wait(0.1)
    end
    window._keyFrame = nil
    window._keyStore = nil
    if window._destroyed then
        DisconnectAll(store)
        pcall(function()
            frame:Destroy()
        end)
        return false
    end
    return done == true
end

---------------------------------------------------------------------
-- Classes
---------------------------------------------------------------------
local WindowClass = {}
WindowClass.__index = WindowClass

local TabClass = {}
TabClass.__index = TabClass

local SectionClass = {}
SectionClass.__index = SectionClass

local SIDEBAR_WIDTH = 176
local TOPBAR_HEIGHT = 56
local ROW_HEIGHT = 44
local ROW_HEIGHT_DESC = 58

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------
function BPUI:CreateWindow(config)
    config = config or {}
    if type(config) == "string" then
        config = { Title = config }
    end

    local title = tostring(config.Title or config.Name or "BPUI")
    local subtitle = tostring(config.Subtitle or "")
    local width, height = 640, 440
    if IsMobile then
        -- smaller base size keeps text close to 1:1 on phones instead of shrinking everything
        width, height = 560, 350
    end
    if typeof(config.Size) == "UDim2" then
        width = config.Size.X.Offset
        height = config.Size.Y.Offset
    elseif typeof(config.Size) == "Vector2" then
        width = config.Size.X
        height = config.Size.Y
    elseif type(config.Size) == "table" then
        width = tonumber(config.Size[1] or config.Size.Width) or width
        height = tonumber(config.Size[2] or config.Size.Height) or height
    end
    width = math.max(420, width)
    height = math.max(300, height)
    local sizeGiven = config.Size ~= nil
    local sidebarWidth = IsMobile and 150 or SIDEBAR_WIDTH
    if tonumber(config.SidebarWidth) then
        sidebarWidth = math.max(110, tonumber(config.SidebarWidth))
    end

    local Window = setmetatable({
        Title = title,
        Subtitle = subtitle,
        Tabs = {},
        Elements = {},
        Visible = true,
        Minimized = false,
        Width = width,
        Height = height,
        SidebarWidth = sidebarWidth,
        SearchQuery = "",
        ConfigFolder = SanitizeName(config.ConfigFolder or config.ConfigurationFolder or config.Folder or title),
        ToggleKey = ToKeyCode(config.ToggleKey or config.Keybind) or Enum.KeyCode.RightShift,
        CloseBehavior = config.CloseBehavior or "Destroy",
        _conns = {},
        _pending = nil,
        _order = 0,
        _destroyed = false,
    }, WindowClass)

    Window._rootPath = "BPUI"
    Window._folderPath = "BPUI/" .. Window.ConfigFolder
    Window._configPath = Window._folderPath .. "/configs"

    -- persisted interface settings (theme, accent, toggle key)
    local settings = Window:_LoadSettings()
    local themeName = config.Theme or settings.Theme or "Dark"
    if not self:SetTheme(themeName) then
        self:SetTheme("Dark")
    end
    if config.Accent and typeof(config.Accent) == "Color3" then
        Theme.Accent = config.Accent
    elseif settings.Accent and not config.Accent then
        local c = ToColor3(settings.Accent)
        if c then
            Theme.Accent = c
        end
    end
    if settings.ToggleKey and not config.ToggleKey then
        Window.ToggleKey = ToKeyCode(settings.ToggleKey) or Window.ToggleKey
    end
    if not sizeGiven and config.RememberSize ~= false and tonumber(settings.Width) and tonumber(settings.Height) then
        Window.Width = math.max(420, math.floor(settings.Width))
        Window.Height = math.max(300, math.floor(settings.Height))
        width, height = Window.Width, Window.Height
    end
    RefreshTheme()

    -- ScreenGui
    local gui = self:_EnsureGui()
    Window.Gui = gui

    -- remove an older copy of the same window (re-executing the script),
    -- including one created by a previous load of the library
    for i = #self.Windows, 1, -1 do
        local other = self.Windows[i]
        if other and other.Title == title and not other._destroyed then
            pcall(function()
                other:Destroy()
            end)
        end
    end
    local registry = GetSharedRegistry()
    local previous = registry[title]
    if type(previous) == "table" and type(previous.Destroy) == "function" then
        pcall(function()
            previous:Destroy()
        end)
    end
    registry[title] = Window

    local store = Window._conns

    -----------------------------------------------------------------
    -- Main frame
    -----------------------------------------------------------------
    local Main = Create("Frame", {
        Name = "Window_" .. title,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = Theme.Window,
        ClipsDescendants = true,
        Active = true, -- sinks input so clicks/touches never reach the game world
        Visible = false,
        Parent = gui,
    })
    Corner(Main, 18)
    Bind(Main, "BackgroundColor3", "Window")
    Stroke(Main, "Stroke", 1, 0.35)
    local Scale = Create("UIScale", { Scale = 1, Parent = Main })
    Window.Main = Main
    Window.Scale = Scale
    Window._baseScale = 1

    -----------------------------------------------------------------
    -- Sidebar
    -----------------------------------------------------------------
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        BackgroundColor3 = Theme.Sidebar,
        Parent = Main,
    })
    Bind(Sidebar, "BackgroundColor3", "Sidebar")

    local SidebarDivider = Create("Frame", {
        Position = UDim2.new(0, sidebarWidth, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.Separator,
        Parent = Main,
    })
    Bind(SidebarDivider, "BackgroundColor3", "Separator")

    local SidebarHeader = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        Active = true,
        Parent = Sidebar,
    })

    local iconOffset = 0
    if config.Icon then
        local iconId = config.Icon
        if type(iconId) == "number" then
            iconId = "rbxassetid://" .. tostring(iconId)
        end
        Create("ImageLabel", {
            Position = UDim2.new(0, 16, 0, 20),
            Size = UDim2.fromOffset(30, 30),
            BackgroundTransparency = 1,
            Image = tostring(iconId),
            ScaleType = Enum.ScaleType.Fit,
            Parent = SidebarHeader,
        })
        iconOffset = 38
    end

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16 + iconOffset, 0, subtitle ~= "" and 18 or 26),
        Size = UDim2.new(1, -24 - iconOffset, 0, 20),
        Font = FONT_BOLD,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = title,
        Parent = SidebarHeader,
    })
    Bind(TitleLabel, "TextColor3", "Text")

    local SubtitleLabel = Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16 + iconOffset, 0, 38),
        Size = UDim2.new(1, -24 - iconOffset, 0, 16),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = subtitle,
        Visible = subtitle ~= "",
        Parent = SidebarHeader,
    })
    Bind(SubtitleLabel, "TextColor3", "SubText")
    Window.TitleLabel = TitleLabel
    Window.SubtitleLabel = SubtitleLabel

    local TabList = Create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.new(0, 0, 0, 72),
        Size = UDim2.new(1, 0, 1, -72 - 30),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.SubText,
        ScrollBarImageTransparency = 0.6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Sidebar,
    })
    Bind(TabList, "ScrollBarImageColor3", "SubText")
    Padding(TabList, 4, 10, 10, 10)
    ListLayout(TabList, 4)
    Window.TabList = TabList

    local Footer = Create("TextLabel", {
        Name = "Footer",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -10),
        Size = UDim2.new(1, -32, 0, 14),
        BackgroundTransparency = 1,
        Font = FONT,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(config.Footer or ("BPUI v" .. BPUI.Version)),
        Parent = Sidebar,
    })
    Bind(Footer, "TextColor3", "SubText")

    -----------------------------------------------------------------
    -- Content
    -----------------------------------------------------------------
    local Content = Create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, sidebarWidth + 1, 0, 0),
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, 0),
        BackgroundTransparency = 1,
        Parent = Main,
    })
    Window.Content = Content

    local TopBar = Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        BackgroundTransparency = 1,
        Active = true,
        Parent = Content,
    })

    local searchWidth = IsMobile and 120 or 160
    local buttonsWidth = 18 + 28 + 8 + 28 + 12 -- close + minimise + gaps

    local TabTitle = Create("TextLabel", {
        Name = "TabTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -(22 + buttonsWidth + searchWidth + 10), 1, 0),
        Font = FONT_BOLD,
        TextSize = 21,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
        Parent = TopBar,
    })
    Bind(TabTitle, "TextColor3", "Text")
    Window.TabTitle = TabTitle

    -- search field (iOS style pill)
    local SearchBox = Create("Frame", {
        Name = "Search",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -buttonsWidth, 0.5, 0),
        Size = UDim2.fromOffset(searchWidth, 30),
        BackgroundColor3 = Theme.Element,
        ClipsDescendants = true,
        Visible = config.Search ~= false,
        Parent = TopBar,
    })
    Corner(SearchBox, 10)
    Bind(SearchBox, "BackgroundColor3", "Element")
    local searchStroke = Stroke(SearchBox, "Stroke", 1, 0.7)

    -- magnifier glyph: ring + handle
    local SearchIcon = Create("Frame", {
        Position = UDim2.new(0, 9, 0.5, -6),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        Parent = SearchBox,
    })
    local ring = Create("Frame", {
        Size = UDim2.fromOffset(9, 9),
        BackgroundTransparency = 1,
        Parent = SearchIcon,
    })
    Corner(ring, 5)
    Stroke(ring, "SubText", 1.6, 0)
    local handle = GlyphBar(SearchIcon, 1.8, 6, -45, "SubText")
    handle.Position = UDim2.new(0, 10, 0, 10)

    local SearchInput = Create("TextBox", {
        Name = "Input",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "Search",
        Text = "",
        ClearTextOnFocus = false,
        Parent = SearchBox,
    })
    Bind(SearchInput, "TextColor3", "Text")
    Bind(SearchInput, "PlaceholderColor3", "SubText")
    Window.SearchInput = SearchInput

    Connect(store, SearchInput.Focused, function()
        searchStroke.Color = Theme.Accent
        searchStroke.Transparency = 0
    end)
    Connect(store, SearchInput.FocusLost, function()
        searchStroke.Color = Theme.Stroke
        searchStroke.Transparency = 0.7
    end)
    Connect(store, SearchInput:GetPropertyChangedSignal("Text"), function()
        Window:Search(SearchInput.Text)
    end)

    local function CircleButton(offsetFromRight)
        local button = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -offsetFromRight, 0.5, 0),
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = Theme.Element,
            Text = "",
            Parent = TopBar,
        })
        Corner(button, 14)
        Bind(button, "BackgroundColor3", "Element")
        return button
    end

    local CloseButton = CircleButton(18)
    local closeGlyph = GlyphClose(CloseButton, 11, 2, "Text")
    closeGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    closeGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)

    local MinButton = CircleButton(18 + 28 + 8)
    local minGlyph = GlyphMinus(MinButton, 11, 2, "Text")
    minGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    minGlyph.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- restore glyph (small square outline) shown while minimised
    local restoreGlyph = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = MinButton,
    })
    Corner(restoreGlyph, 2)
    Stroke(restoreGlyph, "Text", 2, 0)
    Window._minGlyph = minGlyph
    Window._restoreGlyph = restoreGlyph

    if not IsMobile then
        Connect(store, CloseButton.MouseEnter, function()
            Tween(CloseButton, { BackgroundColor3 = Theme.Error }, 0.15)
        end)
        Connect(store, CloseButton.MouseLeave, function()
            Tween(CloseButton, { BackgroundColor3 = Theme.Element }, 0.15)
        end)
        Connect(store, MinButton.MouseEnter, function()
            Tween(MinButton, { BackgroundColor3 = Theme.CardHover }, 0.15)
        end)
        Connect(store, MinButton.MouseLeave, function()
            Tween(MinButton, { BackgroundColor3 = Theme.Element }, 0.15)
        end)
    end

    local Pages = Create("Frame", {
        Name = "Pages",
        Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT),
        Size = UDim2.new(1, 0, 1, -TOPBAR_HEIGHT),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Content,
    })
    Window.Pages = Pages

    -----------------------------------------------------------------
    -- Resize grip (bottom-right, PC only unless Resizable = true)
    -----------------------------------------------------------------
    local resizable = config.Resizable
    if resizable == nil then
        resizable = not IsMobile
    end
    local Grip = Create("Frame", {
        Name = "Resize",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 0, 1, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Active = true,
        Visible = resizable and true or false,
        ZIndex = 5,
        Parent = Main,
    })
    local gripA = GlyphBar(Grip, 1.5, 12, -45, "SubText")
    gripA.Position = UDim2.new(0.5, -1, 0.5, -1)
    gripA.BackgroundTransparency = 0.35
    local gripB = GlyphBar(Grip, 1.5, 6, -45, "SubText")
    gripB.Position = UDim2.new(0.5, 3, 0.5, 3)
    gripB.BackgroundTransparency = 0.35
    Window.ResizeGrip = Grip
    Window._resizable = resizable and true or false

    do
        local resizing = false
        local resizeInput = nil
        local startPos = nil
        local startW, startH = 0, 0
        Connect(store, Grip.InputBegan, function(input)
            if not IsClickInput(input) or Window.Minimized then
                return
            end
            Window:_AnchorTopLeft()
            resizing = true
            startPos = input.Position
            startW, startH = Window.Width, Window.Height
            local changed
            changed = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    pcall(function()
                        changed:Disconnect()
                    end)
                    Window:_SaveSettingsDebounced()
                end
            end)
        end)
        Connect(store, Grip.InputChanged, function(input)
            if IsMoveInput(input) then
                resizeInput = input
            end
        end)
        Connect(store, UserInputService.InputEnded, function(input)
            if resizing and IsClickInput(input) then
                resizing = false
                Window:_SaveSettingsDebounced()
            end
        end)
        Connect(store, UserInputService.InputChanged, function(input)
            if not resizing or input ~= resizeInput then
                return
            end
            local scale = Scale.Scale
            if scale <= 0 then
                scale = 1
            end
            local delta = input.Position - startPos
            Window:SetSize(startW + delta.X / scale, startH + delta.Y / scale, true)
        end)
    end

    -----------------------------------------------------------------
    -- Floating button (mobile by default, optional on PC)
    -----------------------------------------------------------------
    local showFloating = config.FloatingButton
    if showFloating == nil and settings.FloatingButton ~= nil then
        showFloating = settings.FloatingButton == true
    end
    if showFloating == nil then
        showFloating = IsMobile
    end

    local initials = title:sub(1, 2):upper()
    local Float = Create("TextButton", {
        Name = "Float_" .. title,
        Position = UDim2.new(0, 14, 0, 120),
        Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = Theme.Accent,
        Font = FONT_BOLD,
        TextSize = 15,
        Text = tostring(config.FloatingText or initials),
        Visible = showFloating and true or false,
        Parent = gui,
    })
    Corner(Float, 24)
    Bind(Float, "BackgroundColor3", "Accent")
    Bind(Float, "TextColor3", "AccentText")
    local floatStroke = Create("UIStroke", {
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.65,
        Parent = Float,
    })
    if config.Icon then
        local iconId = config.Icon
        if type(iconId) == "number" then
            iconId = "rbxassetid://" .. tostring(iconId)
        end
        Float.Text = ""
        Create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(26, 26),
            BackgroundTransparency = 1,
            Image = tostring(iconId),
            ScaleType = Enum.ScaleType.Fit,
            Parent = Float,
        })
    end
    Window.FloatingButton = Float

    -----------------------------------------------------------------
    -- Behaviour
    -----------------------------------------------------------------
    local function UpdateScale()
        local ok = pcall(function()
            local screen = gui.AbsoluteSize
            if screen.X <= 0 or screen.Y <= 0 then
                return
            end
            local fit = math.min(1, (screen.X - 16) / Window.Width, (screen.Y - 16) / Window.Height)
            fit = math.max(0.5, fit) * (tonumber(config.Scale) or 1)
            Window._baseScale = fit
            if Window.Visible then
                Scale.Scale = fit
            end
            ClampToScreen(Main, gui, 60)
            ClampToScreen(Float, gui, 48)
        end)
        return ok
    end
    Window._UpdateScale = UpdateScale
    UpdateScale()
    Connect(store, gui:GetPropertyChangedSignal("AbsoluteSize"), UpdateScale)

    MakeDraggable(store, TopBar, Main, gui, nil, false)
    MakeDraggable(store, SidebarHeader, Main, gui, nil, false)
    MakeDraggable(store, Float, Float, gui, function()
        Window:Toggle()
    end, true)

    Connect(store, CloseButton.Activated, function()
        if Window.CloseBehavior == "Hide" then
            Window:Hide()
        elseif config.ConfirmClose then
            Window:Dialog({
                Title = "Close " .. title .. "?",
                Content = "The interface will be unloaded.",
                Buttons = {
                    { Text = "Cancel" },
                    { Text = "Close", Style = "Danger", Callback = function()
                        Window:Destroy()
                    end },
                },
            })
        else
            Window:Destroy()
        end
    end)
    Connect(store, MinButton.Activated, function()
        Window:Minimize()
    end)

    Connect(store, UserInputService.InputBegan, function(input)
        if TextBoxFocused() or BPUI._keybindListening then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Window.ToggleKey then
            Window:Toggle()
        end
    end)

    Window.OnDestroy = config.OnDestroy or config.OnUnload
    table.insert(self.Windows, Window)

    -----------------------------------------------------------------
    -- Key system, then reveal
    -----------------------------------------------------------------
    if type(config.KeySystem) == "table" and config.KeySystem.Enabled ~= false then
        local passed = self:_RunKeySystem(Window, config.KeySystem)
        if not passed then
            if Window._destroyed then
                error("[BPUI] Window '" .. title .. "' was replaced by a newer instance before the key was entered", 0)
            end
            Window:Destroy()
            error("[BPUI] Key system failed", 0)
        end
    end

    if config.ShowSettings ~= false then
        Window:_BuildSettingsTab(config)
    end

    Window:Show()

    if config.AutoLoad ~= false then
        task.delay(tonumber(config.AutoLoadDelay) or 1, function()
            if not Window._destroyed then
                Window:LoadAutoConfig()
            end
        end)
    end

    if config.WelcomeNotification ~= false then
        self:Notify({
            Title = title,
            Content = IsMobile and "Tap the floating button to open or close the interface."
                or ("Press " .. PrettyKeyName(Window.ToggleKey.Name) .. " to open or close the interface."),
            Type = "Info",
            Duration = 4,
        })
    end

    return Window
end

function WindowClass:Show()
    if self._destroyed then
        return
    end
    self.Visible = true
    self.Main.Visible = true
    self.Scale.Scale = self._baseScale * 0.94
    Tween(self.Scale, { Scale = self._baseScale }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function WindowClass:Hide()
    if self._destroyed then
        return
    end
    self.Visible = false
    Tween(self.Scale, { Scale = self._baseScale * 0.94 }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.16, function()
        if not self.Visible and not self._destroyed then
            self.Main.Visible = false
        end
    end)
end

function WindowClass:Toggle()
    if self.Visible then
        self:Hide()
    else
        self:Show()
    end
end

function WindowClass:SetVisible(visible)
    if visible then
        self:Show()
    else
        self:Hide()
    end
end

-- switches the window to an offset based top-left anchor without moving it
function WindowClass:_AnchorTopLeft()
    local ok = pcall(function()
        local main = self.Main
        if main.AnchorPoint.X == 0 and main.AnchorPoint.Y == 0 and main.Position.X.Scale == 0 and main.Position.Y.Scale == 0 then
            return
        end
        local guiPos = self.Gui.AbsolutePosition
        local absPos = main.AbsolutePosition
        main.AnchorPoint = Vector2.new(0, 0)
        main.Position = UDim2.fromOffset(math.floor(absPos.X - guiPos.X), math.floor(absPos.Y - guiPos.Y))
    end)
    return ok
end

function WindowClass:SetSize(width, height, silent)
    width = math.max(420, math.floor(tonumber(width) or self.Width))
    height = math.max(300, math.floor(tonumber(height) or self.Height))
    pcall(function()
        local screen = self.Gui.AbsoluteSize
        if screen.X > 0 then
            width = math.min(width, screen.X)
            height = math.min(height, screen.Y)
        end
    end)
    self.Width = width
    self.Height = height
    if not self.Minimized then
        if silent then
            self.Main.Size = UDim2.fromOffset(width, height)
        else
            Tween(self.Main, { Size = UDim2.fromOffset(width, height) }, 0.2)
        end
    end
    if self._UpdateScale then
        self._UpdateScale()
    end
end

function WindowClass:Minimize(state)
    if self._destroyed then
        return
    end
    if state == nil then
        state = not self.Minimized
    end
    state = state and true or false
    if state == self.Minimized then
        return
    end
    self.Minimized = state
    self:_AnchorTopLeft()
    if state then
        self.Main.ClipsDescendants = true
        self.ResizeGrip.Visible = false
        Tween(self.Main, { Size = UDim2.fromOffset(self.Width, TOPBAR_HEIGHT + 4) }, 0.25)
        task.delay(0.25, function()
            if self.Minimized and not self._destroyed then
                self.Pages.Visible = false
            end
        end)
    else
        self.Pages.Visible = true
        self.ResizeGrip.Visible = self._resizable and true or false
        Tween(self.Main, { Size = UDim2.fromOffset(self.Width, self.Height) }, 0.25)
    end
    self._minGlyph.Visible = not state
    self._restoreGlyph.Visible = state
end

-- modal confirmation dialog inside the window
function WindowClass:Dialog(config)
    config = config or {}
    if self._destroyed then
        return nil
    end
    if self._dialog then
        pcall(function()
            self._dialog:Close()
        end)
    end

    local store = self._conns
    local Overlay = Create("Frame", {
        Name = "Dialog",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 50,
        Parent = self.Main,
    })
    Corner(Overlay, 18)
    -- sink every click that is not on a button
    Create("TextButton", {
        Name = "Sink",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 50,
        Parent = Overlay,
    })

    local Card = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(math.min(320, self.Width - 60), 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        ZIndex = 51,
        Parent = Overlay,
    })
    Corner(Card, 16)
    Bind(Card, "BackgroundColor3", "Card")
    Stroke(Card, "Stroke", 1, 0.4)
    Padding(Card, 18, 18, 18, 18)
    local cardScale = Create("UIScale", { Scale = 0.9, Parent = Card })

    local TitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = FONT_BOLD,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(config.Title or "Confirm"),
        ZIndex = 52,
        Parent = Card,
    })
    Bind(TitleLabel, "TextColor3", "Text")

    local ContentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = FONT,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(config.Content or ""),
        ZIndex = 52,
        Parent = Card,
    })
    Bind(ContentLabel, "TextColor3", "SubText")

    local ButtonRow = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 52,
        Parent = Card,
    })
    local rowLayout = ListLayout(ButtonRow, 8, true)
    rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local function LayoutButtons()
        pcall(function()
            local contentHeight = ContentLabel.Text ~= "" and (ContentLabel.TextBounds.Y + 16) or 0
            ButtonRow.Position = UDim2.new(0, 0, 0, 26 + contentHeight + 4)
        end)
    end
    Connect(store, ContentLabel:GetPropertyChangedSignal("TextBounds"), LayoutButtons)
    LayoutButtons()

    local dialog = { Instance = Overlay }
    local closed = false
    function dialog:Close()
        if closed then
            return
        end
        closed = true
        Tween(cardScale, { Scale = 0.9 }, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(Overlay, { BackgroundTransparency = 1 }, 0.15)
        task.delay(0.16, function()
            pcall(function()
                Overlay:Destroy()
            end)
        end)
        if self._dialog == dialog then
            self._dialog = nil
        end
    end
    self._dialog = dialog

    local buttons = config.Buttons or config.Options or {
        { Text = "OK", Style = "Accent" },
    }
    local count = #buttons
    for index, spec in ipairs(buttons) do
        local style = spec.Style or (index == count and "Accent" or "Default")
        local button = Create("TextButton", {
            Size = UDim2.new(1 / count, -(8 * (count - 1)) / count, 1, 0),
            BackgroundColor3 = Theme.Element,
            Font = FONT_BOLD,
            TextSize = 13,
            Text = tostring(spec.Text or spec.Name or "OK"),
            LayoutOrder = index,
            ZIndex = 53,
            Parent = ButtonRow,
        })
        Corner(button, 10)
        if style == "Accent" then
            Bind(button, "BackgroundColor3", "Accent")
            Bind(button, "TextColor3", "AccentText")
        elseif style == "Danger" then
            Bind(button, "BackgroundColor3", "Error")
            Bind(button, "TextColor3", "AccentText")
        else
            Bind(button, "BackgroundColor3", "Element")
            Bind(button, "TextColor3", "Text")
        end
        Connect(store, button.Activated, function()
            dialog:Close()
            SafeCall("Dialog '" .. tostring(spec.Text) .. "'", spec.Callback)
        end)
    end

    Tween(Overlay, { BackgroundTransparency = 0.45 }, 0.2)
    Tween(cardScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
    return dialog
end
WindowClass.Prompt = WindowClass.Dialog

-- filters the rows of the current tab by name / description
function WindowClass:Search(query)
    query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    self.SearchQuery = query
    local sections = {}
    for _, tab in ipairs(self.Tabs) do
        for _, section in ipairs(tab.Sections) do
            sections[#sections + 1] = section
        end
    end
    for _, section in ipairs(sections) do
        local anyVisible = false
        for _, element in ipairs(section.Elements) do
            local hidden = false
            if query ~= "" then
                local haystack = (tostring(element.Name or "") .. " " .. tostring(element.Description or "") .. " " .. tostring(element.Type or "")):lower()
                if element.Type == "Paragraph" then
                    haystack = haystack .. " " .. tostring(element.Value or ""):lower()
                end
                hidden = haystack:find(query, 1, true) == nil
            end
            element._searchHidden = hidden
            element:_ApplyVisibility()
            if element.Row.Visible then
                anyVisible = true
            end
        end
        for _, spacer in ipairs(section.Spacers) do
            spacer.Visible = query == ""
        end
        section.Holder.Visible = section._visible ~= false and (query == "" or anyVisible)
        section:_UpdateSeparators()
    end
end

function WindowClass:SetTitle(text)
    self.Title = tostring(text)
    self.TitleLabel.Text = self.Title
end

function WindowClass:SetSubtitle(text)
    self.Subtitle = tostring(text or "")
    self.SubtitleLabel.Text = self.Subtitle
    self.SubtitleLabel.Visible = self.Subtitle ~= ""
    self.TitleLabel.Position = UDim2.new(self.TitleLabel.Position.X.Scale, self.TitleLabel.Position.X.Offset, 0, self.Subtitle ~= "" and 18 or 26)
end

function WindowClass:SetToggleKey(key)
    local keyCode = ToKeyCode(key)
    if keyCode then
        self.ToggleKey = keyCode
        self:_SaveSettings()
    end
end

function WindowClass:SetFloatingButtonVisible(visible)
    self.FloatingButton.Visible = visible and true or false
end

function WindowClass:Notify(config)
    return BPUI:Notify(config)
end

function WindowClass:SelectTab(tab)
    if type(tab) == "string" then
        for _, candidate in ipairs(self.Tabs) do
            if candidate.Name == tab then
                tab = candidate
                break
            end
        end
    end
    if type(tab) ~= "table" or not tab.Page then
        return
    end
    self.CurrentTab = tab
    self.TabTitle.Text = tab.Name
    for _, other in ipairs(self.Tabs) do
        local selected = other == tab
        other.Page.Visible = selected
        if selected then
            other.Page.Position = UDim2.new(0, 0, 0, 10)
            Tween(other.Page, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)
            Tween(other.Button, { BackgroundTransparency = 0 }, 0.18)
            Tween(other.Label, { TextColor3 = Theme.AccentText }, 0.18)
            if other.Icon then
                Tween(other.Icon, { ImageColor3 = Theme.AccentText }, 0.18)
            end
        else
            Tween(other.Button, { BackgroundTransparency = 1 }, 0.18)
            Tween(other.Label, { TextColor3 = Theme.Text }, 0.18)
            if other.Icon then
                Tween(other.Icon, { ImageColor3 = Theme.Text }, 0.18)
            end
        end
    end
end

function WindowClass:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self.Visible = false
    if type(self.OnDestroy) == "function" then
        SafeCall("Window OnDestroy", self.OnDestroy)
    end
    DisconnectAll(self._conns)
    if self._keyStore then
        DisconnectAll(self._keyStore)
    end
    if self._keyFrame then
        pcall(function()
            self._keyFrame:Destroy()
        end)
    end
    for _, element in ipairs(self.Elements) do
        element._destroyed = true
    end
    for flag, element in pairs(BPUI.Flags) do
        if element.Window == self then
            BPUI.Flags[flag] = nil
        end
    end
    pcall(function()
        self.Main:Destroy()
    end)
    pcall(function()
        self.FloatingButton:Destroy()
    end)
    pcall(function()
        local registry = GetSharedRegistry()
        if registry[self.Title] == self then
            registry[self.Title] = nil
        end
    end)
    for i = #BPUI.Windows, 1, -1 do
        if BPUI.Windows[i] == self then
            table.remove(BPUI.Windows, i)
        end
    end
end

---------------------------------------------------------------------
-- Tabs
---------------------------------------------------------------------
function WindowClass:CreateTab(config)
    config = config or {}
    if type(config) == "string" then
        config = { Name = config }
    end
    local name = tostring(config.Name or config.Title or "Tab")

    self._order = self._order + 1
    local order = config._order or self._order

    local Tab = setmetatable({
        Name = name,
        Window = self,
        Sections = {},
        _defaultSection = nil,
    }, TabClass)

    local store = self._conns

    local Button = Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Text = "",
        LayoutOrder = order,
        Parent = self.TabList,
    })
    Corner(Button, 11)
    Bind(Button, "BackgroundColor3", "Accent")

    local labelOffset = 14
    local Icon = nil
    if config.Icon then
        local iconId = config.Icon
        if type(iconId) == "number" then
            iconId = "rbxassetid://" .. tostring(iconId)
        end
        Icon = Create("ImageLabel", {
            Position = UDim2.new(0, 11, 0.5, -9),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Image = tostring(iconId),
            ImageColor3 = Theme.Text,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Button,
        })
        labelOffset = 38
    end

    local Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, labelOffset, 0, 0),
        Size = UDim2.new(1, -labelOffset - 8, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Theme.Text,
        Text = name,
        Parent = Button,
    })

    local Page = Create("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.SubText,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = self.Pages,
    })
    Bind(Page, "ScrollBarImageColor3", "SubText")
    Padding(Page, 4, 22, 24, 22)
    ListLayout(Page, 16)

    Tab.Button = Button
    Tab.Label = Label
    Tab.Icon = Icon
    Tab.Page = Page

    if not IsMobile then
        Connect(store, Button.MouseEnter, function()
            if self.CurrentTab ~= Tab then
                Tween(Button, { BackgroundTransparency = 0.85 }, 0.15)
            end
        end)
        Connect(store, Button.MouseLeave, function()
            if self.CurrentTab ~= Tab then
                Tween(Button, { BackgroundTransparency = 1 }, 0.15)
            end
        end)
    end
    Connect(store, Button.Activated, function()
        self:SelectTab(Tab)
    end)

    OnThemeChanged(function()
        if self.CurrentTab == Tab then
            Label.TextColor3 = Theme.AccentText
            if Icon then
                Icon.ImageColor3 = Theme.AccentText
            end
        else
            Label.TextColor3 = Theme.Text
            if Icon then
                Icon.ImageColor3 = Theme.Text
            end
        end
    end, self)

    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 or (self.CurrentTab and self.CurrentTab._internal and not config._internal) then
        self:SelectTab(Tab)
    end
    Tab._internal = config._internal

    return Tab
end
WindowClass.AddTab = WindowClass.CreateTab

function TabClass:Select()
    self.Window:SelectTab(self)
end

function TabClass:SetName(name)
    self.Name = tostring(name)
    self.Label.Text = self.Name
    if self.Window.CurrentTab == self then
        self.Window.TabTitle.Text = self.Name
    end
end

function TabClass:Destroy()
    for i = #self.Sections, 1, -1 do
        local section = self.Sections[i]
        for j = #section.Elements, 1, -1 do
            pcall(function()
                section.Elements[j]:Destroy()
            end)
        end
    end
    pcall(function()
        self.Button:Destroy()
    end)
    pcall(function()
        self.Page:Destroy()
    end)
    local window = self.Window
    for i = #window.Tabs, 1, -1 do
        if window.Tabs[i] == self then
            table.remove(window.Tabs, i)
        end
    end
    if window.CurrentTab == self and window.Tabs[1] then
        window:SelectTab(window.Tabs[1])
    end
end

---------------------------------------------------------------------
-- Sections (iOS grouped cards)
---------------------------------------------------------------------
function TabClass:CreateSection(config)
    config = config or {}
    if type(config) == "string" then
        config = { Name = config }
    end
    local title = tostring(config.Name or config.Title or "")

    local Section = setmetatable({
        Tab = self,
        Window = self.Window,
        Name = title,
        Rows = {},
        Elements = {},
        Spacers = {},
        _visible = true,
        _order = 1,
    }, SectionClass)

    local Holder = Create("Frame", {
        Name = title ~= "" and title or "Section",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self.Sections + 1,
        Parent = self.Page,
    })
    ListLayout(Holder, 6)

    local Header = Create("TextLabel", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT_MEDIUM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = title:upper(),
        Visible = title ~= "",
        LayoutOrder = 1,
        Parent = Holder,
    })
    Bind(Header, "TextColor3", "SubText")
    Padding(Header, 0, 14, 0, 14)

    local Card = Create("Frame", {
        Name = "Card",
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = Holder,
    })
    Corner(Card, 13)
    Bind(Card, "BackgroundColor3", "Card")
    ListLayout(Card, 0)

    Section.Holder = Holder
    Section.Header = Header
    Section.Card = Card

    table.insert(self.Sections, Section)
    return Section
end
TabClass.AddSection = TabClass.CreateSection

function TabClass:_DefaultSection()
    if not self._defaultSection then
        self._defaultSection = self:CreateSection("")
    end
    return self._defaultSection
end

function SectionClass:SetTitle(text)
    self.Name = tostring(text or "")
    self.Header.Text = self.Name:upper()
    self.Header.Visible = self.Name ~= ""
end
SectionClass.SetName = SectionClass.SetTitle

function SectionClass:SetVisible(visible)
    self._visible = visible and true or false
    self.Holder.Visible = self._visible
end

function SectionClass:Destroy()
    for i = #self.Elements, 1, -1 do
        pcall(function()
            self.Elements[i]:Destroy()
        end)
    end
    pcall(function()
        self.Holder:Destroy()
    end)
    local tab = self.Tab
    for i = #tab.Sections, 1, -1 do
        if tab.Sections[i] == self then
            table.remove(tab.Sections, i)
        end
    end
end

function SectionClass:_UpdateSeparators()
    local last = nil
    for _, row in ipairs(self.Rows) do
        if row.Visible then
            if last then
                local sep = last:FindFirstChild("Separator")
                if sep then
                    sep.Visible = true
                end
            end
            last = row
        end
    end
    if last then
        local sep = last:FindFirstChild("Separator")
        if sep then
            sep.Visible = false
        end
    end
end

-- Base row: title (+ optional description) with a control area on the right
function SectionClass:_Row(name, description, controlWidth, fixedHeight, titleThemeKey)
    local hasDesc = description ~= nil and description ~= ""
    local headerHeight = hasDesc and ROW_HEIGHT_DESC or ROW_HEIGHT
    local rowHeight = fixedHeight or headerHeight
    controlWidth = controlWidth or 0

    local Row = Create("Frame", {
        Name = tostring(name),
        BackgroundColor3 = Theme.CardHover,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, rowHeight),
        LayoutOrder = self._order,
        Parent = self.Card,
    })
    self._order = self._order + 1
    Corner(Row, 11)
    Bind(Row, "BackgroundColor3", "CardHover")

    local Title = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, hasDesc and 10 or 0),
        Size = UDim2.new(1, -(30 + controlWidth), 0, hasDesc and 20 or headerHeight),
        Font = FONT_MEDIUM,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(name),
        ZIndex = 2,
        Parent = Row,
    })
    Bind(Title, "TextColor3", titleThemeKey or "Text")

    local Description = nil
    if hasDesc then
        Description = Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 30),
            Size = UDim2.new(1, -(30 + controlWidth), 0, 18),
            Font = FONT,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(description),
            ZIndex = 2,
            Parent = Row,
        })
        Bind(Description, "TextColor3", "SubText")
    end

    local Separator = Create("Frame", {
        Name = "Separator",
        Position = UDim2.new(0, 16, 1, -1),
        Size = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = Theme.Separator,
        Parent = Row,
    })
    Bind(Separator, "BackgroundColor3", "Separator")

    if not IsMobile then
        Connect(self.Window._conns, Row.MouseEnter, function()
            Tween(Row, { BackgroundTransparency = 0 }, 0.12)
        end)
        Connect(self.Window._conns, Row.MouseLeave, function()
            Tween(Row, { BackgroundTransparency = 1 }, 0.12)
        end)
    end

    table.insert(self.Rows, Row)
    self:_UpdateSeparators()

    return Row, Title, Description, headerHeight
end

-- Base element object shared by every component
function SectionClass:_Element(elementType, config, row, title, description)
    local Element = {
        Type = elementType,
        Name = tostring(config.Name or config.Text or config.Title or elementType),
        Description = config.Description and tostring(config.Description) or nil,
        Flag = config.Flag,
        Callback = config.Callback,
        Row = row,
        Section = self,
        Window = self.Window,
        Value = nil,
        Visible = true,
        Locked = false,
        _searchHidden = false,
    }

    function Element:Get()
        return self.Value
    end

    function Element:_ApplyVisibility()
        row.Visible = self.Visible and not self._searchHidden
    end

    function Element:SetVisible(visible)
        self.Visible = visible and true or false
        self:_ApplyVisibility()
        self.Section:_UpdateSeparators()
    end

    function Element:SetName(text)
        self.Name = tostring(text)
        if title then
            title.Text = self.Name
        end
    end

    function Element:SetDescription(text)
        self.Description = text and tostring(text) or nil
        if description then
            description.Text = tostring(text or "")
        end
    end

    function Element:SetCallback(fn)
        self.Callback = fn
    end

    -- greys the row out and swallows every input on it
    function Element:SetLocked(locked)
        locked = locked and true or false
        self.Locked = locked
        local overlay = row:FindFirstChild("LockOverlay")
        if locked and not overlay then
            overlay = Create("Frame", {
                Name = "LockOverlay",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme.Card,
                BackgroundTransparency = 0.55,
                Active = true,
                ZIndex = 30,
                Parent = row,
            })
            Corner(overlay, 11)
            Bind(overlay, "BackgroundColor3", "Card")
            -- invisible button so taps never reach the controls underneath
            Create("TextButton", {
                Name = "Sink",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 31,
                Parent = overlay,
            })
        end
        if overlay then
            overlay.Visible = locked
        end
    end

    function Element:Lock()
        self:SetLocked(true)
    end

    function Element:Unlock()
        self:SetLocked(false)
    end

    function Element:Destroy()
        if self._destroyed then
            return
        end
        self._destroyed = true
        if self.Flag and BPUI.Flags[self.Flag] == self then
            BPUI.Flags[self.Flag] = nil
        end
        for i = #self.Section.Rows, 1, -1 do
            if self.Section.Rows[i] == row then
                table.remove(self.Section.Rows, i)
            end
        end
        for i = #self.Section.Elements, 1, -1 do
            if self.Section.Elements[i] == self then
                table.remove(self.Section.Elements, i)
            end
        end
        local windowElements = self.Window.Elements
        for i = #windowElements, 1, -1 do
            if windowElements[i] == self then
                table.remove(windowElements, i)
            end
        end
        pcall(function()
            row:Destroy()
        end)
        self.Section:_UpdateSeparators()
    end

    function Element:_Fire(...)
        SafeCall(self.Type .. " '" .. self.Name .. "'", self.Callback, ...)
    end

    if config.Flag then
        if BPUI.Flags[config.Flag] and BPUI.Flags[config.Flag].Window == self.Window then
            warn("[BPUI] Duplicate flag '" .. tostring(config.Flag) .. "' - the newer element wins")
        end
        BPUI.Flags[config.Flag] = Element
    end
    table.insert(self.Elements, Element)
    table.insert(self.Window.Elements, Element)
    return Element
end

-- convenience aliases applied after each element is finished
local function FinishElement(Element)
    if type(Element.Set) == "function" then
        Element.SetValue = Element.Set
        Element.Update = Element.Set
    end
    Element.GetValue = Element.Get
    return Element
end

local function HitButton(row, height)
    return Create("TextButton", {
        Name = "Hit",
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(1, 0, 0, height),
        ZIndex = 1,
        Parent = row,
    })
end

---------------------------------------------------------------------
-- Button
---------------------------------------------------------------------
function SectionClass:AddButton(config)
    config = config or {}
    if type(config) == "string" then
        config = { Name = config }
    end
    local name = config.Name or config.Title or "Button"
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, 24, nil, "Accent")

    local chevron = GlyphChevron(Row, 12, 2, "SubText")
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -16, 0, headerHeight / 2)
    chevron.Rotation = -90

    local Hit = HitButton(Row, headerHeight)
    local Element = self:_Element("Button", config, Row, Title, Description)

    Connect(self.Window._conns, Hit.Activated, function()
        if IsMobile then
            Row.BackgroundTransparency = 0
            Tween(Row, { BackgroundTransparency = 1 }, 0.35)
        else
            Row.BackgroundTransparency = 0.55
            Tween(Row, { BackgroundTransparency = 0 }, 0.3)
        end
        Element:_Fire()
    end)

    function Element:Click()
        self:_Fire()
    end

    return FinishElement(Element)
end
SectionClass.CreateButton = SectionClass.AddButton

---------------------------------------------------------------------
-- Toggle (iOS switch)
---------------------------------------------------------------------
function SectionClass:AddToggle(config)
    config = config or {}
    local name = config.Name or config.Title or "Toggle"
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, 60)

    local Switch = Create("Frame", {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0, headerHeight / 2),
        Size = UDim2.fromOffset(46, 27),
        BackgroundColor3 = Theme.ToggleOff,
        ZIndex = 2,
        Parent = Row,
    })
    Corner(Switch, 14)

    local Knob = Create("Frame", {
        Name = "Knob",
        Position = UDim2.new(0, 2, 0.5, -11),
        Size = UDim2.fromOffset(23, 23),
        BackgroundColor3 = Theme.Knob,
        ZIndex = 3,
        Parent = Switch,
    })
    Corner(Knob, 12)
    Bind(Knob, "BackgroundColor3", "Knob")
    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.85,
        Parent = Knob,
    })

    local Hit = HitButton(Row, headerHeight)
    local Element = self:_Element("Toggle", config, Row, Title, Description)
    Element.Value = (config.Default == true) or (config.CurrentValue == true) or (config.Value == true)

    local function Render(instant)
        local on = Element.Value
        local trackColor = on and Theme.Toggle or Theme.ToggleOff
        local knobPos = on and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        if instant then
            Switch.BackgroundColor3 = trackColor
            Knob.Position = knobPos
        else
            Tween(Switch, { BackgroundColor3 = trackColor }, 0.2)
            Tween(Knob, { Position = knobPos }, 0.2, Enum.EasingStyle.Back)
        end
    end

    function Element:Set(value, silent)
        self.Value = value and true or false
        Render(false)
        if not silent then
            self:_Fire(self.Value)
        end
    end

    Connect(self.Window._conns, Hit.Activated, function()
        Element:Set(not Element.Value)
    end)
    OnThemeChanged(function()
        Render(true)
    end, self.Window)

    Render(true)
    if Element.Value then
        Element:_Fire(true)
    end
    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateToggle = SectionClass.AddToggle

---------------------------------------------------------------------
-- Slider
---------------------------------------------------------------------
function SectionClass:AddSlider(config)
    config = config or {}
    local name = config.Name or config.Title or "Slider"
    local min = tonumber(config.Min) or (type(config.Range) == "table" and tonumber(config.Range[1])) or 0
    local max = tonumber(config.Max) or (type(config.Range) == "table" and tonumber(config.Range[2])) or 100
    if max < min then
        min, max = max, min
    end
    local increment = tonumber(config.Increment or config.Step) or 1
    if increment <= 0 then
        increment = 1
    end
    local suffix = tostring(config.Suffix or "")
    local decimals = 0
    do
        local text = tostring(increment)
        local dot = text:find("%.")
        if dot then
            decimals = #text - dot
        end
    end

    local trackWidth = 150
    local valueWidth = 52
    local controlWidth = trackWidth + valueWidth + 10
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, controlWidth)

    -- the value is a text box: tap it to type an exact number
    local ValueLabel = Create("TextBox", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0, headerHeight / 2),
        Size = UDim2.fromOffset(valueWidth, 24),
        BackgroundTransparency = 1,
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
        ClearTextOnFocus = true,
        TextEditable = config.Typeable ~= false,
        ZIndex = 2,
        Parent = Row,
    })
    Bind(ValueLabel, "TextColor3", "SubText")
    Bind(ValueLabel, "PlaceholderColor3", "SubText")

    local Track = Create("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(16 + valueWidth + 10), 0, headerHeight / 2),
        Size = UDim2.fromOffset(trackWidth, 4),
        BackgroundColor3 = Theme.Element,
        ZIndex = 2,
        Parent = Row,
    })
    Corner(Track, 2)
    Bind(Track, "BackgroundColor3", "Element")

    local Fill = Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 3,
        Parent = Track,
    })
    Corner(Fill, 2)
    Bind(Fill, "BackgroundColor3", "Accent")

    local Knob = Create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Theme.Knob,
        ZIndex = 4,
        Parent = Track,
    })
    Corner(Knob, 9)
    Bind(Knob, "BackgroundColor3", "Knob")
    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.8,
        Parent = Knob,
    })

    local Hitbox = Create("Frame", {
        Name = "Hitbox",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(16 + valueWidth + 10) + 9, 0, headerHeight / 2),
        Size = UDim2.fromOffset(trackWidth + 18, 34),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 5,
        Parent = Row,
    })

    local Element = self:_Element("Slider", config, Row, Title, Description)
    Element.Min = min
    Element.Max = max

    local function Snap(raw)
        raw = Clamp(tonumber(raw) or min, min, max)
        local stepped = min + math.floor((raw - min) / increment + 0.5) * increment
        stepped = Round(stepped, decimals)
        return Clamp(stepped, min, max)
    end

    local function Render(instant)
        local alpha = 0
        if max > min then
            alpha = (Element.Value - min) / (max - min)
        end
        ValueLabel.Text = FormatNumber(Element.Value, decimals) .. suffix
        if instant then
            Fill.Size = UDim2.new(alpha, 0, 1, 0)
            Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        else
            Tween(Fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.08)
            Tween(Knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.08)
        end
    end

    function Element:Set(value, silent)
        local snapped = Snap(value)
        local changed = snapped ~= self.Value
        self.Value = snapped
        Render(false)
        if not silent and changed then
            self:_Fire(snapped)
        end
    end

    function Element:SetRange(newMin, newMax)
        min = tonumber(newMin) or min
        max = tonumber(newMax) or max
        if max < min then
            min, max = max, min
        end
        self.Min = min
        self.Max = max
        self:Set(self.Value, true)
    end

    MakeSlidable(self.Window._conns, Hitbox, function(position)
        local ok = pcall(function()
            local absPos = Track.AbsolutePosition.X
            local absSize = Track.AbsoluteSize.X
            if absSize <= 0 then
                return
            end
            local alpha = Clamp((position.X - absPos) / absSize, 0, 1)
            Element:Set(min + alpha * (max - min))
        end)
    end)

    Connect(self.Window._conns, ValueLabel.Focused, function()
        ValueLabel.PlaceholderText = FormatNumber(Element.Value, decimals)
    end)
    Connect(self.Window._conns, ValueLabel.FocusLost, function()
        local typed = tonumber((ValueLabel.Text:gsub("[^%d%.%-]", "")))
        if typed then
            Element:Set(typed)
        else
            Render(true)
        end
    end)

    Element.Value = Snap(config.Default or config.CurrentValue or config.Value or min)
    Render(true)
    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateSlider = SectionClass.AddSlider

---------------------------------------------------------------------
-- Dropdown (single / multi select, expands in place)
---------------------------------------------------------------------
local OPTION_HEIGHT = 32
local OPTION_GAP = 2
local DROPDOWN_MAX_HEIGHT = 5 * (OPTION_HEIGHT + OPTION_GAP)

function SectionClass:AddDropdown(config)
    config = config or {}
    local name = config.Name or config.Title or "Dropdown"
    local multi = (config.Multi == true) or (config.MultipleOptions == true) or (config.MultiSelect == true)
    local options = {}
    for _, option in ipairs(config.Options or config.Values or config.List or {}) do
        options[#options + 1] = tostring(option)
    end

    local controlWidth = 180
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, controlWidth)
    local store = self.Window._conns

    local ValueLabel = Create("TextLabel", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -34, 0, headerHeight / 2),
        Size = UDim2.fromOffset(controlWidth - 26, 20),
        BackgroundTransparency = 1,
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "None",
        ZIndex = 2,
        Parent = Row,
    })
    Bind(ValueLabel, "TextColor3", "SubText")

    local Chevron = GlyphChevron(Row, 12, 2, "SubText")
    Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Chevron.Position = UDim2.new(1, -16, 0, headerHeight / 2)
    Chevron.ZIndex = 2

    -- optional filter box for long option lists
    local searchable = config.Searchable
    if searchable == nil then
        searchable = #options > 6
    end
    local FILTER_HEIGHT = searchable and 34 or 0
    local filterText = ""

    local FilterBox = Create("Frame", {
        Name = "Filter",
        Position = UDim2.new(0, 12, 0, headerHeight),
        Size = UDim2.new(1, -24, 0, 30),
        BackgroundColor3 = Theme.Element,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = Row,
    })
    Corner(FilterBox, 9)
    Bind(FilterBox, "BackgroundColor3", "Element")
    local FilterInput = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "Filter...",
        Text = "",
        ClearTextOnFocus = false,
        ZIndex = 3,
        Parent = FilterBox,
    })
    Bind(FilterInput, "TextColor3", "Text")
    Bind(FilterInput, "PlaceholderColor3", "SubText")

    local List = Create("ScrollingFrame", {
        Name = "List",
        Position = UDim2.new(0, 12, 0, headerHeight + FILTER_HEIGHT),
        Size = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.SubText,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 2,
        Parent = Row,
    })
    Bind(List, "ScrollBarImageColor3", "SubText")
    ListLayout(List, OPTION_GAP)

    local Hit = HitButton(Row, headerHeight)
    local Element = self:_Element("Dropdown", config, Row, Title, Description)
    Element.Multi = multi
    Element.Options = options
    Element.Value = multi and {} or nil

    local open = false
    local optionRows = {}

    local function IsSelected(option)
        if multi then
            for _, value in ipairs(Element.Value) do
                if value == option then
                    return true
                end
            end
            return false
        end
        return Element.Value == option
    end

    local function RenderValue(instant)
        if multi then
            ValueLabel.Text = (#Element.Value > 0) and table.concat(Element.Value, ", ") or "None"
        else
            ValueLabel.Text = (Element.Value ~= nil) and tostring(Element.Value) or "None"
        end
        for option, entry in pairs(optionRows) do
            local selected = IsSelected(option)
            entry.Check.Visible = selected
            local ringColor = selected and Theme.Accent or Theme.Element
            local textColor = selected and Theme.Text or Theme.SubText
            if instant then
                entry.Ring.BackgroundColor3 = ringColor
                entry.Label.TextColor3 = textColor
            else
                Tween(entry.Ring, { BackgroundColor3 = ringColor }, 0.15)
                Tween(entry.Label, { TextColor3 = textColor }, 0.15)
            end
        end
    end

    local function VisibleOptionCount()
        local count = 0
        for _, entry in pairs(optionRows) do
            if entry.Button.Visible then
                count = count + 1
            end
        end
        return count
    end

    local function LayoutList(instant)
        local listHeight = 0
        if open then
            local count = VisibleOptionCount()
            listHeight = math.min(count * (OPTION_HEIGHT + OPTION_GAP) - OPTION_GAP, DROPDOWN_MAX_HEIGHT)
            listHeight = math.max(listHeight, 0)
        end
        local rowHeight = headerHeight + (open and (FILTER_HEIGHT + listHeight + 10) or 0)
        if open then
            List.Visible = true
            FilterBox.Visible = searchable
        end
        if instant then
            List.Size = UDim2.new(1, -24, 0, listHeight)
            Row.Size = UDim2.new(1, 0, 0, rowHeight)
            Chevron.Rotation = open and 180 or 0
            if not open then
                List.Visible = false
                FilterBox.Visible = false
            end
        else
            Tween(List, { Size = UDim2.new(1, -24, 0, listHeight) }, 0.22)
            Tween(Row, { Size = UDim2.new(1, 0, 0, rowHeight) }, 0.22)
            Tween(Chevron, { Rotation = open and 180 or 0 }, 0.22)
            if not open then
                task.delay(0.22, function()
                    if not open then
                        List.Visible = false
                        FilterBox.Visible = false
                    end
                end)
            end
        end
    end

    local function ApplyFilter()
        local needle = filterText:lower()
        for option, entry in pairs(optionRows) do
            entry.Button.Visible = needle == "" or option:lower():find(needle, 1, true) ~= nil
        end
        if open then
            LayoutList(false)
        end
    end

    Connect(store, FilterInput:GetPropertyChangedSignal("Text"), function()
        filterText = FilterInput.Text
        ApplyFilter()
    end)

    local function SetOpen(state)
        open = state and true or false
        if not open and FilterInput.Text ~= "" then
            FilterInput.Text = ""
        end
        LayoutList(false)
    end

    local function Rebuild()
        for _, entry in pairs(optionRows) do
            pcall(function()
                entry.Button:Destroy()
            end)
        end
        optionRows = {}

        for index, option in ipairs(options) do
            local Button = Create("TextButton", {
                Name = option,
                Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = index,
                ZIndex = 3,
                Parent = List,
            })
            Corner(Button, 9)
            Bind(Button, "BackgroundColor3", "Element")

            local Label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -52, 1, 0),
                Font = FONT_MEDIUM,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = Theme.SubText,
                Text = option,
                ZIndex = 4,
                Parent = Button,
            })

            local Ring = Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(20, 20),
                BackgroundColor3 = Theme.Element,
                ZIndex = 4,
                Parent = Button,
            })
            Corner(Ring, 10)

            local Check = GlyphCheck(Ring, 11, 2, "AccentText")
            Check.AnchorPoint = Vector2.new(0.5, 0.5)
            Check.Position = UDim2.new(0.5, 0, 0.5, 0)
            Check.ZIndex = 5
            Check.Visible = false

            if not IsMobile then
                Connect(store, Button.MouseEnter, function()
                    Tween(Button, { BackgroundTransparency = 0.5 }, 0.12)
                end)
                Connect(store, Button.MouseLeave, function()
                    Tween(Button, { BackgroundTransparency = 1 }, 0.12)
                end)
            end

            Connect(store, Button.Activated, function()
                if multi then
                    local set = {}
                    for _, value in ipairs(Element.Value) do
                        set[value] = true
                    end
                    set[option] = not set[option]
                    local newValue = {}
                    for _, candidate in ipairs(options) do
                        if set[candidate] then
                            newValue[#newValue + 1] = candidate
                        end
                    end
                    Element.Value = newValue
                    RenderValue(false)
                    Element:_Fire(newValue)
                else
                    Element.Value = option
                    RenderValue(false)
                    Element:_Fire(option)
                    task.delay(0.1, function()
                        SetOpen(false)
                    end)
                end
            end)

            optionRows[option] = { Button = Button, Label = Label, Ring = Ring, Check = Check }
        end

        if filterText ~= "" then
            local needle = filterText:lower()
            for option, entry in pairs(optionRows) do
                entry.Button.Visible = option:lower():find(needle, 1, true) ~= nil
            end
        end
        RenderValue(true)
        if open then
            LayoutList(true)
        end
    end

    function Element:Set(value, silent)
        if multi then
            local wanted = {}
            if type(value) == "table" then
                for _, entry in ipairs(value) do
                    wanted[tostring(entry)] = true
                end
            elseif value ~= nil then
                wanted[tostring(value)] = true
            end
            local newValue = {}
            for _, candidate in ipairs(options) do
                if wanted[candidate] then
                    newValue[#newValue + 1] = candidate
                end
            end
            self.Value = newValue
        else
            if type(value) == "table" then
                value = value[1]
            end
            self.Value = (value ~= nil) and tostring(value) or nil
        end
        RenderValue(false)
        if not silent then
            self:_Fire(self.Value)
        end
    end

    function Element:Refresh(newOptions, keepValue)
        options = {}
        for _, option in ipairs(newOptions or {}) do
            options[#options + 1] = tostring(option)
        end
        self.Options = options
        if config.Searchable == nil then
            searchable = #options > 6
            FILTER_HEIGHT = searchable and 34 or 0
            List.Position = UDim2.new(0, 12, 0, headerHeight + FILTER_HEIGHT)
        end
        Rebuild()
        if keepValue then
            self:Set(self.Value, true)
        else
            self:Set(multi and {} or nil, true)
        end
    end
    Element.SetOptions = Element.Refresh

    function Element:Open()
        SetOpen(true)
    end

    function Element:Close()
        SetOpen(false)
    end

    Connect(store, Hit.Activated, function()
        SetOpen(not open)
    end)
    OnThemeChanged(function()
        RenderValue(true)
    end, self.Window)

    Rebuild()
    local default = config.Default
    if default == nil then
        default = config.CurrentOption
    end
    if default == nil then
        default = config.Value
    end
    Element:Set(default, true)
    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateDropdown = SectionClass.AddDropdown

---------------------------------------------------------------------
-- Input (text box)
---------------------------------------------------------------------
function SectionClass:AddInput(config)
    config = config or {}
    local name = config.Name or config.Title or "Input"
    local controlWidth = 172
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, controlWidth)
    local store = self.Window._conns

    local Box = Create("Frame", {
        Name = "Box",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0, headerHeight / 2),
        Size = UDim2.fromOffset(160, 30),
        BackgroundColor3 = Theme.Element,
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = Row,
    })
    Corner(Box, 9)
    Bind(Box, "BackgroundColor3", "Element")
    local BoxStroke = Stroke(Box, "Stroke", 1, 0.7)

    local TextBox = Create("TextBox", {
        Name = "TextBox",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = tostring(config.Placeholder or config.PlaceholderText or "Type here..."),
        Text = tostring(config.Default or config.CurrentValue or config.Value or ""),
        ClearTextOnFocus = config.ClearOnFocus == true,
        ZIndex = 3,
        Parent = Box,
    })
    Bind(TextBox, "TextColor3", "Text")
    Bind(TextBox, "PlaceholderColor3", "SubText")

    local Element = self:_Element("Input", config, Row, Title, Description)
    Element.Value = TextBox.Text
    Element.TextBox = TextBox

    local function Filter(text)
        if config.Numeric then
            text = text:gsub("[^%d%.%-]", "")
        end
        if config.MaxLength and #text > config.MaxLength then
            text = text:sub(1, config.MaxLength)
        end
        return text
    end

    function Element:Set(text, silent)
        text = Filter(tostring(text or ""))
        self.Value = text
        TextBox.Text = text
        if not silent then
            self:_Fire(text, false)
        end
    end

    Connect(store, TextBox:GetPropertyChangedSignal("Text"), function()
        local filtered = Filter(TextBox.Text)
        if filtered ~= TextBox.Text then
            TextBox.Text = filtered
            return
        end
        Element.Value = filtered
        if config.CallbackOnChange or config.OnChange then
            SafeCall("Input '" .. Element.Name .. "' OnChange", config.OnChange or config.Callback, filtered, false)
        end
    end)

    Connect(store, TextBox.Focused, function()
        BoxStroke.Color = Theme.Accent
        BoxStroke.Transparency = 0
    end)

    Connect(store, TextBox.FocusLost, function(enterPressed)
        BoxStroke.Color = Theme.Stroke
        BoxStroke.Transparency = 0.7
        Element.Value = TextBox.Text
        if config.RemoveTextAfterFocusLost then
            TextBox.Text = ""
        end
        Element:_Fire(Element.Value, enterPressed == true)
    end)

    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateInput = SectionClass.AddInput
SectionClass.AddTextbox = SectionClass.AddInput
SectionClass.CreateTextbox = SectionClass.AddInput

---------------------------------------------------------------------
-- Keybind
---------------------------------------------------------------------
BPUI._keybindListening = false

function SectionClass:AddKeybind(config)
    config = config or {}
    local name = config.Name or config.Title or "Keybind"
    local controlWidth = 120
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, controlWidth)
    local store = self.Window._conns

    local Pill = Create("TextButton", {
        Name = "Pill",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0, headerHeight / 2),
        Size = UDim2.fromOffset(0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.Element,
        Font = FONT_MEDIUM,
        TextSize = 12,
        Text = "None",
        ZIndex = 2,
        Parent = Row,
    })
    Corner(Pill, 8)
    Padding(Pill, 0, 12, 0, 12)
    Bind(Pill, "BackgroundColor3", "Element")
    Bind(Pill, "TextColor3", "SubText")
    local PillStroke = Stroke(Pill, "Stroke", 1, 0.7)

    local Element = self:_Element("Keybind", config, Row, Title, Description)
    Element.Value = "None"
    Element.Mode = tostring(config.Mode or (config.HoldToInteract and "Hold") or "Press")

    local listening = false
    local toggled = false
    local held = false

    local function Render()
        if listening then
            Pill.Text = "..."
            PillStroke.Color = Theme.Accent
            PillStroke.Transparency = 0
        else
            Pill.Text = PrettyKeyName(Element.Value)
            PillStroke.Color = Theme.Stroke
            PillStroke.Transparency = 0.7
        end
    end

    function Element:Set(key, silent)
        if key == nil or key == "None" or key == "" then
            self.Value = "None"
        else
            local keyCode = ToKeyCode(key)
            if keyCode then
                self.Value = keyCode.Name
            else
                self.Value = tostring(key)
            end
        end
        Render()
        if not silent then
            SafeCall("Keybind '" .. self.Name .. "' OnChanged", config.OnChanged or config.ChangedCallback, self.Value)
        end
    end

    function Element:GetKeyCode()
        return ToKeyCode(self.Value)
    end

    local function StopListening()
        if listening then
            listening = false
            if BPUI._activeKeybindCancel == StopListening then
                BPUI._activeKeybindCancel = nil
            end
            task.delay(0.1, function()
                if not BPUI._activeKeybindCancel then
                    BPUI._keybindListening = false
                end
            end)
            Render()
        end
    end

    Connect(store, Pill.Activated, function()
        if listening then
            StopListening()
            return
        end
        -- only one keybind can listen at a time
        if BPUI._activeKeybindCancel then
            pcall(BPUI._activeKeybindCancel)
        end
        listening = true
        BPUI._keybindListening = true
        BPUI._activeKeybindCancel = StopListening
        Render()
    end)

    Connect(store, UserInputService.InputBegan, function(input)
        if Element._destroyed then
            return
        end
        if listening then
            local captured = nil
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    captured = false -- cancel
                elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                    captured = "None"
                else
                    captured = input.KeyCode.Name
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                captured = input.UserInputType.Name
            end
            if captured ~= nil then
                if captured then
                    Element:Set(captured)
                end
                StopListening()
            end
            return
        end
        if Element.Mode == "None" or Element.Value == "None" then
            return
        end
        if TextBoxFocused() then
            return
        end
        if Element.Locked then
            return
        end
        local pressedName = nil
        if input.UserInputType == Enum.UserInputType.Keyboard then
            pressedName = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            pressedName = input.UserInputType.Name
        end
        if pressedName == Element.Value then
            if Element.Mode == "Toggle" then
                toggled = not toggled
                Element:_Fire(toggled)
            elseif Element.Mode == "Hold" then
                held = true
                Element:_Fire(true)
            else
                Element:_Fire()
            end
        end
    end)

    Connect(store, UserInputService.InputEnded, function(input)
        if Element._destroyed or Element.Mode ~= "Hold" or not held then
            return
        end
        local releasedName = nil
        if input.UserInputType == Enum.UserInputType.Keyboard then
            releasedName = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            releasedName = input.UserInputType.Name
        end
        if releasedName == Element.Value then
            held = false
            Element:_Fire(false)
        end
    end)

    Element:Set(config.Default or config.CurrentKeybind or config.Value, true)
    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateKeybind = SectionClass.AddKeybind

---------------------------------------------------------------------
-- Colour picker (HSV square + hue bar + hex input)
---------------------------------------------------------------------
local PICKER_HEIGHT = 132

function SectionClass:AddColorPicker(config)
    config = config or {}
    local name = config.Name or config.Title or "Color"
    local controlWidth = 60
    local Row, Title, Description, headerHeight = self:_Row(name, config.Description, controlWidth)
    local store = self.Window._conns

    local Swatch = Create("Frame", {
        Name = "Swatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0, headerHeight / 2),
        Size = UDim2.fromOffset(38, 24),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = Row,
    })
    Corner(Swatch, 8)
    Stroke(Swatch, "Stroke", 1, 0.3)

    local Hit = HitButton(Row, headerHeight)

    local Panel = Create("Frame", {
        Name = "Panel",
        Position = UDim2.new(0, 16, 0, headerHeight),
        Size = UDim2.new(1, -32, 0, PICKER_HEIGHT),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 2,
        Parent = Row,
    })

    -- saturation / value square
    local SV = Create("Frame", {
        Name = "SV",
        Position = UDim2.new(0, 0, 0, 6),
        Size = UDim2.fromOffset(130, 120),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Active = true,
        ZIndex = 3,
        Parent = Panel,
    })
    Corner(SV, 9)

    local SVWhite = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 4,
        Parent = SV,
    })
    Corner(SVWhite, 9)
    Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = SVWhite,
    })

    local SVBlack = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        ZIndex = 5,
        Parent = SV,
    })
    Corner(SVBlack, 9)
    Create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = SVBlack,
    })

    local SVKnob = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        ZIndex = 6,
        Parent = SV,
    })
    Corner(SVKnob, 7)
    Create("UIStroke", {
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Parent = SVKnob,
    })

    -- hue bar
    local Hue = Create("Frame", {
        Name = "Hue",
        Position = UDim2.new(0, 142, 0, 6),
        Size = UDim2.fromOffset(16, 120),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Active = true,
        ZIndex = 3,
        Parent = Panel,
    })
    Corner(Hue, 8)
    Create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
        }),
        Parent = Hue,
    })

    local HueKnob = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.fromOffset(22, 6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 4,
        Parent = Hue,
    })
    Corner(HueKnob, 3)
    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.5,
        Parent = HueKnob,
    })

    -- preview + hex + rgb
    local Preview = Create("Frame", {
        Position = UDim2.new(0, 172, 0, 6),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 3,
        Parent = Panel,
    })
    Corner(Preview, 10)
    Stroke(Preview, "Stroke", 1, 0.3)

    local HexBox = Create("Frame", {
        Position = UDim2.new(0, 172, 0, 58),
        Size = UDim2.fromOffset(110, 30),
        BackgroundColor3 = Theme.Element,
        ZIndex = 3,
        Parent = Panel,
    })
    Corner(HexBox, 8)
    Bind(HexBox, "BackgroundColor3", "Element")
    local HexStroke = Stroke(HexBox, "Stroke", 1, 0.7)

    local HexInput = Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "#FFFFFF",
        PlaceholderText = "#FFFFFF",
        ClearTextOnFocus = false,
        ZIndex = 4,
        Parent = HexBox,
    })
    Bind(HexInput, "TextColor3", "Text")
    Bind(HexInput, "PlaceholderColor3", "SubText")

    local RGBLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 172, 0, 94),
        Size = UDim2.new(1, -172, 0, 32),
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = "",
        ZIndex = 3,
        Parent = Panel,
    })
    Bind(RGBLabel, "TextColor3", "SubText")

    local Element = self:_Element("ColorPicker", config, Row, Title, Description)
    local hue, sat, val = 0, 0, 1
    local open = false

    local function Render()
        local color = Color3.fromHSV(hue, sat, val)
        Element.Value = color
        SV.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        SVKnob.Position = UDim2.new(sat, 0, 1 - val, 0)
        HueKnob.Position = UDim2.new(0.5, 0, hue, 0)
        Swatch.BackgroundColor3 = color
        Preview.BackgroundColor3 = color
        HexInput.Text = ToHex(color)
        RGBLabel.Text = string.format(
            "R %d   G %d   B %d",
            math.floor(color.R * 255 + 0.5),
            math.floor(color.G * 255 + 0.5),
            math.floor(color.B * 255 + 0.5)
        )
    end

    local function SetOpen(state)
        open = state and true or false
        local rowHeight = headerHeight + (open and (PICKER_HEIGHT + 8) or 0)
        if open then
            Panel.Visible = true
        end
        Tween(Row, { Size = UDim2.new(1, 0, 0, rowHeight) }, 0.22)
        if not open then
            task.delay(0.22, function()
                if not open then
                    Panel.Visible = false
                end
            end)
        end
    end

    function Element:Set(color, silent)
        local c = ToColor3(color)
        if not c then
            return
        end
        local ok, h, s, v = pcall(function()
            return Color3.toHSV(c)
        end)
        if ok and type(h) == "number" then
            hue, sat, val = h, s, v
        else
            hue, sat, val = RGBToHSV(c)
        end
        Render()
        if not silent then
            self:_Fire(self.Value)
        end
    end

    function Element:Open()
        SetOpen(true)
    end

    function Element:Close()
        SetOpen(false)
    end

    MakeSlidable(store, SV, function(position)
        pcall(function()
            local absPos = SV.AbsolutePosition
            local absSize = SV.AbsoluteSize
            if absSize.X <= 0 or absSize.Y <= 0 then
                return
            end
            sat = Clamp((position.X - absPos.X) / absSize.X, 0, 1)
            val = 1 - Clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)
            Render()
            Element:_Fire(Element.Value)
        end)
    end)

    MakeSlidable(store, Hue, function(position)
        pcall(function()
            local absPos = Hue.AbsolutePosition
            local absSize = Hue.AbsoluteSize
            if absSize.Y <= 0 then
                return
            end
            hue = Clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)
            Render()
            Element:_Fire(Element.Value)
        end)
    end)

    Connect(store, HexInput.Focused, function()
        HexStroke.Color = Theme.Accent
        HexStroke.Transparency = 0
    end)
    Connect(store, HexInput.FocusLost, function()
        HexStroke.Color = Theme.Stroke
        HexStroke.Transparency = 0.7
        local parsed = FromHex(HexInput.Text)
        if parsed then
            Element:Set(parsed)
        else
            HexInput.Text = ToHex(Element.Value)
        end
    end)
    Connect(store, Hit.Activated, function()
        SetOpen(not open)
    end)

    Element:Set(config.Default or config.Color or config.Value or Color3.fromRGB(255, 255, 255), true)
    self.Window:_ApplyPending(Element)
    return FinishElement(Element)
end
SectionClass.CreateColorPicker = SectionClass.AddColorPicker
SectionClass.AddColorpicker = SectionClass.AddColorPicker
SectionClass.CreateColorpicker = SectionClass.AddColorPicker

---------------------------------------------------------------------
-- Label
---------------------------------------------------------------------
function SectionClass:AddLabel(config)
    config = config or {}
    if type(config) == "string" then
        config = { Text = config }
    end
    local text = tostring(config.Text or config.Name or config.Title or "Label")
    local themeKey = config.Style == "Accent" and "Accent" or (config.Style == "Sub" and "SubText") or "Text"
    local Row, Title = self:_Row(text, nil, 0, 40, themeKey)
    Title.Font = FONT
    Title.TextSize = 13
    if config.Center or config.Alignment == "Center" then
        Title.TextXAlignment = Enum.TextXAlignment.Center
    end

    local Element = self:_Element("Label", config, Row, Title, nil)
    Element.Value = text

    function Element:Set(newText)
        self.Value = tostring(newText or "")
        Title.Text = self.Value
    end

    return FinishElement(Element)
end
SectionClass.CreateLabel = SectionClass.AddLabel

---------------------------------------------------------------------
-- Paragraph (title + wrapped body)
---------------------------------------------------------------------
function SectionClass:AddParagraph(config)
    config = config or {}
    if type(config) == "string" then
        config = { Content = config }
    end
    local titleText = tostring(config.Title or config.Name or "")
    local contentText = tostring(config.Content or config.Text or "")

    local Row = Create("Frame", {
        Name = titleText ~= "" and titleText or "Paragraph",
        BackgroundColor3 = Theme.CardHover,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
        LayoutOrder = self._order,
        Parent = self.Card,
    })
    self._order = self._order + 1
    Corner(Row, 11)
    Bind(Row, "BackgroundColor3", "CardHover")

    local Title = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 18),
        Font = FONT_BOLD,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = titleText,
        Visible = titleText ~= "",
        ZIndex = 2,
        Parent = Row,
    })
    Bind(Title, "TextColor3", "Text")

    local Content = Create("TextLabel", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, titleText ~= "" and 34 or 12),
        Size = UDim2.new(1, -32, 0, 0),
        Font = FONT,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = contentText,
        ZIndex = 2,
        Parent = Row,
    })
    Bind(Content, "TextColor3", "SubText")

    local Separator = Create("Frame", {
        Name = "Separator",
        Position = UDim2.new(0, 16, 1, -1),
        Size = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = Theme.Separator,
        Parent = Row,
    })
    Bind(Separator, "BackgroundColor3", "Separator")

    local function Relayout()
        pcall(function()
            local top = Title.Visible and 34 or 12
            local contentHeight = 0
            if Content.Text ~= "" then
                contentHeight = math.max(Content.TextBounds.Y, 16)
            end
            Content.Position = UDim2.new(0, 16, 0, top)
            Content.Size = UDim2.new(1, -32, 0, contentHeight)
            local bottom = (Content.Text ~= "") and (top + contentHeight + 12) or (top - (Title.Visible and 4 or 0))
            Row.Size = UDim2.new(1, 0, 0, math.max(bottom, 36))
        end)
    end

    Connect(self.Window._conns, Content:GetPropertyChangedSignal("TextBounds"), Relayout)
    Connect(self.Window._conns, Row:GetPropertyChangedSignal("AbsoluteSize"), Relayout)
    Relayout()

    table.insert(self.Rows, Row)
    self:_UpdateSeparators()

    local Element = self:_Element("Paragraph", config, Row, Title, nil)
    Element.Value = contentText

    function Element:Set(newContent, newTitle)
        if newTitle ~= nil then
            Title.Text = tostring(newTitle)
            Title.Visible = Title.Text ~= ""
        end
        if newContent ~= nil then
            self.Value = tostring(newContent)
            Content.Text = self.Value
        end
        Relayout()
    end

    function Element:SetTitle(newTitle)
        self:Set(nil, newTitle)
    end

    function Element:SetContent(newContent)
        self:Set(newContent, nil)
    end

    return FinishElement(Element)
end
SectionClass.CreateParagraph = SectionClass.AddParagraph

---------------------------------------------------------------------
-- Divider (spacer inside a card)
---------------------------------------------------------------------
function SectionClass:AddDivider(height)
    local Spacer = Create("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, tonumber(height) or 10),
        LayoutOrder = self._order,
        Parent = self.Card,
    })
    self._order = self._order + 1
    table.insert(self.Spacers, Spacer)
    local section = self
    return {
        Type = "Divider",
        Instance = Spacer,
        SetVisible = function(_, visible)
            Spacer.Visible = visible and true or false
        end,
        Destroy = function()
            for i = #section.Spacers, 1, -1 do
                if section.Spacers[i] == Spacer then
                    table.remove(section.Spacers, i)
                end
            end
            pcall(function()
                Spacer:Destroy()
            end)
        end,
    }
end
SectionClass.CreateDivider = SectionClass.AddDivider

---------------------------------------------------------------------
-- Safe mode: a failing element never kills the whole script.
-- Set BPUI.SafeMode = false while developing to see raw errors.
---------------------------------------------------------------------
BPUI.SafeMode = true

local DummyDataKeys = {
    Value = true, Flag = true, Options = true, Min = true, Max = true, Locked = true, Visible = true,
    Description = true, Row = true, Section = true, Window = true, Callback = true, Mode = true,
    Multi = true, TextBox = true, Instance = true,
}
local DummyElementMT = {
    __index = function(_, key)
        if DummyDataKeys[key] then
            return nil
        end
        return function()
        end
    end,
}

local function DummyElement(elementType, name)
    return setmetatable({
        Type = elementType,
        Name = tostring(name),
        Value = nil,
        Failed = true,
    }, DummyElementMT)
end

for _, methodName in ipairs({
    "AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput", "AddKeybind",
    "AddColorPicker", "AddLabel", "AddParagraph", "AddDivider",
}) do
    local raw = SectionClass[methodName]
    SectionClass[methodName] = function(section, config, ...)
        if not BPUI.SafeMode then
            return raw(section, config, ...)
        end
        local ok, result = pcall(raw, section, config, ...)
        if ok then
            return result
        end
        local label = type(config) == "table" and (config.Name or config.Title or config.Text) or config
        warn("[BPUI] Failed to create " .. methodName:gsub("^Add", "") .. " '" .. tostring(label) .. "': " .. tostring(result))
        return DummyElement(methodName:gsub("^Add", ""), label)
    end
end
SectionClass.CreateButton = SectionClass.AddButton
SectionClass.CreateToggle = SectionClass.AddToggle
SectionClass.CreateSlider = SectionClass.AddSlider
SectionClass.CreateDropdown = SectionClass.AddDropdown
SectionClass.CreateInput = SectionClass.AddInput
SectionClass.AddTextbox = SectionClass.AddInput
SectionClass.CreateTextbox = SectionClass.AddInput
SectionClass.CreateKeybind = SectionClass.AddKeybind
SectionClass.CreateColorPicker = SectionClass.AddColorPicker
SectionClass.AddColorpicker = SectionClass.AddColorPicker
SectionClass.CreateColorpicker = SectionClass.AddColorPicker
SectionClass.CreateLabel = SectionClass.AddLabel
SectionClass.CreateParagraph = SectionClass.AddParagraph
SectionClass.CreateDivider = SectionClass.AddDivider

-- Elements can also be added straight to a tab (auto section without a title)
for _, methodName in ipairs({
    "AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput", "AddTextbox",
    "AddKeybind", "AddColorPicker", "AddColorpicker", "AddLabel", "AddParagraph", "AddDivider",
    "CreateButton", "CreateToggle", "CreateSlider", "CreateDropdown", "CreateInput", "CreateTextbox",
    "CreateKeybind", "CreateColorPicker", "CreateColorpicker", "CreateLabel", "CreateParagraph", "CreateDivider",
}) do
    TabClass[methodName] = function(tab, ...)
        local section = tab:_DefaultSection()
        return section[methodName](section, ...)
    end
end

---------------------------------------------------------------------
-- Configuration (flags -> JSON). Every file call is optional/guarded.
---------------------------------------------------------------------
local function EncodeJSON(data)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if ok then
        return result
    end
    return nil
end

local function DecodeJSON(text)
    local ok, result = pcall(function()
        return HttpService:JSONDecode(text)
    end)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local function SerializeElement(element)
    local elementType = element.Type
    if elementType == "ColorPicker" then
        local c = element.Value
        if typeof(c) == "Color3" then
            return {
                R = math.floor(c.R * 255 + 0.5),
                G = math.floor(c.G * 255 + 0.5),
                B = math.floor(c.B * 255 + 0.5),
            }
        end
        return nil
    elseif elementType == "Toggle" or elementType == "Slider" or elementType == "Dropdown"
        or elementType == "Input" or elementType == "Keybind" then
        return element.Value
    end
    return nil
end

local function ApplyValue(element, value)
    if type(element.Set) ~= "function" then
        return
    end
    pcall(function()
        if element.Type == "ColorPicker" then
            local c = ToColor3(value)
            if c then
                element:Set(c)
            end
        else
            element:Set(value)
        end
    end)
end

function WindowClass:_EnsureFolders()
    FS.EnsureFolder(self._rootPath)
    FS.EnsureFolder(self._folderPath)
    FS.EnsureFolder(self._configPath)
end

function WindowClass:_LoadSettings()
    local data = {}
    if not FS.Available then
        return data
    end
    local raw = FS.Read(self._folderPath .. "/settings.json")
    if raw then
        data = DecodeJSON(raw) or {}
    end
    return data
end

function WindowClass:_SaveSettings()
    if not FS.Available or self._destroyed then
        return false
    end
    local accent = Theme.Accent
    local data = {
        Theme = BPUI.ThemeName,
        Accent = {
            R = math.floor(accent.R * 255 + 0.5),
            G = math.floor(accent.G * 255 + 0.5),
            B = math.floor(accent.B * 255 + 0.5),
        },
        ToggleKey = self.ToggleKey.Name,
        FloatingButton = self.FloatingButton.Visible,
        Width = self.Width,
        Height = self.Height,
    }
    local json = EncodeJSON(data)
    if not json then
        return false
    end
    self:_EnsureFolders()
    return FS.Write(self._folderPath .. "/settings.json", json)
end

function WindowClass:_SaveSettingsDebounced()
    if self._settingsSaveQueued then
        return
    end
    self._settingsSaveQueued = true
    task.delay(0.6, function()
        self._settingsSaveQueued = false
        self:_SaveSettings()
    end)
end

function WindowClass:_ApplyPending(element)
    if not self._pending or not element.Flag then
        return
    end
    local value = self._pending[element.Flag]
    if value ~= nil then
        ApplyValue(element, value)
    end
end

function WindowClass:SaveConfig(name)
    name = SanitizeName(name or "default")
    if not FS.Available then
        BPUI:Notify({ Title = "Configuration", Content = "Your executor does not support saving files.", Type = "Warning" })
        return false
    end

    local data = {}
    for flag, element in pairs(BPUI.Flags) do
        if element.Window == self then
            local value = SerializeElement(element)
            if value ~= nil then
                data[flag] = value
            end
        end
    end

    local json = EncodeJSON(data)
    if not json then
        return false
    end
    self:_EnsureFolders()
    local written = FS.Write(self._configPath .. "/" .. name .. ".json", json)
    if written then
        BPUI:Notify({ Title = "Configuration", Content = "Saved config '" .. name .. "'.", Type = "Success" })
    else
        BPUI:Notify({ Title = "Configuration", Content = "Could not write the config file.", Type = "Error" })
    end
    return written
end
WindowClass.SaveConfiguration = WindowClass.SaveConfig

function WindowClass:LoadConfig(name, quiet)
    name = SanitizeName(name or "default")
    if not FS.Available then
        if not quiet then
            BPUI:Notify({ Title = "Configuration", Content = "Your executor does not support reading files.", Type = "Warning" })
        end
        return false
    end

    local raw = FS.Read(self._configPath .. "/" .. name .. ".json")
    if not raw then
        if not quiet then
            BPUI:Notify({ Title = "Configuration", Content = "Config '" .. name .. "' was not found.", Type = "Error" })
        end
        return false
    end

    local data = DecodeJSON(raw)
    if not data then
        if not quiet then
            BPUI:Notify({ Title = "Configuration", Content = "Config '" .. name .. "' is corrupted.", Type = "Error" })
        end
        return false
    end

    -- remembered so elements created later still receive their value
    self._pending = data
    for flag, value in pairs(data) do
        local element = BPUI.Flags[flag]
        if element and element.Window == self then
            ApplyValue(element, value)
        end
    end
    if not quiet then
        BPUI:Notify({ Title = "Configuration", Content = "Loaded config '" .. name .. "'.", Type = "Success" })
    end
    return true
end
WindowClass.LoadConfiguration = WindowClass.LoadConfig

function WindowClass:GetConfigs()
    local names = {}
    if not FS.Available then
        return names
    end
    for _, path in ipairs(FS.List(self._configPath)) do
        local fileName = tostring(path):match("([^/\\]+)%.json$")
        if fileName then
            names[#names + 1] = fileName
        end
    end
    table.sort(names)
    return names
end

function WindowClass:DeleteConfig(name)
    name = SanitizeName(name or "")
    if name == "" then
        return false
    end
    local ok = FS.Delete(self._configPath .. "/" .. name .. ".json")
    if ok then
        BPUI:Notify({ Title = "Configuration", Content = "Deleted config '" .. name .. "'.", Type = "Success" })
    end
    return ok
end

function WindowClass:GetAutoLoad()
    local raw = FS.Read(self._folderPath .. "/autoload.txt")
    if raw then
        raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if raw ~= "" then
            return raw
        end
    end
    return nil
end

function WindowClass:SetAutoLoad(name)
    if not FS.Available then
        return false
    end
    self:_EnsureFolders()
    if name and name ~= "" then
        return FS.Write(self._folderPath .. "/autoload.txt", SanitizeName(name))
    end
    return FS.Write(self._folderPath .. "/autoload.txt", "")
end

function WindowClass:LoadAutoConfig()
    local name = self:GetAutoLoad()
    if name and FS.Exists(self._configPath .. "/" .. name .. ".json") then
        return self:LoadConfig(name, true)
    end
    return false
end
WindowClass.LoadAutoConfiguration = WindowClass.LoadAutoConfig

---------------------------------------------------------------------
-- Built-in Settings tab
---------------------------------------------------------------------
function WindowClass:_BuildSettingsTab(config)
    -- thin separator line above the settings tab
    local spacer = Create("Frame", {
        Name = "SettingsSeparator",
        Size = UDim2.new(1, 0, 0, 9),
        BackgroundTransparency = 1,
        LayoutOrder = 99999,
        Parent = self.TabList,
    })
    local line = Create("Frame", {
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.new(1, -8, 0, 1),
        BackgroundColor3 = Theme.Separator,
        Parent = spacer,
    })
    Bind(line, "BackgroundColor3", "Separator")

    local Tab = self:CreateTab({
        Name = tostring(config.SettingsName or "Settings"),
        Icon = config.SettingsIcon,
        _internal = true,
        _order = 100000,
    })
    self.SettingsTab = Tab

    local Interface = Tab:CreateSection("Interface")

    local toggleBind
    toggleBind = Interface:AddKeybind({
        Name = "Toggle Key",
        Description = "Press to show or hide the interface",
        Default = self.ToggleKey,
        Mode = "None",
        OnChanged = function(key)
            if key == "None" or not ToKeyCode(key) then
                BPUI:Notify({ Title = "Toggle Key", Content = "Only keyboard keys can toggle the interface.", Type = "Warning" })
                if toggleBind then
                    toggleBind:Set(self.ToggleKey, true)
                end
                return
            end
            self:SetToggleKey(key)
        end,
    })

    local themeNames = {}
    for themeName in pairs(BPUI.Themes) do
        themeNames[#themeNames + 1] = themeName
    end
    table.sort(themeNames)

    local accentPicker
    Interface:AddDropdown({
        Name = "Theme",
        Options = themeNames,
        Default = BPUI.ThemeName,
        Callback = function(value)
            if BPUI:SetTheme(value) and accentPicker then
                accentPicker:Set(Theme.Accent, true)
                self:_SaveSettingsDebounced()
            end
        end,
    })

    accentPicker = Interface:AddColorPicker({
        Name = "Accent Color",
        Description = "Used for highlights and buttons",
        Default = Theme.Accent,
        Callback = function(color)
            BPUI:SetAccent(color)
            self:_SaveSettingsDebounced()
        end,
    })

    Interface:AddToggle({
        Name = "Floating Button",
        Description = "Draggable bubble that opens or closes the UI",
        Default = self.FloatingButton.Visible,
        Callback = function(state)
            self.FloatingButton.Visible = state
            self:_SaveSettingsDebounced()
        end,
    })

    local Configs = Tab:CreateSection("Configuration")
    if FS.Available then
        local nameInput = Configs:AddInput({
            Name = "Config Name",
            Placeholder = "default",
            Default = "default",
        })

        local configList
        local function RefreshList()
            configList:Refresh(self:GetConfigs(), true)
        end

        Configs:AddButton({
            Name = "Save Config",
            Description = "Writes every flagged element to the name above",
            Callback = function()
                local name = nameInput.Value
                if name == nil or name == "" then
                    name = "default"
                end
                if self:SaveConfig(name) then
                    RefreshList()
                    configList:Set(SanitizeName(name), true)
                end
            end,
        })

        configList = Configs:AddDropdown({
            Name = "Saved Configs",
            Options = self:GetConfigs(),
            Default = self:GetAutoLoad(),
        })

        Configs:AddButton({
            Name = "Load Selected",
            Callback = function()
                if configList.Value then
                    self:LoadConfig(configList.Value)
                else
                    BPUI:Notify({ Title = "Configuration", Content = "Select a config first.", Type = "Warning" })
                end
            end,
        })

        Configs:AddButton({
            Name = "Refresh List",
            Callback = RefreshList,
        })

        if IsFunction(delfile) then
            Configs:AddButton({
                Name = "Delete Selected",
                Callback = function()
                    if configList.Value then
                        self:DeleteConfig(configList.Value)
                        RefreshList()
                    end
                end,
            })
        end

        Configs:AddToggle({
            Name = "Auto Load",
            Description = "Load the selected config on startup",
            Default = self:GetAutoLoad() ~= nil,
            Callback = function(state)
                if state then
                    if configList.Value then
                        self:SetAutoLoad(configList.Value)
                    else
                        BPUI:Notify({ Title = "Configuration", Content = "Select a config to auto load.", Type = "Warning" })
                    end
                else
                    self:SetAutoLoad(nil)
                end
            end,
        })
    else
        Configs:AddParagraph({
            Title = "Unavailable",
            Content = "Your executor does not support file saving, so configs are disabled. Everything else works normally.",
        })
    end

    local About = Tab:CreateSection("About")
    About:AddParagraph({
        Title = self.Title,
        Content = "Built with BPUI v" .. BPUI.Version .. " - an iOS-style interface library.\nPlatform: "
            .. (IsMobile and "Mobile" or "PC")
            .. "   |   File saving: " .. (FS.Available and "Supported" or "Not supported"),
    })
    About:AddButton({
        Name = "Unload Interface",
        Description = "Removes the UI completely",
        Callback = function()
            self:Dialog({
                Title = "Unload " .. self.Title .. "?",
                Content = "The interface will be removed. Re-execute the script to bring it back.",
                Buttons = {
                    { Text = "Cancel" },
                    { Text = "Unload", Style = "Danger", Callback = function()
                        self:Destroy()
                    end },
                },
            })
        end,
    })
end

---------------------------------------------------------------------
-- Library level helpers
---------------------------------------------------------------------
function BPUI:GetFlag(flag)
    local element = self.Flags[flag]
    if element then
        return element.Value
    end
    return nil
end

function BPUI:SetFlag(flag, value, silent)
    local element = self.Flags[flag]
    if element and type(element.Set) == "function" then
        element:Set(value, silent)
        return true
    end
    return false
end

function BPUI:Destroy()
    for i = #self.Windows, 1, -1 do
        pcall(function()
            self.Windows[i]:Destroy()
        end)
    end
    DisconnectAll(self._connections)
    pcall(function()
        if self._gui then
            self._gui:Destroy()
        end
    end)
    self._gui = nil
    self._notifyHolder = nil
end
BPUI.Unload = BPUI.Destroy

return BPUI
