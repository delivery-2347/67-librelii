# CUCUMBER UI

Компактная Roblox Luau GUI-библиотека в чёрном стиле с зелёным акцентом. Интерфейс специально сделан небольшим: квадратные углы, тонкие границы, плотные отступы и минимум лишних декоративных элементов.

- Вкладки и секции.
- Кнопка, toggle, slider, textbox, dropdown, keybind, colorpicker, label, paragraph и divider.
- У элементов есть методы `Set()`, `Get()`, `SetName()` и другие подходящие методы.
- Уведомления в правом нижнем углу: одновременно показывается максимум четыре.
- Перетаскивание окна мышью, кнопка `X`, скрытие по `RightShift` и закрытие по `Escape`.
- `Close()` скрывает окно, `Open()` открывает его снова, `Destroy()` отключает соединения и удаляет GUI.
- Нет постоянного `while true`, `RenderStepped` или `Heartbeat` цикла.
- Колбэки обёрнуты в `pcall`, чтобы ошибка пользовательского callback не ломала интерфейс.

## Установка

```lua
local Cucumber = loadstring(game:HttpGet("https://raw.githubusercontent.com/delivery-2347/67-librelii/refs/heads/main/CUCUMBER.lua"))
```

Библиотеку нужно создавать на клиенте: она использует `Players.LocalPlayer` и `PlayerGui`.

### Через GitHub

Загрузи `CUCUMBER.lua` в репозиторий и используй raw-ссылку на опубликованный файл только в среде, где разрешены `game:HttpGet` и `loadstring`. Эти функции не являются стандартным способом загрузки кода в обычном Roblox-опыте; для обычного проекта лучше использовать `ModuleScript`.

## Быстрый пример

```lua
local Cucumber = loadstring(game:HttpGet("https://raw.githubusercontent.com/delivery-2347/67-librelii/refs/heads/main/CUCUMBER.lua"))

local Window = Cucumber.new({
    Name = "CUCUMBER",
    Subtitle = "MOVEMENT",
    Accent = Color3.fromRGB(51, 192, 106),
    Size = UDim2.fromOffset(430, 340),
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main")
local Section = Main:CreateSection("General")

local toggle = Section:Toggle({
    Name = "Enabled",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})

local slider = Section:Slider({
    Name = "Power",
    Min = 0,
    Max = 100,
    Step = 1,
    Default = 25,
    Suffix = "%",
    Callback = function(value)
        print("Slider:", value)
    end,
})

local textbox = Section:Textbox({
    Name = "Message",
    Placeholder = "Type something...",
    Callback = function(value, enterPressed)
        if enterPressed then
            Window:Notify("Message", value, 3)
        end
    end,
})

Section:Button({
    Name = "Notify",
    Callback = function()
        Window:Notify("CUCUMBER", "It works!", 3)
    end,
})
```

## Элементы и методы

Все параметры элемента передаются одной таблицей. Все имена параметров чувствительны к регистру.

| Создание | Основные параметры | Методы результата |
|---|---|---|
| `Section:Button({...})` | `Name`, `Callback` | `SetName(name)`, `SetCallback(fn)`, `SetDisabled(bool)`, `Destroy()` |
| `Section:Toggle({...})` | `Name`, `Default`, `Callback` | `Set(value, silent?)`, `Get()`, `Toggle()`, `SetName(name)`, `SetCallback(fn)` |
| `Section:Slider({...})` | `Name`, `Min`, `Max`, `Step`, `Default`, `Suffix`, `Format`, `Callback` | `Set(value, silent?)`, `Get()`, `SetName(name)`, `SetCallback(fn)` |
| `Section:Textbox({...})` | `Name`, `Default`, `Placeholder`, `ClearOnFocus`, `Callback`, `Changed` | `Set(value, silent?)`, `Get()`, `SetName(name)`, `SetPlaceholder(text)`, `SetCallback(fn)` |
| `Section:Dropdown({...})` | `Name`, `Options`, `Default`, `Callback` | `Set(value, silent?)`, `Get()`, `SetName(name)`, `SetOptions(list)`, `SetCallback(fn)` |
| `Section:Keybind({...})` | `Name`, `Default`, `Callback` | `Set(keyCode)`, `Get()`, `SetName(name)`, `SetCallback(fn)` |
| `Section:Colorpicker({...})` | `Name`, `Default` (`Color3`), `Callback` | `Set(color3OrHex, silent?)`, `Get()`, `SetName(name)`, `SetCallback(fn)` |
| `Section:Label({...})` | `Text` или `Name`, опционально `Color` | `Set(text)`, `SetName(text)` |
| `Section:Paragraph({...})` | `Title`, `Content` | `Set(content)`, `SetContent(content)`, `SetTitle(title)`, `SetName(title)` |
| `Section:Divider()` | — | `Destroy()` |

Все элементы также имеют `Destroy()`, кроме тех, у которых метод не указан явно в таблице. `Set(value, true)` обновляет значение без вызова `Callback` там, где поддерживается параметр `silent`.

### Toggle — изменение значения и названия

```lua
local toggle = Section:Toggle({
    Name = "Auto run",
    Default = false,
    Callback = function(value)
        print(value)
    end,
})

toggle:Set(true)                 -- установить true и вызвать Callback
toggle:Set(false, true)          -- установить false без Callback
toggle:Toggle()                  -- переключить значение
print(toggle:Get())
toggle:SetName("Auto run [NEW]")
```

### Slider — диапазон, шаг и программная установка

```lua
local slider = Section:Slider({
    Name = "Speed",
    Min = 8,
    Max = 32,
    Step = 0.5,
    Default = 16,
    Suffix = " stud/s",
    Callback = function(value)
        print(value)
    end,
})

slider:Set(24)
slider:SetName("Player speed")
print(slider:Get())
```

`Step` округляет пользовательское значение к ближайшему шагу. `Suffix` добавляет короткий текст справа от значения. Для собственного форматирования можно передать `Format = function(value) return ... end`.

### Textbox — установка текста и изменение по вводу

```lua
local textbox = Section:Textbox({
    Name = "Command",
    Default = "hello",
    Placeholder = "Enter command...",
    Changed = function(value)
        print("Typing:", value) -- вызывается при изменении текста
    end,
    Callback = function(value, enterPressed)
        if enterPressed then
            print("Submitted:", value)
        end
    end,
})

textbox:Set("new text")
textbox:SetName("Chat message")
print(textbox:Get())
```

`Callback(value, enterPressed)` вызывается при потере фокуса. `enterPressed` равен `true`, когда пользователь нажал Enter. Не передавай чувствительные данные через GUI-текстбоксы.

### Dropdown — варианты и обновление списка

```lua
local dropdown = Section:Dropdown({
    Name = "Mode",
    Options = { "Normal", "Quiet", "Fast" },
    Default = "Normal",
    Callback = function(value)
        print("Selected:", value)
    end,
})

dropdown:Set("Fast")
dropdown:SetOptions({ "Normal", "Fast", "Ultra" })
dropdown:SetName("Movement mode")
```

### Keybind — вызов действия клавишей

```lua
local keybind = Section:Keybind({
    Name = "Toggle feature",
    Default = Enum.KeyCode.G,
    Callback = function(keyCode)
        print("Pressed:", keyCode.Name)
    end,
})

keybind:Set(Enum.KeyCode.H)
keybind:SetName("New key")
```

Нажми на поле с клавишей, затем нажми клавишу, которую хочешь назначить. `Escape` отменяет назначение. Во время ввода текста горячие клавиши библиотеки не срабатывают.

### Colorpicker — цвет и hex

```lua
local picker = Section:Colorpicker({
    Name = "Accent",
    Default = Color3.fromRGB(51, 192, 106),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

picker:Set(Color3.fromRGB(90, 140, 255))
picker:Set("33C06A")
picker:SetName("Theme color")
```

Цвет можно выбрать, введя hex-код в раскрывающейся панели. `Window:SetAccent(Color3)` обновляет акцент интерфейса.

## Окно и уведомления

```lua
Window:Notify("Loaded", "Interface is ready.", 3)
Window:SetTitle("My GUI")
Window:SetSubtitle("v1.0")
Window:SetAccent(Color3.fromRGB(51, 192, 106))
Window:SetSize(UDim2.fromOffset(450, 360))

Window:Close()   -- скрыть, не уничтожая
Window:Open()    -- показать снова
Window:Toggle()  -- переключить видимость
Window:Destroy() -- удалить GUI и очистить соединения
```

Опции `Cucumber.new({...})`:

| Опция | Значение по умолчанию | Назначение |
|---|---|---|
| `Name` | `CUCUMBER` | Заголовок окна |
| `Subtitle` | `UI LIBRARY` | Подзаголовок |
| `Accent` | `Color3.fromRGB(51, 192, 106)` | Цвет акцента |
| `Size` | `UDim2.fromOffset(430, 340)` | Размер окна |
| `Position` | по центру экрана | Начальная позиция окна |
| `ToggleKey` | `Enum.KeyCode.RightShift` | Клавиша показать/скрыть; `false` отключает горячую клавишу |
| `Parent` | `LocalPlayer.PlayerGui` | Родительский объект `ScreenGui` |
| `DisplayOrder` | `50` | Приоритет отображения |
| `GuiName` | `CUCUMBER_UI` | Имя `ScreenGui` |

## Советы

- Сохраняй объект, который вернул `Toggle`, `Slider` или другой элемент, если хочешь потом менять его из callback-кода.
- `Close()` не отключает callback-и: окно можно открыть снова. Для окончательного удаления вызывай `Destroy()`.
- Не создавай десятки одинаковых окон. Одно окно с несколькими вкладками обычно проще и легче.
- Библиотека отвечает за интерфейс. Код в `Callback` — твоя логика; например, `Slider` сообщает новое значение, но сам по себе не меняет характеристики персонажа.

## full

```lua
--[[
    CUCUMBER UI — FULL FEATURE DEMO
    Paste into a client LocalScript, or run in an environment where
    game:HttpGet + loadstring are available.

    Demonstrates every control, callbacks, setters, notifications,
    window methods, changing names/values, and cleanup.
]]

local URL = "https://raw.githubusercontent.com/delivery-2347/67-librelii/refs/heads/main/CUCUMBER.lua"

local ok, Cucumber = pcall(function()
    local source = game:HttpGet(URL)
    local chunk = assert(loadstring(source), "Could not compile CUCUMBER.lua")
    return chunk()
end)

if not ok then
    warn("[CUCUMBER DEMO] Library load failed: " .. tostring(Cucumber))
    return
end

if type(Cucumber) ~= "table" or type(Cucumber.new) ~= "function" then
    warn("[CUCUMBER DEMO] The URL did not return a CUCUMBER UI library table.")
    return
end

local Window = Cucumber.new({
    Name = "CUCUMBER",
    Subtitle = "FULL FEATURE DEMO",
    Accent = Color3.fromRGB(51, 192, 106),
    Size = UDim2.fromOffset(430, 350),
    ToggleKey = Enum.KeyCode.RightShift,
})

--// Main tab: one example of every visual control.
local Main = Window:CreateTab("Main")
local Controls = Main:CreateSection("CONTROLS")

local statusLabel = Controls:Label({
    Text = "Status: ready",
    Color = Color3.fromRGB(51, 192, 106),
})

local info = Controls:Paragraph({
    Title = "CUCUMBER UI",
    Content = "Compact black GUI, green accent, tabs, controls, callbacks and cleanup.",
})

local enabledToggle = Controls:Toggle({
    Name = "Example toggle",
    Default = false,
    Callback = function(value)
        statusLabel:Set("Toggle: " .. tostring(value))
        print("[DEMO] Toggle value:", value)
    end,
})

local powerSlider = Controls:Slider({
    Name = "Power",
    Min = 0,
    Max = 100,
    Step = 5,
    Default = 35,
    Suffix = "%",
    Callback = function(value)
        print("[DEMO] Slider value:", value)
    end,
})

local messageBox = Controls:Textbox({
    Name = "Textbox",
    Default = "Hello, CUCUMBER!",
    Placeholder = "Type and press Enter...",
    Changed = function(value)
        -- Called as text changes; keep this lightweight.
        print("[DEMO] Text changed:", value)
    end,
    Callback = function(value, enterPressed)
        if enterPressed then
            Window:Notify("Textbox submitted", value, 3)
        end
    end,
})

local modeDropdown = Controls:Dropdown({
    Name = "Mode",
    Options = { "Normal", "Quiet", "Fast" },
    Default = "Normal",
    Callback = function(value)
        statusLabel:Set("Mode: " .. tostring(value))
        print("[DEMO] Dropdown value:", value)
    end,
})

local actionKeybind = Controls:Keybind({
    Name = "Demo action",
    Default = Enum.KeyCode.G,
    Callback = function(keyCode)
        enabledToggle:Toggle()
        Window:Notify("Keybind", keyCode.Name .. " pressed", 2)
    end,
})

local accentPicker = Controls:Colorpicker({
    Name = "Accent color",
    Default = Color3.fromRGB(51, 192, 106),
    Callback = function(color)
        Window:SetAccent(color)
    end,
})

Controls:Divider()

local notifyButton = Controls:Button({
    Name = "Show notification",
    Callback = function()
        Window:Notify("CUCUMBER UI", "Notifications work!", 3)
    end,
})

--// Methods tab: examples of changing existing controls after creation.
local Methods = Window:CreateTab("Methods")
local ChangeValues = Methods:CreateSection("CHANGE VALUES")

ChangeValues:Button({
    Name = "Set toggle ON + rename",
    Callback = function()
        enabledToggle:Set(true)
        enabledToggle:SetName("Example toggle (renamed)")
        Window:Notify("Set() / SetName()", "Toggle is now ON", 2)
    end,
})

ChangeValues:Button({
    Name = "Set slider to 75",
    Callback = function()
        powerSlider:Set(75)
        powerSlider:SetName("Power (changed)")
        print("[DEMO] Current slider:", powerSlider:Get())
    end,
})

ChangeValues:Button({
    Name = "Set textbox text",
    Callback = function()
        messageBox:Set("Changed from code", true)
        messageBox:SetName("Textbox (changed)")
        messageBox:SetPlaceholder("Placeholder can change too...")
        print("[DEMO] Textbox value:", messageBox:Get())
    end,
})

ChangeValues:Button({
    Name = "Replace dropdown options",
    Callback = function()
        modeDropdown:SetOptions({ "Normal", "Fast", "Turbo" })
        modeDropdown:Set("Turbo")
        modeDropdown:SetName("Updated mode")
        print("[DEMO] Dropdown value:", modeDropdown:Get())
    end,
})

ChangeValues:Button({
    Name = "Set keybind to H",
    Callback = function()
        actionKeybind:Set(Enum.KeyCode.H)
        actionKeybind:SetName("Demo action (H)")
        print("[DEMO] Keybind:", actionKeybind:Get().Name)
    end,
})

ChangeValues:Button({
    Name = "Set accent to blue",
    Callback = function()
        accentPicker:Set(Color3.fromRGB(90, 140, 255))
        accentPicker:SetName("Blue accent")
    end,
})

ChangeValues:Button({
    Name = "Change label + paragraph",
    Callback = function()
        statusLabel:Set("Status: updated by code")
        statusLabel:SetName("Current status: OK")
        info:SetTitle("Content changed")
        info:SetContent("Label:Set(), Paragraph:SetTitle() and Paragraph:SetContent() were called.")
    end,
})

ChangeValues:Button({
    Name = "Rename notification button",
    Callback = function()
        notifyButton:SetName("Notification button (renamed)")
        notifyButton:SetCallback(function()
            Window:Notify("Updated callback", "Button:SetCallback() also works.", 3)
        end)
    end,
})

ChangeValues:Button({
    Name = "Temporarily disable notification button",
    Callback = function()
        notifyButton:SetDisabled(true)
        Window:Notify("Button disabled", "Run the enable button below to restore it.", 3)
    end,
})

ChangeValues:Button({
    Name = "Enable notification button",
    Callback = function()
        notifyButton:SetDisabled(false)
    end,
})

--// Window tab: window methods and lifecycle.
local WindowTab = Window:CreateTab("Window")
local WindowActions = WindowTab:CreateSection("WINDOW METHODS")

WindowActions:Button({
    Name = "Change title and subtitle",
    Callback = function()
        Window:SetTitle("CUCUMBER UI")
        Window:SetSubtitle("TITLE UPDATED")
    end,
})

WindowActions:Button({
    Name = "Resize window",
    Callback = function()
        Window:SetSize(UDim2.fromOffset(470, 370))
    end,
})

WindowActions:Button({
    Name = "Restore window size",
    Callback = function()
        Window:SetSize(UDim2.fromOffset(430, 350))
    end,
})

WindowActions:Button({
    Name = "Toggle window visibility",
    Callback = function()
        Window:Toggle()
    end,
})

WindowActions:Button({
    Name = "Hide window (RightShift to reopen)",
    Callback = function()
        Window:Close()
    end,
})

WindowActions:Button({
    Name = "Destroy UI (permanent)",
    Callback = function()
        Window:Destroy()
    end,
})

--// Final setup notification.
Window:Notify("Loaded", "RightShift: show/hide | G: toggle example | Esc: close", 5)
print("[CUCUMBER DEMO] Loaded. RightShift shows/hides the window; G toggles the example toggle.")
```
