--[[
═══════════════════════════════════════════════════════════════
    LUXEUI - Ultra-Premium Roblox UI Library v2.0
    Glassmorphism | Luxury Animations | Professional Grade
═══════════════════════════════════════════════════════════════
]]

local LuxeUI = { Version = "2.0.0", SafeMode = true, Flags = {}, IsMobile = false }
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local function pcall_wrap(fn, ...)
    if LuxeUI.SafeMode then
        return pcall(fn, ...)
    else
        return true, fn(...)
    end
end

local function GetGui()
    local success, gui = pcall_wrap(function()
        return (pcall(function() return gethui() end) and gethui()) or game:GetService("CoreGui")
    end)
    return gui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local THEMES = {
    Obsidian = {
        Primary = Color3.fromRGB(20, 20, 28),
        Secondary = Color3.fromRGB(30, 30, 42),
        Tertiary = Color3.fromRGB(40, 40, 55),
        Accent = Color3.fromRGB(100, 200, 255),
        Text = Color3.fromRGB(240, 240, 245),
        SubText = Color3.fromRGB(160, 160, 175),
        Transparent = Color3.fromRGB(60, 60, 80),
        Success = Color3.fromRGB(80, 220, 130),
        Warning = Color3.fromRGB(255, 180, 60),
        Error = Color3.fromRGB(255, 100, 100),
    },
    Platinum = {
        Primary = Color3.fromRGB(245, 245, 250),
        Secondary = Color3.fromRGB(235, 235, 242),
        Tertiary = Color3.fromRGB(220, 220, 235),
        Accent = Color3.fromRGB(50, 130, 255),
        Text = Color3.fromRGB(20, 20, 30),
        SubText = Color3.fromRGB(100, 100, 120),
        Transparent = Color3.fromRGB(200, 200, 220),
        Success = Color3.fromRGB(60, 200, 110),
        Warning = Color3.fromRGB(255, 150, 40),
        Error = Color3.fromRGB(240, 80, 80),
    },
    Midnight = {
        Primary = Color3.fromRGB(10, 15, 35),
        Secondary = Color3.fromRGB(25, 35, 70),
        Tertiary = Color3.fromRGB(40, 55, 100),
        Accent = Color3.fromRGB(120, 180, 255),
        Text = Color3.fromRGB(230, 240, 255),
        SubText = Color3.fromRGB(150, 170, 200),
        Transparent = Color3.fromRGB(50, 80, 150),
        Success = Color3.fromRGB(100, 240, 160),
        Warning = Color3.fromRGB(255, 200, 80),
        Error = Color3.fromRGB(255, 120, 120),
    },
    Amethyst = {
        Primary = Color3.fromRGB(28, 20, 40),
        Secondary = Color3.fromRGB(42, 30, 60),
        Tertiary = Color3.fromRGB(55, 40, 80),
        Accent = Color3.fromRGB(200, 120, 255),
        Text = Color3.fromRGB(245, 240, 255),
        SubText = Color3.fromRGB(175, 160, 190),
        Transparent = Color3.fromRGB(80, 60, 120),
        Success = Color3.fromRGB(130, 220, 80),
        Warning = Color3.fromRGB(255, 180, 60),
        Error = Color3.fromRGB(255, 100, 140),
    },
}

local TWEEN_SPEEDS = {
    Instant = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Elegant = TweenInfo.new(0.7, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
}

local function CreateFrame(props)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = props.Color or Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = props.Transparency or 0
    frame.BorderSizePixel = 0
    frame.Size = props.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.Name = props.Name or "Frame"
    frame.ZIndex = props.ZIndex or 1
    if props.Parent then frame.Parent = props.Parent end
    return frame
end

local function CreateUICorner(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = frame
    return corner
end

local function CreateGradient(frame, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    gradient.Rotation = rotation or 45
    gradient.Parent = frame
    return gradient
end

local function TweenTo(object, props, speed)
    local tween = TweenService:Create(object, speed or TWEEN_SPEEDS.Normal, props)
    tween:Play()
    return tween
end

local function CreateShadow(frame, size, blur, color, transparency)
    local shadow = CreateFrame{
        Name = "Shadow",
        Color = color or Color3.fromRGB(0, 0, 0),
        Transparency = transparency or 0.7,
        Size = frame.Size + UDim2.new(0, size * 2, 0, size * 2),
        Position = frame.Position - UDim2.new(0, size, 0, size),
        ZIndex = frame.ZIndex - 1,
        Parent = frame.Parent
    }
    CreateUICorner(shadow, 12)
    return shadow
end

local function CreateWindow(config)
    config = config or {}

    local windowTitle = config.Title or "LuxeUI"
    local theme = THEMES[config.Theme or "Obsidian"]
    local windowSize = config.Size or UDim2.new(0, 800, 0, 600)
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    if isMobile then
        windowSize = UDim2.new(0, 360, 0, 640)
    end

    LuxeUI.IsMobile = isMobile
    local guiParent = GetGui()

    -- Main container with blur backdrop
    local backdrop = CreateFrame{
        Name = "Backdrop",
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.3,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = guiParent,
        ZIndex = 10
    }

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = workspace.Camera

    TweenTo(blur, {Size = 15}, TWEEN_SPEEDS.Smooth)

    -- Main window
    local window = CreateFrame{
        Name = "LuxeWindow_" .. windowTitle,
        Color = theme.Primary,
        Transparency = 0.05,
        Size = windowSize,
        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
        Parent = guiParent,
        ZIndex = 11
    }

    CreateUICorner(window, 20)
    CreateGradient(window, theme.Primary, theme.Secondary, 135)

    -- Luxury shadow
    CreateShadow(window, 30, 60, Color3.fromRGB(0, 0, 0), 0.8)

    -- Premium stroke (border glow)
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = window

    -- Top bar with glass effect
    local topBar = CreateFrame{
        Name = "TopBar",
        Color = theme.Secondary,
        Transparency = 0.15,
        Size = UDim2.new(1, 0, 0, 60),
        Parent = window,
        ZIndex = 12
    }

    CreateUICorner(topBar, 20)
    CreateGradient(topBar, theme.Secondary, theme.Tertiary, 90)

    local topStroke = Instance.new("UIStroke")
    topStroke.Color = theme.Accent
    topStroke.Thickness = 1
    topStroke.Transparency = 0.7
    topStroke.Parent = topBar

    -- Title text with premium styling
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = windowTitle
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = topBar
    titleLabel.ZIndex = 13

    -- Subtitle
    if config.Subtitle then
        local subtitleLabel = Instance.new("TextLabel")
        subtitleLabel.Name = "Subtitle"
        subtitleLabel.Text = config.Subtitle
        subtitleLabel.TextColor3 = theme.SubText
        subtitleLabel.TextSize = 14
        subtitleLabel.Font = Enum.Font.GothamMedium
        subtitleLabel.BackgroundTransparency = 1
        subtitleLabel.Size = UDim2.new(1, -80, 0, 20)
        subtitleLabel.Position = UDim2.new(0, 20, 0, 30)
        subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
        subtitleLabel.Parent = topBar
        subtitleLabel.ZIndex = 13
    end

    -- Close button (premium design)
    local closeButton = CreateFrame{
        Name = "CloseButton",
        Color = theme.Error,
        Transparency = 0.8,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -50, 0, 10),
        Parent = topBar,
        ZIndex = 13
    }

    CreateUICorner(closeButton, 10)

    local closeText = Instance.new("TextLabel")
    closeText.Text = "✕"
    closeText.TextColor3 = theme.Text
    closeText.TextSize = 20
    closeText.Font = Enum.Font.GothamBold
    closeText.BackgroundTransparency = 1
    closeText.Size = UDim2.new(1, 0, 1, 0)
    closeText.Parent = closeButton
    closeText.ZIndex = 14

    -- Content area with scroll
    local contentFrame = CreateFrame{
        Name = "ContentFrame",
        Color = theme.Primary,
        Transparency = 0.1,
        Size = UDim2.new(1, 0, 1, -70),
        Position = UDim2.new(0, 0, 0, 60),
        Parent = window,
        ZIndex = 11
    }

    CreateUICorner(contentFrame, 15)

    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "Scroll"
    scrollingFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollingFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 6
    scrollingFrame.ScrollBarImageColor3 = theme.Accent
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.Parent = contentFrame
    scrollingFrame.ZIndex = 12

    -- Premium scrollbar
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = scrollingFrame

    -- Layout
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollingFrame

    local layoutPadding = Instance.new("UIPadding")
    layoutPadding.PaddingTop = UDim.new(0, 10)
    layoutPadding.PaddingBottom = UDim.new(0, 10)
    layoutPadding.Parent = scrollingFrame

    -- Window object
    local Window = {
        _object = window,
        _backdrop = backdrop,
        _blur = blur,
        _scrollingFrame = scrollingFrame,
        _contentFrame = contentFrame,
        _theme = theme,
        _title = windowTitle,
        _destroyed = false,
        Visible = true,
        Tabs = {},
    }

    function Window:CreateTab(tabName)
        local tabFrame = CreateFrame{
            Name = tabName,
            Color = theme.Secondary,
            Transparency = 0.2,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = scrollingFrame,
            ZIndex = 12
        }

        CreateUICorner(tabFrame, 15)

        local tabLabel = Instance.new("TextLabel")
        tabLabel.Text = tabName
        tabLabel.TextColor3 = theme.Accent
        tabLabel.TextSize = 18
        tabLabel.Font = Enum.Font.GothamBold
        tabLabel.BackgroundTransparency = 1
        tabLabel.Size = UDim2.new(1, -20, 0, 30)
        tabLabel.Position = UDim2.new(0, 10, 0, 10)
        tabLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabLabel.Parent = tabFrame
        tabLabel.ZIndex = 13

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingTop = UDim.new(0, 40)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = tabFrame

        local Tab = { _frame = tabFrame, _parent = Window }

        function Tab:AddButton(name, callback)
            local button = CreateFrame{
                Name = name,
                Color = theme.Accent,
                Transparency = 0.2,
                Size = UDim2.new(1, 0, 0, 45),
                Parent = tabFrame,
                ZIndex = 13
            }

            CreateUICorner(button, 12)
            CreateGradient(button, theme.Accent, Color3.new(theme.Accent.R * 0.8, theme.Accent.G * 0.8, theme.Accent.B * 0.8), 45)

            local buttonStroke = Instance.new("UIStroke")
            buttonStroke.Color = theme.Accent
            buttonStroke.Thickness = 1
            buttonStroke.Transparency = 0.5
            buttonStroke.Parent = button

            local buttonText = Instance.new("TextLabel")
            buttonText.Text = name
            buttonText.TextColor3 = theme.Text
            buttonText.TextSize = 15
            buttonText.Font = Enum.Font.GothamSemibold
            buttonText.BackgroundTransparency = 1
            buttonText.Size = UDim2.new(1, 0, 1, 0)
            buttonText.Parent = button
            buttonText.ZIndex = 14

            button.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenTo(button, {BackgroundTransparency = 0.1}, TWEEN_SPEEDS.Fast)
                    if callback then callback() end
                end
            end)

            button.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenTo(button, {BackgroundTransparency = 0.2}, TWEEN_SPEEDS.Normal)
                end
            end)

            return button
        end

        function Tab:AddToggle(config)
            local toggleContainer = CreateFrame{
                Name = config.Name,
                Color = theme.Secondary,
                Transparency = 0.15,
                Size = UDim2.new(1, 0, 0, 50),
                Parent = tabFrame,
                ZIndex = 13
            }

            CreateUICorner(toggleContainer, 12)

            local label = Instance.new("TextLabel")
            label.Text = config.Name
            label.TextColor3 = theme.Text
            label.TextSize = 16
            label.Font = Enum.Font.GothamSemibold
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7, 0, 1, 0)
            label.Position = UDim2.new(0, 15, 0, 0)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.Parent = toggleContainer
            label.ZIndex = 14

            local toggleSwitch = CreateFrame{
                Name = "Toggle",
                Color = theme.Error,
                Transparency = 0.3,
                Size = UDim2.new(0, 50, 0, 28),
                Position = UDim2.new(1, -65, 0.5, -14),
                Parent = toggleContainer,
                ZIndex = 14
            }

            CreateUICorner(toggleSwitch, 14)

            local toggleKnob = CreateFrame{
                Name = "Knob",
                Color = theme.Text,
                Transparency = 0,
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 2, 0.5, -12),
                Parent = toggleSwitch,
                ZIndex = 15
            }

            CreateUICorner(toggleKnob, 12)

            local state = config.Default or false

            if state then
                TweenTo(toggleSwitch, {BackgroundColor3 = theme.Success}, TWEEN_SPEEDS.Instant)
                TweenTo(toggleKnob, {Position = UDim2.new(0, 24, 0.5, -12)}, TWEEN_SPEEDS.Instant)
            end

            toggleSwitch.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    state = not state

                    if state then
                        TweenTo(toggleSwitch, {BackgroundColor3 = theme.Success}, TWEEN_SPEEDS.Normal)
                        TweenTo(toggleKnob, {Position = UDim2.new(0, 24, 0.5, -12)}, TWEEN_SPEEDS.Normal)
                    else
                        TweenTo(toggleSwitch, {BackgroundColor3 = theme.Error}, TWEEN_SPEEDS.Normal)
                        TweenTo(toggleKnob, {Position = UDim2.new(0, 2, 0.5, -12)}, TWEEN_SPEEDS.Normal)
                    end

                    if config.Callback then
                        config.Callback(state)
                    end
                end
            end)

            return toggleContainer
        end

        function Tab:AddSlider(config)
            local sliderContainer = CreateFrame{
                Name = config.Name,
                Color = theme.Secondary,
                Transparency = 0.15,
                Size = UDim2.new(1, 0, 0, 70),
                Parent = tabFrame,
                ZIndex = 13
            }

            CreateUICorner(sliderContainer, 12)

            local label = Instance.new("TextLabel")
            label.Text = config.Name
            label.TextColor3 = theme.Text
            label.TextSize = 16
            label.Font = Enum.Font.GothamSemibold
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -20, 0, 25)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderContainer
            label.ZIndex = 14

            local sliderTrack = CreateFrame{
                Name = "Track",
                Color = theme.Tertiary,
                Transparency = 0.3,
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 35),
                Parent = sliderContainer,
                ZIndex = 14
            }

            CreateUICorner(sliderTrack, 3)

            local sliderFill = CreateFrame{
                Name = "Fill",
                Color = theme.Accent,
                Transparency = 0,
                Size = UDim2.new(0.5, 0, 1, 0),
                Parent = sliderTrack,
                ZIndex = 15
            }

            CreateUICorner(sliderFill, 3)
            CreateGradient(sliderFill, theme.Accent, Color3.new(theme.Accent.R * 1.2, theme.Accent.G * 1.2, theme.Accent.B * 1.2), 45)

            local sliderKnob = CreateFrame{
                Name = "Knob",
                Color = theme.Accent,
                Transparency = 0,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0.5, -9, 0.5, -6),
                Parent = sliderTrack,
                ZIndex = 16
            }

            CreateUICorner(sliderKnob, 9)
            CreateShadow(sliderKnob, 8, 20, theme.Accent, 0.6)

            local value = config.Default or config.Min or 0

            local function updateSlider(newVal)
                value = math.max(config.Min, math.min(config.Max, newVal))
                local percent = (value - config.Min) / (config.Max - config.Min)
                TweenTo(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, TWEEN_SPEEDS.Fast)
                TweenTo(sliderKnob, {Position = UDim2.new(percent, -9, 0.5, -6)}, TWEEN_SPEEDS.Fast)

                if config.Callback then
                    config.Callback(math.floor(value))
                end
            end

            local dragging = false

            sliderKnob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    TweenTo(sliderKnob, {Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new((value - config.Min) / (config.Max - config.Min), -11, 0.5, -11)}, TWEEN_SPEEDS.Fast)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                    dragging = false
                    TweenTo(sliderKnob, {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new((value - config.Min) / (config.Max - config.Min), -9, 0.5, -6)}, TWEEN_SPEEDS.Normal)
                end
            end)

            sliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
                    local trackSize = sliderTrack.AbsoluteSize.X
                    local trackPos = sliderTrack.AbsolutePosition.X
                    local mousePos = mouse.X

                    local percent = (mousePos - trackPos) / trackSize
                    local newVal = config.Min + (percent * (config.Max - config.Min))
                    updateSlider(newVal)
                end
            end)

            updateSlider(value)
            return sliderContainer
        end

        return Tab
    end

    function Window:Show()
        if not self._destroyed then
            TweenTo(window, {Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2)}, TWEEN_SPEEDS.Smooth)
            backdrop.Visible = true
        end
    end

    function Window:Hide()
        if not self._destroyed then
            backdrop.Visible = false
        end
    end

    function Window:Destroy()
        self._destroyed = true
        TweenTo(window, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, TWEEN_SPEEDS.Elegant):Completed:Connect(function()
            window:Destroy()
            backdrop:Destroy()
            blur:Destroy()
        end)
    end

    closeButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Window:Destroy()
        end
    end)

    return Window
end

function LuxeUI:CreateWindow(config)
    return CreateWindow(config)
end

function LuxeUI:Notify(config)
    config = config or {}

    local theme = THEMES.Obsidian
    local position = config.Position or UDim2.new(1, -20, 0, 20)

    local notifFrame = CreateFrame{
        Name = "Notification",
        Color = theme.Secondary,
        Transparency = 0.1,
        Size = UDim2.new(0, 300, 0, 80),
        Position = position,
        Parent = GetGui(),
        ZIndex = 20
    }

    CreateUICorner(notifFrame, 15)
    CreateGradient(notifFrame, theme.Secondary, theme.Tertiary, 135)

    local stroke = Instance.new("UIStroke")
    stroke.Color = config.Type == "Success" and theme.Success or config.Type == "Error" and theme.Error or theme.Accent
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = notifFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = config.Title or "Notification"
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notifFrame
    titleLabel.ZIndex = 21

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Text = config.Content or ""
    contentLabel.TextColor3 = theme.SubText
    contentLabel.TextSize = 13
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.BackgroundTransparency = 1
    contentLabel.Size = UDim2.new(1, -20, 0, 30)
    contentLabel.Position = UDim2.new(0, 15, 0, 40)
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextWrapped = true
    contentLabel.Parent = notifFrame
    contentLabel.ZIndex = 21

    task.wait(config.Duration or 3)

    TweenTo(notifFrame, {Position = position + UDim2.new(0, 350, 0, 0)}, TWEEN_SPEEDS.Elegant):Completed:Connect(function()
        notifFrame:Destroy()
    end)
end

return LuxeUI
