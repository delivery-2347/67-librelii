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
