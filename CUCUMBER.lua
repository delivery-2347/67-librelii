--[[
    CUCUMBER UI
    Compact black UI library for Roblox Luau.

    Basic use:
        local UI = loadstring(game:HttpGet("RAW_URL"))()
        local Window = UI.new({ Name = "CUCUMBER", Subtitle = "Movement" })
        local Tab = Window:CreateTab("Main")
        local Section = Tab:CreateSection("General")

    This library uses standard Roblox client APIs. It does not require loops.
    Call Window:Destroy() when the UI is no longer needed to clean up events.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local HostMethods = {}
HostMethods.__index = HostMethods

local tabMethods = {}

local COLORS = {
    Background = Color3.fromRGB(8, 9, 10),
    Panel = Color3.fromRGB(13, 14, 16),
    Element = Color3.fromRGB(19, 21, 23),
    ElementHover = Color3.fromRGB(25, 28, 30),
    Border = Color3.fromRGB(43, 46, 48),
    Text = Color3.fromRGB(238, 240, 240),
    Muted = Color3.fromRGB(137, 143, 143),
    Accent = Color3.fromRGB(51, 192, 106),
    Off = Color3.fromRGB(55, 59, 60),
    Danger = Color3.fromRGB(200, 76, 76),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 3),
    }, object)
end

local function stroke(object, color, transparency)
    return create("UIStroke", {
        Color = color or COLORS.Border,
        Thickness = 1,
        Transparency = transparency or 0,
    }, object)
end

local function padding(object, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, object)
end

local function textLabel(parent, text, size, position, fontSize, color)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(text or ""),
        TextColor3 = color or COLORS.Text,
        TextSize = fontSize or 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = size,
        Position = position or UDim2.new(),
    }, parent)
end

local function textButton(parent, text, size, position)
    return create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = COLORS.Element,
        BorderSizePixel = 0,
        Text = tostring(text or ""),
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        Size = size,
        Position = position or UDim2.new(),
    }, parent)
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[CUCUMBER UI] Callback error: " .. tostring(err))
    end
end

local function asKeyCode(value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        return Enum.KeyCode[value] or Enum.KeyCode.Unknown
    end
    return Enum.KeyCode.Unknown
end

local function isColor3(value)
    return typeof(value) == "Color3"
end

local function formatNumber(value, step)
    local decimals = 0
    local probe = tonumber(step) or 1
    while decimals < 5 and math.abs(probe - math.round(probe)) > 0.000001 do
        probe *= 10
        decimals += 1
    end
    if decimals == 0 then
        return tostring(math.round(value))
    end
    return string.format("%." .. decimals .. "f", value)
end

local function normalizeOptions(options)
    if type(options) ~= "table" then
        return {}
    end
    local result = {}
    for _, option in ipairs(options) do
        table.insert(result, option)
    end
    return result
end

function Library.new(config)
    config = config or {}

    assert(LocalPlayer, "CUCUMBER UI must be created on the client")

    local window = setmetatable({
        Config = config,
        Accent = isColor3(config.Accent) and config.Accent or COLORS.Accent,
        _connections = {},
        _threads = {},
        _notifications = {},
        _tabs = {},
        _keybinds = {},
        _accentUpdaters = {},
        _destroyed = false,
        _dragging = false,
        _dragInput = nil,
        _activeSlider = nil,
        _listeningBinding = nil,
        _openDropdown = nil,
        _activeTab = nil,
    }, WindowMethods)

    local parent = config.Parent or LocalPlayer:WaitForChild("PlayerGui")
    local guiName = config.GuiName or "CUCUMBER_UI"

    window.Gui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = tonumber(config.DisplayOrder) or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)

    local defaultSize = UDim2.fromOffset(430, 340)
    local startPosition = config.Position or UDim2.new(0.5, -215, 0.5, -170)

    window.Main = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0, 0),
        Position = startPosition,
        Size = typeof(config.Size) == "UDim2" and config.Size or defaultSize,
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, window.Gui)
    corner(window.Main, 4)
    stroke(window.Main, COLORS.Border)

    window.TopBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, window.Main)
    corner(window.TopBar, 4)

    -- Covers the lower rounded corners of the top bar to keep its bottom edge square.
    create("Frame", {
        Position = UDim2.new(0, 0, 1, -5),
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, window.TopBar)

    window.TitleLabel = textLabel(
        window.TopBar,
        config.Name or "CUCUMBER",
        UDim2.new(0, 145, 1, 0),
        UDim2.fromOffset(10, 0),
        12,
        COLORS.Text
    )
    window.TitleLabel.Font = Enum.Font.GothamBold

    window.SubtitleLabel = textLabel(
        window.TopBar,
        config.Subtitle or "UI LIBRARY",
        UDim2.new(1, -190, 1, 0),
        UDim2.fromOffset(150, 0),
        10,
        COLORS.Muted
    )

    window.CloseButton = textButton(
        window.TopBar,
        "X",
        UDim2.fromOffset(25, 23),
        UDim2.new(1, -30, 0, 4)
    )
    window.CloseButton.TextSize = 11
    corner(window.CloseButton, 3)
    window:_connect(window.CloseButton.Activated, function()
        window:Close()
    end)

    window.TabBar = create("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(7, 37),
        Size = UDim2.new(1, -14, 0, 25),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        CanvasSize = UDim2.new(),
    }, window.Main)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, window.TabBar)

    window.PageHolder = create("Frame", {
        Name = "Pages",
        Position = UDim2.fromOffset(7, 68),
        Size = UDim2.new(1, -14, 1, -75),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, window.Main)

    window.NotificationHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -12, 1, -12),
        Size = UDim2.new(0, 245, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 50,
    }, window.Gui)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 6),
    }, window.NotificationHolder)

    -- One shared input listener handles dragging, sliders, and keybinds.
    window:_connect(UserInputService.InputBegan, function(input, processed)
        if window._destroyed then
            return
        end

        if window._listeningBinding then
            local binding = window._listeningBinding
            if input.KeyCode == Enum.KeyCode.Escape then
                binding:_finishListening()
                return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding:Set(input.KeyCode, true)
                binding:_finishListening()
                return
            end
        end

        if input.KeyCode == Enum.KeyCode.Escape then
            window:Close()
            return
        end

        local toggleKey = window.Config.ToggleKey
        if toggleKey == nil then
            toggleKey = Enum.KeyCode.RightShift
        else
            toggleKey = asKeyCode(toggleKey)
        end

        if not processed and toggleKey ~= Enum.KeyCode.Unknown and input.KeyCode == toggleKey then
            window:Toggle()
            return
        end

        if processed or UserInputService:GetFocusedTextBox() then
            return
        end

        for _, binding in ipairs(window._keybinds) do
            if binding.Key ~= Enum.KeyCode.Unknown and input.KeyCode == binding.Key then
                safeCall(binding.Callback, input.KeyCode)
            end
        end
    end)

    window:_connect(UserInputService.InputChanged, function(input)
        if window._destroyed then
            return
        end

        if window._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - window._dragStart
            local startPositionNow = window._dragStartPosition
            window.Main.Position = UDim2.new(
                startPositionNow.X.Scale,
                startPositionNow.X.Offset + delta.X,
                startPositionNow.Y.Scale,
                startPositionNow.Y.Offset + delta.Y
            )
        end

        if window._activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            window._activeSlider:_updateFromX(input.Position.X)
        end
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if window._dragInput and (input == window._dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            window._dragging = false
            window._dragInput = nil
        end

        if window._activeSlider and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            window._activeSlider._dragging = false
            window._activeSlider = nil
        end
    end)

    window:_connect(window.TopBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            window._dragging = true
            window._dragInput = input
            window._dragStart = input.Position
            window._dragStartPosition = window.Main.Position
        end
    end)

    window:_addAccentUpdater(function(color)
        window.CloseButton.TextColor3 = color
        for _, tab in ipairs(window._tabs) do
            window:_styleTab(tab)
        end
    end)

    return window
end

Library.CreateWindow = Library.new

function WindowMethods:_connect(signal, callback, bucket)
    local connection = signal:Connect(callback)
    table.insert(self._connections, connection)
    if bucket then
        table.insert(bucket, connection)
    end
    return connection
end

function WindowMethods:_disconnectBucket(bucket)
    if not bucket then
        return
    end

    for _, connection in ipairs(bucket) do
        if connection.Connected then
            connection:Disconnect()
        end
        for index = #self._connections, 1, -1 do
            if self._connections[index] == connection then
                table.remove(self._connections, index)
                break
            end
        end
    end
    table.clear(bucket)
end

function WindowMethods:_addAccentUpdater(callback)
    table.insert(self._accentUpdaters, callback)
end

function WindowMethods:_styleTab(tab)
    if not tab or not tab.Button or not tab.Button.Parent then
        return
    end

    local active = self._activeTab == tab
    tab.Button.BackgroundColor3 = active and self.Accent or COLORS.Element
    tab.Button.TextColor3 = active and COLORS.Background or COLORS.Muted
end

function WindowMethods:CreateTab(name)
    assert(not self._destroyed, "Cannot create a tab on a destroyed window")

    name = tostring(name or ("Tab " .. (#self._tabs + 1)))
    local textBounds = TextService:GetTextSize(name, 11, Enum.Font.GothamMedium, Vector2.new(150, 24))
    local width = math.clamp(textBounds.X + 18, 48, 118)

    local tab = setmetatable({
        Window = self,
        Name = name,
        _host = true,
    }, {
        __index = function(_, key)
            return tabMethods[key] or HostMethods[key]
        end,
    })

    tab.Button = textButton(self.TabBar, name, UDim2.fromOffset(width, 24))
    tab.Button.TextSize = 11
    corner(tab.Button, 3)

    tab.Page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
    }, self.PageHolder)

    tab.Container = tab.Page -- Tabs can contain controls directly as well as sections.

    padding(tab.Page, 2, 5, 2, 5)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, tab.Page)

    self:_connect(tab.Button.Activated, function()
        self:_selectTab(tab)
    end)

    self:_addAccentUpdater(function(color)
        if tab.Page and tab.Page.Parent then
            tab.Page.ScrollBarImageColor3 = color
        end
        self:_styleTab(tab)
    end)

    table.insert(self._tabs, tab)
    if not self._activeTab then
        self:_selectTab(tab)
    else
        self:_styleTab(tab)
    end

    return tab
end

function WindowMethods:_selectTab(tab)
    self._activeTab = tab
    for _, item in ipairs(self._tabs) do
        if item.Page then
            item.Page.Visible = item == tab
        end
        self:_styleTab(item)
    end
end

function WindowMethods:SetTitle(value)
    self.TitleLabel.Text = tostring(value or "")
    return self
end

function WindowMethods:SetSubtitle(value)
    self.SubtitleLabel.Text = tostring(value or "")
    return self
end

function WindowMethods:SetAccent(color)
    assert(isColor3(color), "SetAccent expects a Color3")
    self.Accent = color
    for _, updater in ipairs(self._accentUpdaters) do
        safeCall(updater, color)
    end
    return self
end

function WindowMethods:SetSize(size)
    assert(typeof(size) == "UDim2", "SetSize expects a UDim2")
    self.Main.Size = size
    return self
end

function WindowMethods:Open()
    if not self._destroyed then
        self.Main.Visible = true
    end
    return self
end

function WindowMethods:Close()
    if not self._destroyed then
        self.Main.Visible = false
        if self._listeningBinding then
            self._listeningBinding:_finishListening()
        end
    end
    return self
end

function WindowMethods:Toggle()
    if not self._destroyed then
        self.Main.Visible = not self.Main.Visible
    end
    return self
end

function WindowMethods:Notify(title, message, duration)
    if self._destroyed then
        return nil
    end

    if message == nil then
        message = title
        title = "Notification"
    end

    title = tostring(title or "Notification")
    message = tostring(message or "")
    duration = math.clamp(tonumber(duration) or 3, 1, 15)

    local notification = create("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        ZIndex = 51,
    }, self.NotificationHolder)
    corner(notification, 4)
    stroke(notification, self.Accent)
    padding(notification, 9, 9, 6, 7)

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, notification)

    local titleLabel = textLabel(
        notification,
        title,
        UDim2.new(1, 0, 0, 16),
        nil,
        11,
        self.Accent
    )
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 52

    local messageLabel = textLabel(
        notification,
        message,
        UDim2.new(1, 0, 0, 0),
        nil,
        11,
        COLORS.Text
    )
    messageLabel.TextWrapped = true
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.ZIndex = 52

    table.insert(self._notifications, notification)
    while #self._notifications > 4 do
        local oldest = table.remove(self._notifications, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    local thread
    thread = task.delay(duration, function()
        if notification and notification.Parent then
            notification:Destroy()
        end
        for index, item in ipairs(self._notifications) do
            if item == notification then
                table.remove(self._notifications, index)
                break
            end
        end
        for index, pending in ipairs(self._threads) do
            if pending == thread then
                table.remove(self._threads, index)
                break
            end
        end
    end)
    table.insert(self._threads, thread)

    return notification
end

WindowMethods.Notification = WindowMethods.Notify

function WindowMethods:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true
    self._dragging = false
    self._activeSlider = nil
    self._listeningBinding = nil

    for _, connection in ipairs(self._connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(self._connections)

    for _, thread in ipairs(self._threads) do
        pcall(task.cancel, thread)
    end
    table.clear(self._threads)
    table.clear(self._notifications)

    if self.Gui and self.Gui.Parent then
        self.Gui:Destroy()
    end
end

-- A section is an auto-sizing panel inside a tab. Tabs themselves can also host controls.
local function createSection(tab, name)
    local window = tab.Window
    local sectionFrame = create("Frame", {
        Name = "Section",
        Size = UDim2.new(1, -3, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, tab.Page)
    corner(sectionFrame, 3)
    stroke(sectionFrame, COLORS.Border)

    local header = textLabel(
        sectionFrame,
        tostring(name or "Section"),
        UDim2.new(1, -14, 0, 19),
        UDim2.fromOffset(7, 1),
        10,
        window.Accent
    )
    header.Font = Enum.Font.GothamBold

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(6, 22),
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, sectionFrame)

    padding(content, 0, 0, 0, 6)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    }, content)

    window:_addAccentUpdater(function(color)
        if header.Parent then
            header.TextColor3 = color
        end
    end)

    return setmetatable({
        Window = window,
        Container = content,
        Frame = sectionFrame,
        Header = header,
    }, HostMethods)
end

function tabMethods:CreateSection(name)
    return createSection(self, name)
end

function tabMethods:SetName(name)
    name = tostring(name or "Tab")
    self.Name = name
    self.Button.Text = name
    return self
end

function HostMethods:CreateSection(name)
    -- Supports section nesting without an extra wrapper API: the section belongs to this container.
    local fakeTab = { Window = self.Window, Page = self.Container }
    return createSection(fakeTab, name)
end

local function newControlRow(host, name, height, background)
    local window = host.Window
    local row = create("Frame", {
        Name = name or "Control",
        Size = UDim2.new(1, 0, 0, height or 29),
        BackgroundColor3 = background or COLORS.Element,
        BorderSizePixel = 0,
    }, host.Container)
    corner(row, 3)
    stroke(row, COLORS.Border)
    return row, window
end

local function addNameLabel(row, name, width)
    return textLabel(
        row,
        name,
        UDim2.new(1, -(width or 75), 1, 0),
        UDim2.fromOffset(8, 0),
        11,
        COLORS.Text
    )
end

function HostMethods:Button(options)
    if type(options) == "string" then
        options = { Name = options }
    end
    options = options or {}

    local row, window = newControlRow(self, "Button", 29)
    local button = textButton(row, options.Name or "Button", UDim2.new(1, 0, 1, 0))
    button.BackgroundTransparency = 1
    button.TextColor3 = COLORS.Text
    corner(button, 3)

    local control = {
        Window = window,
        Frame = row,
        Button = button,
        Name = tostring(options.Name or "Button"),
        Callback = options.Callback,
        Disabled = false,
    }

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Button.Text = self.Name
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:SetDisabled(value)
        self.Disabled = value == true
        self.Button.TextColor3 = self.Disabled and COLORS.Muted or COLORS.Text
        self.Frame.BackgroundColor3 = self.Disabled and COLORS.Background or COLORS.Element
        return self
    end

    function control:Destroy()
        if self.Frame then
            self.Frame:Destroy()
        end
    end

    window:_connect(button.Activated, function()
        if not control.Disabled then
            safeCall(control.Callback)
        end
    end)

    return control
end

function HostMethods:Toggle(options)
    options = options or {}
    local row, window = newControlRow(self, "Toggle", 29)
    local label = addNameLabel(row, options.Name or "Toggle", 64)
    local switch = textButton(row, "OFF", UDim2.fromOffset(43, 19), UDim2.new(1, -51, 0.5, -9))
    switch.TextSize = 9
    corner(switch, 3)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        Button = switch,
        Name = tostring(options.Name or "Toggle"),
        Value = options.Default == true,
        Callback = options.Callback,
    }

    local function redraw()
        switch.Text = control.Value and "ON" or "OFF"
        switch.BackgroundColor3 = control.Value and window.Accent or COLORS.Off
        switch.TextColor3 = control.Value and COLORS.Background or COLORS.Text
    end

    function control:Set(value, silent)
        self.Value = value == true
        redraw()
        if not silent then
            safeCall(self.Callback, self.Value)
        end
        return self
    end

    function control:Toggle()
        return self:Set(not self.Value)
    end

    function control:Get()
        return self.Value
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:Destroy()
        self.Frame:Destroy()
    end

    window:_addAccentUpdater(function()
        redraw()
    end)
    window:_connect(switch.Activated, function()
        control:Toggle()
    end)
    window:_connect(row.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Clicking the row label also toggles the switch.
            local mouse = UserInputService:GetMouseLocation()
            local buttonStart = switch.AbsolutePosition.X
            if mouse.X < buttonStart then
                control:Toggle()
            end
        end
    end)

    redraw()
    return control
end

function HostMethods:Slider(options)
    options = options or {}
    local minimum = tonumber(options.Min) or 0
    local maximum = tonumber(options.Max) or 100
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    local step = math.max(tonumber(options.Step) or 1, 0.000001)
    local suffix = tostring(options.Suffix or "")
    local row, window = newControlRow(self, "Slider", 39)
    local label = textLabel(row, options.Name or "Slider", UDim2.new(1, -90, 0, 16), UDim2.fromOffset(8, 1), 10, COLORS.Text)
    local valueLabel = textLabel(row, "", UDim2.new(0, 78, 0, 16), UDim2.new(1, -85, 0, 1), 10, COLORS.Muted)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = create("Frame", {
        Name = "Track",
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 0, 5),
        BackgroundColor3 = COLORS.Off,
        BorderSizePixel = 0,
    }, row)
    corner(track, 3)

    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = window.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 3)

    local knob = create("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(7, 9),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 2)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        ValueLabel = valueLabel,
        Track = track,
        Fill = fill,
        Knob = knob,
        Name = tostring(options.Name or "Slider"),
        Min = minimum,
        Max = maximum,
        Step = step,
        Suffix = suffix,
        Callback = options.Callback,
        Value = minimum,
    }

    local function redraw()
        local alpha = maximum == minimum and 0 or (control.Value - minimum) / (maximum - minimum)
        alpha = math.clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        local formatted = type(options.Format) == "function" and tostring(options.Format(control.Value))
            or (formatNumber(control.Value, step) .. suffix)
        valueLabel.Text = formatted
    end

    function control:Set(value, silent)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        value = math.clamp(value, minimum, maximum)
        self.Value = tonumber(string.format("%.6f", value))
        redraw()
        if not silent then
            safeCall(self.Callback, self.Value)
        end
        return self
    end

    function control:Get()
        return self.Value
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:_updateFromX(positionX)
        if not self.Track or not self.Track.Parent then
            return
        end
        local startX = self.Track.AbsolutePosition.X
        local width = self.Track.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local alpha = math.clamp((positionX - startX) / width, 0, 1)
        self:Set(minimum + (maximum - minimum) * alpha)
    end

    function control:Destroy()
        self.Frame:Destroy()
    end

    window:_addAccentUpdater(function(color)
        fill.BackgroundColor3 = color
    end)
    window:_connect(track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            window._activeSlider = control
            control._dragging = true
            control:_updateFromX(input.Position.X)
        end
    end)

    control:Set(options.Default == nil and minimum or options.Default, true)
    return control
end

function HostMethods:Textbox(options)
    options = options or {}
    local row, window = newControlRow(self, "Textbox", 48)
    local label = textLabel(row, options.Name or "Textbox", UDim2.new(1, -12, 0, 14), UDim2.fromOffset(8, 1), 10, COLORS.Muted)
    local input = create("TextBox", {
        Name = "Input",
        Position = UDim2.new(0, 6, 0, 18),
        Size = UDim2.new(1, -12, 0, 24),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClearTextOnFocus = options.ClearOnFocus == true,
        Text = tostring(options.Default or ""),
        PlaceholderText = tostring(options.Placeholder or "Enter text..."),
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    corner(input, 3)
    stroke(input, COLORS.Border)
    padding(input, 6, 6, 0, 0)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        Input = input,
        Name = tostring(options.Name or "Textbox"),
        Callback = options.Callback,
        Changed = options.Changed,
    }

    function control:Set(value, silent)
        self.Input.Text = tostring(value == nil and "" or value)
        if not silent then
            safeCall(self.Callback, self.Input.Text, false)
        end
        return self
    end

    function control:Get()
        return self.Input.Text
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetPlaceholder(value)
        self.Input.PlaceholderText = tostring(value or "")
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:Destroy()
        self.Frame:Destroy()
    end

    window:_connect(input.FocusLost, function(enterPressed)
        safeCall(control.Callback, input.Text, enterPressed)
    end)
    if type(options.Changed) == "function" then
        window:_connect(input:GetPropertyChangedSignal("Text"), function()
            safeCall(control.Changed, input.Text)
        end)
    end

    return control
end

function HostMethods:Dropdown(options)
    options = options or {}
    local items = normalizeOptions(options.Options)
    local row, window = newControlRow(self, "Dropdown", 29)
    row.ClipsDescendants = true
    local label = addNameLabel(row, options.Name or "Dropdown", 114)
    local chosen = options.Default
    if chosen == nil and #items > 0 then
        chosen = items[1]
    end
    local valueButton = textButton(row, chosen == nil and "Select..." or tostring(chosen), UDim2.new(0, 103, 0, 21), UDim2.new(1, -110, 0, 4))
    valueButton.TextSize = 10
    corner(valueButton, 3)

    local popup = create("Frame", {
        Name = "Options",
        Position = UDim2.new(0, 5, 0, 29),
        Size = UDim2.new(1, -10, 0, 0),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Visible = false,
    }, row)
    corner(popup, 3)
    stroke(popup, COLORS.Border)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        Button = valueButton,
        Popup = popup,
        Name = tostring(options.Name or "Dropdown"),
        Options = items,
        Value = chosen,
        Callback = options.Callback,
        _open = false,
        _optionConnections = {},
    }

    local function setOpen(isOpen)
        control._open = isOpen
        popup.Visible = isOpen
        row.Size = UDim2.new(1, 0, 0, isOpen and (30 + (#items * 23)) or 29)
        if isOpen then
            window._openDropdown = control
        elseif window._openDropdown == control then
            window._openDropdown = nil
        end
    end

    local function redrawValue()
        valueButton.Text = control.Value == nil and "Select..." or tostring(control.Value)
    end

    local function rebuildOptions()
        window:_disconnectBucket(control._optionConnections)
        for _, child in ipairs(popup:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        popup.Size = UDim2.new(1, -10, 0, #items * 23)
        for index, option in ipairs(items) do
            local optionButton = textButton(
                popup,
                tostring(option),
                UDim2.new(1, -6, 0, 21),
                UDim2.fromOffset(3, (index - 1) * 23 + 1)
            )
            optionButton.TextXAlignment = Enum.TextXAlignment.Left
            optionButton.TextSize = 10
            corner(optionButton, 2)
            padding(optionButton, 6, 4, 0, 0)
            window:_connect(optionButton.Activated, function()
                control:Set(option)
                setOpen(false)
            end, control._optionConnections)
        end
    end

    function control:Set(value, silent)
        self.Value = value
        redrawValue()
        if not silent then
            safeCall(self.Callback, self.Value)
        end
        return self
    end

    function control:Get()
        return self.Value
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetOptions(newOptions)
        items = normalizeOptions(newOptions)
        self.Options = items
        local found = false
        for _, option in ipairs(items) do
            if option == self.Value then
                found = true
                break
            end
        end
        if not found then
            self.Value = items[1]
        end
        rebuildOptions()
        redrawValue()
        if self._open then
            setOpen(true)
        end
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:Destroy()
        window:_disconnectBucket(self._optionConnections)
        self.Frame:Destroy()
        if window._openDropdown == self then
            window._openDropdown = nil
        end
    end

    rebuildOptions()
    window:_connect(valueButton.Activated, function()
        if control._open then
            setOpen(false)
        else
            if window._openDropdown and window._openDropdown ~= control then
                window._openDropdown:_close()
            end
            setOpen(true)
        end
    end)

    function control:_close()
        setOpen(false)
    end

    window:_addAccentUpdater(function(color)
        if self.Frame.Parent then
            -- The selected value remains readable; accent is used by active tabs and sliders.
            self.Frame:SetAttribute("Accent", color)
        end
    end)

    if chosen ~= nil then
        control:Set(chosen, true)
    else
        redrawValue()
    end
    return control
end

function HostMethods:Keybind(options)
    options = options or {}
    local row, window = newControlRow(self, "Keybind", 29)
    local label = addNameLabel(row, options.Name or "Keybind", 75)
    local key = asKeyCode(options.Default)
    local keyButton = textButton(row, key == Enum.KeyCode.Unknown and "None" or key.Name, UDim2.new(0, 75, 0, 21), UDim2.new(1, -82, 0, 4))
    keyButton.TextSize = 10
    corner(keyButton, 3)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        Button = keyButton,
        Name = tostring(options.Name or "Keybind"),
        Key = key,
        Callback = options.Callback,
        _waiting = false,
    }

    function control:Set(value, silent)
        self.Key = asKeyCode(value)
        self.Button.Text = self.Key == Enum.KeyCode.Unknown and "None" or self.Key.Name
        if not silent then
            -- Setting a key changes the binding; it does not pretend the key was pressed.
            self.Changed = self.Key
        end
        return self
    end

    function control:Get()
        return self.Key
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:_finishListening()
        self._waiting = false
        if window._listeningBinding == self then
            window._listeningBinding = nil
        end
        self.Button.Text = self.Key == Enum.KeyCode.Unknown and "None" or self.Key.Name
    end

    function control:Destroy()
        if window._listeningBinding == self then
            window._listeningBinding = nil
        end
        for index, binding in ipairs(window._keybinds) do
            if binding == self then
                table.remove(window._keybinds, index)
                break
            end
        end
        self.Frame:Destroy()
    end

    window:_connect(keyButton.Activated, function()
        if window._listeningBinding and window._listeningBinding ~= control then
            window._listeningBinding:_finishListening()
        end
        control._waiting = true
        window._listeningBinding = control
        keyButton.Text = "..."
    end)

    table.insert(window._keybinds, control)
    return control
end

function HostMethods:Colorpicker(options)
    options = options or {}
    local row, window = newControlRow(self, "Colorpicker", 29)
    row.ClipsDescendants = true
    local label = addNameLabel(row, options.Name or "Color", 65)
    local initialColor = isColor3(options.Default) and options.Default or window.Accent
    local swatch = textButton(row, "", UDim2.fromOffset(26, 18), UDim2.new(1, -34, 0, 5))
    swatch.BackgroundColor3 = initialColor
    corner(swatch, 3)

    local popup = create("Frame", {
        Name = "ColorOptions",
        Position = UDim2.new(0, 5, 0, 29),
        Size = UDim2.new(1, -10, 0, 31),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Visible = false,
    }, row)
    corner(popup, 3)
    stroke(popup, COLORS.Border)

    local hexInput = create("TextBox", {
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.new(1, -64, 0, 23),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        Text = initialColor:ToHex(),
        PlaceholderText = "RRGGBB",
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.Muted,
        TextSize = 10,
        Font = Enum.Font.Code,
        ClearTextOnFocus = false,
    }, popup)
    corner(hexInput, 2)
    padding(hexInput, 5, 4, 0, 0)

    local applyButton = textButton(popup, "Apply", UDim2.new(0, 51, 0, 23), UDim2.new(1, -55, 0, 4))
    applyButton.TextSize = 10
    corner(applyButton, 2)

    local control = {
        Window = window,
        Frame = row,
        Label = label,
        Button = swatch,
        Popup = popup,
        Input = hexInput,
        Name = tostring(options.Name or "Color"),
        Value = initialColor,
        Callback = options.Callback,
        _open = false,
    }

    local function setOpen(value)
        control._open = value
        popup.Visible = value
        row.Size = UDim2.new(1, 0, 0, value and 64 or 29)
    end

    function control:Set(value, silent)
        if type(value) == "string" then
            value = value:gsub("#", "")
            local ok, color = pcall(Color3.fromHex, value)
            if ok then
                value = color
            end
        end
        assert(isColor3(value), "Colorpicker:Set expects a Color3 or hex string")
        self.Value = value
        swatch.BackgroundColor3 = value
        hexInput.Text = value:ToHex()
        if not silent then
            safeCall(self.Callback, value)
        end
        return self
    end

    function control:Get()
        return self.Value
    end

    function control:SetName(value)
        self.Name = tostring(value or "")
        self.Label.Text = self.Name
        return self
    end

    function control:SetCallback(callback)
        self.Callback = callback
        return self
    end

    function control:Destroy()
        self.Frame:Destroy()
    end

    window:_connect(swatch.Activated, function()
        setOpen(not control._open)
    end)
    window:_connect(applyButton.Activated, function()
        local value = hexInput.Text:gsub("#", "")
        local ok, color = pcall(Color3.fromHex, value)
        if ok then
            control:Set(color)
            setOpen(false)
        else
            window:Notify("Invalid color", "Enter a hex color such as 33C06A.", 3)
        end
    end)
    window:_connect(hexInput.FocusLost, function(enterPressed)
        if enterPressed then
            applyButton:Activate()
        end
    end)

    return control
end

function HostMethods:Label(options)
    if type(options) == "string" then
        options = { Text = options }
    end
    options = options or {}
    local row, window = newControlRow(self, "Label", 22, COLORS.Panel)
    row.BackgroundTransparency = 1
    local label = textLabel(row, options.Text or options.Name or "Label", UDim2.new(1, -12, 1, 0), UDim2.fromOffset(6, 0), 11, options.Color or COLORS.Text)

    local control = { Window = window, Frame = row, Label = label }
    function control:Set(value)
        self.Label.Text = tostring(value or "")
        return self
    end
    function control:SetName(value)
        return self:Set(value)
    end
    function control:Destroy()
        self.Frame:Destroy()
    end
    return control
end

function HostMethods:Paragraph(options)
    if type(options) == "string" then
        options = { Content = options }
    end
    options = options or {}

    local row, window = newControlRow(self, "Paragraph", 0, COLORS.Panel)
    row.AutomaticSize = Enum.AutomaticSize.Y
    local title = textLabel(row, options.Title or options.Name or "Paragraph", UDim2.new(1, -14, 0, 17), UDim2.fromOffset(7, 3), 11, window.Accent)
    title.Font = Enum.Font.GothamBold

    local body = textLabel(row, options.Content or "", UDim2.new(1, -14, 0, 0), UDim2.fromOffset(7, 21), 10, COLORS.Muted)
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.AutomaticSize = Enum.AutomaticSize.Y
    padding(row, 0, 0, 0, 6)

    local control = { Window = window, Frame = row, Title = title, Content = body }
    function control:Set(value)
        self.Content.Text = tostring(value or "")
        return self
    end
    function control:SetContent(value)
        return self:Set(value)
    end
    function control:SetTitle(value)
        self.Title.Text = tostring(value or "")
        return self
    end
    function control:SetName(value)
        return self:SetTitle(value)
    end
    function control:Destroy()
        self.Frame:Destroy()
    end

    window:_addAccentUpdater(function(color)
        title.TextColor3 = color
    end)
    return control
end

function HostMethods:Divider()
    local row, window = newControlRow(self, "Divider", 9, COLORS.Panel)
    row.BackgroundTransparency = 1
    local line = create("Frame", {
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(1, -6, 0, 1),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
    }, row)
    return {
        Window = window,
        Frame = row,
        Line = line,
        Destroy = function(control)
            control.Frame:Destroy()
        end,
    }
end

-- Aliases make the API easier to discover from autocomplete and README examples.
HostMethods.CreateButton = HostMethods.Button
HostMethods.CreateToggle = HostMethods.Toggle
HostMethods.CreateSlider = HostMethods.Slider
HostMethods.CreateTextbox = HostMethods.Textbox
HostMethods.CreateDropdown = HostMethods.Dropdown
HostMethods.CreateKeybind = HostMethods.Keybind
HostMethods.CreateColorpicker = HostMethods.Colorpicker
HostMethods.CreateLabel = HostMethods.Label
HostMethods.CreateParagraph = HostMethods.Paragraph
HostMethods.CreateDivider = HostMethods.Divider

return Library
