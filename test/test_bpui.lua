-- Runs BPUI.lua under the Roblox mock and exercises every component.
package.path = "./test/?.lua;" .. package.path
local Mock = require("roblox_mock")
local UIS = Mock.UserInputService

local MODE = (arg and arg[1]) or "fs"
local WITH_FS = MODE ~= "nofs"
local MOBILE = MODE == "mobile"
if MOBILE then
    UIS.TouchEnabled = true
    UIS.MouseEnabled = false
    UIS.KeyboardEnabled = false
end
local files
if WITH_FS then
    files = Mock.installFileSystem()
end

local passed, failed = 0, 0
local function check(cond, label)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        print("  FAIL: " .. label)
    end
end

local function click(button)
    button.Activated:Fire()
end

local log = {}
local function logger(name)
    return function(...)
        log[name] = { ... }
        log["#" .. name] = (log["#" .. name] or 0) + 1
    end
end

local chunk = assert(loadfile("BPUI.lua"))

local body = function()
    local BPUI = chunk()
    check(type(BPUI) == "table" and BPUI.CreateWindow, "library loads and returns table")

    -- Notify before any window exists
    local toast = BPUI:Notify({ Title = "Hello", Content = "World", Duration = 1 })
    check(toast and toast.Instance, "notify works before window")

    local Window = BPUI:CreateWindow({
        Title = "BP Hub",
        Subtitle = "Premium",
        Theme = "Dark",
        ToggleKey = Enum.KeyCode.RightShift,
        FloatingButton = true,
        ConfigFolder = "BPHubTest",
        KeySystem = WITH_FS and {
            Title = "BP Hub | Key",
            Note = "Testing",
            Keys = { "BPHUB-TEST" },
            SaveKey = true,
            GetKeyLink = "https://example.com/key",
        } or nil,
    })
    check(Window and Window.Main, "window created")
    check(Window.Main.Visible == true, "window visible after key system")
    check(#Window.Tabs == 1 and Window.Tabs[1].Name == "Settings", "settings tab built")

    local Main = Window:CreateTab({ Name = "Main" })
    check(Window.CurrentTab == Main, "first user tab auto selected over settings")
    local Section = Main:CreateSection("Player")

    -- Button
    local button = Section:AddButton({ Name = "Run", Description = "desc", Callback = logger("button") })
    click(button.Row.Hit)
    check(log["#button"] == 1, "button callback fired")

    -- Toggle
    local toggle = Section:AddToggle({ Name = "Fly", Default = true, Flag = "fly", Callback = logger("toggle") })
    check(toggle.Value == true and log["#toggle"] == 1 and log.toggle[1] == true, "toggle default true fires callback")
    click(toggle.Row.Hit)
    check(toggle.Value == false and log.toggle[1] == false, "toggle click flips value")
    toggle:Set(true, true)
    check(toggle.Value == true and log["#toggle"] == 2, "toggle silent set does not fire")

    -- Slider
    local slider = Section:AddSlider({ Name = "Speed", Min = 16, Max = 200, Default = 50, Increment = 2, Suffix = " st", Flag = "speed", Callback = logger("slider") })
    check(slider.Value == 50, "slider default")
    slider:Set(33)
    check(slider.Value == 34 or slider.Value == 32, "slider snaps to increment (" .. tostring(slider.Value) .. ")")
    slider:Set(9999)
    check(slider.Value == 200, "slider clamps max")
    -- simulate drag: track at x=100..250
    local track = slider.Row.Track
    track.AbsolutePosition = Vector2.new(100, 0)
    track.AbsoluteSize = Vector2.new(150, 4)
    local hitbox = slider.Row.Hitbox
    hitbox.InputBegan:Fire(Mock.input("MouseButton1", nil, Vector2.new(175, 0)))
    check(slider.Value == 108, "slider drag start sets value (" .. tostring(slider.Value) .. ")")
    UIS.InputChanged:Fire(Mock.input("MouseMovement", nil, Vector2.new(250, 0)))
    check(slider.Value == 200, "slider drag move updates")
    UIS.InputEnded:Fire(Mock.input("MouseButton1"))
    UIS.InputChanged:Fire(Mock.input("MouseMovement", nil, Vector2.new(100, 0)))
    check(slider.Value == 200, "slider stops after release")
    local fmt = slider.Row.Value.Text
    check(fmt == "200 st", "slider label format: " .. tostring(fmt))

    -- Dropdown single
    local dropdown = Section:AddDropdown({ Name = "Mode", Options = { "A", "B", "C" }, Default = "B", Flag = "mode", Callback = logger("dropdown") })
    check(dropdown.Value == "B", "dropdown default")
    click(dropdown.Row.Hit)
    local optionC = Mock.find(dropdown.Row.List, function(c) return c.ClassName == "TextButton" and c.Name == "C" end)
    check(optionC ~= nil, "dropdown options built")
    click(optionC)
    check(dropdown.Value == "C" and log.dropdown[1] == "C", "dropdown select fires")
    dropdown:Refresh({ "X", "Y" })
    check(dropdown.Value == nil, "dropdown refresh clears value")
    dropdown:Set("Y", true)
    check(dropdown.Row.Value.Text == "Y", "dropdown label updates")

    -- Dropdown multi
    local multi = Section:AddDropdown({ Name = "Multi", Options = { "One", "Two", "Three" }, Multi = true, Default = { "Three", "One" }, Flag = "multi", Callback = logger("multi") })
    check(#multi.Value == 2 and multi.Value[1] == "One" and multi.Value[2] == "Three", "multi default keeps option order")
    local optionTwo = Mock.find(multi.Row.List, function(c) return c.ClassName == "TextButton" and c.Name == "Two" end)
    click(optionTwo)
    check(#multi.Value == 3, "multi select adds")
    click(optionTwo)
    check(#multi.Value == 2, "multi select removes")

    -- Input
    local input = Section:AddInput({ Name = "Name", Default = "abc", Flag = "name", Callback = logger("input") })
    input.TextBox.Text = "hello"
    input.TextBox.FocusLost:Fire(true)
    check(input.Value == "hello" and log.input[1] == "hello" and log.input[2] == true, "input focus lost fires with enter")
    local numeric = Section:AddInput({ Name = "Num", Numeric = true })
    numeric.TextBox.Text = "12a.5b"
    check(numeric.TextBox.Text == "12.5" and numeric.Value == "12.5", "numeric filter")

    -- Keybind
    local keybind = Section:AddKeybind({ Name = "Bind", Default = Enum.KeyCode.E, Mode = "Toggle", Flag = "bind", Callback = logger("keybind"), OnChanged = logger("keybindChanged") })
    check(keybind.Value == "E", "keybind default")
    UIS.InputBegan:Fire(Mock.input("Keyboard", "E"))
    check(log.keybind[1] == true, "keybind toggle press -> true")
    UIS.InputBegan:Fire(Mock.input("Keyboard", "E"))
    check(log.keybind[1] == false, "keybind toggle press -> false")
    click(keybind.Row.Pill)
    check(keybind.Row.Pill.Text == "..." and BPUI._keybindListening == true, "keybind listening")
    UIS.InputBegan:Fire(Mock.input("Keyboard", "RightShift"))
    check(keybind.Value == "RightShift" and log.keybindChanged[1] == "RightShift", "keybind captured new key")
    check(Window.Visible == true, "toggle key ignored while keybind listening")
    Mock.advance(0.2)
    check(BPUI._keybindListening == false, "listening flag cleared")

    -- Hold keybind
    local hold = Section:AddKeybind({ Name = "Hold", Default = "F", Mode = "Hold", Callback = logger("hold") })
    UIS.InputBegan:Fire(Mock.input("Keyboard", "F"))
    check(log.hold[1] == true, "hold begin")
    UIS.InputEnded:Fire(Mock.input("Keyboard", "F"))
    check(log.hold[1] == false, "hold end")

    -- ColorPicker
    local picker = Section:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(255, 0, 0), Flag = "color", Callback = logger("color") })
    check(picker.Value == Color3.fromRGB(255, 0, 0), "picker default")
    picker:Set("#00FF00")
    check(picker.Value == Color3.fromRGB(0, 255, 0) and log.color[1] == picker.Value, "picker hex set fires")
    click(picker.Row.Hit)
    local hexBox = Mock.find(picker.Row.Panel, function(c) return c.ClassName == "TextBox" end)
    hexBox.Text = "0000ff"
    hexBox.FocusLost:Fire(false)
    check(picker.Value == Color3.fromRGB(0, 0, 255), "hex input parsed")
    hexBox.Text = "zzz"
    hexBox.FocusLost:Fire(false)
    check(hexBox.Text == "#0000FF", "invalid hex restored")
    local sv = picker.Row.Panel.SV
    sv.AbsolutePosition = Vector2.new(0, 0)
    sv.AbsoluteSize = Vector2.new(130, 120)
    sv.InputBegan:Fire(Mock.input("Touch", nil, Vector2.new(130, 120)))
    check(picker.Value == Color3.fromRGB(0, 0, 0), "sv drag bottom-right = black")
    UIS.InputEnded:Fire(Mock.input("Touch"))

    -- Label / Paragraph / Divider
    local label = Section:AddLabel("Info")
    label:Set("Changed")
    check(label.Row.Title.Text == "Changed", "label set")
    local para = Section:AddParagraph({ Title = "About", Content = "Long text" })
    para:Set("New content", "New title")
    check(para.Row.Content.Text == "New content" and para.Row.Title.Text == "New title", "paragraph set")
    Section:AddDivider()

    -- Elements directly on a tab (default section)
    local Misc = Window:CreateTab("Misc")
    local tabToggle = Misc:AddToggle({ Name = "Direct", Flag = "direct" })
    check(tabToggle.Section == Misc._defaultSection, "tab-level element uses default section")

    -- Visibility & separators
    button:SetVisible(false)
    check(button.Row.Visible == false, "element hide")
    button:SetVisible(true)

    -- Window toggle key
    UIS.InputBegan:Fire(Mock.input("Keyboard", "RightShift"))
    check(Window.Visible == false, "toggle key hides")
    Mock.advance(0.5)
    check(Window.Main.Visible == false, "window hidden after animation")
    UIS.InputBegan:Fire(Mock.input("Keyboard", "RightShift"))
    check(Window.Visible == true and Window.Main.Visible == true, "toggle key shows")

    -- Floating button tap (press + release without movement)
    local floatInput = Mock.input("Touch", nil, Vector2.new(10, 10))
    Window.FloatingButton.InputBegan:Fire(floatInput)
    floatInput.UserInputState = Mock.getEnumItem("UserInputState", "End")
    floatInput.Changed:Fire()
    check(Window.Visible == false, "floating button tap toggles window")
    Window:Show()

    -- Drag main window
    local dragInput = Mock.input("MouseButton1", nil, Vector2.new(100, 100))
    Window.Main.AbsolutePosition = Vector2.new(320, 140)
    Window.Main.AbsoluteSize = Vector2.new(640, 440)
    local TopBar = Window.Main.Content.TopBar
    TopBar.InputBegan:Fire(dragInput)
    local moveInput = Mock.input("MouseMovement", nil, Vector2.new(150, 130))
    TopBar.InputChanged:Fire(moveInput)
    UIS.InputChanged:Fire(moveInput)
    local pos = Window.Main.Position
    check(pos.X.Offset == 320 + 50 + 320 and pos.Y.Offset == 140 + 30 + 220, "drag moves window (" .. pos.X.Offset .. "," .. pos.Y.Offset .. ")")
    dragInput.UserInputState = Mock.getEnumItem("UserInputState", "End")
    dragInput.Changed:Fire()

    -- Theme switching keeps things alive
    check(BPUI:SetTheme("Light") == true, "set light theme")
    check(BPUI:SetTheme("Midnight") == true, "set midnight theme")
    BPUI:SetTheme("Dark")
    BPUI:SetAccent(Color3.fromRGB(255, 45, 85))
    check(Window.FloatingButton.BackgroundColor3 == Color3.fromRGB(255, 45, 85), "accent rebinds floating button")

    -- Flags
    check(BPUI:GetFlag("speed") == 200, "GetFlag")
    check(BPUI:SetFlag("speed", 100, true) and slider.Value == 100, "SetFlag")

    -- Mobile / PC specifics
    check(BPUI.IsMobile == MOBILE, "IsMobile detection")
    if MOBILE then
        check(Window.Width == 560 and Window.Height == 350, "mobile default size")
        check(Window.FloatingButton.Visible == true, "floating button visible on mobile")
        check(Window.ResizeGrip.Visible == false, "resize grip hidden on mobile")
        check(BPUI._notifyHolder.AnchorPoint.X == 0.5, "notifications top-centre on mobile")
    else
        check(Window.Width == 640 and Window.Height == 440, "pc default size")
        check(Window.ResizeGrip.Visible == true, "resize grip visible on pc")
    end

    -- Minimise
    Window:Minimize()
    check(Window.Minimized == true, "minimised flag")
    check(Window.Main.AnchorPoint.X == 0 and Window.Main.Position.X.Scale == 0, "minimise re-anchors top-left")
    check(Window.Main.Size.Y.Offset == 60, "minimised height (" .. Window.Main.Size.Y.Offset .. ")")
    Mock.advance(0.3)
    check(Window.Pages.Visible == false, "pages hidden while minimised")
    Window:Minimize()
    check(Window.Minimized == false and Window.Pages.Visible == true, "restore from minimised")
    check(Window.Main.Size.Y.Offset == Window.Height, "restored height")

    -- Resize (grip)
    if not MOBILE then
        local grip = Window.ResizeGrip
        local rInput = Mock.input("MouseButton1", nil, Vector2.new(500, 500))
        grip.InputBegan:Fire(rInput)
        local rMove = Mock.input("MouseMovement", nil, Vector2.new(560, 540))
        grip.InputChanged:Fire(rMove)
        UIS.InputChanged:Fire(rMove)
        check(Window.Width == 700 and Window.Height == 480, "resize grip grows window (" .. Window.Width .. "x" .. Window.Height .. ")")
        rInput.UserInputState = Mock.getEnumItem("UserInputState", "End")
        rInput.Changed:Fire()
        Window:SetSize(100, 100, true)
        check(Window.Width == 420 and Window.Height == 300, "SetSize clamps to minimum")
        Window:SetSize(640, 440, true)
    end

    -- Search
    Window:SelectTab(Main)
    Window.SearchInput.Text = "fly"
    check(toggle.Row.Visible == true and button.Row.Visible == false, "search shows matching rows only")
    check(Window.SearchQuery == "fly", "search query stored")
    Window:SelectTab(Misc)
    check(tabToggle.Row.Visible == false, "search re-applied on tab switch")
    Window.SearchInput.Text = ""
    check(tabToggle.Row.Visible == true and button.Row.Visible == true, "clearing search restores rows")
    Window:SelectTab(Main)
    button:SetVisible(false)
    Window:Search("run")
    check(button.Row.Visible == false, "search never reveals a hidden element")
    Window:Search("")
    button:SetVisible(true)

    -- Lock
    toggle:Lock()
    check(toggle.Locked == true and toggle.Row.LockOverlay.Visible == true, "lock overlay shown")
    toggle:Unlock()
    check(toggle.Locked == false and toggle.Row.LockOverlay.Visible == false, "lock overlay hidden")

    -- Slider typing
    local valueBox = slider.Row.Value
    check(valueBox.ClassName == "TextBox", "slider value is typeable")
    valueBox.Text = "77"
    valueBox.FocusLost:Fire(true)
    check(slider.Value == 78, "typed slider value snaps (" .. tostring(slider.Value) .. ")")
    valueBox.Text = "abc"
    valueBox.FocusLost:Fire(true)
    check(slider.Value == 78 and valueBox.Text == "78 st", "invalid typed value restored")

    -- Dropdown filter
    local big = Section:AddDropdown({ Name = "Big", Options = { "Item1", "Item2", "Item3", "Item4", "Item5", "Item6", "Item7", "Item8", "Other" } })
    click(big.Row.Hit)
    check(big.Row.Filter.Visible == true, "filter box shown for long lists")
    local filterInput = Mock.find(big.Row.Filter, function(c) return c.ClassName == "TextBox" end)
    filterInput.Text = "item1"
    local visibleCount = 0
    for _, b in ipairs(big.Row.List:GetChildren()) do
        if b.ClassName == "TextButton" and b.Visible then visibleCount = visibleCount + 1 end
    end
    check(visibleCount == 1, "filter narrows options (" .. visibleCount .. ")")
    big:Close()
    Mock.advance(0.3)
    check(filterInput.Text == "" and big.Row.Filter.Visible == false, "closing clears the filter")
    check(dropdown.Row.Filter.Visible == false, "short lists have no filter")

    -- Safe mode
    local bad = Section:AddDropdown({ Name = "Bad", Options = 5 })
    check(bad.Failed == true, "safe mode returns a dummy element instead of erroring")
    bad:Set("x")
    bad:Refresh({})
    check(bad.Value == nil, "dummy element methods are no-ops")
    BPUI.SafeMode = false
    local okRaw = pcall(function() Section:AddDropdown({ Name = "Bad2", Options = 5 }) end)
    check(okRaw == false, "safe mode off surfaces the raw error")
    BPUI.SafeMode = true
    local viaTab = Misc:AddDropdown({ Name = "Bad3", Options = 5 })
    check(viaTab.Failed == true, "tab-level constructors are protected too")

    -- Review fixes: page scrolling paused while sliding
    hitbox.InputBegan:Fire(Mock.input("Touch", nil, Vector2.new(175, 0)))
    check(Main.Page.ScrollingEnabled == false, "page scrolling paused during slider drag")
    UIS.InputEnded:Fire(Mock.input("Touch"))
    check(Main.Page.ScrollingEnabled == true, "page scrolling restored after slider drag")

    -- Review fixes: slider decimals follow the increment
    local fine = Section:AddSlider({ Name = "Fine", Min = 0, Max = 1, Default = 0.005, Increment = 0.005 })
    check(fine.Row.Value.Text == "0.005", "slider shows increment precision (" .. fine.Row.Value.Text .. ")")

    -- Review fixes: destroyed keybind stops firing, only one keybind listens at a time
    local kb1 = Section:AddKeybind({ Name = "KB1", Default = "H", Callback = logger("kb1") })
    local kb2 = Section:AddKeybind({ Name = "KB2", Default = "J", Callback = logger("kb2") })
    click(kb1.Row.Pill)
    click(kb2.Row.Pill)
    check(kb1.Row.Pill.Text ~= "..." and kb2.Row.Pill.Text == "...", "second keybind cancels the first listener")
    UIS.InputBegan:Fire(Mock.input("Keyboard", "K"))
    check(kb1.Value == "H" and kb2.Value == "K", "key assigned only to the listening keybind")
    Mock.advance(0.2)
    kb1:Destroy()
    UIS.InputBegan:Fire(Mock.input("Keyboard", "H"))
    check(log["#kb1"] == nil, "destroyed keybind no longer fires")
    check(kb1._destroyed == true, "element destroyed flag")

    -- Review fixes: tab destroy clears flags / window element list
    local TempTab = Window:CreateTab("Temp")
    TempTab:AddToggle({ Name = "TempToggle", Flag = "temp_flag" })
    local before = #Window.Elements
    TempTab:Destroy()
    check(BPUI.Flags.temp_flag == nil and #Window.Elements == before - 1, "tab destroy removes flags and elements")

    -- Review fixes: toggle key must be a KeyCode
    local LibT = chunk()
    local wrongKey = LibT:CreateWindow({ Title = "WrongKey", ToggleKey = Enum.UserInputType.MouseButton2, WelcomeNotification = false, ShowSettings = false })
    check(wrongKey.ToggleKey.Name == "RightShift", "non-KeyCode toggle key falls back to RightShift")
    wrongKey:Destroy()

    -- Review fixes: re-executing while the key prompt is open cleans the old prompt up
    local LibK = chunk()
    local coK = coroutine.create(function()
        return pcall(function()
            return LibK:CreateWindow({ Title = "KeyDup", KeySystem = { Keys = { "zzz" } }, WelcomeNotification = false })
        end)
    end)
    coroutine.resume(coK)
    local prompt = Mock.find(Mock.CoreGui, function(c) return c.Name == "KeySystem" end)
    check(prompt ~= nil, "key prompt open")
    local LibK2 = chunk()
    local dup = LibK2:CreateWindow({ Title = "KeyDup", WelcomeNotification = false, ShowSettings = false })
    coroutine.resume(coK)
    check(coroutine.status(coK) == "dead", "orphaned key loop exits")
    check(prompt.Parent == nil, "orphaned key prompt destroyed")
    dup:Destroy()

    -- Mouse button keybind
    click(keybind.Row.Pill)
    UIS.InputBegan:Fire(Mock.input("MouseButton2"))
    check(keybind.Value == "MouseButton2" and keybind.Row.Pill.Text == "Mouse 2", "mouse button captured")
    Mock.advance(0.2)
    log["#keybind"] = 0
    UIS.InputBegan:Fire(Mock.input("MouseButton2"))
    check(log["#keybind"] == 1, "mouse keybind triggers")
    keybind:Set("RightShift", true)

    -- Notification cap
    local holder = BPUI._notifyHolder
    for i = 1, 8 do
        BPUI:Notify({ Title = "N" .. i, Content = "x", Duration = 30 })
    end
    Mock.advance(0.5)
    local toastCount = 0
    for _, c in ipairs(holder:GetChildren()) do
        if c.Name == "Toast" then toastCount = toastCount + 1 end
    end
    check(toastCount == 5, "at most five toasts on screen (" .. toastCount .. ")")

    -- Dialog
    local dialogFired = false
    local dialog = Window:Dialog({
        Title = "Sure?",
        Content = "Body",
        Buttons = { { Text = "No" }, { Text = "Yes", Style = "Accent", Callback = function() dialogFired = true end } },
    })
    check(dialog and Window.Main.Dialog ~= nil, "dialog created inside window")
    local yes = Mock.find(Window.Main.Dialog, function(c) return c.ClassName == "TextButton" and c.Text == "Yes" end)
    click(yes)
    Mock.advance(0.3)
    check(dialogFired == true and Window.Main:FindFirstChild("Dialog") == nil, "dialog button fires and closes")

    -- Config
    if WITH_FS then
        check(Window:SaveConfig("test") == true, "save config")
        local raw = files["BPUI/BPHubTest/configs/test.json"]
        check(raw ~= nil, "config file written")
        toggle:Set(false, true)
        slider:Set(16, true)
        dropdown:Set("X", true)
        picker:Set(Color3.fromRGB(1, 2, 3), true)
        keybind:Set("Q", true)
        input:Set("zzz", true)
        multi:Set({}, true)
        check(Window:LoadConfig("test") == true, "load config")
        check(toggle.Value == true, "config restored toggle")
        check(slider.Value == 108, "config restored slider (" .. tostring(slider.Value) .. ")")
        check(dropdown.Value == "Y", "config restored dropdown")
        check(picker.Value == Color3.fromRGB(0, 0, 0), "config restored color")
        check(keybind.Value == "RightShift", "config restored keybind")
        check(input.Value == "hello", "config restored input")
        check(#multi.Value == 2, "config restored multi")

        -- late element gets pending value
        local late = Section:AddToggle({ Name = "Late", Flag = "fly", Default = false })
        check(late.Value == true, "late element receives pending config value")

        local names = Window:GetConfigs()
        check(#names == 1 and names[1] == "test", "GetConfigs lists file")
        Window:SetAutoLoad("test")
        check(Window:GetAutoLoad() == "test", "autoload stored")
        check(Window:LoadAutoConfig() == true, "autoload loads")
        check(files["BPUI/BPHubTest/key.txt"] == "bphub-test", "key saved")
        check(files["BPUI/BPHubTest/settings.json"] ~= nil, "settings persisted")
        Window:DeleteConfig("test")
        check(#Window:GetConfigs() == 0, "delete config")

        -- remembered window size
        Window:SetSize(700, 500, true)
        Window:_SaveSettings()
        local LibX = chunk()
        local remembered = LibX:CreateWindow({ Title = "BP Hub", WelcomeNotification = false, ShowSettings = false, ConfigFolder = "BPHubTest", KeySystem = nil })
        check(remembered.Width == 700 and remembered.Height == 500, "window size remembered from settings (" .. remembered.Width .. "x" .. remembered.Height .. ")")
        check(Window._destroyed == true, "same-title window replaced by the newer library instance")
        remembered:Destroy()
        -- recreate the main test window handle for the remaining checks
        Window = BPUI:CreateWindow({ Title = "BP Hub 2", WelcomeNotification = false, ConfigFolder = "BPHubTest" })
    else
        check(Window:SaveConfig("x") == false, "save config gracefully fails without fs")
        check(Window:LoadConfig("x") == false, "load config gracefully fails without fs")
    end

    -- Settings tab interaction: theme dropdown & toggle key keybind exist
    local settingsTab = Window.SettingsTab
    check(settingsTab ~= nil and #settingsTab.Sections >= 3, "settings tab sections")

    -- Destroy
    local destroyed = false
    Window.OnDestroy = function() destroyed = true end
    Window:Destroy()
    check(destroyed == true, "OnDestroy fired")
    check(Window.Main.Parent == nil, "main destroyed")
    check(BPUI.Flags["speed"] == nil, "flags cleared on destroy")
    check(#BPUI.Windows == 0, "window list cleared")

    -- Re-create to ensure a second window works after destroy
    local Window2 = BPUI:CreateWindow({ Title = "Second", WelcomeNotification = false, ShowSettings = false })
    check(#Window2.Tabs == 0, "ShowSettings=false makes no tabs")
    Window2:CreateTab("T"):AddButton({ Name = "B" })
    BPUI:Destroy()
    check(BPUI._gui == nil, "library destroy clears gui")

    -- re-executing the script (fresh library instance) must clean the old window
    local LibA = chunk()
    local first = LibA:CreateWindow({ Title = "Dup", WelcomeNotification = false })
    local LibB = chunk()
    local second = LibB:CreateWindow({ Title = "Dup", WelcomeNotification = false })
    check(first._destroyed == true and second._destroyed == false, "re-execution destroys previous window")
    second:Destroy()
end

-- driver: resumes the body coroutine and automates the key system prompt
local co = coroutine.create(body)
local keyDone = false
local steps = 0
while coroutine.status(co) ~= "dead" do
    local ok, err = coroutine.resume(co)
    if not ok then
        print("RUNTIME ERROR: " .. tostring(err))
        print(debug.traceback(co))
        os.exit(1)
    end
    steps = steps + 1
    if steps > 2000 then
        print("Test timed out (key system never resolved?)")
        os.exit(1)
    end
    if not keyDone then
        local frame = Mock.find(Mock.CoreGui, function(c) return c.Name == "KeySystem" end)
        if frame then
            local box = Mock.find(frame, function(c) return c.ClassName == "TextBox" end)
            local verify = Mock.find(frame, function(c) return c.ClassName == "TextButton" and c.Text == "Verify" end)
            local getKey = Mock.find(frame, function(c) return c.ClassName == "TextButton" and c.Text == "Get Key" end)
            check(box and verify and getKey, "key system ui built")
            getKey.Activated:Fire()
            check(Mock.clipboard == "https://example.com/key", "get key copies link")
            box.Text = "wrong"
            verify.Activated:Fire()
            check(frame.Parent ~= nil, "wrong key keeps prompt")
            box.Text = "bphub-test"
            verify.Activated:Fire()
            keyDone = true
        end
    end
end

print(string.format("Passed: %d   Failed: %d   (mode: %s)", passed, failed, MODE))
if failed > 0 then os.exit(1) end
