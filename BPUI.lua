local BPUI = {
    Version = "2.3.0",
    SafeMode = true,
    Flags = {},
    Windows = {},
    Themes = {},
    IsMobile = false,
    _listeners = {},
    _pendingFlags = {},
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function viewport()
    local ok, cam = pcall(function() return workspace.CurrentCamera end)
    if ok and cam then
        local ok2, size = pcall(function() return cam.ViewportSize end)
        if ok2 and size and size.X > 0 then return size end
    end
    local ok3, ws = pcall(function() return game:GetService("Workspace") end)
    if ok3 and ws then
        local ok4, size = pcall(function() return ws.CurrentCamera.ViewportSize end)
        if ok4 and size and size.X > 0 then return size end
    end
    return Vector2.new(1280, 720)
end

local uidCounter = 0
local function uid()
    uidCounter = uidCounter + 1
    local ok, guid = pcall(function()
        return HttpService:GenerateGUID(false):sub(1, 8)
    end)
    if ok and guid then return guid end
    return string.format("%04X%04X", math.random(0, 65535), uidCounter % 65536)
end

local function env()
    local ok, g = pcall(function() return getgenv() end)
    if ok and type(g) == "table" then return g end
    return _G
end
local ENV = env()

local FS = { Available = false }
do
    if type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" then
        FS.Available = true
        FS.write = function(p, d) return (pcall(writefile, p, d)) end
        FS.read = function(p) local s, r = pcall(readfile, p) if s then return r end end
        FS.exists = function(p) local s, r = pcall(isfile, p) return s and r end
        FS.folder = function(p)
            if type(makefolder) == "function" then
                local s, r = pcall(isfolder, p)
                if not (s and r) then pcall(makefolder, p) end
            end
        end
        FS.list = function(p)
            if type(listfiles) == "function" then
                local s, r = pcall(listfiles, p)
                if s then return r end
            end
            return {}
        end
        FS.delete = function(p)
            if type(delfile) == "function" then return pcall(delfile, p) end
            return false
        end
    end
end
BPUI.FileSystem = FS

local function clipboard(text)
    if type(setclipboard) == "function" then return pcall(setclipboard, text) end
    if type(toclipboard) == "function" then return pcall(toclipboard, text) end
    return false
end
BPUI.CopyToClipboard = clipboard

local function guiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then
        local can = pcall(function() local t = Instance.new("Folder") t.Parent = core t:Destroy() end)
        if can then return core end
    end
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled
BPUI.IsMobile = IS_MOBILE

local function pickFont(names, fallback)
    for _, n in ipairs(names) do
        local ok, f = pcall(function() return Enum.Font[n] end)
        if ok and f then return f end
    end
    return fallback
end

local FONT = {
    bold   = pickFont({ "BuilderSansBold", "GothamBold" }, Enum.Font.SourceSansBold),
    medium = pickFont({ "BuilderSansMedium", "GothamMedium" }, Enum.Font.SourceSansSemibold),
    body   = pickFont({ "BuilderSans", "Gotham" }, Enum.Font.SourceSans),
    mono   = pickFont({ "RobotoMono", "Code" }, Enum.Font.Code),
}

local RADIUS = { xs = 3, sm = 6, md = 8, lg = 10, xl = 12, pill = 999 }

local MOTION = {
    hover    = TweenInfo.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    press    = TweenInfo.new(0.06, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    release  = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    quick    = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    standard = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    page     = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    reveal   = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    ripple   = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

BPUI.Themes.Nocturne = {
    Name = "Nocturne",
    Window       = rgb(17, 18, 24),
    Sidebar      = rgb(13, 14, 19),
    TitleBar     = rgb(13, 14, 19),
    Surface      = rgb(24, 26, 34),
    SurfaceHover = rgb(30, 33, 43),
    Element      = rgb(33, 36, 47),
    ElementHover = rgb(41, 45, 58),
    Stroke       = rgb(40, 44, 58),
    StrokeSoft   = rgb(32, 35, 46),
    Text         = rgb(240, 242, 250),
    SubText      = rgb(170, 176, 196),
    Muted        = rgb(112, 118, 140),
    Accent       = rgb(112, 140, 255),
    AccentText   = rgb(255, 255, 255),
    Success      = rgb(84, 214, 150),
    Warning      = rgb(252, 196, 92),
    Danger       = rgb(255, 112, 128),
    Track        = rgb(52, 56, 72),
    KnobOn       = rgb(255, 255, 255),
    KnobOff      = rgb(176, 182, 202),
    Dark         = true,
}

BPUI.Themes.FluentDark = {
    Name = "FluentDark",
    Window       = rgb(39, 39, 39),
    Sidebar      = rgb(32, 32, 32),
    TitleBar     = rgb(32, 32, 32),
    Surface      = rgb(45, 45, 45),
    SurfaceHover = rgb(52, 52, 52),
    Element      = rgb(58, 58, 58),
    ElementHover = rgb(66, 66, 66),
    Stroke       = rgb(62, 62, 62),
    StrokeSoft   = rgb(54, 54, 54),
    Text         = rgb(255, 255, 255),
    SubText      = rgb(200, 200, 200),
    Muted        = rgb(148, 148, 148),
    Accent       = rgb(96, 205, 255),
    AccentText   = rgb(0, 0, 0),
    Success      = rgb(108, 203, 95),
    Warning      = rgb(252, 201, 90),
    Danger       = rgb(255, 153, 164),
    Track        = rgb(80, 80, 80),
    KnobOn       = rgb(0, 0, 0),
    KnobOff      = rgb(205, 205, 205),
    Dark         = true,
}

BPUI.Themes.FluentLight = {
    Name = "FluentLight",
    Window       = rgb(243, 243, 243),
    Sidebar      = rgb(238, 238, 238),
    TitleBar     = rgb(238, 238, 238),
    Surface      = rgb(251, 251, 251),
    SurfaceHover = rgb(246, 246, 246),
    Element      = rgb(255, 255, 255),
    ElementHover = rgb(249, 249, 249),
    Stroke       = rgb(226, 226, 226),
    StrokeSoft   = rgb(235, 235, 235),
    Text         = rgb(26, 26, 26),
    SubText      = rgb(95, 95, 95),
    Muted        = rgb(138, 138, 138),
    Accent       = rgb(0, 103, 192),
    AccentText   = rgb(255, 255, 255),
    Success      = rgb(15, 123, 15),
    Warning      = rgb(157, 93, 0),
    Danger       = rgb(196, 43, 28),
    Track        = rgb(134, 134, 134),
    KnobOn       = rgb(255, 255, 255),
    KnobOff      = rgb(90, 90, 90),
    Dark         = false,
}

BPUI.Themes.Obsidian = {
    Name = "Obsidian",
    Window       = rgb(22, 22, 24),
    Sidebar      = rgb(16, 16, 18),
    TitleBar     = rgb(16, 16, 18),
    Surface      = rgb(29, 29, 32),
    SurfaceHover = rgb(36, 36, 40),
    Element      = rgb(40, 40, 45),
    ElementHover = rgb(48, 48, 54),
    Stroke       = rgb(46, 46, 51),
    StrokeSoft   = rgb(38, 38, 42),
    Text         = rgb(248, 248, 250),
    SubText      = rgb(186, 188, 196),
    Muted        = rgb(132, 134, 143),
    Accent       = rgb(120, 170, 255),
    AccentText   = rgb(8, 12, 22),
    Success      = rgb(94, 214, 142),
    Warning      = rgb(252, 195, 88),
    Danger       = rgb(255, 122, 132),
    Track        = rgb(62, 62, 70),
    KnobOn       = rgb(8, 12, 22),
    KnobOff      = rgb(198, 200, 208),
    Dark         = true,
}

BPUI.Themes.Midnight = {
    Name = "Midnight",
    Window       = rgb(24, 30, 42),
    Sidebar      = rgb(18, 23, 33),
    TitleBar     = rgb(18, 23, 33),
    Surface      = rgb(31, 39, 54),
    SurfaceHover = rgb(38, 48, 66),
    Element      = rgb(43, 54, 74),
    ElementHover = rgb(51, 64, 87),
    Stroke       = rgb(50, 63, 86),
    StrokeSoft   = rgb(40, 50, 69),
    Text         = rgb(238, 244, 255),
    SubText      = rgb(176, 190, 214),
    Muted        = rgb(124, 140, 167),
    Accent       = rgb(118, 168, 255),
    AccentText   = rgb(8, 14, 28),
    Success      = rgb(86, 214, 156),
    Warning      = rgb(250, 196, 96),
    Danger       = rgb(255, 128, 140),
    Track        = rgb(60, 74, 100),
    KnobOn       = rgb(8, 14, 28),
    KnobOff      = rgb(196, 208, 226),
    Dark         = true,
}

BPUI.Themes.Nord = {
    Name = "Nord",
    Window       = rgb(46, 52, 64),
    Sidebar      = rgb(38, 43, 54),
    TitleBar     = rgb(38, 43, 54),
    Surface      = rgb(56, 63, 77),
    SurfaceHover = rgb(64, 72, 88),
    Element      = rgb(67, 76, 94),
    ElementHover = rgb(76, 86, 106),
    Stroke       = rgb(72, 81, 99),
    StrokeSoft   = rgb(60, 68, 83),
    Text         = rgb(236, 239, 244),
    SubText      = rgb(191, 199, 213),
    Muted        = rgb(143, 154, 173),
    Accent       = rgb(136, 192, 208),
    AccentText   = rgb(24, 29, 38),
    Success      = rgb(163, 190, 140),
    Warning      = rgb(235, 203, 139),
    Danger       = rgb(191, 97, 106),
    Track        = rgb(80, 90, 110),
    KnobOn       = rgb(24, 29, 38),
    KnobOff      = rgb(216, 222, 233),
    Dark         = true,
}

BPUI.Themes.Crimson = {
    Name = "Crimson",
    Window       = rgb(38, 30, 32),
    Sidebar      = rgb(30, 23, 25),
    TitleBar     = rgb(30, 23, 25),
    Surface      = rgb(47, 37, 39),
    SurfaceHover = rgb(56, 44, 47),
    Element      = rgb(60, 47, 50),
    ElementHover = rgb(70, 55, 58),
    Stroke       = rgb(66, 52, 55),
    StrokeSoft   = rgb(54, 42, 45),
    Text         = rgb(250, 242, 242),
    SubText      = rgb(206, 190, 191),
    Muted        = rgb(154, 138, 140),
    Accent       = rgb(255, 122, 132),
    AccentText   = rgb(32, 10, 14),
    Success      = rgb(126, 208, 142),
    Warning      = rgb(250, 194, 102),
    Danger       = rgb(255, 122, 132),
    Track        = rgb(82, 64, 68),
    KnobOn       = rgb(32, 10, 14),
    KnobOff      = rgb(224, 210, 211),
    Dark         = true,
}

local ACTIVE = BPUI.Themes.Nocturne

local function resolveTheme(v)
    local merged = {}
    for k, val in pairs(BPUI.Themes.Nocturne) do merged[k] = val end
    local source
    if type(v) == "string" and BPUI.Themes[v] then source = BPUI.Themes[v]
    elseif type(v) == "table" then source = v end
    if source then
        for k, val in pairs(source) do merged[k] = val end
    end
    if type(v) == "string" then merged.Name = v end
    return merged
end

local function shallowCopy(t)
    local out = {}
    if type(t) ~= "table" then return out end
    for i, v in ipairs(t) do out[i] = v end
    return out
end

local function new(class, props, kids)
    local inst = Instance.new(class)
    local parent
    if props then
        parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do inst[k] = v end
        props.Parent = parent
    end
    if kids then
        for _, k in ipairs(kids) do if k then k.Parent = inst end end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(parent, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or RADIUS.md), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function pad(parent, t, r, b, l)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft = UDim.new(0, l or r or t or 0),
        Parent = parent,
    })
end

local function list(parent, padding, dir)
    return new("UIListLayout", {
        Padding = UDim.new(0, padding or 0),
        FillDirection = dir or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function sheen(parent, topAlpha, _unused, rotation)
    local strength = math.clamp(1 - (topAlpha or 0.94), 0, 0.35)
    local lo = 1 - strength
    return new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(lo, lo, lo)),
        }),
        Rotation = rotation or 90,
        Parent = parent,
    })
end

local function edgeLight(strokeInst, theme)
    local top = theme.Dark and 0.42 or 0.6
    return new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, top),
            NumberSequenceKeypoint.new(0.6, 0.85),
            NumberSequenceKeypoint.new(1, 0.92),
        }),
        Rotation = 90,
        Parent = strokeInst,
    })
end

local function dropShadow(parent, spread, radius, alpha, zindex)
    spread = spread or 18
    radius = radius or RADIUS.lg
    alpha = alpha or 0.82
    local layers = 5
    local holder = new("Frame", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, spread * 2, 1, spread * 2),
        Position = UDim2.new(0, -spread, 0, -spread + math.floor(spread * 0.25)),
        ZIndex = zindex or 0,
        Parent = parent,
    })
    for i = 1, layers do
        local f = (i - 1) / (layers - 1)
        local inset = spread * f
        local layer = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.985 + (alpha - 0.985) * f,
            BorderSizePixel = 0,
            Position = UDim2.new(0, inset, 0, inset),
            Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
            ZIndex = zindex or 0,
            Parent = holder,
        })
        corner(layer, radius + (spread - inset) * 0.6)
    end
    return holder
end

local function tw(obj, info, props)
    if not obj or not obj.Parent then return end
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function tween(obj, props, info)
    return tw(obj, info or MOTION.standard, props)
end

local function closeOpenPanel(except)
    local open = BPUI._openPanel
    if open and open ~= except and not open._destroyed and open.Close then
        pcall(function() open:Close() end)
    end
    if open ~= except then BPUI._openPanel = nil end
end

local function effectiveScale(inst)
    local s = 1
    local node = inst
    while node and node ~= game do
        if node:IsA("GuiObject") then
            local us = node:FindFirstChildOfClass("UIScale")
            if us then s = s * us.Scale end
        end
        node = node.Parent
    end
    return s
end

local function autoSlot(parent, opts)
    opts = opts or {}
    local minH = opts.MinHeight or 0
    local slot = new("Frame", {
        Name = opts.Name or "Slot",
        BackgroundTransparency = 1,
        AnchorPoint = opts.AnchorPoint or Vector2.new(0, 0),
        Position = opts.Position or UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(opts.WidthScale or 1, opts.WidthOffset or 0, 0, minH),
        AutomaticSize = Enum.AutomaticSize.None,
        LayoutOrder = opts.LayoutOrder or 0,
        ZIndex = opts.ZIndex or 1,
        Parent = parent,
    })
    local card = new("Frame", {
        Name = "Card",
        BackgroundColor3 = opts.Color or Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, minH),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = opts.Clip ~= false,
        ZIndex = (opts.ZIndex or 1) + 1,
        Parent = slot,
    })
    local function sync()
        local h = card.AbsoluteSize.Y / math.max(effectiveScale(card), 0.01)
        if h > 0 and math.abs(h - slot.Size.Y.Offset) > 0.5 then
            slot.Size = UDim2.new(slot.Size.X.Scale, slot.Size.X.Offset, 0, h)
        end
    end
    local conn = card:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
    task.defer(sync)
    return slot, card, conn
end

local function isAssetIcon(v)
    if type(v) == "number" then return true end
    if type(v) ~= "string" then return false end
    if v:match("^rbxasset") then return true end
    return v:match("^%s*%d+%s*$") ~= nil
end

local function iconAny(parent, icon, size, color, zindex)
    if icon == nil or icon == "" then return nil, nil end
    if isAssetIcon(icon) then
        local img = tostring(icon)
        if not img:match("^rbxasset") then img = "rbxassetid://" .. img:gsub("%D", "") end
        local i = new("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Image = img,
            ImageColor3 = color,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, size, 0, size),
            ZIndex = zindex or 5,
            Parent = parent,
        })
        return i, "image"
    end
    local t = new("TextLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(icon),
        Font = Enum.Font.GothamMedium,
        TextSize = math.floor(size * 0.92),
        TextColor3 = color,
        TextScaled = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size + 6, 0, size + 6),
        ZIndex = zindex or 5,
        Parent = parent,
    })
    return t, "text"
end

local function accentGlow(parent, color, spread, alpha, zindex)
    local holder = new("Frame", {
        Name = "Glow",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, spread * 2, 1, spread * 2),
        ZIndex = zindex or 0,
        Parent = parent,
    })
    local layers = 4
    for i = 1, layers do
        local f = (i - 1) / (layers - 1)
        local inset = spread * f
        local l = new("Frame", {
            BackgroundColor3 = color,
            BackgroundTransparency = 0.985 + (alpha - 0.985) * f,
            BorderSizePixel = 0,
            Position = UDim2.new(0, inset, 0, inset),
            Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
            ZIndex = zindex or 0,
            Parent = holder,
        })
        corner(l, RADIUS.pill)
    end
    return holder
end

local function iconHolder(parent, size, zindex)
    return new("Frame", {
        Name = "Icon",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size, 0, size),
        ZIndex = zindex or 5,
        Parent = parent,
    })
end

local function bar(parent, w, h, rot, color, zindex, anchor, posX, posY)
    local f = new("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = anchor or Vector2.new(0.5, 0.5),
        Position = UDim2.new(posX or 0.5, 0, posY or 0.5, 0),
        Size = UDim2.new(0, w, 0, h),
        Rotation = rot or 0,
        ZIndex = zindex or 5,
        Parent = parent,
    })
    corner(f, h / 2)
    return f
end

local function tintIcon(holder, color)
    if not holder then return end
    for _, c in ipairs(holder:GetChildren()) do
        if c:IsA("Frame") then
            c.BackgroundColor3 = color
            local s = c:FindFirstChildOfClass("UIStroke")
            if s then s.Color = color end
        elseif c:IsA("UIStroke") then
            c.Color = color
        end
    end
    local s = holder:FindFirstChildOfClass("UIStroke")
    if s then s.Color = color end
end

local function iconClose(parent, size, color, zindex)
    local h = iconHolder(parent, size, zindex)
    bar(h, size * 0.92, 1.4, 45, color, zindex)
    bar(h, size * 0.92, 1.4, -45, color, zindex)
    return h
end

local function iconMinimize(parent, size, color, zindex)
    local h = iconHolder(parent, size, zindex)
    bar(h, size * 0.86, 1.4, 0, color, zindex)
    return h
end

local function iconChevron(parent, size, color, rotation, zindex)
    local h = iconHolder(parent, size, zindex)
    h.Rotation = rotation or 0
    local len = size * 0.52
    bar(h, len, 1.5, 45, color, zindex, Vector2.new(0.5, 0.5), 0.44, 0.32)
    bar(h, len, 1.5, -45, color, zindex, Vector2.new(0.5, 0.5), 0.44, 0.68)
    return h
end

local function iconCheck(parent, size, color, zindex)
    local h = iconHolder(parent, size, zindex)
    bar(h, size * 0.40, 1.7, 45, color, zindex, Vector2.new(0.5, 0.5), 0.29, 0.65)
    bar(h, size * 0.66, 1.7, -48, color, zindex, Vector2.new(0.5, 0.5), 0.64, 0.54)
    return h
end

local function iconSearch(parent, size, color, zindex)
    local h = iconHolder(parent, size, zindex)
    local ring = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, size * 0.66, 0, size * 0.66),
        ZIndex = zindex or 5,
        Parent = h,
    })
    corner(ring, RADIUS.pill)
    stroke(ring, color, 1.4, 0)
    bar(h, size * 0.34, 1.4, 45, color, zindex, Vector2.new(0.5, 0.5), 0.68, 0.68)
    return h
end

local function fadeIcon(holder, transparency, info)
    if not holder then return end
    for _, c in ipairs(holder:GetChildren()) do
        if c:IsA("Frame") then
            tw(c, info or MOTION.quick, { BackgroundTransparency = transparency })
        end
    end
end

local function iconDot(parent, size, color, zindex)
    local h = iconHolder(parent, size, zindex)
    local d = new("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size * 0.42, 0, size * 0.42),
        ZIndex = zindex or 5,
        Parent = h,
    })
    corner(d, RADIUS.pill)
    return h
end
local function bind(owner, inst, prop, key)
    if not owner or not inst then return end
    owner._bindings = owner._bindings or {}
    for i = #owner._bindings, 1, -1 do
        local b = owner._bindings[i]
        if b.inst == inst and b.prop == prop then table.remove(owner._bindings, i) end
    end
    table.insert(owner._bindings, { inst = inst, prop = prop, key = key })
    if ACTIVE[key] then inst[prop] = ACTIVE[key] end
end

local function applyBindings(owner, theme)
    if not owner or not owner._bindings then return end
    for i = #owner._bindings, 1, -1 do
        local b = owner._bindings[i]
        if b.inst and b.inst.Parent then
            local v = theme[b.key]
            if v then pcall(function() b.inst[b.prop] = v end) end
        else
            table.remove(owner._bindings, i)
        end
    end
end

local function track(owner, connection)
    if not owner then return connection end
    owner._connections = owner._connections or {}
    table.insert(owner._connections, connection)
    return connection
end

local function untrack(owner)
    if not owner or not owner._connections then return end
    for _, c in ipairs(owner._connections) do pcall(function() c:Disconnect() end) end
    owner._connections = {}
end

local function isClick(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function ripple(host, input, color, alpha)
    if not host or not host.Parent then return end
    local ok = pcall(function()
        local abs = host.AbsolutePosition
        local size = host.AbsoluteSize
        local px, py = size.X * 0.5, size.Y * 0.5
        if input and input.Position then
            px = input.Position.X - abs.X
            py = input.Position.Y - abs.Y
        end
        local radius = math.max(
            math.sqrt(px * px + py * py),
            math.sqrt((size.X - px) ^ 2 + py * py),
            math.sqrt(px * px + (size.Y - py) ^ 2),
            math.sqrt((size.X - px) ^ 2 + (size.Y - py) ^ 2)
        ) * 2

        local circle = new("Frame", {
            Name = "Ripple",
            BackgroundColor3 = color or Color3.new(1, 1, 1),
            BackgroundTransparency = alpha or 0.86,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, px, 0, py),
            Size = UDim2.new(0, 0, 0, 0),
            ZIndex = (host.ZIndex or 1) + 1,
            Parent = host,
        })
        corner(circle, RADIUS.pill)

        tw(circle, MOTION.ripple, { Size = UDim2.new(0, radius, 0, radius) })
        local fade = tw(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
        if fade then
            fade.Completed:Connect(function() circle:Destroy() end)
        else
            task.delay(0.6, function() if circle then circle:Destroy() end end)
        end
    end)
    return ok
end

local function hoverable(owner, host, target, restKey, hoverKey, extra)
    if IS_MOBILE then return end
    track(owner, host.MouseEnter:Connect(function()
        if owner and owner._locked then return end
        tween(target, { BackgroundColor3 = ACTIVE[hoverKey] }, MOTION.hover)
        if extra and extra.onEnter then extra.onEnter() end
    end))
    track(owner, host.MouseLeave:Connect(function()
        tween(target, { BackgroundColor3 = ACTIVE[restKey] }, MOTION.hover)
        if extra and extra.onLeave then extra.onLeave() end
    end))
end

local function pressable(owner, host, scaleTarget, onActivate, opts)
    opts = opts or {}
    local scale
    if scaleTarget then
        scale = scaleTarget:FindFirstChildOfClass("UIScale") or new("UIScale", { Scale = 1, Parent = scaleTarget })
    end
    local down = false
    track(owner, host.InputBegan:Connect(function(input)
        if not isClick(input) then return end
        if owner and owner._locked then return end
        down = true
        if scale then tw(scale, MOTION.press, { Scale = opts.pressScale or 0.975 }) end
        if opts.ripple ~= false then ripple(host, input, opts.rippleColor, opts.rippleAlpha) end
    end))
    track(owner, host.InputEnded:Connect(function(input)
        if not isClick(input) then return end
        if scale then tw(scale, MOTION.release, { Scale = 1 }) end
        if down and not (owner and owner._locked) and onActivate then
            down = false
            task.spawn(onActivate)
        end
        down = false
    end))
    track(owner, UserInputService.InputEnded:Connect(function(input)
        if isClick(input) and down then
            down = false
            if scale then tw(scale, MOTION.release, { Scale = 1 }) end
        end
    end))
end

local function ancestorScrolling(inst, state)
    local node = inst
    local touched = {}
    while node and node ~= game do
        if node:IsA("ScrollingFrame") then
            table.insert(touched, node)
            node.ScrollingEnabled = state
        end
        node = node.Parent
    end
    return touched
end

local function ownsInput(active, input)
    if not active then return false end
    if input == active then return true end
    return active.UserInputType == Enum.UserInputType.MouseButton1
       and input.UserInputType == Enum.UserInputType.MouseButton1
end

local function tracksInput(active, input)
    if not active then return false end
    if input == active then return true end
    return active.UserInputType == Enum.UserInputType.MouseButton1
       and input.UserInputType == Enum.UserInputType.MouseMovement
end

local function draggable(owner, handle, target, opts)
    opts = opts or {}
    local dragging, startPos, startOffset = false, nil, nil
    local scrolls, activeInput

    track(owner, handle.InputBegan:Connect(function(input)
        if not isClick(input) or dragging then return end
        dragging = true
        activeInput = input
        startPos = input.Position
        startOffset = target.Position
        scrolls = ancestorScrolling(handle, false)
        if opts.onStart then opts.onStart() end
    end))

    local function stop()
        if not dragging then return end
        dragging = false
        activeInput = nil
        if scrolls then
            for _, s in ipairs(scrolls) do pcall(function() s.ScrollingEnabled = true end) end
            scrolls = nil
        end
        if opts.onStop then opts.onStop() end
    end

    track(owner, handle.InputEnded:Connect(function(input)
        if ownsInput(activeInput, input) then stop() end
    end))
    track(owner, UserInputService.InputEnded:Connect(function(input)
        if ownsInput(activeInput, input) then stop() end
    end))
    track(owner, UserInputService.InputChanged:Connect(function(input)
        if not dragging or not tracksInput(activeInput, input) then return end
        local delta = input.Position - startPos
        local p = UDim2.new(
            startOffset.X.Scale, startOffset.X.Offset + delta.X,
            startOffset.Y.Scale, startOffset.Y.Offset + delta.Y
        )
        if opts.clamp then
            local vp = viewport()
            local abs = target.AbsoluteSize
            local minX, maxX = -abs.X * 0.45, vp.X - abs.X * 0.55
            local minY, maxY = 0, vp.Y - 42
            local ax = p.X.Scale * vp.X + p.X.Offset
            local ay = p.Y.Scale * vp.Y + p.Y.Offset
            ax = math.clamp(ax, minX, maxX)
            ay = math.clamp(ay, minY, maxY)
            p = UDim2.new(0, ax, 0, ay)
        end
        target.Position = p
        if opts.onMove then opts.onMove(p) end
    end))
end

local function text(props)
    local t = new("TextLabel", props)
    t.BackgroundTransparency = props.BackgroundTransparency or 1
    t.BorderSizePixel = 0
    return t
end

local function spaced(str)
    local out = {}
    for i = 1, #str do out[#out + 1] = str:sub(i, i) end
    return table.concat(out, " ")
end

local NOTIFY = { holder = nil, items = {}, max = 5 }

local function notifyHolder()
    if NOTIFY.holder and NOTIFY.holder.Parent then return NOTIFY.holder end
    local host = guiParent()
    local stale = host:FindFirstChild("BPUI_Toasts")
    if stale then pcall(function() stale:Destroy() end) end
    local sg = new("ScreenGui", {
        Name = "BPUI_Toasts",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9999,
        Parent = host,
    })
    local holder = new("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        AnchorPoint = IS_MOBILE and Vector2.new(0.5, 0) or Vector2.new(1, 1),
        Position = IS_MOBILE and UDim2.new(0.5, 0, 0, 48) or UDim2.new(1, -18, 1, -18),
        Size = IS_MOBILE and UDim2.new(1, -28, 1, -64) or UDim2.new(0, 330, 1, -36),
        Parent = sg,
    })
    local layout = list(holder, 10)
    layout.HorizontalAlignment = IS_MOBILE and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = IS_MOBILE and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
    NOTIFY.holder = holder
    NOTIFY.gui = sg
    return holder
end

function BPUI:Notify(config)
    config = config or {}
    local theme = ACTIVE
    local kind = config.Type or "Info"
    local accent = theme.Accent
    if kind == "Success" then accent = theme.Success
    elseif kind == "Warning" then accent = theme.Warning
    elseif kind == "Error" or kind == "Danger" then accent = theme.Danger end

    local holder = notifyHolder()

    while #NOTIFY.items >= NOTIFY.max do
        local oldest = table.remove(NOTIFY.items, 1)
        if oldest and oldest.Dismiss then pcall(oldest.Dismiss, oldest) end
    end

    local slot, card, syncConn = autoSlot(holder, {
        Name = "Toast",
        MinHeight = 56,
        Color = theme.Surface,
        ZIndex = 1,
    })
    corner(card, RADIUS.lg)
    local cs = stroke(card, theme.Stroke, 1, 0.1)
    edgeLight(cs, theme)
    dropShadow(slot, 16, RADIUS.lg, 0.84, 1)
    sheen(card, 0.975, nil, 90)

    local badge = new("Frame", {
        Name = "Badge",
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 15),
        Size = UDim2.new(0, 20, 0, 20),
        ZIndex = 4,
        Parent = card,
    })
    corner(badge, RADIUS.pill)
    local glyph = theme.Dark and theme.Window or Color3.new(1, 1, 1)
    if kind == "Success" then iconCheck(badge, 13, glyph, 5)
    elseif kind == "Error" or kind == "Danger" then iconClose(badge, 9, glyph, 5)
    elseif kind == "Warning" then
        bar(badge, 1.8, 7, 0, glyph, 5, Vector2.new(0.5, 0.5), 0.5, 0.40)
        bar(badge, 1.8, 1.8, 0, glyph, 5, Vector2.new(0.5, 0.5), 0.5, 0.70)
    else iconDot(badge, 12, glyph, 5) end

    local body = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -78, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
        Parent = card,
    })
    pad(body, 14, 0, 14, 0)
    list(body, 2)

    local title = text({
        Text = config.Title or "Notification",
        Font = FONT.medium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ZIndex = 5,
        Parent = body,
    })

    local content
    if config.Content and config.Content ~= "" then
        content = text({
            Text = config.Content,
            Font = FONT.body,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 5,
            Parent = body,
        })
    end

    local closeBtn = new("TextButton", {
        Name = "Close",
        BackgroundColor3 = theme.ElementHover,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        Size = UDim2.new(0, 26, 0, 26),
        ClipsDescendants = true,
        ZIndex = 6,
        Parent = card,
    })
    corner(closeBtn, RADIUS.sm)
    local closeIcon = iconClose(closeBtn, 9, theme.Muted, 7)

    local progress
    if (config.Duration or 4) > 0 then
        progress = new("Frame", {
            Name = "Progress",
            BackgroundColor3 = accent,
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 2),
            ZIndex = 7,
            Parent = card,
        })
    end

    local sc = new("UIScale", { Scale = 0.97, Parent = card })
    card.Position = UDim2.new(0.5, IS_MOBILE and 0 or 24, 0.5, 0)
    card.BackgroundTransparency = 1
    tw(card, MOTION.reveal, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0 })
    tw(sc, MOTION.reveal, { Scale = 1 })

    local toast = { _card = card, _slot = slot, _alive = true }
    local duration = config.Duration or 4

    function toast:SetContent(str) if content then content.Text = str end end
    function toast:SetTitle(str) title.Text = str end
    function toast:Dismiss()
        if not self._alive then return end
        self._alive = false
        for i, v in ipairs(NOTIFY.items) do
            if v == self then table.remove(NOTIFY.items, i) break end
        end
        pcall(function() syncConn:Disconnect() end)
        tw(sc, MOTION.quick, { Scale = 0.96 })
        local t = tw(card, MOTION.quick, { BackgroundTransparency = 1, Position = UDim2.new(0.5, IS_MOBILE and 0 or 20, 0.5, 0) })
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then tw(d, MOTION.quick, { TextTransparency = 1 })
            elseif d:IsA("Frame") then tw(d, MOTION.quick, { BackgroundTransparency = 1 })
            elseif d:IsA("UIStroke") then tw(d, MOTION.quick, { Transparency = 1 }) end
        end
        local done = false
        local function finish()
            if done then return end
            done = true
            pcall(function() slot:Destroy() end)
        end
        if t then t.Completed:Connect(finish) end
        task.delay(0.3, finish)
    end

    if not IS_MOBILE then
        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, { BackgroundTransparency = 0.15 }, MOTION.hover)
            tintIcon(closeIcon, ACTIVE.Text)
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, { BackgroundTransparency = 1 }, MOTION.hover)
            tintIcon(closeIcon, ACTIVE.Muted)
        end)
    end
    closeBtn.MouseButton1Click:Connect(function() toast:Dismiss() end)

    if config.Callback then
        local hit = new("TextButton", {
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.new(1, -40, 1, 0),
            ZIndex = 3,
            Parent = card,
        })
        hit.MouseButton1Click:Connect(function()
            task.spawn(config.Callback)
            toast:Dismiss()
        end)
    end

    table.insert(NOTIFY.items, toast)

    if duration > 0 then
        tw(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
        task.delay(duration, function() toast:Dismiss() end)
    end

    return toast
end
local Window = {}
Window.__index = Window

local TAB_H, TAB_GAP = 36, 4

local function keyFromValue(v)
    if typeof(v) == "EnumItem" then
        if tostring(v.EnumType) == "KeyCode" then return v end
        if tostring(v.EnumType) == "UserInputType" then return v end
        return nil
    end
    if type(v) == "string" then
        local ok, e = pcall(function() return Enum.KeyCode[v] end)
        if ok and e then return e end
        local ok2, u = pcall(function() return Enum.UserInputType[v] end)
        if ok2 and u then return u end
    end
    return nil
end

local function keyName(v)
    if typeof(v) ~= "EnumItem" then return "None" end
    return v.Name
end

function BPUI:CreateWindow(config)
    config = config or {}
    local theme = resolveTheme(config.Theme)
    ACTIVE = theme
    if config.Accent then theme.Accent = config.Accent end

    local title = config.Title or "BPUI"
    local cleanupKey = "BPUI_" .. title

    if ENV[cleanupKey] then
        pcall(function() ENV[cleanupKey]:Destroy() end)
        ENV[cleanupKey] = nil
    end

    local folder = "BPUI/" .. (config.ConfigFolder or title:gsub("[^%w%-_ ]", ""))
    if FS.Available then
        FS.folder("BPUI")
        FS.folder(folder)
        FS.folder(folder .. "/configs")
    end

    local settings = {}
    if FS.Available and FS.exists(folder .. "/settings.json") then
        local raw = FS.read(folder .. "/settings.json")
        if raw then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(decoded) == "table" then settings = decoded end
        end
    end

    if settings.Theme and BPUI.Themes[settings.Theme] then
        theme = resolveTheme(settings.Theme)
        ACTIVE = theme
    end
    if settings.Accent and type(settings.Accent) == "table" then
        theme.Accent = Color3.fromRGB(settings.Accent[1], settings.Accent[2], settings.Accent[3])
    end

    local vp = viewport()
    local baseW = IS_MOBILE and 560 or 840
    local baseH = IS_MOBILE and 400 or 580
    if config.Size then
        if typeof(config.Size) == "UDim2" then
            baseW, baseH = config.Size.X.Offset, config.Size.Y.Offset
        elseif typeof(config.Size) == "Vector2" then
            baseW, baseH = config.Size.X, config.Size.Y
        end
    end
    if config.RememberSize ~= false and settings.Width and settings.Height then
        baseW, baseH = settings.Width, settings.Height
    end

    local fit = math.min(1, (vp.X - 32) / baseW, (vp.Y - 32) / baseH) * (config.Scale or 1)
    local sidebarW = config.SidebarWidth or (IS_MOBILE and 156 or 218)

    local self = setmetatable({}, Window)
    self._title = title
    self._cleanupKey = cleanupKey
    self._folder = folder
    self._settings = settings
    self._theme = theme
    self._tabs = {}
    self._elements = {}
    self._destroyed = false
    self._minimized = false
    self._visible = true
    self._connections = {}
    self._bindings = {}
    self._onDestroy = config.OnDestroy

    local sg = new("ScreenGui", {
        Name = "BPUI_" .. uid(),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9000,
        Parent = guiParent(),
    })
    self._gui = sg
    self._cleanupKey = cleanupKey
    ENV[cleanupKey] = self

    local root = new("Frame", {
        Name = "Root",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, baseW, 0, baseH),
        Position = UDim2.new(0.5, -baseW / 2, 0.5, -baseH / 2),
        Parent = sg,
    })
    self._root = root
    local rootScale = new("UIScale", { Scale = fit, Parent = root })
    self._scale = rootScale
    self._fit = fit

    dropShadow(root, 30, RADIUS.xl, 0.76, 0)

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Window,
        BackgroundTransparency = config.Transparency or (theme.Dark and 0.02 or 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        Active = true,
        ZIndex = 1,
        Parent = root,
    })
    corner(main, RADIUS.xl)
    bind(self, main, "BackgroundColor3", "Window")
    local mainStroke = stroke(main, theme.Stroke, 1, 0.05)
    edgeLight(mainStroke, theme)
    bind(self, mainStroke, "Color", "Stroke")
    self._main = main

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(0, sidebarW, 1, 0),
        Active = true,
        ZIndex = 2,
        Parent = main,
    })
    bind(self, sidebar, "BackgroundColor3", "Sidebar")
    sheen(sidebar, 0.985, nil, 90)
    self._sidebar = sidebar

    local vdiv = new("Frame", {
        Name = "Divider",
        BackgroundColor3 = theme.Stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Position = UDim2.new(0, sidebarW, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 3,
        Parent = main,
    })
    bind(self, vdiv, "BackgroundColor3", "Stroke")

    local wash = new("Frame", {
        Name = "Wash",
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 150),
        ZIndex = 2,
        Parent = sidebar,
    })
    bind(self, wash, "BackgroundColor3", "Accent")
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.90),
            NumberSequenceKeypoint.new(0.55, 0.975),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = wash,
    })

    local brand = new("Frame", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 66),
        ZIndex = 3,
        Parent = sidebar,
    })
    pad(brand, 0, 14, 0, 14)

    local markSize = 32
    local mark = new("Frame", {
        Name = "Mark",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, markSize, 0, markSize),
        ZIndex = 4,
        Parent = brand,
    })
    corner(mark, RADIUS.md)
    bind(self, mark, "BackgroundColor3", "Accent")
    sheen(mark, 0.78, nil, 135)
    local markGlow = accentGlow(mark, theme.Accent, 10, 0.80, 3)
    for _, l in ipairs(markGlow:GetChildren()) do bind(self, l, "BackgroundColor3", "Accent") end
    local markStroke = stroke(mark, Color3.new(1, 1, 1), 1, 0.78)

    if config.Icon then
        local ico, kind = iconAny(mark, config.Icon, 18, theme.AccentText, 5)
        if kind == "image" then
            ico.Size = UDim2.new(1, -10, 1, -10)
            bind(self, ico, "ImageColor3", "AccentText")
        end
    else
        local initials = title:sub(1, 1):upper()
        local second = title:match("%s(%a)")
        if second then initials = initials .. second:upper() end
        local initialsLabel = text({
            Text = initials,
            Font = FONT.bold,
            TextSize = 13,
            TextColor3 = theme.AccentText,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5,
            Parent = mark,
        })
        bind(self, initialsLabel, "TextColor3", "AccentText")
    end

    local brandText = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, markSize + 10, 0, 0),
        Size = UDim2.new(1, -(markSize + 10), 1, 0),
        ZIndex = 4,
        Parent = brand,
    })

    local hasSub = config.Subtitle and config.Subtitle ~= ""
    local brandTitle = text({
        Text = title,
        Font = FONT.bold,
        TextSize = 15,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AnchorPoint = Vector2.new(0, hasSub and 0 or 0.5),
        Position = UDim2.new(0, 0, hasSub and 0.5 or 0.5, hasSub and -15 or 0),
        Size = UDim2.new(1, 0, 0, 16),
        ZIndex = 4,
        Parent = brandText,
    })
    bind(self, brandTitle, "TextColor3", "Text")
    self._brandTitle = brandTitle

    local brandSub
    if hasSub then
        brandSub = text({
            Text = config.Subtitle,
            Font = FONT.body,
            TextSize = 11,
            TextColor3 = theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.new(0, 0, 0.5, 2),
            Size = UDim2.new(1, 0, 0, 13),
            ZIndex = 4,
            Parent = brandText,
        })
        bind(self, brandSub, "TextColor3", "Muted")
    end
    self._brandSub = brandSub

    local searchWrap, searchBox
    if config.Search ~= false then
        searchWrap = new("Frame", {
            Name = "Search",
            BackgroundColor3 = theme.Element,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0, 62),
            Size = UDim2.new(1, -24, 0, 32),
            ZIndex = 3,
            Parent = sidebar,
        })
        corner(searchWrap, RADIUS.md)
        bind(self, searchWrap, "BackgroundColor3", "Element")
        local ss = stroke(searchWrap, theme.StrokeSoft, 1, 0.35)
        bind(self, ss, "Color", "StrokeSoft")

        local glassBox = new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 9, 0, 0),
            Size = UDim2.new(0, 14, 1, 0),
            ZIndex = 4,
            Parent = searchWrap,
        })
        local glass = iconSearch(glassBox, 13, theme.Muted, 5)
        self._searchIcon = glass

        searchBox = new("TextBox", {
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Search",
            PlaceholderColor3 = theme.Muted,
            Font = FONT.medium,
            TextSize = 12,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Position = UDim2.new(0, 26, 0, 0),
            Size = UDim2.new(1, -34, 1, 0),
            ZIndex = 4,
            Parent = searchWrap,
        })
        bind(self, searchBox, "TextColor3", "Text")
        bind(self, searchBox, "PlaceholderColor3", "Muted")

        track(self, searchBox.Focused:Connect(function()
            tween(ss, { Color = theme.Accent, Transparency = 0.1 }, MOTION.hover)
        end))
        track(self, searchBox.FocusLost:Connect(function()
            tween(ss, { Color = ACTIVE.StrokeSoft, Transparency = 0.35 }, MOTION.hover)
        end))
        track(self, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            self:Search(searchBox.Text)
        end))
        self._searchBox = searchBox
    end

    local tabTop = (config.Search ~= false) and 108 or 74
    local tabScroll = new("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, tabTop),
        Size = UDim2.new(1, -16, 1, -(tabTop + 52)),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 3,
        Parent = sidebar,
    })
    list(tabScroll, TAB_GAP)
    self._tabScroll = tabScroll
    self._groups = {}

    local footer = new("Frame", {
        Name = "Footer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 3,
        Parent = sidebar,
    })
    local footerLine = new("Frame", {
        BackgroundColor3 = theme.Stroke,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 0, 1),
        ZIndex = 3,
        Parent = footer,
    })
    bind(self, footerLine, "BackgroundColor3", "Stroke")

    local pulse = new("Frame", {
        Name = "Pulse",
        BackgroundColor3 = theme.Success,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 2),
        Size = UDim2.new(0, 7, 0, 7),
        ZIndex = 4,
        Parent = footer,
    })
    corner(pulse, RADIUS.pill)
    bind(self, pulse, "BackgroundColor3", "Success")
    local pulseRing = accentGlow(pulse, theme.Success, 5, 0.75, 3)
    for _, l in ipairs(pulseRing:GetChildren()) do bind(self, l, "BackgroundColor3", "Success") end
    task.spawn(function()
        while not self._destroyed and pulse.Parent do
            tw(pulseRing, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.new(1, 16, 1, 16) })
            task.wait(1.15)
            if self._destroyed then break end
            tw(pulseRing, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.new(1, 8, 1, 8) })
            task.wait(1.15)
        end
    end)

    local who = ""
    pcall(function() who = LocalPlayer.DisplayName or LocalPlayer.Name or "" end)
    local footerName = text({
        Text = config.FooterName or who,
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 27, 0.5, -6),
        Size = UDim2.new(1, -41, 0, 14),
        ZIndex = 4,
        Parent = footer,
    })
    bind(self, footerName, "TextColor3", "SubText")
    local footerText = text({
        Text = config.Footer or ("BPUI v" .. BPUI.Version),
        Font = FONT.body,
        TextSize = 10,
        TextColor3 = theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 27, 0.5, 8),
        Size = UDim2.new(1, -41, 0, 12),
        ZIndex = 4,
        Parent = footer,
    })
    bind(self, footerText, "TextColor3", "Muted")

    local body = new("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarW + 1, 0, 0),
        Size = UDim2.new(1, -(sidebarW + 1), 1, 0),
        ZIndex = 2,
        Parent = main,
    })
    self._body = body

    local topbar = new("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 54),
        Active = true,
        ZIndex = 3,
        Parent = body,
    })
    self._topbar = topbar

    local hairline = new("Frame", {
        Name = "Hairline",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, 0),
        Size = UDim2.new(1, -40, 0, 1),
        ZIndex = 4,
        Parent = topbar,
    })
    bind(self, hairline, "BackgroundColor3", "Accent")
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(0.45, 0.7),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = hairline,
    })

    local pageTitle = text({
        Text = "",
        Font = FONT.bold,
        TextSize = 17,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 20, 0, 13),
        Size = UDim2.new(1, -140, 0, 18),
        ZIndex = 4,
        Parent = topbar,
    })
    bind(self, pageTitle, "TextColor3", "Text")
    self._pageTitle = pageTitle

    local pageSub = text({
        Text = "",
        Font = FONT.body,
        TextSize = 11,
        TextColor3 = theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 20, 0, 31),
        Size = UDim2.new(1, -140, 0, 13),
        ZIndex = 4,
        Parent = topbar,
    })
    bind(self, pageSub, "TextColor3", "Muted")
    self._pageSub = pageSub

    local controls = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 72, 0, 28),
        ZIndex = 4,
        Parent = topbar,
    })
    local clist = list(controls, 4, Enum.FillDirection.Horizontal)
    clist.HorizontalAlignment = Enum.HorizontalAlignment.Right
    clist.VerticalAlignment = Enum.VerticalAlignment.Center

    local function ctrlButton(kind, danger, order, fn)
        local b = new("TextButton", {
            BackgroundColor3 = theme.ElementHover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(0, 32, 0, 28),
            LayoutOrder = order,
            ClipsDescendants = true,
            ZIndex = 4,
            Parent = controls,
        })
        corner(b, RADIUS.sm)
        local g
        if kind == "close" then g = iconClose(b, 10, theme.SubText, 5)
        else g = iconMinimize(b, 11, theme.SubText, 5) end
        if not IS_MOBILE then
            track(self, b.MouseEnter:Connect(function()
                tween(b, {
                    BackgroundTransparency = 0,
                    BackgroundColor3 = danger and ACTIVE.Danger or ACTIVE.ElementHover,
                }, MOTION.hover)
                tintIcon(g, danger and (ACTIVE.Dark and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)) or ACTIVE.Text)
            end))
            track(self, b.MouseLeave:Connect(function()
                tween(b, { BackgroundTransparency = 1 }, MOTION.hover)
                tintIcon(g, ACTIVE.SubText)
            end))
        end
        pressable(self, b, b, fn, { ripple = false })
        return b
    end

    ctrlButton("minimize", false, 1, function() self:Minimize() end)
    ctrlButton("close", true, 2, function()
        if config.ConfirmClose then
            self:Dialog({
                Title = "Close " .. title .. "?",
                Content = "The interface will be unloaded.",
                Buttons = {
                    { Text = "Cancel" },
                    { Text = "Close", Style = "Danger", Callback = function() self:Destroy() end },
                },
            })
        elseif config.CloseBehavior == "Hide" then
            self:Hide()
        else
            self:Destroy()
        end
    end)

    local pages = new("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 54),
        Size = UDim2.new(1, 0, 1, -54),
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = body,
    })
    self._pages = pages

    draggable(self, topbar, root, { clamp = true })
    draggable(self, brand, root, { clamp = true })

    if not IS_MOBILE and config.Resizable ~= false then
        local grip = new("TextButton", {
            Name = "Grip",
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -2, 1, -2),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 8,
            Parent = main,
        })
        for i = 1, 3 do
            local dot = new("Frame", {
                BackgroundColor3 = theme.Muted,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -2, 1, -2 - (i - 1) * 5),
                Size = UDim2.new(0, 3 + (3 - i) * 4, 0, 2),
                ZIndex = 8,
                Parent = grip,
            })
            corner(dot, 1)
            bind(self, dot, "BackgroundColor3", "Muted")
        end

        local resizing, startPos, startSize = false, nil, nil
        track(self, grip.InputBegan:Connect(function(input)
            if not isClick(input) then return end
            resizing = true
            startPos = input.Position
            startSize = root.Size
        end))
        local function stopResize()
            if not resizing then return end
            resizing = false
            self._settings.Width = root.Size.X.Offset
            self._settings.Height = root.Size.Y.Offset
            self:_saveSettings()
        end
        track(self, grip.InputEnded:Connect(function(input) if isClick(input) then stopResize() end end))
        track(self, UserInputService.InputEnded:Connect(function(input) if isClick(input) then stopResize() end end))
        track(self, UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local delta = (input.Position - startPos) / math.max(rootScale.Scale, 0.01)
            root.Size = UDim2.new(
                0, math.clamp(startSize.X.Offset + delta.X, 480, 1400),
                0, math.clamp(startSize.Y.Offset + delta.Y, 320, 900)
            )
        end))
    end

    local float
    if IS_MOBILE or config.FloatingButton then
        local floatWrap = new("Frame", {
            Name = "FloatWrap",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0.5, -26),
            Size = UDim2.new(0, 52, 0, 52),
            ZIndex = 49,
            Parent = sg,
        })
        dropShadow(floatWrap, 14, RADIUS.pill, 0.78, 49)
        float = new("Frame", {
            Name = "Float",
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Active = true,
            ClipsDescendants = true,
            ZIndex = 50,
            Parent = floatWrap,
        })
        corner(float, RADIUS.pill)
        bind(self, float, "BackgroundColor3", "Accent")
        sheen(float, 0.84, nil, 90)
        local fs = stroke(float, Color3.new(1, 1, 1), 1, 0.7)
        local ft = text({
            Text = config.FloatingText or title:sub(1, 2):upper(),
            Font = FONT.bold,
            TextSize = 15,
            TextColor3 = theme.AccentText,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 51,
            Parent = float,
        })
        bind(self, ft, "TextColor3", "AccentText")
        local moved = false
        draggable(self, float, floatWrap, {
            clamp = true,
            onStart = function() moved = false end,
            onMove = function() moved = true end,
        })
        pressable(self, float, float, function()
            if not moved then self:Toggle() end
        end, { rippleAlpha = 0.85 })
        self._float = floatWrap
        self._floatButton = float
    end

    if config.Acrylic then
        pcall(function()
            local Lighting = game:GetService("Lighting")
            local blur = Instance.new("BlurEffect")
            blur.Name = "BPUI_Acrylic_" .. sg.Name
            blur.Size = 0
            blur.Parent = Lighting
            self._blur = blur
            self._blurStrength = config.AcrylicStrength or 14
            tw(blur, MOTION.reveal, { Size = self._blurStrength })
        end)
    end

    local tipHolder = new("Frame", {
        Name = "Tooltip",
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 90,
        Parent = sg,
    })
    corner(tipHolder, RADIUS.sm)
    local tipStroke = stroke(tipHolder, theme.Stroke, 1, 0.1)
    bind(self, tipHolder, "BackgroundColor3", "Surface")
    bind(self, tipStroke, "Color", "Stroke")
    local tipText = text({
        Text = "",
        Font = FONT.body,
        TextSize = 12,
        TextColor3 = theme.Text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        ZIndex = 91,
        Parent = tipHolder,
    })
    new("UISizeConstraint", { MaxSize = Vector2.new(260, 400), Parent = tipText })
    pad(tipHolder, 6, 10, 6, 10)
    bind(self, tipText, "TextColor3", "Text")
    self._tip = tipHolder
    self._tipText = tipText

    track(self, UserInputService.InputBegan:Connect(function(input)
        if not isClick(input) or self._destroyed then return end
        local open = BPUI._openPanel
        if not open or open._destroyed or not open._root then return end
        local ok = pcall(function()
            local p, s = open._root.AbsolutePosition, open._root.AbsoluteSize
            local x, y = input.Position.X, input.Position.Y
            if x < p.X or y < p.Y or x > p.X + s.X or y > p.Y + s.Y then
                closeOpenPanel(nil)
            end
        end)
    end))

    local toggleKey = keyFromValue(settings.ToggleKey or config.ToggleKey or "RightShift")
    self._toggleKey = toggleKey
    track(self, UserInputService.InputBegan:Connect(function(input, gp)
        if gp or self._destroyed or BPUI._activeKeybindCancel then return end
        if self._toggleKey and input.KeyCode == self._toggleKey then
            self:Toggle()
        end
    end))

    main.BackgroundTransparency = 1
    rootScale.Scale = fit * 0.94
    tw(rootScale, MOTION.reveal, { Scale = fit })
    tw(main, MOTION.reveal, { BackgroundTransparency = config.Transparency or (theme.Dark and 0.02 or 0) })

    self._config = config
    table.insert(BPUI.Windows, self)

    if config.WelcomeNotification ~= false and not IS_MOBILE then
        task.delay(0.35, function()
            if self._destroyed then return end
            BPUI:Notify({
                Title = title,
                Content = "Press " .. keyName(self._toggleKey) .. " to toggle the interface.",
                Duration = 4,
            })
        end)
    end

    return self
end

function Window:_showTooltip(str, anchor)
    if IS_MOBILE or self._destroyed or not self._tip then return end
    if not str or str == "" then return end
    self._tipText.Text = str
    local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    local x, y = 0, 0
    if ok and mouse then x, y = mouse.X, mouse.Y end
    local vp = viewport()
    local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
    local ty = ap.Y + as.Y + 6
    if ty + 60 > vp.Y then ty = ap.Y - 40 end
    local tx = math.clamp(x + 12, 8, vp.X - 280)
    self._tip.Position = UDim2.new(0, tx, 0, ty)
    self._tip.Visible = true
    self._tip.BackgroundTransparency = 1
    self._tipText.TextTransparency = 1
    tw(self._tip, MOTION.quick, { BackgroundTransparency = 0 })
    tw(self._tipText, MOTION.quick, { TextTransparency = 0 })
end

function Window:_hideTooltip()
    if self._tip then self._tip.Visible = false end
end

function Window:_saveSettings()
    if not FS.Available or self._destroyed then return end
    local ok, raw = pcall(function() return HttpService:JSONEncode(self._settings) end)
    if ok then FS.write(self._folder .. "/settings.json", raw) end
end

function Window:_layoutIndicator() end
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section
local Group = {}
Group.__index = Group

local function nextOrder(w)
    w._navOrder = (w._navOrder or 0) + 1
    return w._navOrder
end

local function navIcon(owner, parent, icon, x, color)
    if not icon then return nil, nil, 0 end
    local box = new("Frame", {
        Name = "IconBox",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, x, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        ZIndex = 5,
        Parent = parent,
    })
    local ico, kind = iconAny(box, icon, 17, color, 6)
    return ico, kind, 26
end

local function buildTab(w, container, config, group)
    if type(config) == "string" then config = { Name = config } end
    config = config or {}
    local theme = ACTIVE
    local name = config.Name or ("Tab " .. (#w._tabs + 1))

    local tab = setmetatable({}, Tab)
    tab._window = w
    tab._group = group
    tab._name = name
    tab._subtitle = config.Subtitle or config.Description or ""
    tab._sections = {}
    tab._elements = {}
    tab._connections = {}
    tab._bindings = {}

    local button = new("TextButton", {
        Name = "Tab_" .. name,
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, TAB_H),
        LayoutOrder = group and (#group._tabs + 1) or nextOrder(w),
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = container,
    })
    corner(button, RADIUS.sm)
    tab._button = button

    local bar_ = new("Frame", {
        Name = "Bar",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0, 0),
        ZIndex = 6,
        Parent = button,
    })
    corner(bar_, RADIUS.pill)
    bind(tab, bar_, "BackgroundColor3", "Accent")
    tab._bar = bar_

    local inset = group and 12 or 0
    local labelX = 12 + inset
    local ico, kind, w_ = navIcon(tab, button, config.Icon, 11 + inset, theme.SubText)
    if ico then
        tab._icon, tab._iconKind = ico, kind
        labelX = labelX + w_
    end

    local label = text({
        Text = name,
        Font = FONT.medium,
        TextSize = 12,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, labelX, 0, 0),
        Size = UDim2.new(1, -(labelX + 10), 1, 0),
        ZIndex = 5,
        Parent = button,
    })
    tab._label = label

    local page = new("ScrollingFrame", {
        Name = "Page_" .. name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Muted,
        ScrollBarImageTransparency = 0.5,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ZIndex = 2,
        Parent = w._pages,
    })
    pad(page, 10, 22, 26, 22)
    list(page, 20)
    tab._page = page
    bind(tab, page, "ScrollBarImageColor3", "Muted")

    if not IS_MOBILE then
        track(tab, button.MouseEnter:Connect(function()
            if w._activeTab == tab then return end
            tween(button, { BackgroundTransparency = 0.5, BackgroundColor3 = ACTIVE.SurfaceHover }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.Text }, MOTION.hover)
            if tab._iconKind == "image" then tween(tab._icon, { ImageColor3 = ACTIVE.Text }, MOTION.hover) end
        end))
        track(tab, button.MouseLeave:Connect(function()
            if w._activeTab == tab then return end
            tween(button, { BackgroundTransparency = 1 }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.SubText }, MOTION.hover)
            if tab._iconKind == "image" then tween(tab._icon, { ImageColor3 = ACTIVE.SubText }, MOTION.hover) end
        end))
    end

    pressable(tab, button, button, function() tab:Select() end, {
        rippleAlpha = 0.92,
        pressScale = 0.985,
    })

    table.insert(w._tabs, tab)
    if group then table.insert(group._tabs, tab) end
    if #w._tabs == 1 then tab:Select(true) end
    return tab
end

function Window:CreateTab(config)
    return buildTab(self, self._tabScroll, config, nil)
end

function Window:CreateGroup(config)
    if type(config) == "string" then config = { Name = config } end
    config = config or {}
    local theme = ACTIVE
    local w = self

    local group = setmetatable({}, Group)
    group._window = w
    group._name = config.Name or "Group"
    group._tabs = {}
    group._open = config.Open ~= false
    group._connections = {}
    group._bindings = {}

    local header = new("TextButton", {
        Name = "Group_" .. group._name,
        BackgroundColor3 = theme.SurfaceHover,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Size = UDim2.new(1, 0, 0, TAB_H),
        LayoutOrder = nextOrder(w),
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = w._tabScroll,
    })
    corner(header, RADIUS.sm)
    group._header = header

    local labelX = 12
    local ico, kind, w_ = navIcon(group, header, config.Icon, 11, theme.SubText)
    if ico then
        group._icon, group._iconKind = ico, kind
        labelX = labelX + w_
    end

    local label = text({
        Text = group._name,
        Font = FONT.bold,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, labelX, 0, 0),
        Size = UDim2.new(1, -(labelX + 30), 1, 0),
        ZIndex = 5,
        Parent = header,
    })
    bind(group, label, "TextColor3", "SubText")
    group._label = label

    local chevBox = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        ZIndex = 5,
        Parent = header,
    })
    local chev = iconChevron(chevBox, 11, theme.Muted, group._open and 90 or 0, 6)
    group._chev = chev

    local container = new("Frame", {
        Name = "GroupBody_" .. group._name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        LayoutOrder = nextOrder(w),
        ZIndex = 4,
        Parent = w._tabScroll,
    })
    local inner = new("Frame", {
        Name = "Inner",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 4,
        Parent = container,
    })
    list(inner, TAB_GAP)
    pad(inner, 0, 0, 2, 0)
    group._container = container
    group._inner = inner

    local rail = new("Frame", {
        Name = "Rail",
        BackgroundColor3 = theme.StrokeSoft,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 9, 0, 2),
        Size = UDim2.new(0, 1, 1, -6),
        ZIndex = 5,
        Parent = container,
    })
    bind(group, rail, "BackgroundColor3", "StrokeSoft")

    if not IS_MOBILE then
        track(group, header.MouseEnter:Connect(function()
            tween(header, { BackgroundTransparency = 0.5, BackgroundColor3 = ACTIVE.SurfaceHover }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.Text }, MOTION.hover)
        end))
        track(group, header.MouseLeave:Connect(function()
            tween(header, { BackgroundTransparency = 1 }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.SubText }, MOTION.hover)
        end))
    end
    pressable(group, header, header, function() group:Toggle() end, { rippleAlpha = 0.92, pressScale = 0.985 })

    table.insert(w._groups, group)
    group:_layout(true)
    return group
end

function Group:_contentHeight()
    local n = 0
    for _, t in ipairs(self._tabs) do
        if t._button and t._button.Visible then n = n + 1 end
    end
    if n == 0 then return 0 end
    return n * TAB_H + (n - 1) * TAB_GAP + 2
end

function Group:_layout(instant)
    local h = self._open and self:_contentHeight() or 0
    local target = UDim2.new(1, 0, 0, h)
    if instant then
        self._container.Size = target
    else
        tw(self._container, MOTION.standard, { Size = target })
    end
    self._container.Visible = h > 0 or self._open
    if self._chev then
        local rot = self._open and 90 or 0
        if instant then self._chev.Rotation = rot
        else tw(self._chev, MOTION.standard, { Rotation = rot }) end
    end
end

function Group:SetOpen(state, instant)
    self._open = state and true or false
    self:_layout(instant)
end

function Group:Open() self:SetOpen(true) end
function Group:Close() self:SetOpen(false) end
function Group:Toggle() self:SetOpen(not self._open) end
function Group:IsOpen() return self._open end

function Group:CreateTab(config)
    local tab = buildTab(self._window, self._inner, config, self)
    self:_layout(true)
    return tab
end
Group.AddTab = Group.CreateTab

function Group:SetName(str)
    self._name = str
    self._label.Text = str
end

function Group:Destroy()
    for i = #self._tabs, 1, -1 do
        local t = self._tabs[i]
        if t and t.Destroy then pcall(function() t:Destroy() end) end
    end
    untrack(self)
    if self._header then self._header:Destroy() end
    if self._container then self._container:Destroy() end
    local w = self._window
    for i, g in ipairs(w._groups) do
        if g == self then table.remove(w._groups, i) break end
    end
end

function Tab:Select(instant)
    local w = self._window
    if w._destroyed or w._activeTab == self then return end
    local previous = w._activeTab
    w._activeTab = self
    closeOpenPanel(nil)
    w:_hideTooltip()

    if self._group and not self._group._open then
        self._group:SetOpen(true, instant)
    end

    for _, t in ipairs(w._tabs) do
        local on = (t == self)
        local info = instant and TweenInfo.new(0) or MOTION.quick
        tw(t._button, info, {
            BackgroundTransparency = on and 0.86 or 1,
            BackgroundColor3 = on and ACTIVE.Accent or ACTIVE.SurfaceHover,
        })
        tw(t._label, info, { TextColor3 = on and ACTIVE.Text or ACTIVE.SubText })
        tw(t._bar, instant and TweenInfo.new(0) or MOTION.release, { Size = UDim2.new(0, 3, 0, on and 18 or 0) })
        if t._iconKind == "image" then
            tw(t._icon, info, { ImageColor3 = on and ACTIVE.Accent or ACTIVE.SubText })
        end
    end

    w._pageTitle.Text = self._name
    w._pageSub.Text = self._subtitle

    if previous and previous._page then
        local old = previous._page
        if instant then
            old.Visible = false
        else
            tw(old, MOTION.page, { Position = UDim2.new(0, -14, 0, 0) })
            task.delay(0.16, function() if old and old.Parent then old.Visible = false end end)
        end
    end

    self._page.Visible = true
    if instant then
        self._page.Position = UDim2.new(0, 0, 0, 0)
    else
        self._page.Position = UDim2.new(0, 16, 0, 0)
        tw(self._page, MOTION.page, { Position = UDim2.new(0, 0, 0, 0) })
    end
end

function Tab:SetName(name)
    self._name = name
    self._label.Text = name
    if self._window._activeTab == self then self._window._pageTitle.Text = name end
end

function Tab:SetSubtitle(str)
    self._subtitle = str or ""
    if self._window._activeTab == self then self._window._pageSub.Text = self._subtitle end
end

function Tab:SetIcon(icon)
    local box = self._button:FindFirstChild("IconBox")
    if box then box:Destroy() end
    self._icon, self._iconKind = nil, nil
    local inset = self._group and 12 or 0
    local ico, kind, w_ = navIcon(self, self._button, icon, 11 + inset, ACTIVE.SubText)
    if ico then self._icon, self._iconKind = ico, kind end
    local labelX = 12 + inset + (ico and w_ or 0)
    self._label.Position = UDim2.new(0, labelX, 0, 0)
    self._label.Size = UDim2.new(1, -(labelX + 10), 1, 0)
end

function Tab:CreateSection(config)
    if type(config) == "string" then config = { Name = config } end
    config = config or {}
    local theme = ACTIVE

    local section = setmetatable({}, Section)
    section._tab = self
    section._window = self._window
    section._elements = {}
    section._connections = {}
    section._bindings = {}

    local holder = new("Frame", {
        Name = "Section",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self._sections + 1,
        ZIndex = 2,
        Parent = self._page,
    })
    list(holder, 4)
    section._holder = holder
    section._card = holder

    if config.Name and config.Name ~= "" then
        local headWrap = new("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = 0,
            ZIndex = 2,
            Parent = holder,
        })
        local tick = new("Frame", {
            Name = "Tick",
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -8),
            Size = UDim2.new(0, 3, 0, 12),
            ZIndex = 2,
            Parent = headWrap,
        })
        corner(tick, RADIUS.pill)
        bind(section, tick, "BackgroundColor3", "Accent")
        local header = text({
            Text = config.Name,
            Font = FONT.medium,
            TextSize = 13,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -10, 1, -6),
            ZIndex = 2,
            Parent = headWrap,
        })
        bind(section, header, "TextColor3", "Text")
        section._header = header
        section._headerRaw = config.Name
    end

    table.insert(self._sections, section)
    return section
end

function Section:SetTitle(str)
    if self._header then
        self._headerRaw = str
        self._header.Text = tostring(str)
    end
end

function Section:SetVisible(v)
    self._userHidden = not v
    self._holder.Visible = v and true or false
end

function Section:Destroy()
    for i = #self._elements, 1, -1 do
        local e = self._elements[i]
        if e and e.Destroy then pcall(function() e:Destroy() end) end
    end
    untrack(self)
    if self._holder then self._holder:Destroy() end
    for i, s in ipairs(self._tab._sections) do
        if s == self then table.remove(self._tab._sections, i) break end
    end
end


function Tab:Destroy()
    for i = #self._sections, 1, -1 do
        local s = self._sections[i]
        if s and s.Destroy then pcall(function() s:Destroy() end) end
    end
    untrack(self)
    local w = self._window
    for i, t in ipairs(w._tabs) do
        if t == self then table.remove(w._tabs, i) break end
    end
    if self._group then
        for i, t in ipairs(self._group._tabs) do
            if t == self then table.remove(self._group._tabs, i) break end
        end
        self._group:_layout(true)
    end
    if self._button then self._button:Destroy() end
    if self._page then self._page:Destroy() end
    if w._activeTab == self then
        w._activeTab = nil
        if w._tabs[1] then w._tabs[1]:Select(true) end
    end
end

function Window:SelectTab(ref)
    if type(ref) == "string" then
        for _, t in ipairs(self._tabs) do
            if t._name == ref then t:Select() return t end
        end
        return nil
    end
    if ref and ref.Select then ref:Select() end
    return ref
end

function Window:SetTitle(str)
    self._title = str
    self._brandTitle.Text = str
end

function Window:SetSubtitle(str)
    if self._brandSub then self._brandSub.Text = str or "" end
end

function Window:SetVisible(state)
    if self._destroyed then return end
    state = state and true or false
    self._visible = state
    self._visToken = (self._visToken or 0) + 1
    local token = self._visToken
    closeOpenPanel(nil)
    self:_hideTooltip()
    if self._blur then
        pcall(function() tw(self._blur, MOTION.reveal, { Size = state and self._blurStrength or 0 }) end)
    end
    if state then
        self._root.Visible = true
        self._scale.Scale = self._fit * 0.96
        tw(self._scale, MOTION.reveal, { Scale = self._fit })
    else
        tw(self._scale, MOTION.quick, { Scale = self._fit * 0.96 })
        task.delay(0.17, function()
            if self._root and self._visToken == token and not self._visible then
                self._root.Visible = false
            end
        end)
    end
end

function Window:Show() self:SetVisible(true) end
function Window:Hide() self:SetVisible(false) end
function Window:Toggle() self:SetVisible(not self._visible) end

function Window:Minimize(state)
    if self._destroyed then return end
    if state == nil then state = not self._minimized end
    state = state and true or false
    if self._minimized == state then return end
    self._minimized = state
    closeOpenPanel(nil)
    self:_hideTooltip()
    if self._minimized then
        self._restoreSize = self._root.Size
        self._sidebar.Visible = false
        self._body.Position = UDim2.new(0, 0, 0, 0)
        self._body.Size = UDim2.new(1, 0, 1, 0)
        self._pages.Visible = false
        self._pageTitle.Text = self._title
        self._pageSub.Text = ""
        tw(self._root, MOTION.standard, { Size = UDim2.new(0, 300, 0, 54) })
    else
        self._sidebar.Visible = true
        local w = self._sidebar.Size.X.Offset
        self._body.Position = UDim2.new(0, w + 1, 0, 0)
        self._body.Size = UDim2.new(1, -(w + 1), 1, 0)
        self._pages.Visible = true
        if self._activeTab then
            self._pageTitle.Text = self._activeTab._name
            self._pageSub.Text = self._activeTab._subtitle
        end
        tw(self._root, MOTION.standard, { Size = self._restoreSize or UDim2.new(0, 840, 0, 580) })
    end
end

function Window:SetToggleKey(key)
    local k = keyFromValue(key)
    if k then
        self._toggleKey = k
        self._settings.ToggleKey = k.Name
        self:_saveSettings()
    end
end

function Window:SetFloatingButtonVisible(v)
    if self._float then self._float.Visible = v and true or false end
end

function Window:Notify(config) return BPUI:Notify(config) end

function Window:Search(query)
    query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    self._searchQuery = query
    local empty = (query == "")

    for _, tab in ipairs(self._tabs) do
        local tabHits = 0
        for _, section in ipairs(tab._sections) do
            local hits = 0
            for _, el in ipairs(section._elements) do
                if el._root and el._root.Parent then
                    local hay = ((el._name or "") .. " " .. (el._description or "")):lower()
                    local match = empty or hay:find(query, 1, true) ~= nil
                    el._root.Visible = match and not el._hidden
                    if match and not el._hidden then hits = hits + 1 end
                end
            end
            if section._userHidden then
                section._holder.Visible = false
            else
                section._holder.Visible = empty and true or (hits > 0)
            end
            tabHits = tabHits + hits
        end
        local tabMatch = empty or tabHits > 0 or (tab._name or ""):lower():find(query, 1, true) ~= nil
        tab._button.Visible = tabMatch
    end

    for _, g in ipairs(self._groups or {}) do
        local any = false
        for _, t in ipairs(g._tabs) do
            if t._button.Visible then any = true break end
        end
        g._header.Visible = empty or any
        if not empty and any and not g._open then g._open = true end
        g:_layout(true)
    end
end
local Element = {}
Element.__index = Element

local ROW_MIN = 50

local function registerFlag(el, flag)
    if not flag then return end
    el._flag = flag
    BPUI.Flags[flag] = el
    if BPUI._pendingFlags[flag] == nil then return end
    task.delay(0, function()
        local pending = BPUI._pendingFlags[flag]
        if pending == nil or el._destroyed then return end
        if type(el.Set) ~= "function" then return end
        BPUI._pendingFlags[flag] = nil
        pcall(function() el:Set(pending, true) end)
    end)
end

local function baseRow(section, config, opts)
    opts = opts or {}
    local theme = ACTIVE
    local el = setmetatable({}, Element)
    el._section = section
    el._window = section._window
    el._tab = section._tab
    el._connections = {}
    el._bindings = {}
    el._name = config.Name or config.Title or ""
    el._description = config.Description or config.Content or ""
    el._locked = false
    el._hidden = false

    local row = new("Frame", {
        Name = "Row",
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, ROW_MIN),
        AutomaticSize = (el._description ~= "" or opts.autoHeight) and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        ClipsDescendants = true,
        LayoutOrder = #section._elements + 1,
        ZIndex = 3,
        Parent = section._card,
    })
    corner(row, RADIUS.sm)
    bind(el, row, "BackgroundColor3", "Surface")
    local rowStroke = stroke(row, theme.StrokeSoft, 1, 0.15)
    bind(el, rowStroke, "Color", "StrokeSoft")
    el._root = row
    el._stroke = rowStroke

    local autoY = row.AutomaticSize == Enum.AutomaticSize.Y
    local inner = new("Frame", {
        Name = "Inner",
        BackgroundTransparency = 1,
        Size = autoY and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, 0),
        AutomaticSize = row.AutomaticSize,
        ZIndex = 3,
        Parent = row,
    })
    local iconInset = 0
    if config.Icon then
        iconInset = 32
        local box = new("Frame", {
            Name = "RowIcon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -iconInset, 0.5, 0),
            Size = UDim2.new(0, 22, 0, 22),
            ZIndex = 4,
            Parent = inner,
        })
        local ico, kind = iconAny(box, config.Icon, 18, theme.SubText, 5)
        if kind == "image" then bind(el, ico, "ImageColor3", "SubText") end
        el._icon, el._iconKind, el._iconBox = ico, kind, box
    end
    pad(inner, 12, 16, 12, 16 + iconInset)
    el._inner = inner
    el._autoY = autoY
    el._tooltip = config.Tooltip

    if el._tooltip and not IS_MOBILE then
        local token = 0
        track(el, row.MouseEnter:Connect(function()
            token = token + 1
            local mine = token
            task.delay(0.55, function()
                if mine == token and not el._destroyed and el._window and el._window._showTooltip then
                    el._window:_showTooltip(el._tooltip, row)
                end
            end)
        end))
        track(el, row.MouseLeave:Connect(function()
            token = token + 1
            if el._window and el._window._hideTooltip then el._window:_hideTooltip() end
        end))
    end

    local rightW = opts.controlWidth or 0
    local left = new("Frame", {
        Name = "Left",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(rightW + (rightW > 0 and 14 or 0)), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
        Parent = inner,
    })
    list(left, 2)
    if not autoY then
        left.AnchorPoint = Vector2.new(0, 0.5)
        left.Position = UDim2.new(0, 0, 0.5, 0)
    end
    el._left = left

    local nameLabel
    if el._name ~= "" then
        nameLabel = text({
            Text = el._name,
            Font = FONT.medium,
            TextSize = 13,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = opts.wrapName or false,
            TextTruncate = opts.wrapName and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1, 0, 0, 15),
            AutomaticSize = opts.wrapName and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            LayoutOrder = 1,
            ZIndex = 3,
            Parent = left,
        })
        bind(el, nameLabel, "TextColor3", "Text")
    end
    el._nameLabel = nameLabel

    local descLabel
    if el._description ~= "" then
        descLabel = text({
            Text = el._description,
            Font = FONT.body,
            TextSize = 11,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 3,
            Parent = left,
        })
        bind(el, descLabel, "TextColor3", "SubText")
    end
    el._descLabel = descLabel

    local right
    if rightW > 0 then
        right = new("Frame", {
            Name = "Right",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = autoY and UDim2.new(0, rightW, 0, opts.controlHeight or 24)
                          or UDim2.new(0, rightW, 1, 0),
            ZIndex = 4,
            Parent = inner,
        })
        el._right = right
    end

    local dim = new("Frame", {
        Name = "Dim",
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 24,
        Parent = row,
    })
    bind(el, dim, "BackgroundColor3", "Surface")
    el._dim = dim

    table.insert(section._elements, el)
    table.insert(el._window._elements, el)
    registerFlag(el, config.Flag)
    return el
end

function Element:SetName(str)
    self._name = str or ""
    if self._nameLabel then self._nameLabel.Text = self._name end
end

function Element:SetDescription(str)
    self._description = str or ""
    if self._descLabel then
        self._descLabel.Text = self._description
        self._descLabel.Visible = self._description ~= ""
    end
end

function Element:SetVisible(v)
    self._hidden = not v
    self._root.Visible = v and true or false
end

function Element:SetCallback(fn) self._callback = fn end
function Element:SetTooltip(str) self._tooltip = str end
function Element:SetIcon(icon)
    if not self._iconBox then return end
    if self._icon then self._icon:Destroy() end
    local ico, kind = iconAny(self._iconBox, icon, 18, ACTIVE.SubText, 5)
    if kind == "image" then bind(self, ico, "ImageColor3", "SubText") end
    self._icon, self._iconKind = ico, kind
end

function Element:SetLocked(state)
    self._locked = state and true or false
    if self._dim then
        self._dim.Visible = self._locked
        self._dim.Active = self._locked
        tween(self._dim, { BackgroundTransparency = self._locked and 0.45 or 1 }, MOTION.hover)
        if not self._locked then
            task.delay(0.2, function()
                if not self._locked and self._dim then self._dim.Visible = false end
            end)
        end
    end
    if self._locked then
        self._lockedBoxes = {}
        if self._root then
            for _, d in ipairs(self._root:GetDescendants()) do
                if d:IsA("TextBox") and d.TextEditable then
                    table.insert(self._lockedBoxes, d)
                    d.TextEditable = false
                end
            end
        end
    elseif self._lockedBoxes then
        for _, d in ipairs(self._lockedBoxes) do
            if d.Parent then d.TextEditable = true end
        end
        self._lockedBoxes = nil
    end
end

function Element:Lock() self:SetLocked(true) end
function Element:Unlock() self:SetLocked(false) end
function Element:Get() return self.Value end

function Element:Destroy()
    if BPUI._openPanel == self then BPUI._openPanel = nil end
    untrack(self)
    if self._flag then BPUI.Flags[self._flag] = nil end
    local s = self._section
    if s then
        for i, e in ipairs(s._elements) do
            if e == self then table.remove(s._elements, i) break end
        end
        for i, e in ipairs(s._elements) do
            if e._root then e._root.LayoutOrder = i end
        end
    end
    local w = self._window
    if w then
        for i, e in ipairs(w._elements) do
            if e == self then table.remove(w._elements, i) break end
        end
    end
    if self._root then self._root:Destroy() end
    self._destroyed = true
end

local function rowHover(el)
    if IS_MOBILE then return end
    local row = el._root
    track(el, row.MouseEnter:Connect(function()
        if el._locked then return end
        tween(row, { BackgroundColor3 = ACTIVE.SurfaceHover }, MOTION.hover)
    end))
    track(el, row.MouseLeave:Connect(function()
        tween(row, { BackgroundColor3 = ACTIVE.Surface }, MOTION.hover)
    end))
end

local function hitButton(el, zindex)
    return new("TextButton", {
        Name = "Hit",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = zindex or 10,
        Parent = el._root,
    })
end

function Section:AddButton(config)
    if type(config) == "string" then config = { Name = config } end
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { controlWidth = 26, controlHeight = 26 })
    el.Type = "Button"
    el._callback = config.Callback
    local style = config.Style or "Default"
    if el._nameLabel and style ~= "Default" then
        local key = style == "Danger" and "Danger" or style == "Accent" and "Accent" or "Text"
        el._nameLabel.TextColor3 = theme[key]
        bind(el, el._nameLabel, "TextColor3", key)
    end

    local chevBox = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        ZIndex = 4,
        Parent = el._right,
    })
    local chev = iconChevron(chevBox, 13, theme.Muted, 0, 5)
    el._paint = function() tintIcon(chev, ACTIVE.Muted) end

    rowHover(el)
    local hit = hitButton(el)
    if not IS_MOBILE then
        track(el, hit.MouseEnter:Connect(function()
            if el._locked then return end
            tintIcon(chev, ACTIVE.Text)
            tween(chevBox, { Position = UDim2.new(1, 3, 0.5, 0) }, MOTION.hover)
        end))
        track(el, hit.MouseLeave:Connect(function()
            tintIcon(chev, ACTIVE.Muted)
            tween(chevBox, { Position = UDim2.new(1, 0, 0.5, 0) }, MOTION.hover)
        end))
    end

    pressable(el, hit, el._inner, function()
        if el._callback then el._callback() end
    end, { rippleColor = theme.Accent, rippleAlpha = 0.9, pressScale = 0.99 })

    function el:Click() if self._callback and not self._locked then self._callback() end end
    return el
end

function Section:AddToggle(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { controlWidth = 40, controlHeight = 20 })
    el.Type = "Toggle"
    el._callback = config.Callback
    el.Value = config.Default and true or false

    local KNOB_OFF_X, KNOB_ON_X = 4, 23

    local track_ = new("Frame", {
        Name = "Track",
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = el.Value and 0 or 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 20),
        ZIndex = 4,
        Parent = el._right,
    })
    corner(track_, RADIUS.pill)
    bind(el, track_, "BackgroundColor3", "Accent")
    sheen(track_, 0.88, nil, 90)
    local ts = stroke(track_, theme.Track, 1, el.Value and 1 or 0)
    bind(el, ts, "Color", "Track")
    local halo = accentGlow(track_, theme.Accent, 6, 0.82, 3)
    halo.Visible = el.Value
    for _, l in ipairs(halo:GetChildren()) do bind(el, l, "BackgroundColor3", "Accent") end

    local knob = new("Frame", {
        Name = "Knob",
        BackgroundColor3 = el.Value and theme.KnobOn or theme.KnobOff,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, el.Value and KNOB_ON_X or KNOB_OFF_X, 0.5, 0),
        Size = UDim2.new(0, 13, 0, 13),
        ZIndex = 6,
        Parent = track_,
    })
    corner(knob, RADIUS.pill)

    local function paint(animate)
        local on = el.Value
        local info = animate and MOTION.standard or TweenInfo.new(0)
        tw(track_, info, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = ACTIVE.Accent })
        tw(ts, info, { Transparency = on and 1 or 0, Color = ACTIVE.Track })
        halo.Visible = on
        tw(knob, info, {
            Position = UDim2.new(0, on and KNOB_ON_X or KNOB_OFF_X, 0.5, 0),
            BackgroundColor3 = on and ACTIVE.KnobOn or ACTIVE.KnobOff,
        })
    end
    el._paint = paint

    function el:Set(value, silent)
        self.Value = value and true or false
        paint(true)
        if not silent and self._callback then
            task.spawn(function() self._callback(self.Value) end)
        end
    end
    el.SetValue = el.Set
    el.Update = el.Set

    rowHover(el)
    local hit = hitButton(el)
    pressable(el, hit, nil, function()
        el:Set(not el.Value)
    end, { ripple = false })

    track(el, hit.InputBegan:Connect(function(input)
        if isClick(input) and not el._locked then
            tw(knob, MOTION.press, { Size = UDim2.new(0, 17, 0, 13) })
        end
    end))
    track(el, hit.InputEnded:Connect(function(input)
        if isClick(input) then tw(knob, MOTION.release, { Size = UDim2.new(0, 13, 0, 13) }) end
    end))
    if not IS_MOBILE then
        track(el, hit.MouseEnter:Connect(function()
            if el._locked then return end
            tw(knob, MOTION.hover, { Size = UDim2.new(0, 15, 0, 15) })
        end))
        track(el, hit.MouseLeave:Connect(function()
            tw(knob, MOTION.hover, { Size = UDim2.new(0, 13, 0, 13) })
        end))
    end

    if el.Value and config.Callback and config.FireOnCreate ~= false then
        task.defer(function() if not el._destroyed then config.Callback(true) end end)
    end
    return el
end

function Section:AddSlider(config)
    config = config or {}
    local theme = ACTIVE
    local min = config.Min or 0
    local max = config.Max or 100
    local inc = config.Increment or 1
    local suffix = config.Suffix or ""
    local el = baseRow(self, config, { autoHeight = true })
    el.Type = "Slider"
    el._callback = config.Callback

    local decimals = 0
    do
        local s = tostring(inc)
        local dot = s:find("%.")
        if dot then decimals = #s - dot end
        if decimals > 4 then decimals = 4 end
    end

    local function fmt(v)
        if decimals == 0 then return tostring(math.floor(v + 0.5)) end
        return string.format("%." .. decimals .. "f", v)
    end

    local valueBtn = new("TextButton", {
        Name = "Value",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, -2),
        Size = UDim2.new(0, 62, 0, 22),
        ZIndex = 7,
        Parent = el._inner,
    })
    corner(valueBtn, RADIUS.sm)
    bind(el, valueBtn, "BackgroundColor3", "Element")
    local vs = stroke(valueBtn, theme.StrokeSoft, 1, 0.45)
    bind(el, vs, "Color", "StrokeSoft")

    local valueBox = new("TextBox", {
        BackgroundTransparency = 1,
        Text = fmt(config.Default or min) .. suffix,
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        TextEditable = config.Typeable ~= false,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 8,
        Parent = valueBtn,
    })
    bind(el, valueBox, "TextColor3", "Text")

    el._left.Size = UDim2.new(1, -74, 0, 0)

    local spacer = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 2),
        LayoutOrder = 9,
        Parent = el._left,
    })

    local bar = new("Frame", {
        Name = "Bar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 24),
        LayoutOrder = 10,
        ZIndex = 4,
        Parent = el._left,
    })

    local rail = new("Frame", {
        Name = "Rail",
        BackgroundColor3 = theme.Track,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4),
        ZIndex = 4,
        Parent = bar,
    })
    corner(rail, RADIUS.pill)
    bind(el, rail, "BackgroundColor3", "Track")

    local fill = new("Frame", {
        Name = "Fill",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 5,
        Parent = rail,
    })
    corner(fill, RADIUS.pill)
    bind(el, fill, "BackgroundColor3", "Accent")
    sheen(fill, 0.80, nil, 0)

    local knob = new("Frame", {
        Name = "Knob",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        ZIndex = 7,
        Parent = rail,
    })
    corner(knob, RADIUS.pill)
    bind(el, knob, "BackgroundColor3", "Element")
    local ks = stroke(knob, theme.Stroke, 1, 0.1)
    bind(el, ks, "Color", "Stroke")

    local core = new("Frame", {
        Name = "Core",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
        ZIndex = 8,
        Parent = knob,
    })
    corner(core, RADIUS.pill)
    bind(el, core, "BackgroundColor3", "Accent")

    if not IS_MOBILE then
        track(el, bar.MouseEnter:Connect(function()
            if el._locked then return end
            tw(core, MOTION.hover, { Size = UDim2.new(0, 12, 0, 12) })
        end))
        track(el, bar.MouseLeave:Connect(function()
            tw(core, MOTION.hover, { Size = UDim2.new(0, 10, 0, 10) })
        end))
    end

    local function snap(v)
        v = math.clamp(v, min, max)
        if inc > 0 then v = min + math.floor((v - min) / inc + 0.5) * inc end
        return math.clamp(v, min, max)
    end

    local function paint(animate)
        local alpha = (max - min) == 0 and 0 or (el.Value - min) / (max - min)
        local info = animate and MOTION.quick or TweenInfo.new(0)
        tw(fill, info, { Size = UDim2.new(alpha, 0, 1, 0) })
        tw(knob, info, { Position = UDim2.new(alpha, 0, 0.5, 0) })
        valueBox.Text = fmt(el.Value) .. suffix
    end

    el.Value = snap(config.Default or min)

    function el:Set(value, silent)
        local v = tonumber(value)
        if not v then return end
        self.Value = snap(v)
        paint(true)
        if not silent and self._callback then
            task.spawn(function() self._callback(self.Value) end)
        end
    end
    el.SetValue = el.Set
    el.Update = el.Set

    function el:SetRange(newMin, newMax)
        min, max = newMin or min, newMax or max
        self:Set(self.Value, true)
    end

    local dragging = false
    local activeInput
    local function fromInput(pos)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return el.Value end
        local a = math.clamp((pos - abs) / w, 0, 1)
        return min + a * (max - min)
    end

    local scrolls
    track(el, bar.InputBegan:Connect(function(input)
        if not isClick(input) or el._locked or dragging then return end
        dragging = true
        activeInput = input
        scrolls = ancestorScrolling(bar, false)
        tw(core, MOTION.quick, { Size = UDim2.new(0, 8, 0, 8) })
        el:Set(fromInput(input.Position.X))
    end))

    local function endDrag()
        if not dragging then return end
        dragging = false
        activeInput = nil
        if scrolls then
            for _, s in ipairs(scrolls) do pcall(function() s.ScrollingEnabled = true end) end
            scrolls = nil
        end
        tw(core, MOTION.release, { Size = UDim2.new(0, 10, 0, 10) })
    end
    track(el, UserInputService.InputEnded:Connect(function(input)
        if ownsInput(activeInput, input) then endDrag() end
    end))
    track(el, UserInputService.InputChanged:Connect(function(input)
        if not dragging or not tracksInput(activeInput, input) then return end
        el:Set(fromInput(input.Position.X))
    end))

    track(el, valueBox.FocusLost:Connect(function()
        if el._locked then paint(false) return end
        local raw = valueBox.Text:gsub("[^%d%.%-]", "")
        local v = tonumber(raw)
        if v then el:Set(v) else paint(false) end
    end))
    if not IS_MOBILE then
        track(el, valueBtn.MouseEnter:Connect(function()
            tween(valueBtn, { BackgroundColor3 = ACTIVE.ElementHover }, MOTION.hover)
        end))
        track(el, valueBtn.MouseLeave:Connect(function()
            tween(valueBtn, { BackgroundColor3 = ACTIVE.Element }, MOTION.hover)
        end))
    end

    paint(false)
    if config.Default ~= nil and config.Callback and config.FireOnCreate then
        task.defer(function() if not el._destroyed then config.Callback(el.Value) end end)
    end
    return el
end
local function pill(parent, theme, width, height)
    local p = new("TextButton", {
        Name = "Pill",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, width, 0, height or 26),
        ClipsDescendants = true,
        ZIndex = 7,
        Parent = parent,
    })
    corner(p, RADIUS.sm)
    local s = stroke(p, theme.StrokeSoft, 1, 0.4)
    return p, s
end

function Section:AddDropdown(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { autoHeight = true })
    el.Type = "Dropdown"
    el._callback = config.Callback
    el._multi = config.Multi and true or false
    el._options = {}
    for i, v in ipairs(config.Options or {}) do el._options[i] = tostring(v) end

    if el._nameLabel then el._nameLabel.Size = UDim2.new(1, -134, 0, 15) end
    if el._descLabel then el._descLabel.Size = UDim2.new(1, -134, 0, 0) end

    local head, hs = pill(el._inner, theme, 124, 26)
    head.AnchorPoint = Vector2.new(1, 0)
    head.Position = UDim2.new(1, 0, 0, el._descLabel and 3 or 0)
    bind(el, head, "BackgroundColor3", "Element")
    bind(el, hs, "Color", "StrokeSoft")

    local headText = text({
        Text = "None",
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 9, 0, 0),
        Size = UDim2.new(1, -26, 1, 0),
        ZIndex = 8,
        Parent = head,
    })
    bind(el, headText, "TextColor3", "SubText")

    local caretBox = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        ZIndex = 8,
        Parent = head,
    })
    local caret = iconChevron(caretBox, 11, theme.Muted, 90, 9)

    local menu = new("Frame", {
        Name = "Menu",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        LayoutOrder = 20,
        ZIndex = 4,
        Parent = el._left,
    })
    corner(menu, RADIUS.md)
    bind(el, menu, "BackgroundColor3", "Element")
    local ms = stroke(menu, theme.StrokeSoft, 1, 0.4)
    bind(el, ms, "Color", "StrokeSoft")

    local menuPad = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 4,
        Parent = menu,
    })

    local filterBox
    local searchable = config.Searchable
    if searchable == nil then searchable = #el._options > 6 end

    local optScroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, searchable and 34 or 6),
        Size = UDim2.new(1, -12, 1, searchable and -40 or -12),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Muted,
        ScrollBarImageTransparency = 0.5,
        ZIndex = 5,
        Parent = menuPad,
    })
    list(optScroll, 2)

    if searchable then
        local fw = new("Frame", {
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 6, 0, 6),
            Size = UDim2.new(1, -12, 0, 24),
            ZIndex = 5,
            Parent = menuPad,
        })
        corner(fw, RADIUS.sm)
        bind(el, fw, "BackgroundColor3", "Surface")
        filterBox = new("TextBox", {
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = "Filter...",
            PlaceholderColor3 = theme.Muted,
            Font = FONT.body,
            TextSize = 11,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -14, 1, 0),
            ZIndex = 6,
            Parent = fw,
        })
        bind(el, filterBox, "TextColor3", "Text")
        bind(el, filterBox, "PlaceholderColor3", "Muted")
    end

    el._open = false
    el._rows = {}
    el.Value = el._multi and {} or nil

    local function isSelected(opt)
        if el._multi then
            for _, v in ipairs(el.Value) do if v == opt then return true end end
            return false
        end
        return el.Value == opt
    end

    local function label()
        if el._multi then
            if #el.Value == 0 then return "None" end
            if #el.Value <= 2 then return table.concat(el.Value, ", ") end
            return #el.Value .. " selected"
        end
        return el.Value or "None"
    end

    local function paintRows()
        for opt, row in pairs(el._rows) do
            local on = isSelected(opt)
            tween(row.check, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = ACTIVE.Accent }, MOTION.quick)
            fadeIcon(row.mark, on and 0 or 1)
            if on then tintIcon(row.mark, ACTIVE.AccentText) end
            if row.stroke then row.stroke.Color = ACTIVE.Muted end
            tween(row.label, { TextColor3 = on and ACTIVE.Text or ACTIVE.SubText }, MOTION.quick)
            tween(row.frame, { BackgroundTransparency = on and 0.85 or 1, BackgroundColor3 = ACTIVE.Accent }, MOTION.quick)
        end
        headText.Text = label()
        local hasValue
        if el._multi then hasValue = #el.Value > 0 else hasValue = el.Value ~= nil end
        headText.TextColor3 = hasValue and ACTIVE.Text or ACTIVE.SubText
    end
    el._paint = paintRows

    local function menuHeight()
        local count = 0
        for _, row in pairs(el._rows) do
            if row.frame.Visible then count = count + 1 end
        end
        local h = math.min(count, 6) * 28 + (searchable and 40 or 12)
        return math.max(h, searchable and 46 or 34)
    end

    local function setOpen(state)
        if state and el._locked then return end
        el._open = state
        if state then
            closeOpenPanel(el)
            BPUI._openPanel = el
            if el._window and el._window._hideTooltip then el._window:_hideTooltip() end
            menu.Visible = true
            tw(caret, MOTION.standard, { Rotation = -90 })
            tw(menu, MOTION.standard, { Size = UDim2.new(1, 0, 0, menuHeight()) })
            tween(hs, { Color = ACTIVE.Accent, Transparency = 0.1 }, MOTION.hover)
        else
            if BPUI._openPanel == el then BPUI._openPanel = nil end
            tw(caret, MOTION.standard, { Rotation = 90 })
            local t = tw(menu, MOTION.standard, { Size = UDim2.new(1, 0, 0, 0) })
            tween(hs, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
            if t then t.Completed:Connect(function() if not el._open then menu.Visible = false end end)
            else menu.Visible = false end
        end
    end

    local function choose(opt)
        if el._multi then
            local found
            for i, v in ipairs(el.Value) do if v == opt then found = i break end end
            if found then table.remove(el.Value, found) else table.insert(el.Value, opt) end
        else
            el.Value = opt
            setOpen(false)
        end
        paintRows()
        if el._callback then
            local payload = el._multi and shallowCopy(el.Value) or el.Value
            task.spawn(function() el._callback(payload) end)
        end
    end

    local function buildRows()
        for _, row in pairs(el._rows) do row.frame:Destroy() end
        el._rows = {}
        for i, opt in ipairs(el._options) do
            local frame = new("TextButton", {
                BackgroundColor3 = ACTIVE.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Size = UDim2.new(1, 0, 0, 26),
                LayoutOrder = i,
                ClipsDescendants = true,
                ZIndex = 6,
                Parent = optScroll,
            })
            corner(frame, RADIUS.sm)

            local check = new("Frame", {
                BackgroundColor3 = ACTIVE.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 7, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                ZIndex = 7,
                Parent = frame,
            })
            corner(check, el._multi and 4 or RADIUS.pill)
            local cstroke = stroke(check, ACTIVE.Muted, 1, 0.5)

            local mark = iconCheck(check, 10, ACTIVE.AccentText, 8)
            fadeIcon(mark, 1, TweenInfo.new(0))

            local lbl = text({
                Text = opt,
                Font = FONT.body,
                TextSize = 11,
                TextColor3 = ACTIVE.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.new(0, 28, 0, 0),
                Size = UDim2.new(1, -34, 1, 0),
                ZIndex = 7,
                Parent = frame,
            })

            if not IS_MOBILE then
                track(el, frame.MouseEnter:Connect(function()
                    if not isSelected(opt) then
                        tween(frame, { BackgroundTransparency = 0.9, BackgroundColor3 = ACTIVE.SurfaceHover }, MOTION.hover)
                    end
                end))
                track(el, frame.MouseLeave:Connect(function()
                    if not isSelected(opt) then tween(frame, { BackgroundTransparency = 1 }, MOTION.hover) end
                end))
            end
            pressable(el, frame, frame, function() choose(opt) end, { rippleAlpha = 0.92, pressScale = 0.99 })

            el._rows[opt] = { frame = frame, check = check, mark = mark, label = lbl, stroke = cstroke }
        end
    end

    if filterBox then
        track(el, filterBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = filterBox.Text:lower()
            for opt, row in pairs(el._rows) do
                row.frame.Visible = q == "" or opt:lower():find(q, 1, true) ~= nil
            end
            if el._open then tw(menu, MOTION.quick, { Size = UDim2.new(1, 0, 0, menuHeight()) }) end
        end))
    end

    pressable(el, head, head, function() setOpen(not el._open) end, { rippleAlpha = 0.92, pressScale = 0.98 })
    if not IS_MOBILE then
        track(el, head.MouseEnter:Connect(function()
            if not el._open then tween(head, { BackgroundColor3 = ACTIVE.ElementHover }, MOTION.hover) end
        end))
        track(el, head.MouseLeave:Connect(function()
            tween(head, { BackgroundColor3 = ACTIVE.Element }, MOTION.hover)
        end))
    end

    function el:Set(value, silent)
        if self._multi then
            local t = {}
            if type(value) == "table" then
                for _, v in ipairs(value) do
                    for _, o in ipairs(self._options) do
                        if o == tostring(v) then table.insert(t, o) break end
                    end
                end
            end
            self.Value = t
        else
            local found
            for _, o in ipairs(self._options) do
                if o == tostring(value) then found = o break end
            end
            self.Value = found
        end
        paintRows()
        if not silent and self._callback then
            local payload = self._multi and shallowCopy(self.Value) or self.Value
            task.spawn(function() self._callback(payload) end)
        end
    end
    el.SetValue = el.Set
    el.Update = el.Set

    function el:Refresh(options, keepValue)
        self._options = {}
        for i, v in ipairs(options or {}) do self._options[i] = tostring(v) end
        buildRows()
        if keepValue then self:Set(self.Value, true)
        else self.Value = self._multi and {} or nil end
        paintRows()
        if self._open then tw(menu, MOTION.quick, { Size = UDim2.new(1, 0, 0, menuHeight()) }) end
    end

    function el:Open() setOpen(true) end
    function el:Close() setOpen(false) end

    buildRows()
    if config.Default ~= nil then el:Set(config.Default, true) end
    paintRows()
    return el
end

function Section:AddInput(config)
    config = config or {}
    local theme = ACTIVE
    local width = config.Width or 132
    local el = baseRow(self, config, { controlWidth = width, controlHeight = 28 })
    el.Type = "Input"
    el._callback = config.Callback
    el.Value = config.Default or ""

    local wrap = new("Frame", {
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, width, 0, 28),
        ZIndex = 7,
        Parent = el._right,
    })
    corner(wrap, RADIUS.sm)
    bind(el, wrap, "BackgroundColor3", "Element")
    local ws = stroke(wrap, theme.StrokeSoft, 1, 0.4)
    bind(el, ws, "Color", "StrokeSoft")

    local box = new("TextBox", {
        BackgroundTransparency = 1,
        Text = el.Value,
        PlaceholderText = config.Placeholder or "",
        PlaceholderColor3 = theme.Muted,
        Font = FONT.body,
        TextSize = 12,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = config.ClearOnFocus or false,
        Size = UDim2.new(1, -18, 1, 0),
        Position = UDim2.new(0, 9, 0, 0),
        ZIndex = 8,
        Parent = wrap,
    })
    bind(el, box, "TextColor3", "Text")
    bind(el, box, "PlaceholderColor3", "Muted")

    track(el, box.Focused:Connect(function()
        tween(ws, { Color = ACTIVE.Accent, Transparency = 0 }, MOTION.hover)
        tween(wrap, { BackgroundColor3 = ACTIVE.ElementHover }, MOTION.hover)
    end))

    local function commit(text_, enter)
        if config.Numeric then text_ = text_:gsub("[^%d%.%-]", "") end
        if config.MaxLength and #text_ > config.MaxLength then text_ = text_:sub(1, config.MaxLength) end
        el.Value = text_
        box.Text = text_
        if el._callback then task.spawn(function() el._callback(text_, enter) end) end
    end

    track(el, box.FocusLost:Connect(function(enter)
        tween(ws, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
        tween(wrap, { BackgroundColor3 = ACTIVE.Element }, MOTION.hover)
        if el._locked then box.Text = el.Value return end
        commit(box.Text, enter)
        if config.RemoveTextAfterFocusLost then box.Text = "" el.Value = "" end
    end))

    if config.CallbackOnChange then
        track(el, box:GetPropertyChangedSignal("Text"):Connect(function()
            if box:IsFocused() then
                el.Value = box.Text
                if el._callback then task.spawn(function() el._callback(box.Text, false) end) end
            end
        end))
    end

    function el:Set(value, silent)
        self.Value = tostring(value or "")
        box.Text = self.Value
        if not silent and self._callback then
            task.spawn(function() self._callback(self.Value, false) end)
        end
    end
    el.SetValue = el.Set
    el.Update = el.Set
    return el
end

function Section:AddKeybind(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { controlWidth = 92, controlHeight = 26 })
    el.Type = "Keybind"
    el._callback = config.Callback
    el._onChanged = config.OnChanged
    el._mode = config.Mode or "Press"
    el._key = keyFromValue(config.Default)
    el.Value = keyName(el._key)
    el._state = false

    local p, ps = pill(el._right, theme, 92, 26)
    bind(el, p, "BackgroundColor3", "Element")
    bind(el, ps, "Color", "StrokeSoft")

    local lbl = text({
        Text = el.Value,
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = el._key and theme.Text or theme.Muted,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8,
        Parent = p,
    })

    local listening = false
    local function setLabel()
        lbl.Text = listening and "..." or el.Value
        lbl.TextColor3 = listening and ACTIVE.Accent or (el._key and ACTIVE.Text or ACTIVE.Muted)
    end
    el._paint = setLabel

    local function stopListening()
        if not listening then return end
        listening = false
        BPUI._activeKeybindCancel = nil
        setLabel()
        tween(ps, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
    end

    pressable(el, p, p, function()
        if listening then stopListening() return end
        if BPUI._activeKeybindCancel then BPUI._activeKeybindCancel() end
        listening = true
        BPUI._activeKeybindCancel = stopListening
        setLabel()
        tween(ps, { Color = ACTIVE.Accent, Transparency = 0.05 }, MOTION.hover)
    end, { rippleAlpha = 0.92 })

    track(el, UserInputService.InputBegan:Connect(function(input, gp)
        if el._destroyed then return end
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then stopListening() return end
                if input.KeyCode == Enum.KeyCode.Backspace then
                    el._key = nil
                    el.Value = "None"
                    stopListening()
                    if el._onChanged then task.spawn(function() el._onChanged(nil) end) end
                    return
                end
                el._key = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                el._key = input.UserInputType
            else
                return
            end
            el.Value = keyName(el._key)
            stopListening()
            if el._onChanged then task.spawn(function() el._onChanged(el._key) end) end
            return
        end
        if gp or el._locked or not el._key then return end
        local hit = (input.KeyCode == el._key) or (input.UserInputType == el._key)
        if not hit then return end
        if el._mode == "Toggle" then
            el._state = not el._state
            if el._callback then task.spawn(function() el._callback(el._state) end) end
        elseif el._mode == "Hold" then
            el._state = true
            if el._callback then task.spawn(function() el._callback(true) end) end
        else
            if el._callback then task.spawn(function() el._callback() end) end
        end
    end))

    track(el, UserInputService.InputEnded:Connect(function(input)
        if el._destroyed or el._mode ~= "Hold" or not el._key then return end
        local hit = (input.KeyCode == el._key) or (input.UserInputType == el._key)
        if hit and el._state then
            el._state = false
            if el._callback then task.spawn(function() el._callback(false) end) end
        end
    end))

    function el:Set(value, silent)
        self._key = keyFromValue(value)
        self.Value = keyName(self._key)
        setLabel()
        if not silent and self._onChanged then
            task.spawn(function() self._onChanged(self._key) end)
        end
    end
    el.SetValue = el.Set
    el.Update = el.Set
    function el:GetKeyCode() return self._key end
    return el
end
local function toHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function fromHex(str)
    if type(str) ~= "string" then return nil end
    local hex = str:gsub("#", ""):gsub("%s", "")
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local function toColor(v)
    if typeof(v) == "Color3" then return v end
    if type(v) == "string" then return fromHex(v) end
    if type(v) == "table" and v[1] then return Color3.fromRGB(v[1], v[2] or 0, v[3] or 0) end
    return nil
end

function Section:AddColorPicker(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { autoHeight = true })
    el.Type = "ColorPicker"
    el._callback = config.Callback
    el.Value = toColor(config.Default) or theme.Accent

    if el._nameLabel then el._nameLabel.Size = UDim2.new(1, -92, 0, 15) end
    if el._descLabel then el._descLabel.Size = UDim2.new(1, -92, 0, 0) end

    local swatchBtn = new("TextButton", {
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, el._descLabel and 3 or 0),
        Size = UDim2.new(0, 82, 0, 26),
        ClipsDescendants = true,
        ZIndex = 7,
        Parent = el._inner,
    })
    corner(swatchBtn, RADIUS.sm)
    bind(el, swatchBtn, "BackgroundColor3", "Element")
    local sbs = stroke(swatchBtn, theme.StrokeSoft, 1, 0.4)
    bind(el, sbs, "Color", "StrokeSoft")

    local chip = new("Frame", {
        BackgroundColor3 = el.Value,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        ZIndex = 8,
        Parent = swatchBtn,
    })
    corner(chip, 5)
    stroke(chip, Color3.new(1, 1, 1), 1, 0.75)

    local hexLabel = text({
        Text = toHex(el.Value),
        Font = FONT.mono,
        TextSize = 10,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        ZIndex = 8,
        Parent = swatchBtn,
    })
    bind(el, hexLabel, "TextColor3", "SubText")

    local panel = new("Frame", {
        Name = "Panel",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Visible = false,
        LayoutOrder = 20,
        ZIndex = 4,
        Parent = el._left,
    })
    corner(panel, RADIUS.md)
    bind(el, panel, "BackgroundColor3", "Element")
    local pns = stroke(panel, theme.StrokeSoft, 1, 0.4)
    bind(el, pns, "Color", "StrokeSoft")

    local sv = new("Frame", {
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(1, -20, 0, 86),
        ZIndex = 5,
        Parent = panel,
    })
    corner(sv, RADIUS.sm)

    local whiteLayer = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
        Parent = sv,
    })
    corner(whiteLayer, RADIUS.sm)
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 0,
        Parent = whiteLayer,
    })

    local blackLayer = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 7,
        Parent = sv,
    })
    corner(blackLayer, RADIUS.sm)
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = blackLayer,
    })

    local cursor = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 9,
        Parent = sv,
    })
    corner(cursor, RADIUS.pill)
    stroke(cursor, Color3.new(1, 1, 1), 2, 0)
    local cursorInner = stroke(cursor, Color3.new(0, 0, 0), 1, 0.6)

    local hue = new("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 104),
        Size = UDim2.new(1, -20, 0, 12),
        ZIndex = 5,
        Parent = panel,
    })
    corner(hue, RADIUS.pill)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hue,
    })

    local hueKnob = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 6, 0, 18),
        ZIndex = 6,
        Parent = hue,
    })
    corner(hueKnob, 3)
    stroke(hueKnob, Color3.new(0, 0, 0), 1, 0.7)

    local hexWrap = new("Frame", {
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 124),
        Size = UDim2.new(1, -20, 0, 26),
        ZIndex = 5,
        Parent = panel,
    })
    corner(hexWrap, RADIUS.sm)
    bind(el, hexWrap, "BackgroundColor3", "Surface")

    local hexBox = new("TextBox", {
        BackgroundTransparency = 1,
        Text = toHex(el.Value),
        Font = FONT.mono,
        TextSize = 11,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
        Parent = hexWrap,
    })
    bind(el, hexBox, "TextColor3", "Text")

    local h, s, v = el.Value:ToHSV()

    local function apply(fire)
        el.Value = Color3.fromHSV(h, s, v)
        chip.BackgroundColor3 = el.Value
        hexLabel.Text = toHex(el.Value)
        hexBox.Text = toHex(el.Value)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        if fire and el._callback then
            task.spawn(function() el._callback(el.Value) end)
        end
    end

    local svDragging, hueDragging = false, false
    local svScrolls, hueScrolls
    local svInput, hueInput

    local function svFrom(pos)
        local abs, size = sv.AbsolutePosition, sv.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then return end
        s = math.clamp((pos.X - abs.X) / size.X, 0, 1)
        v = 1 - math.clamp((pos.Y - abs.Y) / size.Y, 0, 1)
        apply(true)
    end
    local function hueFrom(pos)
        local abs, size = hue.AbsolutePosition, hue.AbsoluteSize
        if size.X <= 0 then return end
        h = math.clamp((pos.X - abs.X) / size.X, 0, 1)
        apply(true)
    end

    track(el, sv.InputBegan:Connect(function(input)
        if not isClick(input) or el._locked or svDragging then return end
        svDragging = true
        svInput = input
        svScrolls = ancestorScrolling(sv, false)
        svFrom(input.Position)
    end))
    track(el, hue.InputBegan:Connect(function(input)
        if not isClick(input) or el._locked or hueDragging then return end
        hueDragging = true
        hueInput = input
        hueScrolls = ancestorScrolling(hue, false)
        hueFrom(input.Position)
    end))
    track(el, UserInputService.InputEnded:Connect(function(input)
        if svDragging and ownsInput(svInput, input) then
            svDragging, svInput = false, nil
            if svScrolls then
                for _, x in ipairs(svScrolls) do pcall(function() x.ScrollingEnabled = true end) end
                svScrolls = nil
            end
        end
        if hueDragging and ownsInput(hueInput, input) then
            hueDragging, hueInput = false, nil
            if hueScrolls then
                for _, x in ipairs(hueScrolls) do pcall(function() x.ScrollingEnabled = true end) end
                hueScrolls = nil
            end
        end
    end))
    track(el, UserInputService.InputChanged:Connect(function(input)
        if svDragging and tracksInput(svInput, input) then svFrom(input.Position) end
        if hueDragging and tracksInput(hueInput, input) then hueFrom(input.Position) end
    end))

    track(el, hexBox.FocusLost:Connect(function()
        if el._locked then hexBox.Text = toHex(el.Value) return end
        local c = fromHex(hexBox.Text)
        if c then
            h, s, v = c:ToHSV()
            apply(true)
        else
            hexBox.Text = toHex(el.Value)
        end
    end))

    el._open = false
    local function setOpen(state)
        if state and el._locked then return end
        el._open = state
        if state then
            closeOpenPanel(el)
            BPUI._openPanel = el
            if el._window and el._window._hideTooltip then el._window:_hideTooltip() end
            panel.Visible = true
            tw(panel, MOTION.standard, { Size = UDim2.new(1, 0, 0, 160) })
            tween(sbs, { Color = ACTIVE.Accent, Transparency = 0.1 }, MOTION.hover)
        else
            if BPUI._openPanel == el then BPUI._openPanel = nil end
            local t = tw(panel, MOTION.standard, { Size = UDim2.new(1, 0, 0, 0) })
            tween(sbs, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
            if t then t.Completed:Connect(function() if not el._open then panel.Visible = false end end)
            else panel.Visible = false end
        end
    end

    pressable(el, swatchBtn, swatchBtn, function() setOpen(not el._open) end, { rippleAlpha = 0.92 })

    function el:Set(value, silent)
        local c = toColor(value)
        if not c then return end
        h, s, v = c:ToHSV()
        apply(not silent)
    end
    el.SetValue = el.Set
    el.Update = el.Set
    function el:Open() setOpen(true) end
    function el:Close() setOpen(false) end

    apply(false)
    return el
end

function Section:AddLabel(config)
    if type(config) == "string" then config = { Text = config } end
    config = config or {}
    local theme = ACTIVE
    local el = setmetatable({}, Element)
    el.Type = "Label"
    el._section = self
    el._window = self._window
    el._connections = {}
    el._bindings = {}
    el._name = config.Text or config.Name or ""
    el._description = ""

    local row = new("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #self._elements + 1,
        ZIndex = 3,
        Parent = self._card,
    })
    el._root = row
    pad(row, 4, 4, 6, 4)

    local style = config.Style or "Default"
    local color = theme.SubText
    if style == "Accent" then color = theme.Accent
    elseif style == "Sub" then color = theme.SubText
    elseif style == "Success" then color = theme.Success
    elseif style == "Warning" then color = theme.Warning
    elseif style == "Error" or style == "Danger" then color = theme.Danger end

    local lbl = text({
        Text = el._name,
        Font = config.Bold and FONT.bold or FONT.body,
        TextSize = config.TextSize or 12,
        TextColor3 = color,
        TextXAlignment = config.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
        Parent = row,
    })
    el._label = lbl
    el.Value = el._name

    function el:Set(str)
        self._name = tostring(str or "")
        self.Value = self._name
        lbl.Text = self._name
    end
    el.SetValue = el.Set
    el.SetText = el.Set
    el.Update = el.Set
    function el:SetName(str) self:Set(str) end
    function el:SetDescription() end
    function el:SetLocked() end
    function el:Lock() end
    function el:Unlock() end

    table.insert(self._elements, el)
    table.insert(el._window._elements, el)
    registerFlag(el, config.Flag)
    return el
end

function Section:AddParagraph(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, {
        Name = config.Title or config.Name or "",
        Description = config.Content or config.Text or "",
        Flag = config.Flag,
    }, { autoHeight = true, wrapName = true })
    el.Type = "Paragraph"
    el.Value = el._description
    if el._nameLabel then el._nameLabel.Font = FONT.bold end

    function el:SetTitle(str) self:SetName(str) end
    function el:SetContent(str)
        self:SetDescription(str)
        self.Value = str
    end
    function el:Set(str) self:SetContent(str) end
    el.SetValue = el.Set
    el.Update = el.Set
    return el
end

function Section:AddDivider(height)
    local theme = ACTIVE
    local el = setmetatable({}, Element)
    el.Type = "Divider"
    el._section = self
    el._window = self._window
    el._connections = {}
    el._bindings = {}
    el._name = ""
    el._description = ""

    local row = new("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, type(height) == "number" and height or 9),
        LayoutOrder = #self._elements + 1,
        ZIndex = 3,
        Parent = self._card,
    })
    el._root = row
    local line = new("Frame", {
        BackgroundColor3 = theme.StrokeSoft,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.new(1, -28, 0, 1),
        ZIndex = 3,
        Parent = row,
    })
    bind(el, line, "BackgroundColor3", "StrokeSoft")

    function el:Set() end
    function el:SetName() end
    function el:SetDescription() end
    function el:SetLocked() end
    function el:Lock() end
    function el:Unlock() end

    table.insert(self._elements, el)
    table.insert(el._window._elements, el)
    return el
end

Section.CreateButton = Section.AddButton
Section.CreateToggle = Section.AddToggle
Section.CreateSlider = Section.AddSlider
Section.CreateDropdown = Section.AddDropdown
Section.CreateInput = Section.AddInput
Section.CreateKeybind = Section.AddKeybind
Section.CreateColorPicker = Section.AddColorPicker
Section.CreateLabel = Section.AddLabel
Section.CreateParagraph = Section.AddParagraph
Section.CreateDivider = Section.AddDivider
Section.AddTextbox = Section.AddInput
Section.AddColorpicker = Section.AddColorPicker

for _, method in ipairs({
    "AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput",
    "AddKeybind", "AddColorPicker", "AddLabel", "AddParagraph", "AddDivider",
}) do
    Tab[method] = function(self, config)
        if not self._defaultSection then
            self._defaultSection = self:CreateSection({ Name = "" })
        end
        return self._defaultSection[method](self._defaultSection, config)
    end
    Tab[method:gsub("^Add", "Create")] = Tab[method]
end
Tab.CreateSection = Tab.CreateSection
Tab.AddSection = Tab.CreateSection
function Window:Dialog(config)
    config = config or {}
    local theme = ACTIVE
    if self._minimized then self:Minimize(false) end
    closeOpenPanel(nil)
    self:_hideTooltip()

    local overlay = new("Frame", {
        Name = "Dialog",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Active = true,
        ZIndex = 40,
        Parent = self._main,
    })
    tw(overlay, MOTION.standard, { BackgroundTransparency = 0.45 })

    local slot, card, syncConn = autoSlot(overlay, {
        Name = "DialogSlot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        WidthScale = 0,
        WidthOffset = 330,
        Color = theme.Surface,
        ZIndex = 41,
    })
    corner(card, RADIUS.lg)
    local cs = stroke(card, theme.Stroke, 1, 0.2)
    edgeLight(cs, theme)
    dropShadow(slot, 22, RADIUS.lg, 0.82, 41)
    sheen(card, 0.975, nil, 90)

    local sc = new("UIScale", { Scale = 0.94, Parent = card })
    tw(sc, MOTION.reveal, { Scale = 1 })

    local body = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 43,
        Parent = card,
    })
    pad(body, 18, 18, 16, 18)
    list(body, 8)

    text({
        Text = config.Title or "Confirm",
        Font = FONT.bold,
        TextSize = 15,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ZIndex = 43,
        Parent = body,
    })

    if config.Content and config.Content ~= "" then
        text({
            Text = config.Content,
            Font = FONT.body,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 43,
            Parent = body,
        })
    end

    local buttonRow = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = 3,
        ZIndex = 43,
        Parent = body,
    })
    local brl = list(buttonRow, 8, Enum.FillDirection.Horizontal)
    brl.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local closed = false
    local holders = {}
    local function close()
        if closed then return end
        closed = true
        pcall(function() syncConn:Disconnect() end)
        for _, h in ipairs(holders) do untrack(h) end
        holders = {}
        tw(sc, MOTION.quick, { Scale = 0.95 })
        local t = tw(overlay, MOTION.quick, { BackgroundTransparency = 1 })
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then tw(d, MOTION.quick, { TextTransparency = 1 })
            elseif d:IsA("Frame") then tw(d, MOTION.quick, { BackgroundTransparency = 1 })
            elseif d:IsA("ImageLabel") then tw(d, MOTION.quick, { ImageTransparency = 1 })
            elseif d:IsA("UIStroke") then tw(d, MOTION.quick, { Transparency = 1 }) end
        end
        tw(card, MOTION.quick, { BackgroundTransparency = 1 })
        local done = false
        local function finish()
            if done then return end
            done = true
            pcall(function() overlay:Destroy() end)
        end
        if t then t.Completed:Connect(finish) end
        task.delay(0.3, finish)
    end

    local buttons = config.Buttons or { { Text = "OK" } }
    for i, spec in ipairs(buttons) do
        local style = spec.Style or "Default"
        local bg = theme.Element
        local fg = theme.Text
        if style == "Accent" then bg, fg = theme.Accent, theme.AccentText
        elseif style == "Danger" then bg, fg = theme.Danger, Color3.new(1, 1, 1) end

        local b = new("TextButton", {
            BackgroundColor3 = bg,
            BackgroundTransparency = style == "Default" and 0.1 or 0,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(0, math.max(74, #(spec.Text or "OK") * 8 + 26), 0, 32),
            LayoutOrder = i,
            ClipsDescendants = true,
            ZIndex = 44,
            Parent = buttonRow,
        })
        corner(b, RADIUS.sm)
        if style == "Default" then stroke(b, theme.StrokeSoft, 1, 0.35) end
        sheen(b, style == "Default" and 0.95 or 0.82, 1, 90)

        text({
            Text = spec.Text or "OK",
            Font = FONT.medium,
            TextSize = 12,
            TextColor3 = fg,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 45,
            Parent = b,
        })

        if not IS_MOBILE then
            b.MouseEnter:Connect(function()
                tween(b, { BackgroundTransparency = style == "Default" and 0 or 0.12 }, MOTION.hover)
            end)
            b.MouseLeave:Connect(function()
                tween(b, { BackgroundTransparency = style == "Default" and 0.1 or 0 }, MOTION.hover)
            end)
        end

        local holder = { _connections = {} }
        table.insert(holders, holder)
        pressable(holder, b, b, function()
            close()
            if spec.Callback then task.spawn(spec.Callback) end
        end, { rippleAlpha = 0.88 })
    end

    return { Close = close }
end

keyPrompt = function(window, config, title)
    local theme = ACTIVE
    local store = window._folder .. "/key.txt"

    if config.SaveKey ~= false and FS.Available and FS.exists(store) then
        local saved = FS.read(store)
        if saved and saved ~= "" then
            local ok = false
            if config.Validate then
                local s, r = pcall(config.Validate, saved)
                ok = s and r and true or false
            else
                local keys = config.Keys or { config.Key }
                for _, k in ipairs(keys) do
                    if config.CaseSensitive and k == saved then ok = true break end
                    if not config.CaseSensitive and tostring(k):lower() == saved:lower() then ok = true break end
                end
            end
            if ok then return true end
            FS.delete(store)
        end
    end

    local sg = new("ScreenGui", {
        Name = "BPUI_Key",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9500,
        Parent = guiParent(),
    })
    window._keyGui = sg

    local slot, card, syncConn = autoSlot(sg, {
        Name = "KeySystem",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        WidthScale = 0,
        WidthOffset = 360,
        Color = theme.Window,
        ZIndex = 1,
    })
    card.Active = true
    corner(card, RADIUS.xl)
    local cs = stroke(card, theme.Stroke, 1, 0.15)
    edgeLight(cs, theme)
    dropShadow(slot, 24, RADIUS.xl, 0.82, 1)
    sheen(card, 0.975, nil, 90)

    local sc = new("UIScale", { Scale = 0.95, Parent = card })
    tw(sc, MOTION.reveal, { Scale = 1 })

    local body = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
        Parent = card,
    })
    pad(body, 22, 22, 20, 22)
    list(body, 10)

    text({
        Text = config.Title or (title .. " - Key System"),
        Font = FONT.bold,
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ZIndex = 3,
        Parent = body,
    })

    if config.Subtitle or config.Note then
        text({
            Text = config.Subtitle or config.Note,
            Font = FONT.body,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 3,
            Parent = body,
        })
    end

    local inputWrap = new("Frame", {
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        LayoutOrder = 3,
        ZIndex = 3,
        Parent = body,
    })
    corner(inputWrap, RADIUS.md)
    local iws = stroke(inputWrap, theme.StrokeSoft, 1, 0.35)

    local box = new("TextBox", {
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Enter key",
        PlaceholderColor3 = theme.Muted,
        Font = FONT.medium,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        ZIndex = 4,
        Parent = inputWrap,
    })
    box.Focused:Connect(function() tween(iws, { Color = ACTIVE.Accent, Transparency = 0.05 }, MOTION.hover) end)
    box.FocusLost:Connect(function() tween(iws, { Color = ACTIVE.StrokeSoft, Transparency = 0.35 }, MOTION.hover) end)

    local status = text({
        Text = "",
        Font = FONT.body,
        TextSize = 11,
        TextColor3 = theme.Danger,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 4,
        ZIndex = 3,
        Parent = body,
    })

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = 5,
        ZIndex = 3,
        Parent = body,
    })
    local rl = list(row, 8, Enum.FillDirection.Horizontal)
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local result = nil
    local attempts = 0
    local holders = {}

    local function mkButton(label, style, order, fn)
        local bg = style == "Accent" and theme.Accent or theme.Element
        local fg = style == "Accent" and theme.AccentText or theme.Text
        local b = new("TextButton", {
            BackgroundColor3 = bg,
            BackgroundTransparency = style == "Accent" and 0 or 0.1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.new(0, math.max(80, #label * 8 + 24), 0, 34),
            LayoutOrder = order,
            ClipsDescendants = true,
            ZIndex = 4,
            Parent = row,
        })
        corner(b, RADIUS.sm)
        if style ~= "Accent" then stroke(b, theme.StrokeSoft, 1, 0.35) end
        sheen(b, style == "Accent" and 0.82 or 0.95, 1, 90)
        text({
            Text = label,
            Font = FONT.medium,
            TextSize = 12,
            TextColor3 = fg,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5,
            Parent = b,
        })
        local holder = { _connections = {} }
        table.insert(holders, holder)
        pressable(holder, b, b, fn, { rippleAlpha = 0.88 })
        return b
    end

    local function fail(message)
        status.Text = message
        status.TextTransparency = 0
        tween(iws, { Color = ACTIVE.Danger, Transparency = 0 }, MOTION.hover)
        local basePos = slot.Position
        for i = 1, 3 do
            task.delay((i - 1) * 0.06, function()
                if not slot.Parent then return end
                slot.Position = basePos + UDim2.new(0, (i % 2 == 0) and -6 or 6, 0, 0)
            end)
        end
        task.delay(0.22, function() if slot.Parent then slot.Position = basePos end end)
    end

    local function submit()
        local entered = box.Text
        if entered == "" then fail("Enter a key to continue.") return end
        local ok = false
        if config.Validate then
            local s, r = pcall(config.Validate, entered)
            ok = s and r and true or false
        else
            local keys = config.Keys or { config.Key }
            for _, k in ipairs(keys) do
                if config.CaseSensitive and k == entered then ok = true break end
                if not config.CaseSensitive and tostring(k):lower() == entered:lower() then ok = true break end
            end
        end
        if ok then
            if config.SaveKey ~= false and FS.Available then FS.write(store, entered) end
            result = true
        else
            attempts = attempts + 1
            if config.MaxAttempts and attempts >= config.MaxAttempts then
                result = false
            else
                fail("Invalid key." .. (config.MaxAttempts and (" " .. (config.MaxAttempts - attempts) .. " left.") or ""))
            end
        end
    end

    if config.GetKeyLink or config.OnGetKey then
        mkButton("Get Key", "Default", 1, function()
            if config.OnGetKey then task.spawn(config.OnGetKey) end
            if config.GetKeyLink then
                if clipboard(config.GetKeyLink) then
                    BPUI:Notify({ Title = "Copied", Content = "Key link copied to clipboard.", Type = "Success" })
                else
                    BPUI:Notify({ Title = "Key link", Content = config.GetKeyLink, Duration = 10 })
                end
            end
        end)
    end
    mkButton("Verify", "Accent", 2, submit)
    box.FocusLost:Connect(function(enter) if enter then submit() end end)

    while result == nil do
        if window._destroyed or not sg.Parent then result = false break end
        task.wait(0.05)
    end

    for _, h in ipairs(holders) do untrack(h) end
    pcall(function() syncConn:Disconnect() end)
    tw(sc, MOTION.quick, { Scale = 0.95 })
    task.delay(0.2, function() if sg then sg:Destroy() end end)
    window._keyGui = nil
    return result
end
local function serializeValue(el)
    local v = el.Value
    if typeof(v) == "Color3" then
        return {
            __t = "Color3",
            r = math.floor(v.R * 255 + 0.5),
            g = math.floor(v.G * 255 + 0.5),
            b = math.floor(v.B * 255 + 0.5),
        }
    end
    if type(v) == "table" then
        local copy = {}
        for i, item in ipairs(v) do copy[i] = item end
        return copy
    end
    return v
end

local function deserializeValue(v)
    if type(v) == "table" and v.__t == "Color3" then
        return Color3.fromRGB(v.r or 0, v.g or 0, v.b or 0)
    end
    return v
end

function Window:GetConfigs()
    local out = {}
    if not FS.Available then return out end
    for _, path in ipairs(FS.list(self._folder .. "/configs")) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

function Window:SaveConfig(name)
    if not FS.Available then
        BPUI:Notify({ Title = "Unavailable", Content = "This executor has no file system.", Type = "Warning" })
        return false
    end
    name = tostring(name or "default"):gsub("[^%w%-_ ]", "")
    if name == "" then return false end
    local data = {}
    for flag, el in pairs(BPUI.Flags) do
        if el and not el._destroyed and el._root and el._root.Parent and el.Value ~= nil then
            data[flag] = serializeValue(el)
        end
    end
    local ok, raw = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    FS.folder(self._folder .. "/configs")
    local wrote = FS.write(self._folder .. "/configs/" .. name .. ".json", raw)
    if wrote then
        BPUI:Notify({ Title = "Config saved", Content = name, Type = "Success" })
    end
    return wrote
end

function Window:LoadConfig(name)
    if not FS.Available then return false end
    name = tostring(name or "default")
    local path = self._folder .. "/configs/" .. name .. ".json"
    if not FS.exists(path) then
        BPUI:Notify({ Title = "Not found", Content = name, Type = "Error" })
        return false
    end
    local raw = FS.read(path)
    if not raw then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return false end
    for flag, value in pairs(data) do
        local el = BPUI.Flags[flag]
        local v = deserializeValue(value)
        if el and el.Set and not el._destroyed then
            pcall(function() el:Set(v) end)
        else
            BPUI._pendingFlags[flag] = v
        end
    end
    BPUI:Notify({ Title = "Config loaded", Content = name, Type = "Success" })
    return true
end

function Window:DeleteConfig(name)
    if not FS.Available then return false end
    local path = self._folder .. "/configs/" .. tostring(name) .. ".json"
    if not FS.exists(path) then return false end
    FS.delete(path)
    BPUI:Notify({ Title = "Config deleted", Content = tostring(name), Type = "Warning" })
    return true
end

function Window:SetAutoLoad(name)
    self._settings.AutoLoad = name
    self:_saveSettings()
    return true
end

function Window:GetAutoLoad() return self._settings.AutoLoad end

function Window:LoadAutoConfig()
    local name = self._settings.AutoLoad
    if name and name ~= "" then return self:LoadConfig(name) end
    return false
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    for i, w in ipairs(BPUI.Windows) do
        if w == self then table.remove(BPUI.Windows, i) break end
    end

    for _, el in ipairs(self._elements) do
        if el._flag then BPUI.Flags[el._flag] = nil end
        untrack(el)
        el._destroyed = true
    end
    for _, tab in ipairs(self._tabs) do
        for _, section in ipairs(tab._sections) do untrack(section) end
        untrack(tab)
    end
    for _, g in ipairs(self._groups or {}) do untrack(g) end
    untrack(self)

    if self._keyGui then pcall(function() self._keyGui:Destroy() end) end
    if self._blur then
        local blur = self._blur
        self._blur = nil
        pcall(function()
            local t = tw(blur, MOTION.quick, { Size = 0 })
            task.delay(0.25, function() pcall(function() blur:Destroy() end) end)
        end)
    end
    if BPUI._openPanel and BPUI._openPanel._window == self then BPUI._openPanel = nil end

    local gui = self._gui
    tw(self._scale, MOTION.quick, { Scale = self._fit * 0.94 })
    tw(self._main, MOTION.quick, { BackgroundTransparency = 1 })
    if self._float then
        for _, d in ipairs(self._float:GetDescendants()) do
            if d:IsA("TextLabel") then tw(d, MOTION.quick, { TextTransparency = 1 })
            elseif d:IsA("Frame") then tw(d, MOTION.quick, { BackgroundTransparency = 1 })
            elseif d:IsA("UIStroke") then tw(d, MOTION.quick, { Transparency = 1 }) end
        end
    end
    for _, d in ipairs(self._root:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then tw(d, MOTION.quick, { TextTransparency = 1 })
        elseif d:IsA("Frame") then tw(d, MOTION.quick, { BackgroundTransparency = 1 })
        elseif d:IsA("ImageLabel") then tw(d, MOTION.quick, { ImageTransparency = 1 })
        elseif d:IsA("UIStroke") then tw(d, MOTION.quick, { Transparency = 1 }) end
    end

    if self._cleanupKey then ENV[self._cleanupKey] = nil end
    task.delay(0.3, function() if gui then pcall(function() gui:Destroy() end) end end)
    if self._onDestroy then task.spawn(self._onDestroy) end
end

function BPUI:SetTheme(theme)
    local resolved = resolveTheme(theme)
    ACTIVE = resolved
    for i = #BPUI.Windows, 1, -1 do
        local w = BPUI.Windows[i]
        if w._destroyed then
            table.remove(BPUI.Windows, i)
        else
            w._theme = resolved
            applyBindings(w, resolved)
            for _, g in ipairs(w._groups or {}) do
                applyBindings(g, resolved)
                if g._chev then tintIcon(g._chev, resolved.Muted) end
            end
            for _, tab in ipairs(w._tabs) do
                applyBindings(tab, resolved)
                for _, section in ipairs(tab._sections) do
                    applyBindings(section, resolved)
                    for _, el in ipairs(section._elements) do
                        applyBindings(el, resolved)
                        if el._paint then pcall(function() el._paint(false) end) end
                    end
                end
            end
            if w._activeTab then
                local active = w._activeTab
                w._activeTab = nil
                active:Select(true)
            end
            if type(theme) == "string" then
                w._settings.Theme = theme
                w:_saveSettings()
            end
        end
    end
    return resolved
end

function BPUI:SetAccent(color)
    local c = toColor(color)
    if not c then return end
    ACTIVE.Accent = c
    for _, w in ipairs(BPUI.Windows) do
        if not w._destroyed then
            w._settings.Accent = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
            w:_saveSettings()
        end
    end
    BPUI:SetTheme(ACTIVE)
end

function BPUI:GetFlag(flag)
    local el = BPUI.Flags[flag]
    if el then return el.Value end
    return BPUI._pendingFlags[flag]
end

function BPUI:SetFlag(flag, value)
    local el = BPUI.Flags[flag]
    if el and el.Set then return el:Set(value) end
    BPUI._pendingFlags[flag] = value
end

function BPUI:GetThemes()
    local names = {}
    for name in pairs(BPUI.Themes) do table.insert(names, name) end
    table.sort(names)
    return names
end

function BPUI:Destroy()
    for i = #BPUI.Windows, 1, -1 do
        local w = BPUI.Windows[i]
        pcall(function() w:Destroy() end)
    end
    for _, toast in ipairs(NOTIFY.items) do pcall(function() toast:Dismiss() end) end
    NOTIFY.items = {}
    if NOTIFY.gui then pcall(function() NOTIFY.gui:Destroy() end) end
    NOTIFY.holder, NOTIFY.gui = nil, nil
end

buildSettingsTab = function(window, config)
    local tab = window:CreateTab({
        Name = config.SettingsName or "Settings",
        Subtitle = "Interface, themes and saved configurations",
        Icon = config.SettingsIcon,
    })

    local appearance = tab:CreateSection("Appearance")

    appearance:AddDropdown({
        Name = "Theme",
        Description = "Colour palette used across the interface.",
        Options = BPUI:GetThemes(),
        Default = window._settings.Theme or ACTIVE.Name or "Obsidian",
        Callback = function(choice) BPUI:SetTheme(choice) end,
    })

    appearance:AddColorPicker({
        Name = "Accent colour",
        Description = "Highlight used for active states.",
        Default = ACTIVE.Accent,
        Callback = function(c) BPUI:SetAccent(c) end,
    })

    local behaviour = tab:CreateSection("Interface")

    if not IS_MOBILE then
        behaviour:AddKeybind({
            Name = "Toggle key",
            Description = "Shows and hides the window.",
            Default = window._toggleKey,
            Mode = "Press",
            OnChanged = function(key) window:SetToggleKey(key) end,
        })
    end

    behaviour:AddToggle({
        Name = "Floating button",
        Description = "A draggable bubble that opens the window.",
        Default = window._float ~= nil and window._float.Visible or false,
        Callback = function(state) window:SetFloatingButtonVisible(state) end,
    })

    behaviour:AddButton({
        Name = "Reset window size",
        Description = "Restores the default dimensions.",
        Callback = function()
            window._settings.Width, window._settings.Height = nil, nil
            window:_saveSettings()
            window._root.Size = UDim2.new(0, IS_MOBILE and 560 or 840, 0, IS_MOBILE and 400 or 580)
        end,
    })

    local configs = tab:CreateSection("Configuration")

    if not FS.Available then
        configs:AddParagraph({
            Title = "File system unavailable",
            Content = "This executor does not expose writefile/readfile, so configurations cannot be stored. Everything else works normally.",
        })
        return tab
    end

    local nameInput = configs:AddInput({
        Name = "Config name",
        Placeholder = "my-config",
        Width = 150,
    })

    local picker
    local function refreshPicker()
        local list_ = window:GetConfigs()
        if #list_ == 0 then list_ = { "-" } end
        picker:Refresh(list_, true)
    end

    picker = configs:AddDropdown({
        Name = "Saved configs",
        Options = (function()
            local l = window:GetConfigs()
            if #l == 0 then l = { "-" } end
            return l
        end)(),
        Default = window._settings.AutoLoad,
    })

    configs:AddButton({
        Name = "Save",
        Description = "Writes every flagged element to the named file.",
        Callback = function()
            local name = nameInput.Value
            if name == "" then name = picker.Value end
            if not name or name == "" or name == "-" then
                BPUI:Notify({ Title = "Name required", Content = "Type a config name first.", Type = "Warning" })
                return
            end
            window:SaveConfig(name)
            refreshPicker()
        end,
    })

    configs:AddButton({
        Name = "Load",
        Callback = function()
            local name = picker.Value
            if not name or name == "-" then
                BPUI:Notify({ Title = "Nothing selected", Content = "Pick a config to load.", Type = "Warning" })
                return
            end
            window:LoadConfig(name)
        end,
    })

    configs:AddButton({
        Name = "Delete",
        Callback = function()
            local name = picker.Value
            if not name or name == "-" then return end
            window:Dialog({
                Title = "Delete " .. name .. "?",
                Content = "This removes the saved file permanently.",
                Buttons = {
                    { Text = "Cancel" },
                    { Text = "Delete", Style = "Danger", Callback = function()
                        window:DeleteConfig(name)
                        refreshPicker()
                    end },
                },
            })
        end,
    })

    configs:AddToggle({
        Name = "Auto load on launch",
        Description = "Applies the selected config the next time the script runs.",
        Default = window._settings.AutoLoad ~= nil,
        Callback = function(state)
            if state then
                local name = picker.Value
                if name and name ~= "-" then
                    window:SetAutoLoad(name)
                    BPUI:Notify({ Title = "Auto load", Content = name, Type = "Success" })
                end
            else
                window:SetAutoLoad(nil)
            end
        end,
    })

    return tab
end

local rawCreateWindow = BPUI.CreateWindow

function BPUI:CreateWindow(config)
    config = config or {}

    if config.KeySystem then
        local folder = "BPUI/" .. (config.ConfigFolder or tostring(config.Title or "BPUI"):gsub("[^%w%-_ ]", ""))
        if FS.Available then FS.folder("BPUI") FS.folder(folder) end
        local shell = { _folder = folder, _destroyed = false }
        local passed = keyPrompt(shell, config.KeySystem, config.Title or "BPUI")
        if not passed then
            BPUI:Notify({ Title = "Access denied", Content = "The key was not accepted.", Type = "Error", Duration = 6 })
            return nil
        end
    end

    local window = rawCreateWindow(self, config)
    if not window then return nil end

    if config.ShowSettings ~= false then
        task.delay(0, function()
            if window._destroyed then return end
            local ok, err = pcall(buildSettingsTab, window, config)
            if not ok then warn("[BPUI] Settings tab failed: " .. tostring(err)) end
        end)
    end

    if config.AutoLoad ~= false then
        task.delay(config.AutoLoadDelay or 1, function()
            if window._destroyed then return end
            pcall(function() window:LoadAutoConfig() end)
        end)
    end

    return window
end

local function guard(tbl, names, label)
    for _, name in ipairs(names) do
        local original = tbl[name]
        if type(original) == "function" then
            tbl[name] = function(...)
                if not BPUI.SafeMode then return original(...) end
                local results = table.pack(pcall(original, ...))
                if results[1] then return table.unpack(results, 2, results.n) end
                warn("[BPUI] " .. label .. "." .. name .. " failed: " .. tostring(results[2]))
                local stub = setmetatable({ _stub = true, Type = "Stub" }, {
                    __index = function(_, key)
                        if key == "Value" or key == "_flag" or key == "_root"
                           or key == "_name" or key == "_description" then return nil end
                        return function() return nil end
                    end,
                })
                return stub
            end
        end
    end
end

guard(Section, {
    "AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput",
    "AddKeybind", "AddColorPicker", "AddLabel", "AddParagraph", "AddDivider",
    "CreateButton", "CreateToggle", "CreateSlider", "CreateDropdown", "CreateInput",
    "CreateKeybind", "CreateColorPicker", "CreateLabel", "CreateParagraph", "CreateDivider",
}, "Section")

guard(Tab, { "CreateSection", "AddSection" }, "Tab")

BPUI.Window = Window
BPUI.Tab = Tab
BPUI.Section = Section
BPUI.Element = Element
BPUI.Motion = MOTION
BPUI.Radius = RADIUS

return BPUI
