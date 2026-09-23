local BPUI = {
    Version = "2.15.0",
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

-- The layout is authored at a 1x, ~768p pixel grid. On a larger desktop
-- screen that leaves text at 10-12px physical size, which reads thin and
-- toy-like in-game, so the window and toasts are scaled up to a comfortable
-- physical size instead (1080p ~= 1.22x, 1440p hits the 1.4x cap). Mobile
-- keeps 1x -- its own fit logic already shrinks to the screen.
local function uiDensity()
    if IS_MOBILE then return 1 end
    local vp = viewport()
    return math.clamp(vp.Y / 840, 1, 1.4)
end

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

-- A tight, slightly sharper ladder than the generic "round everything 8-12px"
-- default: rows and panels stay closer to a rectangle (xs/sm/md) so the shell
-- reads as engineered rather than templated, and only pills/knobs/dots keep
-- the full pill radius. Every corner in the library resolves to one of these
-- six values -- nothing hand-picks its own number.
local RADIUS = { xs = 3, sm = 5, md = 7, lg = 9, xl = 10, pill = 999 }

-- One easing family for everything: Quint Out moves fast at the start and
-- settles over a long, soft tail, which is what reads as "fluid" rather than
-- "animated". Hover and press used to be Quad and release used to overshoot
-- with Back, so the three smallest, most-repeated interactions in the whole
-- UI each moved on a different curve. They are one system now. `spring` is
-- the deliberate exception: a small overshoot reserved for moments the UI
-- should feel snapped into place rather than merely arrived -- the nav
-- indicator, and a dropdown/colour popover opening. Closing never uses
-- it: a panel should snap open with a little confidence and get out of the
-- way instantly, not overshoot on its way out too.
local MOTION = {
    hover    = TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    press    = TweenInfo.new(0.07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    release  = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    spring   = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    quick    = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    standard = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    page     = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    reveal   = TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    ripple   = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- Void is opaque by design. It used to be glass, which only worked because
-- two big coloured glows sat behind it; with those gone, translucency would
-- just let the game bleed through and read as noise. Depth now comes from an
-- even tonal ladder -- sidebar (darkest) -> page -> row card -> inner control
-- -- with each step small enough to feel calm and large enough to separate.
BPUI.Themes.Void = {
    Name = "Void",
    Window       = rgb(15, 15, 19),
    Sidebar      = rgb(11, 11, 14),
    TitleBar     = rgb(15, 15, 19),
    Surface      = rgb(21, 21, 26),
    SurfaceHover = rgb(25, 25, 31),
    -- Element must stay clearly above SurfaceHover, not just above Surface:
    -- hovering the empty part of a row raises the card to SurfaceHover, and
    -- if the two met there, every control would dissolve into its own row
    -- the moment the cursor approached it.
    Element      = rgb(33, 33, 40),
    ElementHover = rgb(40, 40, 48),
    -- StrokeSoft sits ~9 above the card fill so a row reads as a contained
    -- object rather than a lighter smudge; Stroke stays clearly above that
    -- again so the window's own edge and the sidebar divider remain the
    -- strongest lines on screen. Controls are defined by their fill instead,
    -- which is why StrokeSoft may sit below Element.
    Stroke       = rgb(44, 44, 55),
    StrokeSoft   = rgb(30, 30, 37),
    Text         = rgb(244, 244, 248),
    SubText      = rgb(158, 160, 174),
    -- Muted carries the footer version line and every placeholder, both at
    -- small sizes -- kept light enough to clear 4.5:1 on the sidebar.
    Muted        = rgb(122, 124, 140),
    Accent       = rgb(214, 92, 196),
    AccentText   = rgb(255, 255, 255),
    Success      = rgb(84, 214, 150),
    Warning      = rgb(252, 196, 92),
    Danger       = rgb(255, 106, 122),
    Track        = rgb(50, 50, 62),
    KnobOn       = rgb(255, 255, 255),
    KnobOff      = rgb(170, 172, 190),
    SidebarAlpha = 0,
    SurfaceAlpha = 0,
    ElementAlpha = 0,
    Dark         = true,
}

BPUI.Themes.Nocturne = {
    Name = "Nocturne",
    SidebarAlpha = 0,
    SurfaceAlpha = 0,
    ElementAlpha = 0,
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

local ACTIVE = BPUI.Themes.Void

local function resolveTheme(v)
    local merged = {}
    for k, val in pairs(BPUI.Themes.Nocturne) do merged[k] = val end
    merged.SidebarAlpha, merged.SurfaceAlpha, merged.ElementAlpha = 0, 0, 0
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

-- sheen() and edgeLight() used to lay white-to-grey gradients over fills
-- and a bright top edge on strokes. In-game they read as a cheap plastic
-- glint rather than depth, so both are now deliberate no-ops: every surface
-- is a single flat colour and every hairline an even one. The call sites
-- stay so a theme could opt back in later without re-plumbing anything.
local function sheen() return nil end
local function edgeLight() return nil end

local function dropShadow(parent, spread, radius, alpha, zindex)
    spread = spread or 18
    radius = radius or RADIUS.lg
    alpha = alpha or 0.82
    local layers = 14
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
        local eased = f * f * (3 - 2 * f)
        local layer = new("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.992 + (alpha - 0.992) * eased,
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

-- Lucide icon sprites --------------------------------------------------
-- ~330 commonly used icons from the Lucide set (ISC license), embedded
-- directly as {assetId, x, y} sprite-sheet coordinates on a shared 48x48
-- grid (spread across a handful of separately-uploaded sheet assets, one
-- per assetId). No runtime network fetch is made to load this table --
-- unlike Rayfield, which pulls its icon table down on every load -- it
-- ships inside the library file itself. Every coordinate below
-- was read byte-exact out of the source sprite-sheet data with a Lua
-- interpreter, never hand-transcribed, since a wrong coordinate here is a
-- silent failure (it renders a different, real-looking icon, not an
-- error) with no way to catch it after the fact.
local ICON_SPRITE_SIZE = 48
local ICON_SPRITES = {
["activity"]={16898612629,514,771},
["alarm-clock"]={16898612629,257,820},
["anchor"]={16898612629,306,869},
["archive"]={16898612629,918,49},
["arrow-down"]={16898612629,967,49},
["arrow-down-right"]={16898612629,820,661},
["arrow-left"]={16898612629,98,918},
["arrow-right"]={16898612629,453,820},
["arrow-up"]={16898612629,967,355},
["arrow-up-right"]={16898612629,918,147},
["at-sign"]={16898612629,453,869},
["award"]={16898612629,918,661},
["axe"]={16898612629,869,710},
["banknote"]={16898612629,453,967},
["bar-chart-3"]={16898612629,918,759},
["battery"]={16898612629,967,857},
["battery-charging"]={16898612629,771,955},
["battery-low"]={16898612629,918,857},
["bell"]={16898612819,820,257},
["bell-off"]={16898612819,771,49},
["bell-ring"]={16898612819,0,820},
["bike"]={16898612819,771,563},
["bird"]={16898612819,869,0},
["bluetooth"]={16898612819,771,355},
["bolt"]={16898612819,306,820},
["bomb"]={16898612819,257,869},
["book"]={16898612819,820,612},
["book-open"]={16898612819,820,355},
["bookmark"]={16898612819,514,918},
["box"]={16898612819,771,196},
["brain"]={16898612819,967,257},
["brush"]={16898612819,404,820},
["bug"]={16898612819,257,967},
["building"]={16898612819,918,563},
["building-2"]={16898612819,967,514},
["bus"]={16898612819,820,661},
["calendar"]={16898612819,355,918},
["calendar-check"]={16898612819,967,49},
["calendar-days"]={16898612819,869,147},
["camera"]={16898612819,967,563},
["candy"]={16898612819,771,759},
["car"]={16898612819,918,147},
["check"]={16898612819,710,869},
["check-circle"]={16898612819,869,710},
["chevron-down"]={16898612819,196,918},
["chevron-left"]={16898612819,404,967},
["chevron-right"]={16898612819,869,759},
["chevron-up"]={16898612819,710,918},
["church"]={16898612819,771,906},
["circle"]={16898613044,771,355},
["circle-alert"]={16898612819,918,808},
["circle-dollar-sign"]={16898613044,257,771},
["circle-gauge"]={16898613044,0,820},
["circle-help"]={16898613044,820,257},
["clipboard"]={16898613044,49,869},
["clipboard-check"]={16898613044,869,514},
["clock"]={16898613044,771,661},
["cloud"]={16898613044,918,306},
["cloud-download"]={16898613044,612,820},
["cloud-lightning"]={16898613044,918,49},
["cloud-rain"]={16898613044,147,820},
["cloud-upload"]={16898613044,967,257},
["clover"]={16898613044,820,404},
["code"]={16898613044,355,869},
["cog"]={16898613044,918,563},
["coins"]={16898613044,869,612},
["columns"]={16898613044,661,820},
["compass"]={16898613044,514,967},
["contact"]={16898613044,49,967},
["copy"]={16898613044,918,612},
["cpu"]={16898613044,196,869},
["credit-card"]={16898613044,98,967},
["crop"]={16898613044,918,404},
["crosshair"]={16898613044,453,869},
["crown"]={16898613044,404,918},
["database"]={16898613044,710,869},
["diamond"]={16898613044,196,918},
["dices"]={16898613044,918,710},
["disc"]={16898613044,661,967},
["dna"]={16898613044,967,710},
["dog"]={16898613044,869,808},
["door-open"]={16898613044,967,759},
["download"]={16898613044,820,906},
["droplet"]={16898613044,820,955},
["droplets"]={16898613044,967,857},
["ear"]={16898613044,967,955},
["egg"]={16898613353,514,771},
["eraser"]={16898613353,820,257},
["expand"]={16898613353,306,771},
["external-link"]={16898613353,257,820},
["eye"]={16898613353,771,563},
["eye-off"]={16898613353,820,514},
["factory"]={16898613353,514,820},
["fast-forward"]={16898613353,820,49},
["feather"]={16898613353,771,98},
["file"]={16898613353,820,661},
["file-check"]={16898613353,563,820},
["file-plus"]={16898613353,918,49},
["file-text"]={16898613353,869,355},
["files"]={16898613353,771,710},
["film"]={16898613353,710,771},
["filter"]={16898613353,612,869},
["fingerprint"]={16898613353,563,918},
["fish"]={16898613353,869,147},
["flag"]={16898613353,98,918},
["flame"]={16898613353,967,306},
["flashlight"]={16898613353,869,404},
["flask-conical"]={16898613353,453,820},
["flower"]={16898613353,820,710},
["flower-2"]={16898613353,869,661},
["folder"]={16898613353,404,967},
["folder-open"]={16898613353,820,759},
["folder-plus"]={16898613353,661,918},
["footprints"]={16898613353,918,710},
["frown"]={16898613353,967,196},
["fuel"]={16898613353,196,967},
["gamepad"]={16898613353,967,759},
["gamepad-2"]={16898613353,710,967},
["gauge"]={16898613353,771,955},
["gauge-circle"]={16898613353,820,906},
["gem"]={16898613353,918,857},
["ghost"]={16898613353,869,906},
["gift"]={16898613353,820,955},
["git-branch"]={16898613353,918,906},
["git-commit-horizontal"]={16898613353,869,955},
["git-merge"]={16898613509,771,257},
["github"]={16898613509,0,820},
["glasses"]={16898613509,306,771},
["globe"]={16898613509,771,563},
["grab"]={16898613509,514,820},
["grid-2x2"]={16898613509,771,98},
["hammer"]={16898613509,306,820},
["hand"]={16898613509,563,820},
["hand-metal"]={16898613509,771,612},
["hard-drive"]={16898613509,820,98},
["hash"]={16898613509,147,771},
["headphones"]={16898613509,306,869},
["heart"]={16898613509,661,771},
["helping-hand"]={16898613509,514,918},
["hexagon"]={16898613509,967,0},
["highlighter"]={16898613509,918,49},
["history"]={16898613509,869,98},
["home"]={16898613509,820,147},
["hourglass"]={16898613509,49,918},
["image"]={16898613509,306,918},
["images"]={16898613509,257,967},
["inbox"]={16898613509,918,563},
["info"]={16898613509,612,869},
["key"]={16898613509,869,404},
["key-round"]={16898613509,967,306},
["keyboard"]={16898613509,453,820},
["landmark"]={16898613509,771,759},
["laptop"]={16898613509,563,967},
["laugh"]={16898613509,869,196},
["layers"]={16898613509,98,967},
["layout"]={16898613509,967,612},
["layout-dashboard"]={16898613509,967,355},
["layout-grid"]={16898613509,918,404},
["layout-list"]={16898613509,869,453},
["leaf"]={16898613509,918,661},
["library"]={16898613509,710,869},
["lightbulb"]={16898613509,918,196},
["line-chart"]={16898613509,196,918},
["link"]={16898613509,918,453},
["link-2"]={16898613509,967,404},
["list"]={16898613509,869,808},
["lock"]={16898613509,918,857},
["magnet"]={16898613509,967,906},
["mail"]={16898613613,820,0},
["map"]={16898613613,306,771},
["map-pin"]={16898613613,820,257},
["maximize"]={16898613613,771,563},
["medal"]={16898613613,563,771},
["meh"]={16898613613,820,49},
["menu"]={16898613613,49,820},
["mic"]={16898613613,820,612},
["mic-off"]={16898613613,918,514},
["minimize"]={16898613613,918,49},
["minus"]={16898613613,771,196},
["minus-circle"]={16898613613,869,98},
["monitor"]={16898613613,404,820},
["mountain"]={16898613613,869,612},
["mouse"]={16898613613,563,918},
["move"]={16898613613,453,820},
["music"]={16898613613,967,563},
["navigation"]={16898613613,771,759},
["navigation-2"]={16898613613,869,661},
["newspaper"]={16898613613,661,869},
["notebook"]={16898613613,869,196},
["octagon-alert"]={16898613613,918,404},
["orbit"]={16898613613,967,612},
["package"]={16898613613,918,196},
["package-check"]={16898613613,820,759},
["paintbrush"]={16898613613,918,453},
["palette"]={16898613613,453,918},
["palmtree"]={16898613613,404,967},
["panel-left"]={16898613613,967,453},
["paperclip"]={16898613613,918,857},
["pause"]={16898613699,0,771},
["paw-print"]={16898613699,771,257},
["pen"]={16898613699,771,49},
["pencil"]={16898613699,820,257},
["percent"]={16898613699,771,563},
["person-standing"]={16898613699,563,771},
["phone"]={16898613699,0,869},
["phone-call"]={16898613699,514,820},
["piggy-bank"]={16898613699,820,563},
["pin"]={16898613699,918,0},
["pipette"]={16898613699,869,49},
["plane"]={16898613699,98,820},
["play"]={16898613699,918,257},
["plug"]={16898613699,404,771},
["plug-2"]={16898613699,869,306},
["plus"]={16898613699,257,918},
["plus-circle"]={16898613699,355,820},
["power"]={16898613699,820,147},
["power-off"]={16898613699,918,49},
["printer"]={16898613699,196,771},
["puzzle"]={16898613699,49,918},
["rabbit"]={16898613699,869,355},
["radar"]={16898613699,820,404},
["radio"]={16898613699,306,918},
["receipt"]={16898613699,869,147},
["refresh-ccw"]={16898613699,820,453},
["refresh-cw"]={16898613699,404,869},
["repeat"]={16898613699,820,710},
["rewind"]={16898613699,563,967},
["rocket"]={16898613699,918,147},
["rotate-ccw"]={16898613699,967,355},
["rotate-cw"]={16898613699,869,453},
["route"]={16898613699,404,918},
["ruler"]={16898613699,710,869},
["sandwich"]={16898613699,918,196},
["save"]={16898613699,918,453},
["scale"]={16898613699,404,967},
["scan"]={16898613699,967,196},
["scan-eye"]={16898613699,869,759},
["scan-face"]={16898613699,820,808},
["school"]={16898613699,453,967},
["scissors"]={16898613699,820,857},
["screen-share"]={16898613699,710,967},
["search"]={16898613699,918,857},
["send"]={16898613699,967,857},
["server"]={16898613777,771,0},
["server-crash"]={16898613699,918,955},
["server-off"]={16898613699,967,955},
["settings"]={16898613777,771,257},
["settings-2"]={16898613777,0,771},
["share"]={16898613777,514,771},
["share-2"]={16898613777,771,514},
["shield"]={16898613777,869,0},
["shield-alert"]={16898613777,49,771},
["shield-check"]={16898613777,820,257},
["shield-off"]={16898613777,820,514},
["ship"]={16898613777,771,98},
["shopping-bag"]={16898613777,49,820},
["shopping-cart"]={16898613777,869,257},
["shuffle"]={16898613777,257,869},
["signal"]={16898613777,918,0},
["siren"]={16898613777,771,147},
["skip-back"]={16898613777,147,771},
["skip-forward"]={16898613777,98,820},
["skull"]={16898613777,49,869},
["sliders"]={16898613777,404,771},
["sliders-horizontal"]={16898613777,820,355},
["smartphone"]={16898613777,257,918},
["smile"]={16898613777,869,563},
["snowflake"]={16898613777,771,661},
["sparkle"]={16898613777,967,0},
["sparkles"]={16898613777,918,49},
["speaker"]={16898613777,869,98},
["sprout"]={16898613777,918,306},
["square"]={16898613777,869,710},
["square-pen"]={16898613777,710,820},
["squirrel"]={16898613777,771,808},
["stamp"]={16898613777,710,869},
["star"]={16898613777,967,147},
["sticky-note"]={16898613777,918,453},
["stop-circle"]={16898613777,453,918},
["store"]={16898613777,404,967},
["sun"]={16898613777,967,453},
["sun-moon"]={16898613777,967,196},
["sword"]={16898613777,710,967},
["swords"]={16898613777,967,759},
["syringe"]={16898613777,918,808},
["tablet"]={16898613777,918,906},
["tag"]={16898613777,967,906},
["tags"]={16898613777,918,955},
["target"]={16898613869,514,771},
["tent"]={16898613869,49,771},
["terminal"]={16898613869,820,257},
["thermometer"]={16898613869,869,257},
["thumbs-down"]={16898613869,820,306},
["thumbs-up"]={16898613869,771,355},
["timer"]={16898613869,918,0},
["tornado"]={16898613869,771,147},
["train-front"]={16898613869,404,771},
["trash"]={16898613869,918,514},
["trash-2"]={16898613869,257,918},
["tree-pine"]={16898613869,771,661},
["trending-down"]={16898613869,563,869},
["trending-up"]={16898613869,514,918},
["triangle"]={16898613869,869,98},
["triangle-alert"]={16898613869,967,0},
["trophy"]={16898613869,820,147},
["truck"]={16898613869,771,196},
["tv"]={16898613869,98,869},
["umbrella"]={16898613869,869,355},
["unlock"]={16898613869,771,710},
["upload"]={16898613869,612,869},
["usb"]={16898613869,563,918},
["user"]={16898613869,661,869},
["user-check"]={16898613869,918,98},
["user-minus"]={16898613869,49,967},
["user-plus"]={16898613869,918,355},
["user-x"]={16898613869,710,820},
["users"]={16898613869,967,98},
["utensils"]={16898613869,869,196},
["video"]={16898613869,355,967},
["video-off"]={16898613869,404,918},
["volume"]={16898613869,661,918},
["volume-2"]={16898613869,771,808},
["volume-x"]={16898613869,710,869},
["wallet"]={16898613869,147,967},
["wand"]={16898613869,404,967},
["wand-2"]={16898613869,918,453},
["warehouse"]={16898613869,967,661},
["watch"]={16898613869,869,759},
["waves"]={16898613869,820,808},
["wifi"]={16898613869,869,808},
["wifi-off"]={16898613869,918,759},
["wind"]={16898613869,820,857},
["wrench"]={16898613869,820,906},
["x"]={16898613869,869,906},
["x-circle"]={16898613869,771,955},
["zap"]={16898613869,918,906},
["zap-off"]={16898613869,967,857},
}

-- Names carried over from the old drawn-icon set (or otherwise convenient)
-- that aren't their own Lucide key, mapped onto the closest real icon. Kept
-- separate from ICON_SPRITES so that table stays pure, verified source data.
local ICON_ALIASES = {
    alert = "triangle-alert",
    chart = "bar-chart-3",
    config = "settings",
    dice = "dices",
    door = "door-open",
    esp = "scan-eye",
    fire = "flame",
    flask = "flask-conical",
    fps = "gauge-circle",
    gear = "cog",
    grid = "grid-2x2",
    money = "banknote",
    paw = "paw-print",
    question = "circle-help",
    refresh = "refresh-cw",
    thumbsup = "thumbs-up",
    tool = "wrench",
    warning = "triangle-alert",
    -- common guesses people type that Lucide spells differently
    house = "home",
    eggs = "egg",
    player = "user",
    person = "person-standing",
    run = "footprints",
    running = "footprints",
    walk = "footprints",
    teleport = "map-pin",
    tp = "map-pin",
    coin = "coins",
    ["dollar-sign"] = "circle-dollar-sign",
    dollar = "circle-dollar-sign",
    cash = "banknote",
    magic = "wand",
    lightning = "zap",
    bolt = "zap",
    tree = "tree-pine",
    moon = "sun-moon",
    pickaxe = "hammer",
    ["mouse-pointer"] = "mouse",
    cursor = "mouse",
    aim = "crosshair",
    aimbot = "crosshair",
    visuals = "eye",
    visual = "eye",
    misc = "list",
    main = "home",
    farm = "tree-pine",
    autofarm = "repeat",
    shop = "shopping-cart",
    store = "shopping-cart",
}

local function spriteFor(name)
    return ICON_SPRITES[name] or ICON_SPRITES[ICON_ALIASES[name]]
end

-- A flat membership/enumeration table shaped like the old ICONS table (name
-- -> truthy) so `if ICONS[key] then` lookups and the public `BPUI.Icons`
-- (exposed below, mainly for introspection/tests now) still work the same
-- way. It no longer carries drawing functions -- authoring a custom icon by
-- hand is gone along with the drawn pictogram system; a name outside this
-- set still works fine via `Icon = "rbxassetid://..."` or an emoji string.
local ICONS = {}
for name in pairs(ICON_SPRITES) do ICONS[name] = true end
for name in pairs(ICON_ALIASES) do ICONS[name] = true end

BPUI.Icons = ICONS

-- Builds one sliced-and-tinted icon ImageLabel from a {assetId, x, y} sprite
-- entry on the shared ICON_SPRITE_SIZE grid.
local function spriteIcon(parent, sprite, size, color, zindex)
    return new("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. sprite[1],
        ImageRectOffset = Vector2.new(sprite[2], sprite[3]),
        ImageRectSize = Vector2.new(ICON_SPRITE_SIZE, ICON_SPRITE_SIZE),
        ImageColor3 = color,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size, 0, size),
        ZIndex = zindex,
        Parent = parent,
    })
end

local function isAssetIcon(v)
    if type(v) == "number" then return true end
    if type(v) ~= "string" then return false end
    if v:match("^rbxasset") then return true end
    return v:match("^%s*%d+%s*$") ~= nil
end

-- `colored` opts a named icon into a flat ACTIVE.Accent tint instead of the
-- caller's base color (the `Colored = true` config flag). `iconColor`, when
-- given, wins over both and is remembered on the instance (IconLocked) so
-- later hover/selection/theme retinting -- which always goes through
-- tintIcon or a direct ImageColor3 tween -- leaves it alone.
local warnedOnce = {}
local function warnOnce(key, msg)
    if warnedOnce[key] then return end
    warnedOnce[key] = true
    warn(msg)
end

-- Whether iconAny() would draw anything for this value. Callers that reserve
-- room for an icon ask first, so a bad name leaves no empty gap. An ASCII word
-- that isn't a known icon (a typo, or a name from another library's icon
-- set) would otherwise print itself into an 18px box; it is dropped with a
-- one-time warning so the author can fix it. Emoji and one or two character
-- glyphs still render as text.
local function iconUsable(icon)
    if icon == nil or icon == "" or icon == false then return false end
    if type(icon) == "number" then return true end
    if type(icon) ~= "string" then return false end
    local key = icon:lower():gsub("^lucide:", ""):gsub("^icon:", "")
    if spriteFor(key) or isAssetIcon(icon) then return true end
    if #icon > 2 and not icon:find("[\128-\255]") then
        warnOnce("icon:" .. icon, "[BPUI] Unknown icon \"" .. icon .. "\" -- use a Lucide name (see BPUI.Icons), an emoji, or an rbxassetid. No icon is shown.")
        return false
    end
    return true
end

-- Calls fn() if an image asset turns out not to load (a deleted, private or
-- mistyped rbxassetid), so the owner can drop the empty slot it reserved.
local function whenAssetFails(img, fn)
    if typeof(img) ~= "Instance" then return end
    task.spawn(function()
        local status
        pcall(function()
            game:GetService("ContentProvider"):PreloadAsync({ img }, function(_, st) status = st end)
        end)
        if status == Enum.AssetFetchStatus.Failure and img.Parent then
            warnOnce("asset:" .. tostring(img.Image), "[BPUI] Icon " .. tostring(img.Image) .. " failed to load (deleted, private or not an image). It is hidden.")
            fn()
        end
    end)
end

local function iconAny(parent, icon, size, color, zindex, colored, iconColor)
    if icon == nil or icon == "" then return nil, nil end
    zindex = zindex or 5
    if type(icon) == "string" then
        local key = icon:lower():gsub("^lucide:", ""):gsub("^icon:", "")
        local sprite = spriteFor(key)
        if sprite then
            local tint = iconColor or (colored and ACTIVE.Accent) or color
            local i = spriteIcon(parent, sprite, size, tint, zindex)
            if iconColor or colored then i:SetAttribute("IconLocked", true) end
            return i, "draw"
        end
    end
    if isAssetIcon(icon) then
        local img = tostring(icon)
        if not img:match("^rbxasset") then img = "rbxassetid://" .. img:gsub("%D", "") end
        local i = new("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Image = img,
            ImageColor3 = iconColor or color,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, size, 0, size),
            ZIndex = zindex,
            Parent = parent,
        })
        if iconColor then i:SetAttribute("IconLocked", true) end
        return i, "image"
    end
    -- An ASCII word that isn't a known icon (a typo, or a name from another
    -- library's icon set) would otherwise print itself into an 18px box.
    -- Draw nothing -- the label then sits where the icon would have been --
    -- and say why once, so the author can fix the name. Emoji and one or two
    -- character glyphs still render as text.
    if not iconUsable(icon) then return nil, nil end
    local t = new("TextLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(icon),
        Font = Enum.Font.GothamMedium,
        TextSize = math.floor(size * 0.92),
        TextColor3 = iconColor or color,
        TextScaled = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, size + 6, 0, size + 6),
        ZIndex = zindex,
        Parent = parent,
    })
    return t, "text"
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

-- Re-tints an icon (used for hover/selection state and theme rebinding).
-- Named/asset icons built via iconAny are a single ImageLabel, so that's
-- just an ImageColor3 set -- EXCEPT when the icon carries an explicit
-- IconLocked attribute: that means it was given a fixed tint on purpose
-- (`Colored = true` or an explicit `IconColor`), and hover/selection/theme
-- changes must leave it alone rather than silently overwriting the one
-- color it was asked to keep. Internal chrome (a checkmark, a chevron, the
-- close cross, ...) is still a small stack of plain Frames built via
-- bar()/iconHolder() -- no "role" tagging, that belonged only to the
-- drawn-pictogram system these replaced -- so those get a flat recolor of
-- every child instead.
local function tintIcon(holder, color)
    if not holder then return end
    if holder:GetAttribute("IconLocked") == true then return end
    if holder:IsA("ImageLabel") then holder.ImageColor3 = color return end
    for _, c in ipairs(holder:GetChildren()) do
        if c:IsA("Frame") then
            if c.Name ~= "Stroke" then c.BackgroundColor3 = color end
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
            if c.Name == "Stroke" then
                local s = c:FindFirstChildOfClass("UIStroke")
                if s then tw(s, info or MOTION.quick, { Transparency = transparency }) end
            else
                tw(c, info or MOTION.quick, { BackgroundTransparency = transparency })
            end
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

local function bindIcon(owner, holder, key)
    if not owner or not holder then return end
    owner._iconBinds = owner._iconBinds or {}
    table.insert(owner._iconBinds, { holder = holder, key = key })
    if ACTIVE[key] then tintIcon(holder, ACTIVE[key]) end
end

local function applyBindings(owner, theme)
    if not owner then return end
    if owner._iconBinds then
        for i = #owner._iconBinds, 1, -1 do
            local b = owner._iconBinds[i]
            if b.holder and b.holder.Parent then
                if theme[b.key] then pcall(tintIcon, b.holder, theme[b.key]) end
            else
                table.remove(owner._iconBinds, i)
            end
        end
    end
    if not owner._bindings then return end
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

-- Press feedback: a brief wash over the pressed control that fades out.
-- It used to be a circle growing from the touch point -- but Roblox's
-- AutomaticSize measures descendants even when they're clipped, so that
-- circle briefly inflated whatever auto-sized row it sat in (a dropdown row
-- "opened" downward and snapped back on every click), and inside a
-- list-laid-out host it was laid out like an item and stretched the host.
-- The wash never extends past the host, and hosts driven by a layout get
-- no wash at all.
local function ripple(host, input, color, alpha)
    if not host or not host.Parent then return end
    local ok = pcall(function()
        if host:FindFirstChildOfClass("UIListLayout") or host:FindFirstChildOfClass("UIGridLayout") then return end
        local wash = new("Frame", {
            Name = "Ripple",
            BackgroundColor3 = color or Color3.new(1, 1, 1),
            BackgroundTransparency = alpha or 0.86,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = (host.ZIndex or 1) + 1,
            Parent = host,
        })
        local hc = host:FindFirstChildOfClass("UICorner")
        if hc then new("UICorner", { CornerRadius = hc.CornerRadius, Parent = wash }) end
        local fade = tw(wash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
        if fade then
            fade.Completed:Connect(function() wash:Destroy() end)
        end
        task.delay(0.55, function() if wash and wash.Parent then wash:Destroy() end end)
    end)
    return ok
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

-- Wrapped text inside a chain of AutomaticSize parents is measured by
-- Roblox before its width is settled, so it can come out one line tall and
-- clip everything after the first line. This pins the label's height to its
-- real TextBounds instead, and keeps it pinned as the text or width change.
local TextService = game:GetService("TextService")
local function fitWrapped(label, minH)
    if not label then return end
    minH = minH or 0
    -- Converges in two steps: while the text doesn't fit (TextFits false)
    -- the label grows to TextService's estimate; once it fits, it snaps to
    -- the renderer's own TextBounds, which is exact. Re-run whenever the
    -- text, the width or the fit changes.
    local function fit()
        local target
        pcall(function()
            local fits = label.TextFits
            local cur = label.Size.Y.Offset
            if fits == true then
                local tb = label.TextBounds.Y
                if tb and tb > 0 then target = math.max(minH, math.ceil(tb)) end
            else
                local sc = effectiveScale(label)
                if not sc or sc <= 0 then sc = 1 end
                local w = label.AbsoluteSize.X / sc
                if w >= 4 then
                    local est = TextService:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(w, 10000)).Y
                    target = math.max(minH, math.ceil(est))
                    -- the estimate can undershoot the real font by a line;
                    -- nudge past it, but never more than a few lines (a
                    -- single unbreakable word would otherwise never "fit").
                    if fits == false and cur >= target then
                        target = math.min(cur + label.TextSize, math.ceil(est) + label.TextSize * 3)
                    end
                end
            end
        end)
        if target and (label.Size.Y.Offset ~= target or label.Size.Y.Scale ~= 0) then
            label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset, 0, target)
        end
    end
    pcall(function()
        label.AutomaticSize = Enum.AutomaticSize.None
        label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset, 0, math.max(minH, (label.TextSize or 12) + 3))
        for _, prop in ipairs({ "AbsoluteSize", "Text", "TextBounds", "TextFits" }) do
            label:GetPropertyChangedSignal(prop):Connect(fit)
        end
    end)
    fit()
    task.defer(fit)
end

local function text(props)
    local t = new("TextLabel", props)
    t.BackgroundTransparency = props.BackgroundTransparency or 1
    t.BorderSizePixel = 0
    return t
end

-- A same-colour cover over a panel's contents, faded away right after it
-- opens. Without it, a menu's rows are already fully drawn the instant its
-- height starts growing, so the reveal reads as "a box got taller" rather
-- than "this appeared". With it, the box grows AND its contents materialise
-- a beat behind, which is what an intentional, unfolding motion feels like
-- instead of layout math playing out on screen.
local function panelVeil(parent, color, zindex)
    local veil = new("Frame", {
        Name = "Reveal",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = zindex or 9,
        Parent = parent,
    })
    return veil
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
    -- On desktop the toast stack gets the same physical-size scaling as the
    -- window (uiDensity). The UIScale sits on a full-screen wrapper anchored
    -- at the top-left and sized 1/d of the screen, so once scaled it covers
    -- the screen exactly and the holder inside keeps its ordinary 18px
    -- bottom-right inset.
    local d = uiDensity()
    local host2 = sg
    if d > 1 then
        host2 = new("Frame", {
            Name = "Scaled",
            BackgroundTransparency = 1,
            Size = UDim2.new(1 / d, 0, 1 / d, 0),
            Parent = sg,
        })
        new("UIScale", { Scale = d, Parent = host2 })
    end
    local holder = new("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        AnchorPoint = IS_MOBILE and Vector2.new(0.5, 0) or Vector2.new(1, 1),
        Position = IS_MOBILE and UDim2.new(0.5, 0, 0, 48) or UDim2.new(1, -18, 1, -18),
        Size = IS_MOBILE and UDim2.new(1, -28, 1, -64) or UDim2.new(0, 330, 1, -36),
        Parent = host2,
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
    fitWrapped(title)

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
        fitWrapped(content)
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

local TAB_H, TAB_GAP = 31, 3
-- Grouped tabs: how far the whole button shifts right, and where the tree
-- connector's trunk runs -- straight down from the centre of the group
-- header's icon (11 + 18/2), so the branch visibly grows out of its parent.
local BRANCH_INDENT, BRANCH_X = 30, 20

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
    local baseW = IS_MOBILE and 520 or 760
    local baseH = IS_MOBILE and 370 or 520
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

    local fit = math.min(uiDensity(), (vp.X - 32) / baseW, (vp.Y - 32) / baseH) * (config.Scale or 1)
    local sidebarW = config.SidebarWidth or (IS_MOBILE and 140 or 190)

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
        -- The UIScale below grows the window from its top-left corner, so
        -- centre it on its scaled footprint, not its authored one.
        Position = UDim2.new(0.5, -math.floor(baseW * fit / 2), 0.5, -math.floor(baseH * fit / 2)),
        Parent = sg,
    })
    self._root = root
    local rootScale = new("UIScale", { Scale = fit, Parent = root })
    self._scale = rootScale
    self._fit = fit

    self._shadow = dropShadow(root, 16, RADIUS.xl, 0.88, 0)

    local main = new("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Window,
        -- Fully opaque unless the script asks otherwise: a solid panel reads
        -- as one crisp object against whatever the game is doing behind it.
        BackgroundTransparency = config.Transparency or 0,
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
    self._mainStroke = mainStroke

    -- Open/close veil: a sheet of the window's own colour laid over the
    -- whole panel. Fading it out is what makes the contents appear; it is
    -- a single transparency tween, so it stays smooth where scaling the
    -- whole window (UIScale) made every label re-rasterise each frame and
    -- the animation stutter.
    local veil = new("Frame", {
        Name = "Veil",
        BackgroundColor3 = theme.Window,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 150,
        Parent = main,
    })
    corner(veil, RADIUS.xl)
    bind(self, veil, "BackgroundColor3", "Window")
    self._veil = veil

    local backdrop = new("Frame", {
        Name = "Backdrop",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = main,
    })
    self._backdrop = backdrop
    self._sectionStyle = config.SectionStyle or "Caps"

    local bgDefaults = { ImageAlpha = 0.7 }
    self._bg = {}
    for k, v in pairs(bgDefaults) do self._bg[k] = v end
    if type(config.Background) == "table" then
        for k, v in pairs(config.Background) do self._bg[k] = v end
    end
    if type(settings.Background) == "table" then
        -- Rebuilt rather than read in place: a settings.json written by an
        -- older version still carries Ambient/Orb1/Orb2/Watermark keys, and
        -- self._settings is the very table that gets re-encoded on every
        -- later save. Dropping them here is what lets an upgraded file
        -- actually converge on the current schema instead of carrying dead
        -- keys forever.
        local sb = settings.Background
        local clean = {}
        for _, k in ipairs({ "Image", "ImageAlpha", "ImageTile", "ImageTileSize" }) do
            if sb[k] ~= nil then
                clean[k] = sb[k]
                self._bg[k] = sb[k]
            end
        end
        settings.Background = clean
    end
    self:_buildBackground()

    local sidebar = new("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Sidebar,
        BackgroundTransparency = theme.SidebarAlpha or 0,
        BorderSizePixel = 0,
        Size = UDim2.new(0, sidebarW, 1, 0),
        Active = true,
        ZIndex = 2,
        Parent = main,
    })
    bind(self, sidebar, "BackgroundColor3", "Sidebar")
    bind(self, sidebar, "BackgroundTransparency", "SidebarAlpha")
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
    self._vdiv = vdiv

    local brand = new("Frame", {
        Name = "Brand",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 54),
        ZIndex = 3,
        Parent = sidebar,
    })
    pad(brand, 0, 14, 0, 14)

    local markSize = 0
    local useBox = config.BrandBox == true
    local mark
    if useBox then
        markSize = 28
        mark = new("Frame", {
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
        stroke(mark, Color3.new(1, 1, 1), 1, 0.78)
    elseif iconUsable(config.Icon) then
        markSize = 22
        mark = new("Frame", {
            Name = "Mark",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, markSize, 0, markSize),
            ZIndex = 4,
            Parent = brand,
        })
    end

    if iconUsable(config.Icon) and mark then
        local ico, kind = iconAny(mark, config.Icon, useBox and 18 or 22, useBox and theme.AccentText or theme.Text, 5, config.IconColored == true, config.IconColor)
        if kind == "image" then
            ico.Size = UDim2.new(1, useBox and -10 or -2, 1, useBox and -10 or -2)
            if not config.IconColor then bind(self, ico, "ImageColor3", useBox and "AccentText" or "Text") end
        elseif kind == "draw" then
            bindIcon(self, ico, useBox and "AccentText" or "Text")
        end
    elseif useBox then
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
        Position = UDim2.new(0, markSize > 0 and markSize + 10 or 0, 0, 0),
        Size = UDim2.new(1, -(markSize > 0 and markSize + 10 or 0), 1, 0),
        ZIndex = 4,
        Parent = brand,
    })

    local hasSub = config.Subtitle and config.Subtitle ~= ""
    local brandTitle = text({
        Text = title,
        Font = FONT.bold,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AnchorPoint = Vector2.new(0, hasSub and 0 or 0.5),
        Position = UDim2.new(0, 0, hasSub and 0.5 or 0.5, hasSub and -14 or 0),
        Size = UDim2.new(1, 0, 0, 15),
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
            Position = UDim2.new(0, 0, 0.5, 1),
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
            Position = UDim2.new(0, 12, 0, 52),
            Size = UDim2.new(1, -24, 0, 28),
            ZIndex = 3,
            Parent = sidebar,
        })
        corner(searchWrap, RADIUS.md)
        bind(self, searchWrap, "BackgroundColor3", "Element")
        bind(self, searchWrap, "BackgroundTransparency", "ElementAlpha")
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

    local tabTop = (config.Search ~= false) and 92 or 62
    local tabScroll = new("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, tabTop),
        Size = UDim2.new(1, -16, 1, -(tabTop + 44)),
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
        Size = UDim2.new(1, 0, 0, 40),
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

    -- Profile chip: the player's headshot with a small (static) online dot,
    -- then the name. Streamer mode / a custom display name swaps the photo
    -- for a lettered disc, since the face gives an account away as surely
    -- as the name does. See Window:_refreshIdentity.
    local avatar = new("Frame", {
        Name = "Avatar",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 1),
        Size = UDim2.new(0, 24, 0, 24),
        ZIndex = 4,
        Parent = footer,
    })
    corner(avatar, RADIUS.pill)
    bind(self, avatar, "BackgroundColor3", "Element")
    local avatarImg = new("ImageLabel", {
        Name = "Headshot",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "",
        ZIndex = 6,
        Parent = avatar,
    })
    corner(avatarImg, RADIUS.pill)
    pcall(function()
        avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48"
    end)
    local avatarLetter = text({
        Text = "?",
        Font = FONT.bold,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 5,
        Parent = avatar,
    })
    bind(self, avatarLetter, "TextColor3", "SubText")
    local pulse = new("Frame", {
        Name = "Pulse",
        BackgroundColor3 = theme.Success,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 1, 1, 1),
        Size = UDim2.new(0, 8, 0, 8),
        ZIndex = 7,
        Parent = avatar,
    })
    corner(pulse, RADIUS.pill)
    bind(self, pulse, "BackgroundColor3", "Success")
    local pulseRing = stroke(pulse, theme.Sidebar, 2, 0)
    bind(self, pulseRing, "Color", "Sidebar")

    local who = ""
    pcall(function() who = LocalPlayer.DisplayName or LocalPlayer.Name or "" end)
    local footerName = text({
        Text = config.FooterName or who,
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 46, 0.5, -7),
        Size = UDim2.new(1, -60, 0, 13),
        ZIndex = 4,
        Parent = footer,
    })
    bind(self, footerName, "TextColor3", "Text")
    self._footerName = footerName
    self._avatarImg = avatarImg
    self._avatarLetter = avatarLetter
    self._realName = who
    self._configFooterName = config.FooterName
    local footerText = text({
        Text = config.Footer or ("BPUI v" .. BPUI.Version),
        Font = FONT.body,
        TextSize = 9,
        TextColor3 = theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 46, 0.5, 7),
        Size = UDim2.new(1, -60, 0, 11),
        ZIndex = 4,
        Parent = footer,
    })
    bind(self, footerText, "TextColor3", "Muted")
    self:_refreshIdentity()

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
        Size = UDim2.new(1, 0, 0, 46),
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
    self._hairline = hairline
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
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 18, 0, 8),
        Size = UDim2.new(1, -130, 0, 18),
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
        Position = UDim2.new(0, 18, 0, 27),
        Size = UDim2.new(1, -130, 0, 13),
        ZIndex = 4,
        Parent = topbar,
    })
    bind(self, pageSub, "TextColor3", "Muted")
    self._pageSub = pageSub
    -- A tab without a subtitle shouldn't leave its title hanging at the top
    -- of an empty two-line block: centre it in the bar instead.
    local function seatTitle()
        local solo = pageSub.Text == ""
        pageTitle.Position = UDim2.new(0, 18, 0, solo and 14 or 8)
    end
    seatTitle()
    track(self, pageSub:GetPropertyChangedSignal("Text"):Connect(seatTitle))

    local controls = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 62, 0, 24),
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
            Size = UDim2.new(0, 27, 0, 24),
            LayoutOrder = order,
            ClipsDescendants = true,
            ZIndex = 4,
            Parent = controls,
        })
        corner(b, RADIUS.sm)
        local g
        if kind == "close" then g = iconClose(b, 9, theme.SubText, 5)
        else g = iconMinimize(b, 10, theme.SubText, 5) end
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

    ctrlButton("minimize", false, 1, function()
        -- With the menu button on screen, minimising simply closes the
        -- window (the button brings it back); without one, fall back to the
        -- compact title-bar pill so there's always a way back in.
        if self:IsMenuButtonVisible() then
            self:Hide()
            if not self._tuckHintShown then
                self._tuckHintShown = true
                BPUI:Notify({
                    Title = "Window closed",
                    Content = "Use the menu button to open it again.",
                    Duration = 4,
                })
            end
        else
            self:Minimize()
        end
    end)
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
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -46),
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = body,
    })
    self._pages = pages

    -- grabbing the window mid-open takes over from the open animation
    -- instead of fighting its position tween
    local function takeOver()
        if self._openTween then pcall(function() self._openTween:Cancel() end) self._openTween = nil end
        if self._animating and self._visible then
            self._animating = false
            if self._veil then self._veil.Visible = false end
        end
    end
    draggable(self, topbar, root, { clamp = true, onStart = takeOver })
    draggable(self, brand, root, { clamp = true, onStart = takeOver })

    if not IS_MOBILE and config.Resizable ~= false then
        local grip = new("TextButton", {
            Name = "Grip",
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -2, 1, -2),
            Size = UDim2.new(0, 16, 0, 16),
            ZIndex = 8,
            Parent = main,
        })
        self._grip = grip
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

    local okWm, errWm = pcall(function() self:_buildWatermark(config) end)
    if not okWm then warn("[BPUI] watermark failed: " .. tostring(errWm)) end

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
            local x, y = input.Position.X, input.Position.Y
            local function inside(g)
                if not g or not g.Parent or not g.Visible then return false end
                local p, s = g.AbsolutePosition, g.AbsoluteSize
                return x >= p.X and y >= p.Y and x <= p.X + s.X and y <= p.Y + s.Y
            end
            -- A floating popover lives outside its row, so a click on it
            -- counts as "inside" too.
            if not inside(open._root) and not inside(open._popup) then
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
    self:_animateOpen()
    -- Must match the creation value above. This tween is what the window
    -- actually ends up at (creation sets it, the next line blanks it to 1,
    -- this brings it back), so a stale expression here silently overrides
    -- the real default.
    tw(main, MOTION.reveal, { BackgroundTransparency = config.Transparency or 0 })

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

-- The backdrop holds nothing but an optional user-supplied tiled texture.
-- There is deliberately no ambient glow and no giant watermark behind the
-- page: depth comes from the tonal ladder between window, sidebar, card and
-- row plus hairline strokes, not from coloured light. A flat, quiet surface
-- keeps attention on the content and never competes with the game behind it.
-- Background image sources -------------------------------------------------
--
-- Accepts whatever a user is likely to paste:
--   * a bare id, "rbxassetid://id", or any rbxasset/rbxthumb content id
--   * a Roblox page link (create.roblox.com/store/asset/ID, roblox.com/
--     library/ID, catalog/ID, ...?id=ID) -> that asset id
--   * a direct web image link (.png / .jpg) -> downloaded once through the
--     executor, cached in the config folder, shown via getcustomasset
-- A Decal id isn't an image id; if the id doesn't load as an image it is
-- retried as the asset's thumbnail, which is the decal's picture.

local function strHash(str)
    local h = 5381
    for i = 1, #str do h = (h * 33 + str:byte(i)) % 4294967296 end
    return string.format("%08x", h)
end

-- BEGIN user-requested image download
-- The only network access in the library, and it only ever happens when
-- the user pastes a web image link into Settings -> Background image.
local function fetchImageBytes(url)
    local body
    local req = (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request)
        or (type(http_request) == "function" and http_request) or (type(request) == "function" and request)
    if type(req) == "function" then
        local ok, res = pcall(req, { Url = url, Method = "GET" })
        if ok and type(res) == "table" and type(res.Body) == "string"
            and (res.StatusCode == nil or (res.StatusCode >= 200 and res.StatusCode < 300)) then
            body = res.Body
        end
    end
    if not body then
        pcall(function() body = game:HttpGet(url) end)
    end
    return body
end
-- END user-requested image download

local function robloxIdFrom(input)
    if input:match("^%d+$") then return input end
    local id = input:match("^rbxassetid://(%d+)")
        or input:match("[?&]id=(%d+)")
        or input:match("/store/asset/(%d+)")
        or input:match("/library/(%d+)")
        or input:match("/catalog/(%d+)")
        or input:match("/asset/(%d+)")
        or input:match("/decal/(%d+)")
    if id then return id end
    if input:match("^https?://[%w%.%-]*roblox%.com/") then return input:match("(%d%d%d%d%d+)") end
    return nil
end

-- Most ids people copy from the Creator Store are Decal ids, which don't
-- load as images. game:GetObjects (available in executors) returns the Decal,
-- and its Texture holds the image id. Yields; results are cached per id.
local decalCache = {}
local function decalImage(id)
    if decalCache[id] ~= nil then return decalCache[id] or nil end
    local found = false
    pcall(function()
        local objs = game:GetObjects("rbxassetid://" .. id)
        local d = objs and objs[1]
        if d and not d:IsA("Decal") then d = d:FindFirstChildWhichIsA("Decal", true) end
        if d and type(d.Texture) == "string" and d.Texture ~= "" then found = d.Texture end
        for _, o in ipairs(objs or {}) do pcall(function() o:Destroy() end) end
    end)
    decalCache[id] = found
    return found or nil
end

local function customAsset(path)
    local fn = (type(getcustomasset) == "function" and getcustomasset)
        or (type(getsynasset) == "function" and getsynasset)
    if not fn then return nil end
    local ok, id = pcall(fn, path)
    if ok and type(id) == "string" and id ~= "" then return id end
    return nil
end

-- Calls done(contentId) or done(nil, reason). Web links resolve
-- asynchronously; everything else resolves immediately.
function Window:_resolveImage(input, done)
    input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then return done(nil) end
    if input:match("^rbxasset") or input:match("^rbxthumb://") then return done(input) end
    local id = robloxIdFrom(input)
    if id then return done("rbxassetid://" .. id, nil, id) end
    if not input:match("^https?://") then
        return done(nil, "That doesn't look like an image id or link.")
    end
    if not (FS.Available and (type(getcustomasset) == "function" or type(getsynasset) == "function")) then
        return done(nil, "This executor can't load web images. Use a Roblox image id instead.")
    end
    local path = self._folder .. "/bg_" .. strHash(input)
    task.spawn(function()
        local cached
        for _, ext in ipairs({ ".png", ".jpg" }) do
            if FS.exists(path .. ext) then cached = path .. ext break end
        end
        if not cached then
            local bytes = fetchImageBytes(input)
            if type(bytes) ~= "string" or #bytes < 16 then
                return done(nil, "Couldn't download that link.")
            end
            local ext
            if bytes:sub(1, 4) == "\137PNG" then ext = ".png"
            elseif bytes:sub(1, 2) == "\255\216" then ext = ".jpg" end
            if not ext then
                return done(nil, "The link must point straight to a PNG or JPG image (not a web page).")
            end
            if not FS.write(path .. ext, bytes) then
                return done(nil, "Couldn't save the image.")
            end
            cached = path .. ext
        end
        local asset = customAsset(cached)
        if not asset then
            return done(nil, "This executor can't load web images. Use a Roblox image id instead.")
        end
        done(asset)
    end)
end

function Window:_buildBackground()
    if self._destroyed or not self._backdrop then return end
    for _, c in ipairs(self._backdrop:GetChildren()) do c:Destroy() end
    local bg = self._bg
    if not bg.Image or bg.Image == false or tostring(bg.Image) == "" then return end

    self._bgToken = (self._bgToken or 0) + 1
    local token = self._bgToken
    local w = self
    local function fail(reason)
        if reason and w._bgNotify then
            BPUI:Notify({ Title = "Background image", Content = reason, Type = "Warning", Duration = 5 })
        end
    end
    self:_resolveImage(bg.Image, function(content, reason, rawId)
        if w._destroyed or w._bgToken ~= token then return end
        if not content then return fail(reason) end
        local tile = bg.ImageTile == true
        local tex = new("ImageLabel", {
            Name = "Texture",
            BackgroundTransparency = 1,
            Image = content,
            ImageTransparency = math.clamp(bg.ImageAlpha or 0.7, 0, 1),
            -- a tiled pattern is tinted to the theme; a picture keeps its colours
            ImageColor3 = tile and ACTIVE.Text or Color3.new(1, 1, 1),
            ScaleType = tile and Enum.ScaleType.Tile or Enum.ScaleType.Crop,
            TileSize = UDim2.new(0, bg.ImageTileSize or 96, 0, bg.ImageTileSize or 96),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 1,
            Parent = w._backdrop,
        })
        -- A plain id that doesn't load as an image is most often a Decal
        -- id: show that asset's thumbnail instead (which is the picture).
        if rawId then
            task.spawn(function()
                local status
                pcall(function()
                    game:GetService("ContentProvider"):PreloadAsync({ tex }, function(_, st) status = st end)
                end)
                if w._bgToken ~= token or not tex.Parent then return end
                if status == Enum.AssetFetchStatus.Failure then
                    -- A Decal id: read the Decal to find the image it wraps.
                    local decalTex = decalImage(rawId)
                    if w._bgToken ~= token or not tex.Parent then return end
                    if decalTex then
                        tex.Image = decalTex
                        return
                    end
                    tex.Image = "rbxthumb://type=Asset&id=" .. rawId .. "&w=420&h=420"
                    local second
                    pcall(function()
                        game:GetService("ContentProvider"):PreloadAsync({ tex }, function(_, st) second = st end)
                    end)
                    if second == Enum.AssetFetchStatus.Failure and w._bgToken == token then
                        fail("Couldn't load that id. If it's a Decal, try its Image id.")
                    end
                end
            end)
        end
    end)
end

function Window:SetBackground(cfg)
    if type(cfg) ~= "table" then return end
    local rebuild = cfg.Image ~= nil or cfg.ImageTile ~= nil
    self._bgNotify = true
    for k, v in pairs(cfg) do
        self._bg[k] = v
    end
    -- Only a change of Image itself needs the texture torn down and rebuilt.
    -- Opacity and tiling are applied to the existing ImageLabel in place,
    -- because the opacity slider fires this on every frame of a drag and
    -- recreating the label each time makes the texture re-resolve its asset
    -- and flicker under the very control that is meant to fade it smoothly.
    local tex = self._backdrop and self._backdrop:FindFirstChild("Texture")
    if rebuild or not tex then
        self:_buildBackground()
    else
        local bg = self._bg
        local tile = bg.ImageTile == true
        tex.ImageTransparency = math.clamp(bg.ImageAlpha or 0.7, 0, 1)
        tex.ScaleType = tile and Enum.ScaleType.Tile or Enum.ScaleType.Crop
        tex.ImageColor3 = tile and ACTIVE.Text or Color3.new(1, 1, 1)
        tex.TileSize = UDim2.new(0, bg.ImageTileSize or 96, 0, bg.ImageTileSize or 96)
    end
    self._settings.Background = {
        Image = self._bg.Image,
        ImageAlpha = self._bg.ImageAlpha,
        ImageTile = self._bg.ImageTile,
        ImageTileSize = self._bg.ImageTileSize,
    }
    self:_saveSettingsLater()
end

function Window:_saveSettingsLater()
    self._saveToken = (self._saveToken or 0) + 1
    local token = self._saveToken
    task.delay(0.35, function()
        if self._saveToken == token and not self._destroyed then self:_saveSettings() end
    end)
end

function Window:GetBackground() return self._bg end

function Window:_retintBackground()
    if not self._backdrop then return end
    local tex = self._backdrop:FindFirstChild("Texture")
    if tex and self._bg.ImageTile == true then tex.ImageColor3 = ACTIVE.Text end
end

function Window:_showTooltip(str, anchor)
    if IS_MOBILE or self._destroyed or not self._tip then return end
    if not str or str == "" then return end
    -- Rows keep receiving MouseEnter underneath a floating popover; a
    -- tooltip for a row the user can't even see would be noise.
    local open = BPUI._openPanel
    if open and open._popup and open._popup.Visible then return end
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

-- Watermark, menu button + identity ---------------------------------------
--
-- The watermark is a small always-on-screen information tag: the hub's
-- icon and a name the user can rename, then live FPS and ping. It doesn't
-- open or close anything; it can be dragged anywhere (remembered).
--
-- The menu button is the one control for opening and closing the window:
-- a small plain square, draggable, on PC and mobile alike.
--
-- Identity is the footer's profile chip: avatar headshot + display name.
-- A user can replace the shown name with their own text and/or hide it
-- entirely (streamer mode); both also drop the avatar, which would give the
-- account away just as surely as the name.

-- Keep an on-screen HUD piece (watermark, menu button) fully inside its
-- ScreenGui -- while dragging, when a saved spot is loaded, and whenever
-- the screen size changes -- so it can never end up somewhere unreachable.
local function clampHud(frame)
    pcall(function()
        local host = frame.Parent
        if not host then return end
        local ps, fs = host.AbsoluteSize, frame.AbsoluteSize
        if ps.X <= 0 or ps.Y <= 0 then return end
        local p = frame.Position
        local x = math.clamp(p.X.Offset, 0, math.max(0, ps.X - fs.X))
        local y = math.clamp(p.Y.Offset, 0, math.max(0, ps.Y - fs.Y))
        if x ~= p.X.Offset or y ~= p.Y.Offset or p.X.Scale ~= 0 or p.Y.Scale ~= 0 then
            frame.Position = UDim2.new(0, math.floor(x), 0, math.floor(y))
        end
    end)
end

local function keepOnScreen(owner, frame)
    task.defer(clampHud, frame)
    pcall(function()
        track(owner, frame.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() clampHud(frame) end))
    end)
end

local function wmSettings(w)
    local s = w._settings
    local c = w._wmConfig or {}
    local function pick(key, cfgKey, default)
        if s[key] ~= nil then return s[key] end
        if c[cfgKey] ~= nil then return c[cfgKey] end
        return default
    end
    return {
        enabled = pick("WatermarkVisible", "Enabled", true),
        text = pick("WatermarkText", "Text", w._title),
        fps = pick("WatermarkFPS", "ShowFPS", true),
        ping = pick("WatermarkPing", "ShowPing", true),
    }
end

function Window:_buildWatermark(config)
    local cfg = config.Watermark
    if cfg == false then self._wmConfig = { Enabled = false }
    elseif type(cfg) == "table" then self._wmConfig = cfg
    else self._wmConfig = {} end

    local theme = ACTIVE
    local w = self

    local sg = new("ScreenGui", {
        Name = "BPUI_Watermark_" .. uid(),
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 9001,
        Parent = guiParent(),
    })
    self._wmGui = sg

    -- Default spot: top-left, just right of the menu button, both sitting
    -- in one row above where Roblox's chat window opens.
    local saved = self._settings.WatermarkPos
    local dd = uiDensity()
    local px, py = math.floor(12 + 38 * dd + 8), math.floor(8 + 4 * dd)
    if type(saved) == "table" and tonumber(saved[1]) and tonumber(saved[2]) then
        px, py = tonumber(saved[1]), tonumber(saved[2])
    end

    local pill = new("TextButton", {
        Name = "Watermark",
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.new(0, px, 0, py),
        Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 10,
        Parent = sg,
    })
    corner(pill, RADIUS.lg)
    bind(self, pill, "BackgroundColor3", "Window")
    local ps = stroke(pill, theme.Stroke, 1, 0)
    bind(self, ps, "Color", "Stroke")
    local d = uiDensity()
    if d > 1 then new("UIScale", { Scale = d, Parent = pill }) end

    local row = list(pill, 8, Enum.FillDirection.Horizontal)
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    pad(pill, 0, 12, 0, 4)

    -- The hub's own icon, drawn bare in the text colour -- no filled
    -- accent square behind it (with a white accent that read as a blank
    -- white box). No icon configured means no mark at all, just the name.
    if iconUsable(config.Icon) then
        local box = new("Frame", {
            Name = "Mark",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 15, 0, 15),
            LayoutOrder = 1,
            ZIndex = 11,
            Parent = pill,
        })
        local ico, kind = iconAny(box, config.Icon, 15, theme.Text, 12)
        if kind == "image" then bind(self, ico, "ImageColor3", "Text")
        elseif kind == "draw" then bindIcon(self, ico, "Text") end
    end

    local label = text({
        Name = "Label",
        Text = "",
        Font = FONT.bold,
        TextSize = 12,
        TextColor3 = theme.Text,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
        ZIndex = 11,
        Parent = pill,
    })
    bind(self, label, "TextColor3", "Text")

    local function divider(order)
        local f = new("Frame", {
            BackgroundColor3 = theme.Stroke,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 1, 0, 12),
            LayoutOrder = order,
            ZIndex = 11,
            Parent = pill,
        })
        bind(self, f, "BackgroundColor3", "Stroke")
        return f
    end

    local function stat(order, unit)
        local holder = new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = order,
            ZIndex = 11,
            Parent = pill,
        })
        local l = list(holder, 3, Enum.FillDirection.Horizontal)
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        -- fixed-width number slot (right-aligned) so the tag keeps one width
        -- whether it reads 9 or 240 -- it no longer twitches sideways
        local value = text({
            Text = "--",
            Font = FONT.mono,
            TextSize = 11,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Right,
            Size = UDim2.new(0, 22, 1, 0),
            LayoutOrder = 1,
            ZIndex = 11,
            Parent = holder,
        })
        local u = text({
            Text = unit,
            Font = FONT.medium,
            TextSize = 10,
            TextColor3 = theme.Muted,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = 2,
            ZIndex = 11,
            Parent = holder,
        })
        bind(self, u, "TextColor3", "Muted")
        return holder, value
    end

    local fpsDiv = divider(3)
    local fpsHolder, fpsValue = stat(4, "FPS")
    local pingDiv = divider(5)
    local pingHolder, pingValue = stat(6, "ms")

    self._wm = pill
    self._wmLabel = label
    self._wmParts = { fpsDiv = fpsDiv, fps = fpsHolder, pingDiv = pingDiv, ping = pingHolder }

    -- live stats ---------------------------------------------------------
    local frames, acc = 0, 0
    local function healthColor(v, good, ok)
        if v >= good then return ACTIVE.Success or ACTIVE.Text end
        if v >= ok then return ACTIVE.Warning or ACTIVE.Text end
        return ACTIVE.Danger or ACTIVE.Text
    end
    local function readPing()
        local ms
        pcall(function()
            local item = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            ms = item:GetValue()
        end)
        if not ms then
            pcall(function() ms = LocalPlayer:GetNetworkPing() * 2000 end)
        end
        return ms
    end
    pcall(function()
        track(self, RunService.Heartbeat:Connect(function(dt)
            frames = frames + 1
            acc = acc + (dt or 0)
            if acc < 0.5 then return end
            local fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
            if not sg.Parent or not pill.Visible then return end
            fpsValue.Text = tostring(fps)
            fpsValue.TextColor3 = healthColor(fps, 50, 30)
            local ms = readPing()
            if ms then
                ms = math.floor(ms + 0.5)
                pingValue.Text = tostring(ms)
                pingValue.TextColor3 = healthColor(-ms, -120, -250)
            end
        end))
    end)

    -- interaction --------------------------------------------------------
    if not IS_MOBILE then
        track(self, pill.MouseEnter:Connect(function()
            tween(pill, { BackgroundColor3 = ACTIVE.Surface }, MOTION.hover)
        end))
        track(self, pill.MouseLeave:Connect(function()
            tween(pill, { BackgroundColor3 = ACTIVE.Window }, MOTION.hover)
        end))
    end

    local startPos, moved = nil, false
    keepOnScreen(self, pill)
    draggable(self, pill, pill, {
        onStart = function() startPos = pill.Position moved = false end,
        onMove = function(p)
            clampHud(pill)
            p = pill.Position
            if startPos and (math.abs(p.X.Offset - startPos.X.Offset) + math.abs(p.Y.Offset - startPos.Y.Offset)) > 4 then
                moved = true
            end
        end,
        onStop = function()
            local p = pill.Position
            if startPos and (p.X.Offset ~= startPos.X.Offset or p.Y.Offset ~= startPos.Y.Offset) then
                w._settings.WatermarkPos = { math.floor(pill.Position.X.Offset), math.floor(pill.Position.Y.Offset) }
                w:_saveSettingsLater()
            end
        end,
    })
    -- The watermark is information only; opening and closing the window is
    -- the menu button's job (see _buildMenuButton).
    self:_applyWatermark()
    self:_buildMenuButton(config)
end

-- Menu button ----------------------------------------------------------
--
-- One small, plain button whose only job is opening and closing the
-- window: a rounded square in the window's own colours with a menu glyph,
-- draggable anywhere (remembered), on PC and mobile alike. While the
-- window is closed a small accent dot sits on its corner.
function Window:_buildMenuButton(config)
    local theme = ACTIVE
    local w = self
    local sg = self._wmGui
    if not sg then return end

    local saved = self._settings.MenuButtonPos
    local px, py = 12, 8
    if type(saved) == "table" and tonumber(saved[1]) and tonumber(saved[2]) then
        px, py = tonumber(saved[1]), tonumber(saved[2])
    end

    local holder = new("Frame", {
        Name = "MenuButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, px, 0, py),
        Size = UDim2.new(0, 38, 0, 38),
        ZIndex = 20,
        Parent = sg,
    })
    local d = uiDensity()
    if d > 1 then new("UIScale", { Scale = d, Parent = holder }) end

    local btn = new("TextButton", {
        Name = "Button",
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 21,
        Parent = holder,
    })
    corner(btn, RADIUS.lg)
    bind(self, btn, "BackgroundColor3", "Window")
    local bs = stroke(btn, theme.Stroke, 1, 0)
    bind(self, bs, "Color", "Stroke")
    local press = new("UIScale", { Scale = 1, Parent = btn })

    local iconBox = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        ZIndex = 22,
        Parent = btn,
    })
    local ico, kind = iconAny(iconBox, config.MenuButtonIcon or "menu", 17, theme.Text, 22)
    if kind == "image" then bind(self, ico, "ImageColor3", "Text")
    elseif kind == "draw" then bindIcon(self, ico, "Text") end

    local dot = new("Frame", {
        Name = "Dot",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -7, 0, 7),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = 23,
        Parent = btn,
    })
    corner(dot, RADIUS.pill)
    bind(self, dot, "BackgroundColor3", "Accent")

    if not IS_MOBILE then
        track(self, btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = ACTIVE.Surface }, MOTION.hover)
        end))
        track(self, btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = ACTIVE.Window }, MOTION.hover)
        end))
    end

    local startPos, moved = nil, false
    keepOnScreen(self, holder)
    draggable(self, btn, holder, {
        onStart = function() startPos = holder.Position moved = false end,
        onMove = function(p)
            clampHud(holder)
            p = holder.Position
            if startPos and (math.abs(p.X.Offset - startPos.X.Offset) + math.abs(p.Y.Offset - startPos.Y.Offset)) > 4 then
                moved = true
            end
        end,
        onStop = function()
            local p = holder.Position
            if startPos and (p.X.Offset ~= startPos.X.Offset or p.Y.Offset ~= startPos.Y.Offset) then
                w._settings.MenuButtonPos = { math.floor(p.X.Offset), math.floor(p.Y.Offset) }
                w:_saveSettingsLater()
            end
        end,
    })
    track(self, btn.InputBegan:Connect(function(input)
        if isClick(input) then tw(press, MOTION.press, { Scale = 0.92 }) end
    end))
    track(self, btn.InputEnded:Connect(function(input)
        if isClick(input) then tw(press, MOTION.release, { Scale = 1 }) end
    end))
    pressable(self, btn, nil, function()
        if moved then moved = false return end
        w:_watermarkActivate()
    end, { rippleAlpha = 0.9 })

    self._float = holder
    self._floatButton = btn
    self._menuDot = dot

    local show = config.MenuButton
    if show == nil then show = config.FloatingButton end
    if show == nil then show = true end
    if self._settings.MenuButtonVisible ~= nil then show = self._settings.MenuButtonVisible end
    holder.Visible = show and true or false
    self:_syncWatermarkState()
end

-- Menu button / watermark activation: bring the window back if it's hidden
-- or collapsed, otherwise hide it.
function Window:_watermarkActivate()
    if self._destroyed then return end
    if not self._visible then
        self:Show()
    elseif self._minimized then
        self:Minimize(false)
    else
        self:Hide()
    end
end
Window._menuButtonActivate = Window._watermarkActivate

function Window:IsMenuButtonVisible()
    return self._float ~= nil and self._float.Visible
end

-- the accent dot on the menu button: shown while the window is closed
function Window:_syncWatermarkState()
    local dot = self._menuDot
    if not dot then return end
    local closed = (not self._visible) or self._minimized
    tw(dot, MOTION.spring, { Size = closed and UDim2.new(0, 7, 0, 7) or UDim2.new(0, 0, 0, 0) })
end

function Window:_applyWatermark()
    if not self._wm then return end
    local s = wmSettings(self)
    self._wm.Visible = s.enabled and true or false
    local t = tostring(s.text or "")
    if t == "" then t = self._title or "BPUI" end
    self._wmLabel.Text = t
    self._wmParts.fpsDiv.Visible = s.fps and true or false
    self._wmParts.fps.Visible = s.fps and true or false
    self._wmParts.pingDiv.Visible = s.ping and true or false
    self._wmParts.ping.Visible = s.ping and true or false
    self:_syncWatermarkState()
end

function Window:SetWatermark(text_)
    self._settings.WatermarkText = text_ ~= nil and tostring(text_) or nil
    self:_applyWatermark()
    self:_saveSettingsLater()
end

function Window:SetWatermarkVisible(state)
    self._settings.WatermarkVisible = state and true or false
    self:_applyWatermark()
    self:_saveSettingsLater()
end

function Window:SetWatermarkStats(showFps, showPing)
    if showFps ~= nil then self._settings.WatermarkFPS = showFps and true or false end
    if showPing ~= nil then self._settings.WatermarkPing = showPing and true or false end
    self:_applyWatermark()
    self:_saveSettingsLater()
end

function Window:IsWatermarkVisible()
    return self._wm ~= nil and self._wm.Visible
end

-- identity ---------------------------------------------------------------
function Window:_refreshIdentity()
    if not self._footerName then return end
    local s = self._settings
    local custom = s.DisplayName
    if type(custom) ~= "string" or custom:gsub("%s", "") == "" then custom = nil end
    local hidden = s.HideName == true
    local shown
    if custom then shown = custom
    elseif hidden then shown = "Hidden"
    else shown = self._configFooterName or self._realName or "" end
    self._footerName.Text = shown
    local masked = hidden or custom ~= nil
    if self._avatarImg then self._avatarImg.Visible = not masked end
    if self._avatarLetter then
        -- The lettered disc always sits underneath: it's what shows while
        -- the headshot loads, if thumbnails are blocked in this executor,
        -- and on its own in streamer mode.
        self._avatarLetter.Visible = true
        local first = shown:match("[%w]") or "?"
        self._avatarLetter.Text = first:upper()
    end
end

function Window:SetDisplayName(str)
    if str ~= nil then str = tostring(str) end
    self._settings.DisplayName = (str ~= nil and str ~= "") and str or nil
    self:_refreshIdentity()
    self:_saveSettingsLater()
end

function Window:SetNameHidden(state)
    self._settings.HideName = state and true or false
    self:_refreshIdentity()
    self:_saveSettingsLater()
end
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

local function navIcon(owner, parent, icon, x, color, colored, iconColor)
    if not iconUsable(icon) then return nil, nil, 0 end
    local box = new("Frame", {
        Name = "IconBox",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, x, 0.5, 0),
        Size = UDim2.new(0, 18, 0, 18),
        ZIndex = 5,
        Parent = parent,
    })
    local ico, kind = iconAny(box, icon, 15, color, 6, colored, iconColor)
    return ico, kind, 23
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

    -- A grouped tab is a whole indented block, not just indented text: it
    -- lives in a full-width, non-clipping "branch" row, with the button
    -- itself (highlight, accent bar and all) shifted right by BRANCH_INDENT.
    -- The free strip on the left carries the tree connector -- a trunk that
    -- bleeds through the gap into the next row so the line reads continuous,
    -- and an elbow reaching across to the button. Group:_layout() shortens
    -- the last visible trunk to end at its elbow (a proper corner), and
    -- Select() tints the active branch's elbow with the accent.
    local row
    if group then
        row = new("Frame", {
            Name = "Branch_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, TAB_H),
            LayoutOrder = #group._tabs + 1,
            ZIndex = 4,
            Parent = container,
        })
        tab._row = row
    end
    local indent = group and BRANCH_INDENT or 0

    local button = new("TextButton", {
        Name = "Tab_" .. name,
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Position = UDim2.new(0, indent, 0, 0),
        Size = UDim2.new(1, -indent, 0, TAB_H),
        LayoutOrder = group and 1 or nextOrder(w),
        ClipsDescendants = true,
        ZIndex = 4,
        Parent = row or container,
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

    if row then
        local rail = new("Frame", {
            Name = "Rail",
            BackgroundColor3 = theme.Stroke,
            BorderSizePixel = 0,
            Position = UDim2.new(0, BRANCH_X, 0, 0),
            Size = UDim2.new(0, 1, 0, TAB_H + TAB_GAP),
            ZIndex = 5,
            Parent = row,
        })
        bind(tab, rail, "BackgroundColor3", "Stroke")
        tab._rail = rail

        local elbow = new("Frame", {
            Name = "Elbow",
            BackgroundColor3 = theme.Stroke,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, BRANCH_X, 0.5, 0),
            Size = UDim2.new(0, BRANCH_INDENT - BRANCH_X - 2, 0, 1),
            ZIndex = 5,
            Parent = row,
        })
        bind(tab, elbow, "BackgroundColor3", "Stroke")
        tab._elbow = elbow
    end

    local inset = 0
    local labelX = 12 + inset
    tab._iconColored = config.Colored == true
    tab._iconColor = config.IconColor
    local ico, kind, w_ = navIcon(tab, button, config.Icon, 11 + inset, theme.SubText, tab._iconColored, tab._iconColor)
    if ico then
        tab._icon, tab._iconKind = ico, kind
        if kind == "draw" then bindIcon(tab, ico, "SubText") end
        labelX = labelX + w_
    end
    if kind == "image" then
        whenAssetFails(ico, function()
            if tab._icon == ico and tab.SetIcon then tab:SetIcon(nil) end
        end)
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

    local badge = new("Frame", {
        Name = "Badge",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Visible = false,
        ZIndex = 6,
        Parent = button,
    })
    corner(badge, RADIUS.pill)
    bind(tab, badge, "BackgroundColor3", "Element")
    local badgeText = text({
        Text = "",
        Font = FONT.bold,
        TextSize = 9,
        TextColor3 = theme.SubText,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 7,
        Parent = badge,
    })
    pad(badge, 0, 7, 0, 7)
    bind(tab, badgeText, "TextColor3", "SubText")
    tab._badge, tab._badgeText = badge, badgeText
    function tab:SetBadge(v)
        local lx = label.Position.X.Offset
        if v == nil or v == false or v == "" then
            badge.Visible = false
            label.Size = UDim2.new(1, -(lx + 10), 1, 0)
            return
        end
        badgeText.Text = tostring(v)
        badge.Visible = true
        label.Size = UDim2.new(1, -(lx + 44), 1, 0)
    end
    if config.Badge ~= nil then tab:SetBadge(config.Badge) end

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
    pad(page, 8, 16, 18, 16)
    list(page, 14)
    tab._page = page
    bind(tab, page, "ScrollBarImageColor3", "Muted")

    -- Empty state: a page with nothing to show (a tab with no sections yet,
    -- or nothing matching the current search) says so instead of rendering
    -- as a blank panel that looks broken.
    local empty = new("Frame", {
        Name = "EmptyState",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 190),
        LayoutOrder = -1,
        ZIndex = 3,
        Parent = page,
    })
    local emptyIconBox = new("Frame", {
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 56),
        Size = UDim2.new(0, 44, 0, 44),
        ZIndex = 3,
        Parent = empty,
    })
    corner(emptyIconBox, RADIUS.lg)
    bind(tab, emptyIconBox, "BackgroundColor3", "Surface")
    local eis = stroke(emptyIconBox, theme.StrokeSoft, 1, 0)
    bind(tab, eis, "Color", "StrokeSoft")
    local eico = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 22, 0, 22),
        ZIndex = 4,
        Parent = emptyIconBox,
    })
    local emptyIcon, emptyKind = iconAny(eico, "inbox", 20, theme.Muted, 4)
    if emptyKind == "image" then bind(tab, emptyIcon, "ImageColor3", "Muted")
    elseif emptyKind == "draw" then bindIcon(tab, emptyIcon, "Muted") end
    local emptyTitle = text({
        Text = "Nothing here yet",
        Font = FONT.bold,
        TextSize = 14,
        TextColor3 = theme.Text,
        Position = UDim2.new(0, 0, 0, 112),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 3,
        Parent = empty,
    })
    bind(tab, emptyTitle, "TextColor3", "Text")
    local emptySub = text({
        Text = "This page doesn't have any settings yet.",
        Font = FONT.body,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextWrapped = true,
        Position = UDim2.new(0.5, -150, 0, 134),
        Size = UDim2.new(0, 300, 0, 30),
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 3,
        Parent = empty,
    })
    bind(tab, emptySub, "TextColor3", "SubText")
    tab._empty, tab._emptyTitle, tab._emptySub, tab._emptyIconBox = empty, emptyTitle, emptySub, eico

    if not IS_MOBILE then
        track(tab, button.MouseEnter:Connect(function()
            if w._activeTab == tab then return end
            tween(button, { BackgroundTransparency = 0.5, BackgroundColor3 = ACTIVE.SurfaceHover }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.Text }, MOTION.hover)
            if tab._iconKind == "image" then
                if not tab._icon:GetAttribute("IconLocked") then tween(tab._icon, { ImageColor3 = ACTIVE.Text }, MOTION.hover) end
            elseif tab._iconKind == "draw" then tintIcon(tab._icon, ACTIVE.Text) end
        end))
        track(tab, button.MouseLeave:Connect(function()
            if w._activeTab == tab then return end
            tween(button, { BackgroundTransparency = 1 }, MOTION.hover)
            tween(label, { TextColor3 = ACTIVE.SubText }, MOTION.hover)
            if tab._iconKind == "image" then
                if not tab._icon:GetAttribute("IconLocked") then tween(tab._icon, { ImageColor3 = ACTIVE.SubText }, MOTION.hover) end
            elseif tab._iconKind == "draw" then tintIcon(tab._icon, ACTIVE.SubText) end
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
    group._iconColored = config.Colored == true
    group._iconColor = config.IconColor
    local ico, kind, w_ = navIcon(group, header, config.Icon, 11, theme.SubText, group._iconColored, group._iconColor)
    if ico then
        group._icon, group._iconKind = ico, kind
        if kind == "draw" then bindIcon(group, ico, "SubText")
        elseif kind == "image" and not group._iconColor then bind(group, ico, "ImageColor3", "SubText") end
        labelX = labelX + w_
    end

    local label = text({
        Text = group._name,
        Font = FONT.bold,
        TextSize = 12,
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
    -- Per-child tree connectors (trunk + elbow) are drawn by each grouped
    -- tab button itself; see buildTab(). No group-level rail needed here.

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
    local last
    for _, t in ipairs(self._tabs) do
        if t._button and t._button.Visible then last = t end
    end
    for _, t in ipairs(self._tabs) do
        if t._rail then
            t._rail.Size = UDim2.new(0, 1, 0, t == last and (math.floor(TAB_H / 2) + 1) or (TAB_H + TAB_GAP))
        end
    end
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
        tw(t._bar, instant and TweenInfo.new(0) or MOTION.spring, { Size = UDim2.new(0, 3, 0, on and 18 or 0) })
        if t._elbow then tw(t._elbow, info, { BackgroundColor3 = on and ACTIVE.Accent or ACTIVE.Stroke }) end
        if t._iconKind == "image" then
            if not t._icon:GetAttribute("IconLocked") then
                tw(t._icon, info, { ImageColor3 = on and ACTIVE.Accent or ACTIVE.SubText })
            end
        elseif t._iconKind == "draw" then
            tintIcon(t._icon, on and ACTIVE.Accent or ACTIVE.SubText)
        end
    end

    w._pageTitle.Text = self._name
    w._pageSub.Text = self._subtitle

    -- The outgoing page is hidden immediately (no delayed callback, no
    -- lingering crossfade) so it can never stay Visible at the same time as
    -- the incoming one -- that overlap is what produced the "tangled" look
    -- when flipping through tabs quickly.
    if previous and previous._page then
        local old = previous._page
        old.Position = UDim2.new(0, 0, 0, 0)
        old.Visible = false
    end

    -- Reset transparency-affecting state on every OTHER tab's page so a page
    -- that was mid-transition when the user jumped away is never left
    -- visible or offset the next time it's selected.
    for _, t in ipairs(w._tabs) do
        if t ~= self and t._page and t._page.Visible then
            t._page.Visible = false
            t._page.Position = UDim2.new(0, 0, 0, 0)
        end
    end

    self._page.Position = UDim2.new(0, 0, 0, 0)
    self._page.Visible = true
    if not instant then
        self._page.Position = UDim2.new(0, 16, 0, 0)
        tw(self._page, MOTION.page, { Position = UDim2.new(0, 0, 0, 0) })
    end
end

function Tab:_syncEmpty(query)
    if not self._empty then return end
    local any = false
    for _, sec in ipairs(self._sections) do
        if sec._holder and sec._holder.Visible then any = true break end
    end
    self._empty.Visible = not any
    if any then return end
    if query and query ~= "" then
        self._emptyTitle.Text = "No matches"
        self._emptySub.Text = 'Nothing on this page matches "' .. query .. '".'
    else
        self._emptyTitle.Text = "Nothing here yet"
        self._emptySub.Text = "This page doesn't have any settings yet."
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

function Tab:SetIcon(icon, colored, iconColor)
    local box = self._button:FindFirstChild("IconBox")
    if box then box:Destroy() end
    self._icon, self._iconKind = nil, nil
    if colored ~= nil then self._iconColored = colored == true end
    if iconColor ~= nil then self._iconColor = iconColor or nil end
    local inset = 0
    local ico, kind, w_ = navIcon(self, self._button, icon, 11 + inset, ACTIVE.SubText, self._iconColored, self._iconColor)
    if ico then
        self._icon, self._iconKind = ico, kind
        if kind == "draw" then bindIcon(self, ico, "SubText") end
    end
    local labelX = 12 + inset + (ico and w_ or 0)
    self._label.Position = UDim2.new(0, labelX, 0, 0)
    self._label.Size = UDim2.new(1, -(labelX + 10), 1, 0)
    if self._badge and self._badge.Visible then self:SetBadge(self._badgeText.Text) end
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
    list(holder, 3)
    section._holder = holder
    section._card = holder

    if config.Name and config.Name ~= "" then
        local headWrap = new("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            LayoutOrder = 0,
            ZIndex = 2,
            Parent = holder,
        })
        local tick = new("Frame", {
            Name = "Tick",
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -6),
            Size = UDim2.new(0, 3, 0, 10),
            ZIndex = 2,
            Parent = headWrap,
        })
        corner(tick, RADIUS.pill)
        bind(section, tick, "BackgroundColor3", "Accent")
        local caps = (self._window._sectionStyle or "Caps") == "Caps"
        local header = text({
            Text = caps and spaced(tostring(config.Name):upper()) or config.Name,
            Font = caps and FONT.bold or FONT.medium,
            TextSize = caps and 10 or 13,
            TextColor3 = caps and theme.Muted or theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            Position = UDim2.new(0, 9, 0, 0),
            Size = UDim2.new(1, -9, 1, -5),
            ZIndex = 2,
            Parent = headWrap,
        })
        bind(section, header, "TextColor3", caps and "Muted" or "Text")
        section._header = header
        section._headerRaw = config.Name
        section._caps = caps
    end

    table.insert(self._sections, section)
    self:_syncEmpty(self._window and self._window._searchQuery)
    return section
end

function Section:SetTitle(str)
    if self._header then
        self._headerRaw = str
        self._header.Text = self._caps and spaced(tostring(str):upper()) or tostring(str)
    end
end

function Section:SetVisible(v)
    if not v then
        local open = BPUI._openPanel
        if open and open._section == self then closeOpenPanel(nil) end
    end
    self._userHidden = not v
    self._holder.Visible = v and true or false
    if self._tab and self._tab._syncEmpty then self._tab:_syncEmpty() end
end

function Section:Destroy()
    self._destroyed = true
    for i = #self._elements, 1, -1 do
        local e = self._elements[i]
        if e and e.Destroy then pcall(function() e:Destroy() end) end
    end
    untrack(self)
    if self._holder then self._holder:Destroy() end
    for i, s in ipairs(self._tab._sections) do
        if s == self then table.remove(self._tab._sections, i) break end
    end
    if self._tab._syncEmpty then self._tab:_syncEmpty() end
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
    if self._row then self._row:Destroy() end
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
        -- already open and settled: nothing to replay (and no snapping a
        -- dragged window back to an old spot)
        if self._root.Visible and not self._animating then
            if self._syncWatermarkState then self:_syncWatermarkState() end
            return
        end
        self:_animateOpen()
    else
        self:_animateClose(token)
    end
    if self._syncWatermarkState then self:_syncWatermarkState() end
end

-- Open / close: the window rises a few pixels into place while the veil
-- over its contents fades away and its border + shadow fade in; closing is
-- the same in reverse, a touch faster. Only positions and transparencies
-- are tweened -- nothing is rescaled -- so it stays smooth even on a busy
-- window, and it plays where the window actually is (not tied to the
-- watermark or anything else).
local OPEN_INFO = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local OPEN_FADE = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local RISE = 10

local function shadowLayers(w)
    local out = {}
    if w._shadow then
        for _, l in ipairs(w._shadow:GetChildren()) do
            if l:IsA("Frame") then
                if l:GetAttribute("BaseAlpha") == nil then l:SetAttribute("BaseAlpha", l.BackgroundTransparency) end
                table.insert(out, l)
            end
        end
    end
    return out
end

function Window:_animateOpen()
    local root = self._root
    if not root then return end
    if not self._animating then self._restPos = root.Position end
    local rest = self._restPos
    self._animating = true
    self._animToken = (self._animToken or 0) + 1
    local token = self._animToken
    root.Visible = true
    if self._scale and self._fit then self._scale.Scale = self._fit end
    root.Position = UDim2.new(rest.X.Scale, rest.X.Offset, rest.Y.Scale, rest.Y.Offset + RISE)
    self._openTween = tw(root, OPEN_INFO, { Position = rest })
    local veil = self._veil
    if veil then
        veil.BackgroundTransparency = 0
        veil.Visible = true
        tw(veil, OPEN_FADE, { BackgroundTransparency = 1 })
    end
    for _, l in ipairs(shadowLayers(self)) do
        l.BackgroundTransparency = 1
        tw(l, OPEN_FADE, { BackgroundTransparency = l:GetAttribute("BaseAlpha") })
    end
    if self._mainStroke then
        self._mainStroke.Transparency = 1
        tw(self._mainStroke, OPEN_FADE, { Transparency = 0.05 })
    end
    task.delay(OPEN_INFO.Time, function()
        if self._animToken ~= token then return end
        self._animating = false
        if veil and self._visible then veil.Visible = false end
    end)
end

function Window:_animateClose(token)
    local root = self._root
    if not root then return end
    if not self._animating then self._restPos = root.Position end
    local rest = self._restPos or root.Position
    self._animating = true
    self._animToken = (self._animToken or 0) + 1
    local mine = self._animToken
    local veil = self._veil
    if veil then
        veil.Visible = true
        tw(veil, CLOSE_INFO, { BackgroundTransparency = 0 })
    end
    for _, l in ipairs(shadowLayers(self)) do tw(l, CLOSE_INFO, { BackgroundTransparency = 1 }) end
    if self._mainStroke then tw(self._mainStroke, CLOSE_INFO, { Transparency = 1 }) end
    tw(root, CLOSE_INFO, { Position = UDim2.new(rest.X.Scale, rest.X.Offset, rest.Y.Scale, rest.Y.Offset + RISE) })
    task.delay(CLOSE_INFO.Time, function()
        if self._animToken ~= mine then return end
        self._animating = false
        if token and self._visToken ~= token then return end
        if self._visible then return end
        root.Visible = false
        root.Position = rest
    end)
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
        if self._vdiv then self._vdiv.Visible = false end
        if self._grip then self._grip.Visible = false end
        if self._hairline then self._hairline.Visible = false end
        self._body.Position = UDim2.new(0, 0, 0, 0)
        self._body.Size = UDim2.new(1, 0, 1, 0)
        self._pages.Visible = false
        self._pageTitle.Text = self._title
        self._pageSub.Text = ""
        tw(self._root, MOTION.standard, { Size = UDim2.new(0, 264, 0, 46) })
    else
        self._sidebar.Visible = true
        if self._vdiv then self._vdiv.Visible = true end
        if self._grip then self._grip.Visible = true end
        if self._hairline then self._hairline.Visible = true end
        local w = self._sidebar.Size.X.Offset
        self._body.Position = UDim2.new(0, w + 1, 0, 0)
        self._body.Size = UDim2.new(1, -(w + 1), 1, 0)
        self._pages.Visible = true
        if self._activeTab then
            self._pageTitle.Text = self._activeTab._name
            self._pageSub.Text = self._activeTab._subtitle
        end
        tw(self._root, MOTION.standard, { Size = self._restoreSize or UDim2.new(0, 760, 0, 520) })
    end
    if self._syncWatermarkState then self:_syncWatermarkState() end
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
    self._settings.MenuButtonVisible = v and true or false
    if self._saveSettingsLater then self:_saveSettingsLater() end
end
Window.SetMenuButtonVisible = Window.SetFloatingButtonVisible

function Window:Notify(...) return BPUI:Notify(...) end

function Window:Search(query)
    closeOpenPanel(nil)
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
        if tab._row then tab._row.Visible = tabMatch end
        tab._searchHits = tabHits
        if tab._syncEmpty then tab:_syncEmpty(query) end
    end

    -- Searching from a page that has no hits jumps to the first page that
    -- does, instead of leaving the user staring at "No matches" while the
    -- result sits one click away in the sidebar.
    local current = self._activeTab
    if not empty and current and (current._searchHits or 0) == 0 then
        for _, tab in ipairs(self._tabs) do
            if tab ~= current and (tab._searchHits or 0) > 0 then
                tab:Select(true)
                break
            end
        end
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

local ROW_MIN = 42

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
    row.BackgroundTransparency = theme.SurfaceAlpha or 0
    bind(el, row, "BackgroundColor3", "Surface")
    bind(el, row, "BackgroundTransparency", "SurfaceAlpha")
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
    if iconUsable(config.Icon) then
        iconInset = 28
        local box = new("Frame", {
            Name = "RowIcon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, -iconInset, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            ZIndex = 4,
            Parent = inner,
        })
        el._iconColored = config.Colored == true
        el._iconColor = config.IconColor
        local ico, kind = iconAny(box, config.Icon, 16, theme.SubText, 5, el._iconColored, el._iconColor)
        if kind == "image" then
            if not el._iconColor then bind(el, ico, "ImageColor3", "SubText") end
        elseif kind == "draw" then bindIcon(el, ico, "SubText") end
        el._icon, el._iconKind, el._iconBox = ico, kind, box
    end
    pad(inner, 9, 13, 9, 13 + iconInset)
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
            Size = UDim2.new(1, 0, 0, 16),
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
        fitWrapped(descLabel)
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
    if not v and self._open and self.Close then pcall(function() self:Close() end) end
end

function Element:SetCallback(fn) self._callback = fn end
function Element:SetTooltip(str) self._tooltip = str end
function Element:SetIcon(icon, colored, iconColor)
    if not self._iconBox then return end
    if self._icon then self._icon:Destroy() end
    if colored ~= nil then self._iconColored = colored == true end
    if iconColor ~= nil then self._iconColor = iconColor or nil end
    local ico, kind = iconAny(self._iconBox, icon, 18, ACTIVE.SubText, 5, self._iconColored, self._iconColor)
    if kind == "image" then
        if not self._iconColor then bind(self, ico, "ImageColor3", "SubText") end
    elseif kind == "draw" then bindIcon(self, ico, "SubText") end
    self._icon, self._iconKind = ico, kind
end

function Element:SetLocked(state)
    self._locked = state and true or false
    if self._locked and self._open and self.Close then pcall(function() self:Close() end) end
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
    if self._popup then pcall(function() self._popup:Destroy() end) self._popup = nil end
    if self._rowOwner then untrack(self._rowOwner) self._rowOwner = nil end
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
    local el = baseRow(self, config, { controlWidth = 36, controlHeight = 19 })
    el.Type = "Toggle"
    el._callback = config.Callback
    el.Value = config.Default and true or false

    local KNOB_OFF_X, KNOB_ON_X = 3, 21

    local track_ = new("Frame", {
        Name = "Track",
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = el.Value and 0 or 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 19),
        ZIndex = 4,
        Parent = el._right,
    })
    corner(track_, RADIUS.pill)
    bind(el, track_, "BackgroundColor3", "Accent")
    sheen(track_, 0.88, nil, 90)
    local ts = stroke(track_, theme.Track, 1, el.Value and 1 or 0)
    bind(el, ts, "Color", "Track")

    local knob = new("Frame", {
        Name = "Knob",
        BackgroundColor3 = el.Value and theme.KnobOn or theme.KnobOff,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, el.Value and KNOB_ON_X or KNOB_OFF_X, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 6,
        Parent = track_,
    })
    corner(knob, RADIUS.pill)

    local function paint(animate)
        local on = el.Value
        local info = animate and MOTION.standard or TweenInfo.new(0)
        tw(track_, info, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = ACTIVE.Accent })
        tw(ts, info, { Transparency = on and 1 or 0, Color = ACTIVE.Track })
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
            tw(knob, MOTION.press, { Size = UDim2.new(0, 15, 0, 12) })
        end
    end))
    track(el, hit.InputEnded:Connect(function(input)
        if isClick(input) then tw(knob, MOTION.release, { Size = UDim2.new(0, 12, 0, 12) }) end
    end))
    if not IS_MOBILE then
        track(el, hit.MouseEnter:Connect(function()
            if el._locked then return end
            tw(knob, MOTION.hover, { Size = UDim2.new(0, 14, 0, 14) })
        end))
        track(el, hit.MouseLeave:Connect(function()
            tw(knob, MOTION.hover, { Size = UDim2.new(0, 12, 0, 12) })
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
        Size = UDim2.new(0, 54, 0, 20),
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

    el._left.Size = UDim2.new(1, -66, 0, 0)

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
        Size = UDim2.new(1, 0, 0, 22),
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
        Size = UDim2.new(0, 18, 0, 18),
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
        Size = UDim2.new(0, 9, 0, 9),
        ZIndex = 8,
        Parent = knob,
    })
    corner(core, RADIUS.pill)
    bind(el, core, "BackgroundColor3", "Accent")

    if not IS_MOBILE then
        track(el, bar.MouseEnter:Connect(function()
            if el._locked then return end
            tw(core, MOTION.hover, { Size = UDim2.new(0, 11, 0, 11) })
        end))
        track(el, bar.MouseLeave:Connect(function()
            tw(core, MOTION.hover, { Size = UDim2.new(0, 9, 0, 9) })
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
        tw(core, MOTION.quick, { Size = UDim2.new(0, 7, 0, 7) })
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
        tw(core, MOTION.release, { Size = UDim2.new(0, 9, 0, 9) })
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
        Size = UDim2.new(0, width, 0, height or 24),
        ClipsDescendants = true,
        ZIndex = 7,
        Parent = parent,
    })
    corner(p, RADIUS.sm)
    p.BackgroundTransparency = theme.ElementAlpha or 0
    local s = stroke(p, theme.StrokeSoft, 1, 0.4)
    return p, s
end

local DD_ROW_H, DD_ROW_GAP = 26, 2
-- Popover: z-layer above every page element (rows top out around 10), and
-- its minimum width -- it grows to the pill's width when that is wider.
local POP_Z, POP_W = 60, 196

function Section:AddDropdown(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { autoHeight = true })
    el.Type = "Dropdown"
    el._callback = config.Callback
    el._multi = config.Multi and true or false
    el._options = {}
    for i, v in ipairs(config.Options or {}) do el._options[i] = tostring(v) end

    if el._nameLabel then el._nameLabel.Size = UDim2.new(1, -122, 0, 16) end
    if el._descLabel then el._descLabel.Size = UDim2.new(1, -122, 0, el._descLabel.Size.Y.Offset) end
    -- This row grows when the menu unfolds, so nothing in its header may be
    -- centred on the row as a whole: the icon is pinned to the header line
    -- (name + description block, or the 24px pill when there's no
    -- description) and a lone name is nudged down to sit level with the pill.
    if el._iconBox then
        el._iconBox.AnchorPoint = Vector2.new(0, 0.5)
        el._iconBox.Position = UDim2.new(0, el._iconBox.Position.X.Offset, 0, el._descLabel and 16 or 12)
    end
    if not el._descLabel then el._left.Position = UDim2.new(0, 0, 0, 4) end

    local head, hs = pill(el._inner, theme, 112, 24)
    head.AnchorPoint = Vector2.new(1, 0)
    head.Position = UDim2.new(1, 0, 0, el._descLabel and 2 or 0)
    bind(el, head, "BackgroundColor3", "Element")
    bind(el, head, "BackgroundTransparency", "ElementAlpha")
    bind(el, hs, "Color", "StrokeSoft")

    local headText = text({
        Text = "None",
        Font = FONT.medium,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        ZIndex = 8,
        Parent = head,
    })
    bind(el, headText, "TextColor3", "SubText")

    local caretBox = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.new(0, 13, 0, 13),
        ZIndex = 8,
        Parent = head,
    })
    local caret = iconChevron(caretBox, 10, theme.Muted, 90, 9)

    -- The menu is a floating popover, not an in-row expansion: opening it
    -- no longer shoves every row below it down the page. It lives on the
    -- window's own surface (so it moves with a dragged window and is clipped
    -- to it), sits on a soft shadow, and flips above its pill when there
    -- isn't room below. `pop` is the unclipped holder that carries the
    -- shadow; `menu` inside it clips the list while it grows.
    local pop = new("Frame", {
        Name = "DropdownPopover",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, POP_W, 0, 0),
        Visible = false,
        ZIndex = POP_Z,
        Parent = el._window and el._window._main or el._left,
    })
    local menu = new("Frame", {
        Name = "Menu",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        Active = true,
        ZIndex = POP_Z + 4,
        Parent = pop,
    })
    el._popup = pop
    corner(menu, RADIUS.md)
    bind(el, menu, "BackgroundColor3", "Element")
    local ms = stroke(menu, theme.Stroke, 1, 0.1)
    bind(el, ms, "Color", "Stroke")

    local menuPad = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = POP_Z + 4,
        Parent = menu,
    })

    local filterBox
    local searchable = config.Searchable
    if searchable == nil then searchable = #el._options > 6 end

    local optScroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, searchable and 32 or 5),
        Size = UDim2.new(1, -10, 1, searchable and -37 or -10),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Muted,
        ScrollBarImageTransparency = 0.5,
        ZIndex = POP_Z + 5,
        Parent = menuPad,
    })
    list(optScroll, DD_ROW_GAP)

    if searchable then
        local fw = new("Frame", {
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 5, 0, 5),
            Size = UDim2.new(1, -10, 0, 22),
            ZIndex = POP_Z + 5,
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
            Position = UDim2.new(0, 7, 0, 0),
            Size = UDim2.new(1, -12, 1, 0),
            ZIndex = POP_Z + 6,
            Parent = fw,
        })
        bind(el, filterBox, "TextColor3", "Text")
        bind(el, filterBox, "PlaceholderColor3", "Muted")
    end

    -- Cast right before the menu opens and faded away right after: this is
    -- what turns "the box got taller" into "this appeared". See panelVeil.
    local veil = panelVeil(menuPad, theme.Element, POP_Z + 10)
    bind(el, veil, "BackgroundColor3", "Element")
    veil.Visible = false

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
            -- Font isn't a tweenable property, so the medium/body swap that
            -- marks the selected label happens instantly; only its colour
            -- and the row's own washes animate.
            row.label.Font = on and FONT.medium or FONT.body
            tween(row.label, { TextColor3 = on and ACTIVE.Text or ACTIVE.SubText }, MOTION.quick)
            tween(row.frame, { BackgroundTransparency = on and 0.88 or 1, BackgroundColor3 = ACTIVE.Accent }, MOTION.quick)
            if row.tick then
                row.tick.BackgroundColor3 = ACTIVE.Accent
                tw(row.tick, MOTION.quick, { BackgroundTransparency = on and 0 or 1, Size = UDim2.new(0, 3, 0, on and 12 or 4) })
            end
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
        local h = math.min(count, 6) * (DD_ROW_H + DD_ROW_GAP) + (searchable and 37 or 10)
        return math.max(h, searchable and 42 or 30)
    end

    -- Where the popover goes, in the window's own (unscaled) coordinates:
    -- right-aligned under its pill, at least POP_W wide, flipped above the
    -- pill when the space below is short and the space above is larger, and
    -- clamped to whatever room there is (the list scrolls past that).
    local function popGeometry(h)
        local main = pop.Parent
        local sc = effectiveScale(main)
        if not sc or sc <= 0 then sc = 1 end
        local mp, msz = main.AbsolutePosition, main.AbsoluteSize
        local hp, hsz = head.AbsolutePosition, head.AbsoluteSize
        local width = math.max(POP_W, math.floor(hsz.X / sc + 0.5))
        local mainW, mainH = msz.X / sc, msz.Y / sc
        local right = (hp.X + hsz.X - mp.X) / sc
        local top = (hp.Y - mp.Y) / sc
        local bottom = top + hsz.Y / sc
        local x = math.clamp(right - width, 8, math.max(8, mainW - width - 8))
        local below, above = mainH - bottom - 12, top - 12
        local up = below < h and above > below
        local room = up and above or below
        return x, up and (top - 4) or (bottom + 4), width, math.min(h, math.max(room, 40)), up
    end

    -- Opening snaps to size with a small deliberate overshoot (MOTION.spring)
    -- while its contents fade in from underneath the veil a beat behind, so
    -- the menu reads as unfolding into place rather than a box getting
    -- taller. Closing is quick and overshoot-free: it should get out of the
    -- way, not linger.
    local popWidth = POP_W
    local function setOpen(state)
        if state and el._locked then return end
        el._open = state
        if state then
            closeOpenPanel(el)
            BPUI._openPanel = el
            if el._window and el._window._hideTooltip then el._window:_hideTooltip() end
            local x, y, width, h, up = popGeometry(menuHeight())
            popWidth = width
            pop.AnchorPoint = Vector2.new(0, up and 1 or 0)
            pop.Position = UDim2.new(0, x, 0, y + (up and 6 or -6))
            pop.Size = UDim2.new(0, width, 0, 0)
            pop.Visible = true
            veil.Visible = true
            veil.BackgroundTransparency = 0
            tw(veil, MOTION.quick, { BackgroundTransparency = 1 })
            tw(caret, MOTION.spring, { Rotation = -90 })
            tw(pop, MOTION.spring, { Size = UDim2.new(0, width, 0, h), Position = UDim2.new(0, x, 0, y) })
            tween(hs, { Color = ACTIVE.Accent, Transparency = 0.1 }, MOTION.hover)
        else
            if BPUI._openPanel == el then BPUI._openPanel = nil end
            tw(caret, MOTION.quick, { Rotation = 90 })
            local t = tw(pop, MOTION.quick, { Size = UDim2.new(0, popWidth, 0, 0) })
            tween(hs, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
            if t then t.Completed:Connect(function() if not el._open then pop.Visible = false end end)
            else pop.Visible = false end
        end
    end
    local function refit()
        if not el._open then return end
        local x, y, width, h, up = popGeometry(menuHeight())
        popWidth = width
        pop.AnchorPoint = Vector2.new(0, up and 1 or 0)
        tw(pop, MOTION.quick, { Size = UDim2.new(0, width, 0, h), Position = UDim2.new(0, x, 0, y) })
    end
    -- A popover pinned to a row must not drift away from it: scrolling the
    -- page it belongs to closes it, the way native menus behave.
    if el._tab and el._tab._page then
        track(el, el._tab._page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if el._open then setOpen(false) end
        end))
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

    -- Option rows keep their connections on a separate owner (reads fall
    -- through to el, so pressable still sees el._locked) and drop them on
    -- every rebuild -- a Refresh() used to leave each old row's global
    -- input hook connected, piling up on a list refreshed every few seconds.
    local rowOwner
    local function buildRows()
        if rowOwner then untrack(rowOwner) end
        rowOwner = setmetatable({ _connections = {} }, { __index = el })
        el._rowOwner = rowOwner
        for _, row in pairs(el._rows) do row.frame:Destroy() end
        el._rows = {}
        local total = #el._options
        for i, opt in ipairs(el._options) do
            local frame = new("TextButton", {
                BackgroundColor3 = ACTIVE.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Size = UDim2.new(1, 0, 0, DD_ROW_H),
                LayoutOrder = i,
                ClipsDescendants = true,
                ZIndex = POP_Z + 6,
                Parent = optScroll,
            })
            corner(frame, RADIUS.sm)

            -- The same slim accent tick the section headers use for their
            -- own "this is the current one" mark, reused here for "this is
            -- the selected option" -- one recognisable motif standing in
            -- for two different jobs instead of two different affordances.
            local tick = new("Frame", {
                Name = "Tick",
                BackgroundColor3 = ACTIVE.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(0, 3, 0, 4),
                ZIndex = POP_Z + 7,
                Parent = frame,
            })
            corner(tick, RADIUS.pill)

            local check = new("Frame", {
                BackgroundColor3 = ACTIVE.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 7, 0.5, 0),
                Size = UDim2.new(0, 13, 0, 13),
                ZIndex = POP_Z + 7,
                Parent = frame,
            })
            corner(check, el._multi and 4 or RADIUS.pill)
            local cstroke = stroke(check, ACTIVE.Muted, 1, 0.5)

            local mark = iconCheck(check, 9, ACTIVE.AccentText, POP_Z + 8)
            fadeIcon(mark, 1, TweenInfo.new(0))

            local lbl = text({
                Text = opt,
                Font = FONT.body,
                TextSize = 11,
                TextColor3 = ACTIVE.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.new(0, 26, 0, 0),
                Size = UDim2.new(1, -32, 1, 0),
                ZIndex = POP_Z + 7,
                Parent = frame,
            })

            -- A hairline between rows, not around them: it reads as one
            -- continuous list with quiet divisions rather than a stack of
            -- separate cards, and it steps aside (see paintRows) wherever a
            -- row's own hover/selected wash already does the separating.
            if i < total then
                local sep = new("Frame", {
                    Name = "Sep",
                    BackgroundColor3 = ACTIVE.StrokeSoft,
                    BackgroundTransparency = 0.55,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 8, 1, 0),
                    Size = UDim2.new(1, -16, 0, 1),
                    ZIndex = POP_Z + 7,
                    Parent = frame,
                })
                bind(el, sep, "BackgroundColor3", "StrokeSoft")
            end

            if not IS_MOBILE then
                track(rowOwner, frame.MouseEnter:Connect(function()
                    if not isSelected(opt) then
                        -- Opaque ElementHover, not a 0.9 wash: the menu it
                        -- sits in is already an opaque Element panel, so a
                        -- 10% tint of a near-identical colour composited to
                        -- no visible change at all and options had no hover.
                        tween(frame, { BackgroundTransparency = 0, BackgroundColor3 = ACTIVE.ElementHover }, MOTION.hover)
                    end
                end))
                track(rowOwner, frame.MouseLeave:Connect(function()
                    if not isSelected(opt) then tween(frame, { BackgroundTransparency = 1 }, MOTION.hover) end
                end))
            end
            pressable(rowOwner, frame, frame, function() choose(opt) end, { rippleAlpha = 0.92, pressScale = 0.99 })

            el._rows[opt] = { frame = frame, check = check, mark = mark, label = lbl, stroke = cstroke, tick = tick }
        end
    end

    if filterBox then
        track(el, filterBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = filterBox.Text:lower()
            for opt, row in pairs(el._rows) do
                row.frame.Visible = q == "" or opt:lower():find(q, 1, true) ~= nil
            end
            refit()
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
            if type(value) == "table" then value = value[1] end
            local found
            if value ~= nil then
                for _, o in ipairs(self._options) do
                    if o == tostring(value) then found = o break end
                end
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
        refit()
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
    local width = config.Width or 122
    local el = baseRow(self, config, { controlWidth = width, controlHeight = 24 })
    el.Type = "Input"
    el._callback = config.Callback
    el.Value = config.Default or ""

    local wrap = new("Frame", {
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, width, 0, 24),
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
        TextSize = 11,
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

    -- Numeric / MaxLength are enforced as you type, not only on commit: a
    -- rejected keystroke simply doesn't land, and the outline blinks the
    -- theme's Danger colour so it's clear why.
    if config.Numeric or config.MaxLength then
        track(el, box:GetPropertyChangedSignal("Text"):Connect(function()
            local t = box.Text
            local c = t
            if config.Numeric then c = c:gsub("[^%d%.%-]", "") end
            if config.MaxLength and #c > config.MaxLength then c = c:sub(1, config.MaxLength) end
            if c ~= t then
                box.Text = c
                ws.Color = ACTIVE.Danger or ACTIVE.Accent
                ws.Transparency = 0
                tween(ws, { Color = box:IsFocused() and ACTIVE.Accent or ACTIVE.StrokeSoft }, MOTION.standard)
            end
        end))
    end

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
    local el = baseRow(self, config, { controlWidth = 84, controlHeight = 24 })
    el.Type = "Keybind"
    el._callback = config.Callback
    el._onChanged = config.OnChanged
    el._mode = config.Mode or "Press"
    el._key = keyFromValue(config.Default)
    el.Value = keyName(el._key)
    el._state = false

    local p, ps = pill(el._right, theme, 84, 24)
    bind(el, p, "BackgroundColor3", "Element")
    bind(el, p, "BackgroundTransparency", "ElementAlpha")
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
    -- Friendlier labels for the pill only (el.Value keeps the raw KeyCode
    -- name so configs and callers see exactly what they always did).
    local PRETTY = {
        LeftShift = "L-Shift", RightShift = "R-Shift", LeftControl = "L-Ctrl", RightControl = "R-Ctrl",
        LeftAlt = "L-Alt", RightAlt = "R-Alt", MouseButton1 = "Mouse 1", MouseButton2 = "Mouse 2",
        MouseButton3 = "Mouse 3", Return = "Enter", Backquote = "`", Space = "Space",
        One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
    }
    local function pretty(v) return PRETTY[v] or v end
    local function setLabel()
        lbl.Text = listening and "Press a key" or pretty(el.Value)
        lbl.TextColor3 = listening and ACTIVE.Accent or (el._key and ACTIVE.Text or ACTIVE.Muted)
    end
    el._paint = setLabel

    local function stopListening(captured)
        if not listening then return end
        listening = false
        BPUI._activeKeybindCancel = nil
        setLabel()
        if captured then
            -- a short confirming blink in the success colour, then settle
            ps.Color = ACTIVE.Success or ACTIVE.Accent
            ps.Transparency = 0
            tween(ps, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        else
            tween(ps, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
        end
    end

    pressable(el, p, p, function()
        if listening then stopListening() return end
        if BPUI._activeKeybindCancel then BPUI._activeKeybindCancel() end
        listening = true
        BPUI._activeKeybindCancel = stopListening
        setLabel()
        ps.Color = ACTIVE.Accent
        -- breathing outline while it waits for a key
        ps.Transparency = 0
        tw(ps, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 })
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
            stopListening(true)
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

local PICK_W, PICK_H = 230, 146

function Section:AddColorPicker(config)
    config = config or {}
    local theme = ACTIVE
    local el = baseRow(self, config, { autoHeight = true })
    el.Type = "ColorPicker"
    el._callback = config.Callback
    el.Value = toColor(config.Default) or theme.Accent

    if el._nameLabel then el._nameLabel.Size = UDim2.new(1, -84, 0, 14) end
    if el._descLabel then el._descLabel.Size = UDim2.new(1, -84, 0, el._descLabel.Size.Y.Offset) end

    local swatchBtn = new("TextButton", {
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, el._descLabel and 2 or 0),
        Size = UDim2.new(0, 76, 0, 24),
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
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        ZIndex = 8,
        Parent = swatchBtn,
    })
    bind(el, hexLabel, "TextColor3", "SubText")

    -- Like the dropdown, the picker is a floating popover now rather than
    -- a panel that unfolds inside its row and pushes the page down.
    local pop = new("Frame", {
        Name = "ColorPopover",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, PICK_W, 0, 0),
        Visible = false,
        ZIndex = POP_Z,
        Parent = el._window and el._window._main or el._left,
    })
    el._popup = pop
    local panel = new("Frame", {
        Name = "Panel",
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ClipsDescendants = true,
        Active = true,
        ZIndex = POP_Z + 4,
        Parent = pop,
    })
    corner(panel, RADIUS.md)
    bind(el, panel, "BackgroundColor3", "Element")
    local pns = stroke(panel, theme.Stroke, 1, 0.1)
    bind(el, pns, "Color", "Stroke")

    local panelVeilFrame = panelVeil(panel, theme.Element, POP_Z + 10)
    bind(el, panelVeilFrame, "BackgroundColor3", "Element")
    panelVeilFrame.Visible = false

    local sv = new("Frame", {
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 9, 0, 9),
        Size = UDim2.new(1, -18, 0, 78),
        ZIndex = POP_Z + 5,
        Parent = panel,
    })
    corner(sv, RADIUS.sm)

    local whiteLayer = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = POP_Z + 6,
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
        ZIndex = POP_Z + 7,
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
        ZIndex = POP_Z + 9,
        Parent = sv,
    })
    corner(cursor, RADIUS.pill)
    stroke(cursor, Color3.new(1, 1, 1), 2, 0)
    local cursorInner = stroke(cursor, Color3.new(0, 0, 0), 1, 0.6)

    local hue = new("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.new(0, 9, 0, 95),
        Size = UDim2.new(1, -18, 0, 11),
        ZIndex = POP_Z + 5,
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
        ZIndex = POP_Z + 6,
        Parent = hue,
    })
    corner(hueKnob, 3)
    stroke(hueKnob, Color3.new(0, 0, 0), 1, 0.7)

    local hexWrap = new("Frame", {
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 9, 0, 114),
        Size = UDim2.new(1, -18, 0, 22),
        ZIndex = POP_Z + 5,
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
        ZIndex = POP_Z + 6,
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
    local function geometry()
        local main = pop.Parent
        local sc = effectiveScale(main)
        if not sc or sc <= 0 then sc = 1 end
        local mp, msz = main.AbsolutePosition, main.AbsoluteSize
        local hp, hsz = swatchBtn.AbsolutePosition, swatchBtn.AbsoluteSize
        local mainW, mainH = msz.X / sc, msz.Y / sc
        local right = (hp.X + hsz.X - mp.X) / sc
        local top = (hp.Y - mp.Y) / sc
        local bottom = top + hsz.Y / sc
        local x = math.clamp(right - PICK_W, 8, math.max(8, mainW - PICK_W - 8))
        local below, above = mainH - bottom - 12, top - 12
        local up = below < PICK_H and above > below
        return x, up and (top - 4) or (bottom + 4), up
    end
    local function setOpen(state)
        if state and el._locked then return end
        el._open = state
        if state then
            closeOpenPanel(el)
            BPUI._openPanel = el
            if el._window and el._window._hideTooltip then el._window:_hideTooltip() end
            local x, y, up = geometry()
            pop.AnchorPoint = Vector2.new(0, up and 1 or 0)
            pop.Position = UDim2.new(0, x, 0, y + (up and 6 or -6))
            pop.Size = UDim2.new(0, PICK_W, 0, 0)
            pop.Visible = true
            panelVeilFrame.Visible = true
            panelVeilFrame.BackgroundTransparency = 0
            tw(panelVeilFrame, MOTION.quick, { BackgroundTransparency = 1 })
            tw(pop, MOTION.spring, { Size = UDim2.new(0, PICK_W, 0, PICK_H), Position = UDim2.new(0, x, 0, y) })
            tween(sbs, { Color = ACTIVE.Accent, Transparency = 0.1 }, MOTION.hover)
        else
            if BPUI._openPanel == el then BPUI._openPanel = nil end
            local t = tw(pop, MOTION.quick, { Size = UDim2.new(0, PICK_W, 0, 0) })
            tween(sbs, { Color = ACTIVE.StrokeSoft, Transparency = 0.4 }, MOTION.hover)
            if t then t.Completed:Connect(function() if not el._open then pop.Visible = false end end)
            else pop.Visible = false end
        end
    end
    if el._tab and el._tab._page then
        track(el, el._tab._page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if el._open then setOpen(false) end
        end))
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

    local dTitle = text({
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
    fitWrapped(dTitle)

    if config.Content and config.Content ~= "" then
        local dContent = text({
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
        fitWrapped(dContent)
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
        elseif style == "Danger" then
            -- The theme's Danger is tuned as a text/icon colour, so it's
            -- too light to carry white text as a fill; deepen it first.
            bg, fg = theme.Danger:Lerp(Color3.new(0, 0, 0), 0.28), Color3.new(1, 1, 1)
        end

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
    if self._wmGui then pcall(function() self._wmGui:Destroy() end) self._wmGui = nil end
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
    self:_animateClose(nil)
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

Window.Unload = Window.Destroy
Window.Close = Window.Destroy

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
            pcall(function() w:_retintBackground() end)
            if type(theme) == "string" then
                w._settings.Theme = theme
                w:_saveSettingsLater()
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
            w:_saveSettingsLater()
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
        Icon = config.SettingsIcon or "sliders",
        __settings = true,
    })
    -- Settings is built a frame after CreateWindow returns. A script that
    -- yields before making its own tabs would otherwise see Settings land
    -- in the middle of the sidebar (and open first); pin it to the end.
    tab._isSettings = true
    if tab._button then tab._button.LayoutOrder = 1000000 end

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

    local backdrop = tab:CreateSection("Background")

    backdrop:AddInput({
        Name = "Background image",
        Description = "A Roblox image id, a Roblox asset link, or a direct PNG/JPG link. Leave empty for none.",
        Icon = "image",
        Placeholder = "id or link",
        Default = window._bg.Image and tostring(window._bg.Image) or "",
        Width = 170,
        Callback = function(v)
            v = tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
            window:SetBackground({ Image = v ~= "" and v or false })
        end,
    })

    backdrop:AddSlider({
        Name = "Image opacity",
        Min = 0, Max = 100, Default = math.floor((1 - (window._bg.ImageAlpha or 0.7)) * 100 + 0.5),
        Suffix = "%",
        Callback = function(v) window:SetBackground({ ImageAlpha = 1 - v / 100 }) end,
    })

    backdrop:AddToggle({
        Name = "Tile image",
        Description = "Repeat a small pattern instead of filling the window with one picture.",
        Default = window._bg.ImageTile == true,
        Callback = function(v) window:SetBackground({ ImageTile = v }) end,
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
        Name = "Menu button",
        Description = "Small draggable button that opens and closes the window.",
        Icon = "menu",
        Default = window._float ~= nil and window._float.Visible or false,
        Callback = function(state) window:SetFloatingButtonVisible(state) end,
    })

    behaviour:AddButton({
        Name = "Reset window size",
        Description = "Restores the default dimensions.",
        Callback = function()
            window._settings.Width, window._settings.Height = nil, nil
            window:_saveSettings()
            window._root.Size = UDim2.new(0, IS_MOBILE and 520 or 760, 0, IS_MOBILE and 370 or 520)
        end,
    })

    if window._wm then
        local wmS = wmSettings(window)
        local wmSec = tab:CreateSection("Watermark")
        wmSec:AddToggle({
            Name = "Show watermark",
            Description = "Small on-screen tag with the hub name, FPS and ping.",
            Icon = "monitor",
            Default = wmS.enabled,
            Callback = function(v) window:SetWatermarkVisible(v) end,
        })
        wmSec:AddInput({
            Name = "Watermark text",
            Description = "Shown on the tag. Leave empty for the hub name.",
            Icon = "pencil",
            Placeholder = window._title,
            Default = window._settings.WatermarkText or "",
            MaxLength = 32,
            Width = 150,
            Callback = function(v) window:SetWatermark(v) end,
        })
        wmSec:AddToggle({
            Name = "Show FPS",
            Icon = "gauge",
            Default = wmS.fps,
            Callback = function(v) window:SetWatermarkStats(v, nil) end,
        })
        wmSec:AddToggle({
            Name = "Show ping",
            Icon = "wifi",
            Default = wmS.ping,
            Callback = function(v) window:SetWatermarkStats(nil, v) end,
        })
    end

    local privacy = tab:CreateSection("Privacy")
    privacy:AddToggle({
        Name = "Hide my name",
        Description = "Streamer mode: your Roblox name and avatar are hidden in the window.",
        Icon = "eye-off",
        Default = window._settings.HideName == true,
        Callback = function(v) window:SetNameHidden(v) end,
    })
    privacy:AddInput({
        Name = "Display name",
        Description = "Shown instead of your Roblox name. Leave empty to use your own.",
        Icon = "user",
        Placeholder = "anything",
        Default = window._settings.DisplayName or "",
        MaxLength = 24,
        Width = 150,
        Callback = function(v) window:SetDisplayName(v) end,
    })

    if config.ShowConfig == false then return tab end

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
---------------------------------------------------------------- compatibility
-- People arrive with scripts written for other UI libraries, or with code an
-- AI wrote from memory of one: `Window:Tab{}`, `tab:CreateToggle{name=...,
-- callback=...}`, `Tab:AddToggle("Flag", {Title=...})`. Before this layer a
-- single unknown method threw "attempt to call a nil value" after the tab was
-- made, which left users staring at an empty page. Now:
--   * the usual method names from other libraries are aliases of ours;
--   * config keys are accepted in any case and under their common synonyms;
--   * positional forms (name, callback) / (flag, config) are understood;
--   * an element method BPUI doesn't have warns once, puts a visible note in
--     the section, and returns a harmless stub so the rest of the script runs.

local KEY_SYNONYMS = {
    -- identity
    Title = "Name", Text = "Name", Label = "Name",
    Desc = "Description", Info = "Description", SubText = "Description", Subtitle = "Description",
    -- behaviour
    Func = "Callback", Function = "Callback", OnClick = "Callback", OnChange = "Callback",
    Changed = "Callback", Clicked = "Callback", Pressed = "Callback",
    Id = "Flag", ID = "Flag", Pointer = "Flag", Key = "Flag",
    Image = "Icon",
    Disabled = "Locked",
    -- values
    Value = "Default", CurrentValue = "Default", CurrentOption = "Default",
    CurrentKeybind = "Default", Current = "Default", State = "Default",
    Keybind = "Default", Bind = "Default", Hold = nil,
    Values = "Options", List = "Options", Items = "Options", Choices = "Options",
    MultiSelect = "Multi", MultipleOptions = "Multi", Multiple = "Multi", AllowMultiple = "Multi",
    Minimum = "Min", Maximum = "Max", Step = "Increment", Precise = nil,
    ValueName = "Suffix", Unit = "Suffix",
    PlaceholderText = "Placeholder", PlaceHolder = "Placeholder",
    CharacterLimit = "MaxLength", ClearTextOnFocus = "ClearOnFocus",
    NumbersOnly = "Numeric", NumberOnly = "Numeric",
    Variant = "Style",
}

-- Keys an element must NOT have renamed, per kind (a Label's Text is its
-- text, a Paragraph's Title is its title, a keybind's Key is its key).
local KEEP = {
    Label = { Text = true },
    Paragraph = { Title = true, Text = true, Desc = true, Description = true },
    Keybind = { Key = true, Hold = true },
}

local function isArray(t)
    return type(t) == "table" and (t[1] ~= nil or next(t) == nil)
end

local function canon(config, kind)
    if type(config) ~= "table" then return config end
    if config.__bpuiCanon then return config end
    local out = {}
    for k, v in pairs(config) do out[k] = v end
    local keep = KEEP[kind] or {}
    for k, v in pairs(config) do
        if type(k) == "string" then
            local upper = k:sub(1, 1):upper() .. k:sub(2)
            -- lowercase / camelCase spelling of a key we already know
            if upper ~= k and out[upper] == nil then out[upper] = v end
            local syn = KEY_SYNONYMS[upper]
            if syn and not keep[upper] and out[syn] == nil then out[syn] = v end
        end
    end

    if kind == "Slider" then
        if type(out.Range) == "table" then
            out.Min = out.Min or out.Range[1]
            out.Max = out.Max or out.Range[2]
        end
        -- Fluent's Rounding is a number of decimals, not a step
        if out.Increment == nil and type(out.Rounding) == "number" then
            out.Increment = out.Rounding <= 0 and 1 or 10 ^ -out.Rounding
        end
        if type(out.Default) ~= "number" then out.Default = tonumber(out.Default) end
    elseif kind == "Dropdown" then
        -- {a=true, b=true} (Fluent multi default) -> {"a","b"}
        if type(out.Default) == "table" and not isArray(out.Default) then
            local list = {}
            for k, on in pairs(out.Default) do if on then list[#list + 1] = k end end
            out.Default = list
        end
        -- a single-select default given as {"a"} or {} (Rayfield)
        if not out.Multi and type(out.Default) == "table" then out.Default = out.Default[1] end
        -- Fluent/Linoria: Default = 2 means the second option
        if type(out.Default) == "number" and type(out.Options) == "table" then
            local asText = false
            for _, o in ipairs(out.Options) do if tostring(o) == tostring(out.Default) then asText = true end end
            if not asText then out.Default = out.Options[out.Default] end
        end
        -- Rayfield hands a single-select callback a table ({"a"}); scripts
        -- written for it read Options[1]. Keep that shape for them.
        local rayfieldShape = config.CurrentOption ~= nil or config.MultipleOptions ~= nil
        if rayfieldShape and not out.Multi and type(out.Callback) == "function" then
            local cb = out.Callback
            out.Callback = function(v) return cb(v ~= nil and { v } or {}) end
        end
    elseif kind == "Button" then
        local st = type(out.Style) == "string" and out.Style:lower()
        if st == "primary" or st == "accent" then out.Style = "Accent"
        elseif st == "danger" or st == "destructive" or st == "red" then out.Style = "Danger"
        elseif st then out.Style = "Default" end
    elseif kind == "Keybind" then
        if out.Default == nil and out.Key ~= nil and type(out.Key) ~= "boolean" then out.Default = out.Key end
        if type(out.Mode) == "string" then
            local m = out.Mode:lower()
            out.Mode = (m == "toggle" and "Toggle") or (m == "hold" and "Hold") or "Press"
        end
        if out.Hold == true or out.HoldToInteract == true then out.Mode = "Hold" end
    elseif kind == "ColorPicker" then
        if out.Default == nil and typeof(out.Color) == "Color3" then out.Default = out.Color end
    elseif kind == "Label" then
        out.Text = out.Text or out.Name or out.Title or out.Content or out.Label
    elseif kind == "Paragraph" then
        out.Title = out.Title or out.Name or out.Header
        out.Content = out.Content or out.Text or out.Desc or out.Description or out.Body
    end
    out.__bpuiCanon = true
    return out
end

-- Turns every calling convention we have seen into one config table:
--   ({...})                 the normal form
--   ("Flag", {...})         Fluent / Linoria: id first, config second
--   ("Name", fn)            Orion-ish shorthand for buttons
--   ("Name", "Info", fn)    Kavo-style
--   ("Name")                just a name
local function argsToConfig(kind, a, b, c, d, e)
    local config
    if type(a) == "table" then
        config = a
        if type(b) == "function" and config.Callback == nil and config.callback == nil then
            config = canon(config, kind)
            config.Callback = b
        end
    elseif type(a) == "string" or type(a) == "number" then
        if type(b) == "table" then
            config = {}
            for k, v in pairs(b) do config[k] = v end
            local named = config.Name or config.name or config.Title or config.title
                or (kind ~= "Label" and kind ~= "Paragraph" and (config.Text or config.text))
            if named then
                if config.Flag == nil and config.flag == nil then config.Flag = tostring(a) end
            else
                config.Name = tostring(a)
            end
        elseif kind == "Label" then
            config = { Text = tostring(a) }
        elseif kind == "Paragraph" then
            config = { Title = tostring(a), Content = type(b) == "string" and b or nil }
        else
            config = { Name = tostring(a) }
            local rest = { b, c, d, e }
            local first = 1
            if type(b) == "string" and (kind ~= "Keybind" or (c ~= nil and type(c) ~= "function")) then
                config.Description = b
                first = 2
            end
            -- Kavo: NewSlider(name, info, max, min, cb), NewDropdown(name,
            -- info, options, cb), NewKeybind(name, info, key, cb), ...
            local numbers = 0
            for i = first, 4 do
                local v = rest[i]
                if type(v) == "function" then
                    config.Callback = config.Callback or v
                elseif kind == "Dropdown" and type(v) == "table" and config.Options == nil then
                    config.Options = v
                elseif kind == "Slider" and type(v) == "number" then
                    numbers = numbers + 1
                    if numbers == 1 then config.Max = v elseif numbers == 2 then config.Min = v end
                elseif v ~= nil and config.Default == nil then
                    config.Default = v
                end
            end
        end
    else
        config = {}
    end
    return canon(config, kind)
end

---------------------------------------------------------------- visible notes
local function sectionNote(section, message)
    if BPUI.ShowErrors == false or not section or section._stub then return end
    pcall(function()
        local p = Section.AddParagraph(section, {
            Title = "BPUI: " .. message.title,
            Content = message.body .. " See GUIDE.md on the BPUI GitHub page.",
        })
        if p and p._nameLabel then
            p._nameLabel.TextColor3 = ACTIVE.Danger
            bind(p, p._nameLabel, "TextColor3", "Danger")
        end
    end)
end

local function stubElement()
    return setmetatable({ _stub = true, Type = "Stub" }, {
        __index = function(_, key)
            if type(key) ~= "string" or key:sub(1, 1) == "_" or key == "Value" then return nil end
            return function() return nil end
        end,
    })
end

---------------------------------------------------------------- element aliases
local KINDS = {
    Button = "AddButton", Toggle = "AddToggle", Slider = "AddSlider",
    Dropdown = "AddDropdown", Input = "AddInput", Keybind = "AddKeybind",
    ColorPicker = "AddColorPicker", Label = "AddLabel", Paragraph = "AddParagraph",
    Divider = "AddDivider",
}
-- other names for the same element, as seen in the wild
local KIND_ALIASES = {
    Button = { "Button" },
    Toggle = { "Toggle", "Checkbox", "CheckBox", "Switch" },
    Slider = { "Slider" },
    Dropdown = { "Dropdown", "DropDown", "Dropdownlist", "Combo" },
    Input = { "Input", "Textbox", "TextBox", "TextInput", "Box" },
    Keybind = { "Keybind", "KeyBind", "Bind", "Keypicker", "KeyPicker" },
    ColorPicker = { "ColorPicker", "Colorpicker", "ColourPicker", "Colorwheel", "Color" },
    Label = { "Label" },
    Paragraph = { "Paragraph", "Text", "Info", "Note" },
    Divider = { "Divider", "Separator", "Seperator", "Line", "Space", "Spacer" },
}
local PREFIXES = { "", "Add", "Create", "Make", "New" }

local function makeSectionMethod(kind, method)
    local original = Section[method]
    return function(self, a, b, c, d, e)
        if getmetatable(self) ~= Section then
            warn("[BPUI] Call " .. method .. " with a colon: section:" .. method .. "({...}), not section." .. method .. "({...})")
            return stubElement()
        end
        if kind == "Divider" then return original(self, type(a) == "number" and a or nil) end
        local config = argsToConfig(kind, a, b, c, d, e)
        -- Rayfield's CreateText({name, text}) / Label with a title and body
        if kind == "Label" and config.Content and (config.Name or config.Title) then
            return Section.AddParagraph(self, canon({ Title = config.Name or config.Title, Content = config.Content }, "Paragraph"))
        end
        local el = original(self, config)
        if el and not el._stub and config.Locked == true and el.SetLocked then pcall(el.SetLocked, el, true) end
        if el and el._stub then
            sectionNote(self, { title = kind .. " \"" .. tostring(config.Name or config.Text or config.Title or "") .. "\" failed",
                body = "It raised an error while being created; the [BPUI] line in the console (F9) says why." })
        end
        return el
    end
end

for kind, method in pairs(KINDS) do
    Section[method] = makeSectionMethod(kind, method)
end
for kind, method in pairs(KINDS) do
    for _, word in ipairs(KIND_ALIASES[kind]) do
        for _, pre in ipairs(PREFIXES) do
            Section[pre .. word] = Section[method]
        end
    end
end

-- Elements called straight on a tab land in the tab's most recent section --
-- Rayfield scripts do `Tab:CreateSection("Aim")` then `Tab:CreateToggle{}` and
-- expect the toggle under "Aim" -- or in an untitled section if there's none.
local function tabTarget(tab)
    local last = tab._lastSection
    if last and not last._destroyed and getmetatable(last) == Section then return last end
    if not tab._defaultSection or tab._defaultSection._destroyed then
        tab._defaultSection = tab:CreateSection({ Name = "" })
    end
    tab._lastSection = tab._defaultSection
    return tab._defaultSection
end

for name, fn in pairs(Section) do
    if type(fn) == "function" and name:match("^%u") and not name:match("^Set")
        and name ~= "Destroy" and name ~= "SetTitle" and name ~= "SetVisible" then
        Tab[name] = Tab[name] or function(self, ...)
            if getmetatable(self) ~= Tab then
                warn("[BPUI] Call " .. name .. " with a colon: tab:" .. name .. "({...}), not tab." .. name .. "({...})")
                return stubElement()
            end
            local target = tabTarget(self)
            return target[name](target, ...)
        end
    end
end
for kind, method in pairs(KINDS) do
    -- p7 bound Tab.AddX to the old single-argument path; route it here too
    Tab[method] = function(self, ...)
        if getmetatable(self) ~= Tab then
            warn("[BPUI] Call " .. method .. " with a colon: tab:" .. method .. "({...})")
            return stubElement()
        end
        local target = tabTarget(self)
        return target[method](target, ...)
    end
    Tab["Create" .. kind] = Tab[method]
end

---------------------------------------------------------------- sections
local rawCreateSection = Tab.CreateSection
function Tab:CreateSection(a, b)
    if getmetatable(self) ~= Tab then
        warn("[BPUI] Call CreateSection with a colon: tab:CreateSection(\"Name\")")
        return stubElement()
    end
    local config
    if type(a) == "table" then
        config = canon(a, "Section")
    elseif a ~= nil then
        config = { Name = tostring(a) }
        if type(b) == "table" then for k, v in pairs(canon(b, "Section")) do config[k] = config[k] or v end end
    else
        config = { Name = "" }
    end
    config.Name = config.Name or ""
    local section = rawCreateSection(self, config)
    if section and getmetatable(section) == Section then self._lastSection = section end
    return section
end
for _, name in ipairs({ "AddSection", "Section", "MakeSection", "NewSection", "CreateCategory", "AddCategory" }) do
    Tab[name] = Tab.CreateSection
end
-- A section object handed to CreateSection again (Linoria's groupboxes, or a
-- nested "subsection") just becomes a sibling section on the same tab.
for _, name in ipairs({ "CreateSection", "AddSection", "Section", "AddLeftGroupbox", "AddRightGroupbox",
                         "AddGroupbox", "AddLeftTabbox", "AddRightTabbox" }) do
    Section[name] = Section[name] or function(self, ...)
        return Tab.CreateSection(self._tab, ...)
    end
end
Tab.AddLeftGroupbox = Tab.CreateSection
Tab.AddRightGroupbox = Tab.CreateSection
Tab.AddGroupbox = Tab.CreateSection

---------------------------------------------------------------- tabs
local function tabConfig(a, b)
    local config
    if type(a) == "table" then
        config = canon(a, "Tab")
    else
        config = { Name = a ~= nil and tostring(a) or nil }
        -- Rayfield: CreateTab("Main", 4483362458); Orion/Kavo: (name, icon)
        if b ~= nil and (type(b) == "number" or type(b) == "string") then config.Icon = b end
        if type(b) == "table" then for k, v in pairs(canon(b, "Tab")) do config[k] = config[k] or v end end
    end
    -- Rayfield's default tab image (4483362458) is a generic placeholder that
    -- doesn't load for most people; a missing icon beats an empty square.
    if config.Icon == 4483362458 or config.Icon == "4483362458" then config.Icon = nil end
    return config
end

-- If Settings got built first (the script yielded before its first tab),
-- the script's first real tab is the one that should be open.
local function afterRealTab(window, tab)
    if not tab or window._realTabShown then return end
    window._realTabShown = true
    local active = window._activeTab
    if active and active ~= tab and active._isSettings then
        pcall(function() tab:Select(true) end)
    end
end

local rawCreateTab = Window.CreateTab
function Window:CreateTab(a, b)
    if getmetatable(self) ~= Window then
        warn("[BPUI] Call CreateTab with a colon: Window:CreateTab({ Name = \"Main\" })")
        return stubElement()
    end
    local config = tabConfig(a, b)
    local tab = rawCreateTab(self, config)
    if not config.__settings then afterRealTab(self, tab) end
    return tab
end
for _, name in ipairs({ "Tab", "AddTab", "MakeTab", "NewTab", "Page", "AddPage", "CreatePage" }) do
    Window[name] = Window.CreateTab
end

local rawGroupTab = Group.CreateTab
function Group:CreateTab(a, b)
    local tab = rawGroupTab(self, tabConfig(a, b))
    afterRealTab(self._window, tab)
    return tab
end
Group.AddTab = Group.CreateTab
Group.Tab = Group.CreateTab

local rawCreateGroup = Window.CreateGroup
function Window:CreateGroup(a, b)
    return rawCreateGroup(self, tabConfig(a, b))
end
for _, name in ipairs({ "Group", "AddGroup", "Category", "AddCategory", "CreateCategory", "Folder", "AddFolder" }) do
    Window[name] = Window.CreateGroup
end

---------------------------------------------------------------- windows
local WINDOW_SYNONYMS = {
    Name = "Title", SubTitle = "Subtitle", LoadingSubtitle = "Subtitle", Author = "Subtitle",
    Keybind = "ToggleKey", MinimizeKey = "ToggleKey", ToggleUIKeybind = "ToggleKey",
    Logo = "Icon", Image = "Icon", Folder = "ConfigFolder",
}
local compatCreateWindow = BPUI.CreateWindow
function BPUI:CreateWindow(config, extra)
    -- BPUI.CreateWindow({...}) with a dot: the config arrives as self
    if self ~= BPUI and (type(self) == "table" or type(self) == "string") then
        config, extra, self = self, config, BPUI
    end
    if type(config) == "string" then config = { Title = config, Subtitle = type(extra) == "string" and extra or nil } end
    config = type(config) == "table" and config or {}
    local out = {}
    for k, v in pairs(config) do out[k] = v end
    for k, v in pairs(config) do
        if type(k) == "string" then
            local upper = k:sub(1, 1):upper() .. k:sub(2)
            if upper ~= k and out[upper] == nil then out[upper] = v end
            local syn = WINDOW_SYNONYMS[upper]
            if syn and out[syn] == nil then out[syn] = v end
        end
    end
    -- Rayfield: KeySystem = true + KeySettings = { Title, Subtitle, Note, Key, SaveKey }
    if out.KeySystem ~= nil and type(out.KeySystem) ~= "table" then
        local ks = out.KeySettings
        if out.KeySystem and type(ks) == "table" then
            local keys = ks.Key or ks.Keys
            out.KeySystem = {
                Title = ks.Title,
                Subtitle = ks.Subtitle,
                Note = ks.Note,
                Keys = type(keys) == "table" and keys or (keys ~= nil and { tostring(keys) } or nil),
                SaveKey = ks.SaveKey,
                GetKeyLink = ks.GetKeyLink or ks.Link,
            }
        else
            out.KeySystem = nil
        end
    end
    -- Rayfield's ConfigurationSaving.FolderName
    if type(out.ConfigurationSaving) == "table" and out.ConfigFolder == nil then
        out.ConfigFolder = out.ConfigurationSaving.FolderName
    end
    if typeof(out.ToggleKey) == "EnumItem" or type(out.ToggleKey) == "string" then
        -- fine as is
    else
        out.ToggleKey = nil
    end
    -- Theme names from other libraries that we don't have fall back quietly
    if type(out.Theme) == "string" and not BPUI.Themes[out.Theme] then out.Theme = nil end
    return compatCreateWindow(BPUI, out)
end
for _, name in ipairs({ "MakeWindow", "NewWindow", "CreateLib", "Load", "new", "New" }) do
    BPUI[name] = BPUI.CreateWindow
end

---------------------------------------------------------------- element methods
-- Methods other libraries put on every element, mapped onto ours.
local function alias(name, fn) if Element[name] == nil then Element[name] = fn end end
alias("SetValue", function(self, ...) if self.Set then return self:Set(...) end end)
alias("GetValue", function(self) return self.Value end)
-- a keybind's "changed" is its key being rebound, which is _onChanged;
-- everywhere else it is the value changing, which is the callback
local function onChanged(self, fn)
    if self.Type == "Keybind" then self._onChanged = fn else self._callback = fn end
end
alias("OnChanged", onChanged)
alias("OnChange", onChanged)
alias("SetValues", function(self, list, keep) if self.Refresh then return self:Refresh(list, keep) end end)
alias("SetOptions", function(self, list, keep) if self.Refresh then return self:Refresh(list, keep) end end)
alias("SetText", function(self, str)
    if self.Type == "Paragraph" then return self:SetContent(str) end
    if self.Type == "Label" then return self:Set(str) end
    return self:SetName(str)
end)
alias("SetDesc", function(self, str) return self:SetDescription(str) end)
alias("SetDisabled", function(self, v) return self:SetLocked(v) end)
alias("SetEnabled", function(self, v) return self:SetLocked(not v) end)
alias("Show", function(self) return self:SetVisible(true) end)
alias("Hide", function(self) return self:SetVisible(false) end)
alias("Remove", function(self) return self:Destroy() end)
alias("Fire", function(self) if self.Click then return self:Click() end end)

-- Linoria chains extras off a row: Groupbox:AddLabel("Color"):AddColorPicker(...)
for kind, method in pairs(KINDS) do
    for _, word in ipairs(KIND_ALIASES[kind]) do
        alias("Add" .. word, function(self, ...)
            local section = self._section
            if not section or getmetatable(section) ~= Section then return stubElement() end
            return section[method](section, ...)
        end)
    end
end
alias("AddKeyPicker", Element.AddKeybind)

---------------------------------------------------------------- library-level
BPUI.Options = BPUI.Flags
local rawNotify = BPUI.Notify
function BPUI:Notify(config, b, c)
    if self ~= BPUI and (type(self) == "table" or type(self) == "string") then config, b, self = self, config, BPUI end
    if type(config) == "string" then
        -- Linoria Notify("text", seconds) / plain Notify("Title", "Content")
        config = type(b) == "string" and { Title = config, Content = b, Duration = tonumber(c) }
            or { Title = "Notice", Content = config, Duration = tonumber(b) }
    end
    config = type(config) == "table" and config or {}
    local out = {}
    for k, v in pairs(config) do out[k] = v end
    for k, v in pairs(config) do
        if type(k) == "string" then
            local upper = k:sub(1, 1):upper() .. k:sub(2)
            if out[upper] == nil then out[upper] = v end
        end
    end
    out.Title = out.Title or out.Name or out.Header
    out.Content = out.Content or out.Text or out.Description or out.Desc or out.SubContent
    out.Duration = out.Duration or out.Time or out.Delay or out.Length
    return rawNotify(BPUI, out)
end
BPUI.MakeNotification = BPUI.Notify
BPUI.Notification = BPUI.Notify
BPUI.Notif = BPUI.Notify
-- no-ops other libraries require to be called
BPUI.Init = BPUI.Init or function() end
BPUI.LoadConfiguration = BPUI.LoadConfiguration or function() end

local rawSelectTab = Window.SelectTab
function Window:SelectTab(ref)
    if type(ref) == "number" then
        -- count the script's own tabs; Settings may have been built first
        local n = 0
        local pick
        for _, t in ipairs(self._tabs) do
            if not t._isSettings then
                n = n + 1
                if n == ref then pick = t break end
            end
        end
        ref = pick
    end
    return rawSelectTab(self, ref)
end
Window.MakeNotification = function(self, ...) return BPUI.Notify(BPUI, ...) end

---------------------------------------------------------------- unknown methods
-- Anything that looks like "make me an element" but isn't one of ours.
local function looksLikeCreate(key)
    return type(key) == "string" and (key:match("^Add%u") or key:match("^Create%u")
        or key:match("^Make%u") or key:match("^New%u"))
end

local function unknownOn(kindName, host)
    return function(t, key)
        local v = rawget(host, key)
        if v ~= nil then return v end
        if not looksLikeCreate(key) then return nil end
        return function(self)
            local what = kindName .. ":" .. key .. "()"
            if not BPUI._unknownWarned then BPUI._unknownWarned = {} end
            if not BPUI._unknownWarned[what] then
                BPUI._unknownWarned[what] = true
                warn("[BPUI] " .. what .. " doesn't exist in BPUI -- skipped. Elements are: "
                    .. "Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker, Label, Paragraph, Divider.")
            end
            local section = (kindName == "Section" and self)
                or (kindName == "Tab" and getmetatable(self) == Tab and tabTarget(self))
            if section and getmetatable(section) == Section then
                sectionNote(section, { title = key .. " is not a BPUI element",
                    body = "This line of the script was skipped." })
            end
            return stubElement()
        end
    end
end
Section.__index = unknownOn("Section", Section)
Tab.__index = unknownOn("Tab", Tab)

BPUI.Group = Group
BPUI._canon = canon

return BPUI
