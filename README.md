# 🎨 Kitsu UI Library

A modern, feature-rich UI library for Roblox executors with a sleek dark theme and comprehensive configuration management.

![Version](https://img.shields.io/badge/version-3.2.0-ff0055)
![License](https://img.shields.io/badge/license-MIT-blue)
![Roblox](https://img.shields.io/badge/platform-Roblox-00a2ff)

## ✨ Features

- **Modern Dark Theme** - Sleek, minimalist interface with accent colors
- **Mobile Support** - Fully functional on touch devices
- **Save Manager** - Built-in configuration save/load system
- **Collapsible Categories** - Organized tab structure
- **Smooth Animations** - TweenService-powered transitions
- **Notification System** - Toast-style notifications
- **Toggle Keybind** - Press RightShift to show/hide (customizable)
- **Draggable Interface** - Move the window anywhere on screen

## 📦 Installation

### Method 1: Direct Load
```lua
local Library = loadstring(game:HttpGet("YOUR_LIBRARY_URL_HERE"))()
local SaveManager = loadstring(game:HttpGet("YOUR_SAVEMANAGER_URL_HERE"))()
```

### Method 2: Local Files
Download both files and load them from your executor's workspace.

## 🚀 Quick Start

```lua
-- Initialize the library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/NeziaReal/autoparry/refs/heads/main/ethossuite.lua"))()

-- Create main window
local Window = Library:New({
    Title = "KITSU",
    GameName = "Universal"  -- Optional game tag
})

-- Create a tab
local Tab = Window:CreateTab("Main", "Home")

-- Create a section
local Section = Tab:CreateSection("Features")

-- Add elements
Section:CreateToggle("Auto Farm", "Automatically farms resources", false, function(value)
    print("Auto Farm:", value)
end)

Section:CreateSlider("Speed", "Movement speed", 16, 100, 50, function(value)
    print("Speed:", value)
end)
```

## 📚 Full Documentation

### Window Creation

```lua
local Window = Library:New({
    Title = "KITSU",      -- Main title (default: "KITSU")
    GameName = "Game"     -- Optional game tag shown next to title
})
```

### Tabs & Categories

Tabs are organized under categories for better structure:

```lua
-- Syntax: Window:CreateTab(category, tabName)
local MainTab = Window:CreateTab("Main", "Home")
local CombatTab = Window:CreateTab("Main", "Combat")
local SettingsTab = Window:CreateTab("Settings", "Configuration")
```

Categories auto-create with collapse/expand functionality.

### Sections

Sections group related elements within a tab:

```lua
local Section = Tab:CreateSection("Section Title")
```

### UI Elements

#### Toggle
```lua
Section:CreateToggle(
    "Toggle Name",           -- Title
    "Description text",      -- Description (optional)
    false,                   -- Default state (true/false)
    function(value)          -- Callback function
        print(value)
    end,
    "MyToggle"              -- Flag (optional, auto-generated if not provided)
)
```

#### Slider
```lua
Section:CreateSlider(
    "Slider Name",          -- Title
    "Description",          -- Description (optional)
    0,                      -- Minimum value
    100,                    -- Maximum value
    50,                     -- Default value
    function(value)         -- Callback function
        print(value)
    end,
    "MySlider"             -- Flag (optional)
)
```

#### Button
```lua
Section:CreateButton(
    "Button Name",          -- Title
    "Description",          -- Description (optional)
    function()              -- Callback function
        print("Button clicked!")
    end
)
```

#### Dropdown
```lua
Section:CreateDropdown(
    "Dropdown Name",                    -- Title
    "Description",                      -- Description (optional)
    {"Option 1", "Option 2", "Option 3"}, -- Options list
    "Option 1",                         -- Default selection
    function(value)                     -- Callback function
        print("Selected:", value)
    end,
    "MyDropdown"                       -- Flag (optional)
)
```

#### Text Input
```lua
Section:CreateInput(
    "Input Name",           -- Title
    "Description",          -- Description (optional)
    "Placeholder text",     -- Placeholder
    function(value)         -- Callback function
        print("Input:", value)
    end,
    "MyInput"              -- Flag (optional)
)
```

#### Keybind
```lua
Section:CreateKeybind(
    "Keybind Name",             -- Title
    "Description",              -- Description (optional)
    Enum.KeyCode.E,             -- Default key
    function()                  -- Callback function
        print("Key pressed!")
    end,
    "MyKeybind"                -- Flag (optional)
)
```

#### Label
```lua
Section:CreateLabel("This is informational text")
```

## 💾 Save Manager

The Save Manager allows users to save and load their configurations.

### Setup

```lua
-- Load SaveManager
local SaveManager = loadstring(game:HttpGet("YOUR_SAVEMANAGER_URL"))()

-- Initialize with library
SaveManager:SetLibrary(Library)

-- Set folder name (optional)
SaveManager:SetFolder("MyScriptConfigs")

-- Build config UI (adds config section to a tab)
local SettingsTab = Window:CreateTab("Settings", "Configuration")
SaveManager:BuildConfigSection(SettingsTab)

-- Enable autoload (call after all elements are created)
task.spawn(function()
    SaveManager:Autoload()
end)
```

### Manual Save/Load

```lua
-- Save current settings
SaveManager:Save("MyConfig")

-- Load settings
SaveManager:Load("MyConfig")

-- Delete config
SaveManager:Delete("MyConfig")

-- List all configs
local configs = SaveManager:ListConfigs()
for _, name in pairs(configs) do
    print(name)
end

-- Set autoload config
SaveManager:SetAutoload("MyConfig")

-- Clear autoload
SaveManager:ClearAutoload()
```

### Ignoring Flags

Prevent specific flags from being saved:

```lua
SaveManager:SetIgnoreIndexes({
    "TempValue",
    "DontSaveThis"
})
```

## 🎯 Advanced Usage

### Accessing Flag Values

```lua
-- Get current value
local value = Library.Flags["MyToggle"]

-- Set value programmatically
Library.Options["MyToggle"]:Set(true)

-- Get value using element reference
local toggle = Section:CreateToggle("Test", "", false, function() end)
local currentValue = toggle:Get()
toggle:Set(true)
```

### Custom Toggle Key

```lua
-- Change the UI toggle key (default: RightShift)
Library.ToggleKey = Enum.KeyCode.RightControl
```

### Notifications

```lua
Library:Notify(
    "Title",           -- Notification title
    "Message text",    -- Message content
    5                  -- Duration in seconds (default: 3)
)
```

### Window Controls

```lua
-- Toggle window visibility
Window:Toggle()

-- Unload (destroy) the UI
Window:Unload()

-- Global toggle/unload
Library:Toggle()
Library:Unload()
```

## 🎨 Customization

### Theme Colors

Edit the `Theme` table in the library file:

```lua
local Theme = {
    Main        = Color3.fromRGB(10, 10, 10),
    Sidebar     = Color3.fromRGB(10, 10, 10), 
    Section     = Color3.fromRGB(16, 16, 16), 
    Stroke      = Color3.fromRGB(35, 35, 35),
    Separator   = Color3.fromRGB(25, 25, 25),
    Text        = Color3.fromRGB(240, 240, 240),
    TextDim     = Color3.fromRGB(100, 100, 100),
    TextHover   = Color3.fromRGB(240, 240, 240),
    Divider     = Color3.fromRGB(25, 25, 25)
}
```

### Accent Color

```lua
local UI_CONFIG = {
    Title = "KITSU",
    GameName = "",
    Accent = Color3.fromRGB(255, 0, 85),  -- Main accent color
    FontMain = Enum.Font.GothamBold,
    FontBody = Enum.Font.GothamMedium,
}
```

## 📋 Complete Example

```lua
-- Load library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/NeziaReal/autoparry/refs/heads/main/ethossuite.lua"))()
local SaveManager = loadstring(game:HttpGet("SAVEMANAGER_URL"))()

-- Create window
local Window = Library:New({
    Title = "My Script",
    GameName = "Universal"
})

-- Main tab
local MainTab = Window:CreateTab("Main", "Home")
local MainSection = MainTab:CreateSection("Main Features")

-- Auto farm toggle
local autoFarmEnabled = false
MainSection:CreateToggle("Auto Farm", "Automatically farms resources", false, function(value)
    autoFarmEnabled = value
    Library:Notify("Auto Farm", value and "Enabled" or "Disabled", 2)
end, "AutoFarm")

-- Speed slider
MainSection:CreateSlider("Walk Speed", "Your movement speed", 16, 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end, "WalkSpeed")

-- Weapon dropdown
MainSection:CreateDropdown("Weapon", "Select your weapon", 
    {"Sword", "Gun", "Bow"}, 
    "Sword", 
    function(value)
        print("Selected weapon:", value)
    end, 
    "SelectedWeapon"
)

-- Settings tab
local SettingsTab = Window:CreateTab("Settings", "Configuration")
local SettingsSection = SettingsTab:CreateSection("Script Settings")

-- UI toggle keybind
SettingsSection:CreateKeybind("Toggle UI", "Key to show/hide UI", 
    Enum.KeyCode.RightShift, 
    function()
        Library:Toggle()
    end, 
    "ToggleKey"
)

-- Save Manager
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScriptConfigs")
SaveManager:BuildConfigSection(SettingsTab)

-- Autoload
task.spawn(function()
    task.wait(1)
    SaveManager:Autoload()
end)

-- Notification
Library:Notify("Script Loaded", "Welcome to My Script v1.0!", 5)
```

## 🔧 Executor Compatibility

This library has been tested and works with:
- ✅ Synapse X / Synapse Z
- ✅ Script-Ware
- ✅ Krnl
- ✅ Fluxus
- ✅ Arceus X (Mobile)
- ✅ Delta (iOS)

## 📱 Mobile Support

The library automatically detects mobile devices and adjusts touch input handling. All elements are fully functional on mobile executors.

## ⚠️ Important Notes

1. **Flag Naming**: Flags are auto-generated from element names by removing spaces. For consistency, always provide custom flags.
2. **Save Manager**: Elements are automatically registered in `Library.Options` - no manual registration needed.
3. **Callbacks**: All callbacks run in protected mode (`pcall`) to prevent errors from breaking the UI.
4. **Performance**: The library uses efficient event handling and TweenService for smooth performance.

## 🐛 Troubleshooting

### UI doesn't appear
```lua
-- Ensure you're calling Library:New()
local Window = Library:New({ Title = "Test" })
```

### Configs not saving
```lua
-- Make sure SaveManager is initialized
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("YourFolderName")
```

### Elements not updating
```lua
-- Use the Set method instead of direct flag assignment
Library.Options["MyToggle"]:Set(true)
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📞 Support

For support, questions, or feature requests:
- Open an issue on GitHub
- Join our Discord server (if applicable)

---

**Made with ❤️ for the Roblox scripting community**

**Star ⭐ this repository if you find it useful!**
