-- Example LocalScript for CUCUMBER UI.
-- Replace the require line with your own library loader when publishing it.

local Cucumber = require(path.to.CUCUMBER) -- Example only; replace with your ModuleScript path.

local Window = Cucumber.new({
    Name = "CUCUMBER",
    Subtitle = "MOVEMENT",
    Accent = Color3.fromRGB(51, 192, 106),
    Size = UDim2.fromOffset(430, 340),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main")
local Movement = Main:CreateSection("Movement")

local speedToggle = Movement:Toggle({
    Name = "Enable speed",
    Default = false,
    Callback = function(enabled)
        print("Speed enabled:", enabled)
    end,
})

local speedSlider = Movement:Slider({
    Name = "Walk speed",
    Min = 8,
    Max = 32,
    Step = 1,
    Default = 16,
    Callback = function(value)
        print("Walk speed:", value)
    end,
})

local messageBox = Movement:Textbox({
    Name = "Message",
    Placeholder = "Type and press Enter...",
    Callback = function(value, enterPressed)
        if enterPressed then
            Window:Notify("Textbox", "Entered: " .. value, 3)
        end
    end,
})

Movement:Dropdown({
    Name = "Mode",
    Options = { "Normal", "Quiet", "Fast" },
    Default = "Normal",
    Callback = function(value)
        print("Mode:", value)
    end,
})

Movement:Keybind({
    Name = "Toggle speed",
    Default = Enum.KeyCode.G,
    Callback = function()
        speedToggle:Toggle()
    end,
})

Movement:Colorpicker({
    Name = "Accent color",
    Default = Color3.fromRGB(51, 192, 106),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

local Misc = Window:CreateTab("Misc")
local Info = Misc:CreateSection("Info")
local status = Info:Paragraph({
    Title = "Ready",
    Content = "Small, dark, and event-driven. No permanent RenderStepped loop is used.",
})

Info:Button({
    Name = "Show notification",
    Callback = function()
        Window:Notify("CUCUMBER", "Notification example.", 3)
    end,
})

Info:Button({
    Name = "Change toggle name",
    Callback = function()
        speedToggle:SetName("Speed (renamed)")
    end,
})

Info:Button({
    Name = "Set slider to 24",
    Callback = function()
        speedSlider:Set(24)
    end,
})

Info:Button({
    Name = "Destroy UI",
    Callback = function()
        Window:Destroy() -- Disconnects events, cancels notifications, destroys the ScreenGui.
    end,
})

Window:Notify("Loaded", "Press RightShift to hide/show the window.", 4)
