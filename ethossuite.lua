--[[ 
    KITSU UI LIBRARY - ULTRA COMPACT VERSION
    Matches the second reference image exactly
    
    FIXES:
    - Removed sidebar tab indentation (no PaddingLeft on tabs)
    - Increased section header size from 11 to 13
    - Made section headers bolder and more prominent
    - Improved separator line visibility
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}
Library.Flags = {}
Library.FlagCallbacks = {}
Library.Options = {}  -- Store all UI element objects for SaveManager
Library.ToggleKey = Enum.KeyCode.RightShift  -- Default toggle key
Library.Visible = true

--// MOBILE DETECTION
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--// CONFIGURATION
local UI_CONFIG = {
    Title = "KITSU",
    GameName = "",
    Accent = Color3.fromRGB(255, 0, 85),
    FontMain = Enum.Font.GothamBold,
    FontBody = Enum.Font.GothamMedium,
}

--// THEME PALETTE
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

--// UTILS
local function Create(instance, properties, children)
    local obj = Instance.new(instance)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    if children then
        for _, child in pairs(children) do
            child.Parent = obj
        end
    end
    return obj
end

local function ApplyStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Parent = parent
    stroke.Color = color or Theme.Stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

--// HOVER EFFECT HELPER
local function AddHoverEffect(textLabel, normalColor, hoverColor)
    if not textLabel then return end
    
    normalColor = normalColor or Theme.TextDim
    hoverColor = hoverColor or Theme.TextHover
    
    local parent = textLabel.Parent
    if parent and parent:IsA("GuiButton") then
        parent.MouseEnter:Connect(function()
            TweenService:Create(textLabel, TweenInfo.new(0.15), { TextColor3 = hoverColor }):Play()
        end)
        parent.MouseLeave:Connect(function()
            TweenService:Create(textLabel, TweenInfo.new(0.15), { TextColor3 = normalColor }):Play()
        end)
    end
end

--// DRAGGABLE LOGIC
local function MakeDraggable(topbar, main)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

--// NOTIFICATION SYSTEM
local NotificationHolder = nil

function Library:Notify(title, message, duration)
    if not NotificationHolder or not NotificationHolder.Parent then return end
    
    duration = duration or 3

    local NotifFrame = Create("Frame", {
        Parent = NotificationHolder,
        BackgroundColor3 = Theme.Section,
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundTransparency = 0.05,
        ZIndex = 200,
        ClipsDescendants = true
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 4) })
    })
    ApplyStroke(NotifFrame, Theme.Stroke, 1)

    Create("Frame", {
        Parent = NotifFrame,
        BackgroundColor3 = UI_CONFIG.Accent,
        Size = UDim2.new(0, 2, 1, 0),
        ZIndex = 201
    }, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

    Create("TextLabel", {
        Parent = NotifFrame,
        Text = title,
        Font = UI_CONFIG.FontMain,
        TextColor3 = Theme.Text,
        TextSize = 13,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(1, -20, 0, 15),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201
    })

    Create("TextLabel", {
        Parent = NotifFrame,
        Text = message,
        Font = UI_CONFIG.FontBody,
        TextColor3 = Theme.Text,
        TextSize = 11,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(1, -20, 0, 15),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201
    })
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, -NotifFrame.Size.X.Offset - 10, 0, 0) }):Play()

    task.delay(duration, function()
        if NotifFrame and NotifFrame.Parent then
            TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1, 20, 0, 0) }):Play()
            task.wait(0.3)
            if NotifFrame and NotifFrame.Parent then
                NotifFrame:Destroy()
            end
        end
    end)
end

--// KEYBIND GLOBAL HANDLER
local KeybindFunctions = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    for _, bind in pairs(KeybindFunctions) do
        if input.KeyCode == bind.Key or input.UserInputType == bind.Key then
            pcall(bind.Callback)
        end
    end
end)

--// MAIN LIBRARY
function Library:New(options)
    local Title = options.Title or UI_CONFIG.Title
    local GameName = options.GameName or UI_CONFIG.GameName
    
    local TargetParent = (RunService:IsStudio() and Players.LocalPlayer.PlayerGui) or CoreGui
    if TargetParent:FindFirstChild("KitsuComplete") then 
        TargetParent.KitsuComplete:Destroy() 
    end

    local ScreenGui = Create("ScreenGui", { 
        Name = "KitsuComplete", 
        Parent = TargetParent, 
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Main,
        Position = UDim2.new(0.5, -375, 0.5, -260),
        Size = UDim2.new(0, 750, 0, 520),
        ClipsDescendants = true
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) })
    })
    ApplyStroke(MainFrame, Theme.Stroke, 1)
    
    --// TOP BAR
    local TopBar = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        ZIndex = 10
    })
    MakeDraggable(TopBar, MainFrame)

    local Logo = Create("TextLabel", {
        Parent = TopBar,
        Text = Title,
        Font = Enum.Font.GothamBlack,
        TextColor3 = Theme.Text,
        TextSize = 22,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X
    })

    local GameTag, VerTag, ExecTag
    
    if GameName and GameName ~= "" then
        GameTag = Create("TextLabel", {
            Parent = TopBar,
            BackgroundColor3 = UI_CONFIG.Accent,
            Text = " " .. string.upper(GameName) .. " ",
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(10, 10, 10),
            TextSize = 11,
            Size = UDim2.new(0, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.X,
        }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    end

    VerTag = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Text = " v3.2.0 ",
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
    }, { 
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        ApplyStroke(nil, Theme.Stroke, 1)
    })

    ExecTag = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Text = " Executions: 70 ",
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Size = UDim2.new(0, 0, 0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
    }, { 
        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
        ApplyStroke(nil, Theme.Stroke, 1)
    })

    task.wait()
    local logoWidth = Logo.TextBounds.X
    
    if GameTag then
        GameTag.Position = UDim2.new(0, logoWidth + 30, 0, 16)
        VerTag.Position = UDim2.new(0, logoWidth + GameTag.AbsoluteSize.X + 40, 0, 16)
        ExecTag.Position = UDim2.new(0, logoWidth + GameTag.AbsoluteSize.X + VerTag.AbsoluteSize.X + 50, 0, 16)
    else
        VerTag.Position = UDim2.new(0, logoWidth + 30, 0, 16)
        ExecTag.Position = UDim2.new(0, logoWidth + VerTag.AbsoluteSize.X + 40, 0, 16)
    end

    local MinimizeBtn = Create("TextButton", {
        Parent = TopBar,
        Text = "−",
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.TextDim,
        TextSize = 24,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -60, 0, 12),
        Size = UDim2.new(0, 25, 0, 25),
        AutoButtonColor = false
    })
    
    MinimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
    end)
    MinimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    local CloseBtn = Create("TextButton", {
        Parent = TopBar,
        Text = "×",
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.TextDim,
        TextSize = 24,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 12),
        Size = UDim2.new(0, 25, 0, 25),
        AutoButtonColor = false
    })
    
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function() 
        ScreenGui:Destroy() 
    end)

    --// SIDEBAR
    local Sidebar = Create("ScrollingFrame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(0, 200, 1, -90),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingTop = UDim.new(0, 10) }),
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    })

    Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 200, 0, 60),
        Size = UDim2.new(0, 1, 1, -90)
    })

    --// PAGE CONTAINER
    local PageContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 201, 0, 60),
        Size = UDim2.new(1, -201, 1, -90),
        ClipsDescendants = true
    })

    --// FOOTER
    local Footer = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Color3.fromRGB(5, 5, 5),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -30),
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 20
    })
    
    Create("Frame", {
        Parent = Footer,
        BackgroundColor3 = Theme.Divider,
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0
    })
    
    local ChatIconBox = Create("Frame", {
        Parent = Footer,
        BackgroundColor3 = Theme.Main,
        Position = UDim2.new(0, 10, 0.5, -18),
        Size = UDim2.new(0, 36, 0, 36),
        ZIndex = 21
    }, { 
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        ApplyStroke(nil, Theme.Stroke, 1)
    })
    
    Create("ImageLabel", {
        Parent = ChatIconBox,
        Image = "rbxassetid://18635456488",
        ImageColor3 = UI_CONFIG.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0.5, -10, 0.5, -10)
    })

    local FooterList = Create("Frame", {
        Parent = Footer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 60, 0, 0),
        Size = UDim2.new(1, -60, 1, 0)
    }, {
        Create("UIListLayout", { 
            FillDirection = Enum.FillDirection.Horizontal, 
            VerticalAlignment = Enum.VerticalAlignment.Center, 
            Padding = UDim.new(0, 20) 
        })
    })

    local function AddFooterItem(text, color)
        local Item = Create("Frame", {
            Parent = FooterList,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X
        })
        
        Create("Frame", {
            Parent = Item,
            BackgroundColor3 = color,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(0, 0, 0.5, -3)
        }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
        
        Create("TextLabel", {
            Parent = Item,
            Text = text,
            Font = Enum.Font.Gotham,
            TextColor3 = Theme.TextDim,
            TextSize = 10,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.X
        })
    end

    AddFooterItem("Equipped: Living Blade", Color3.fromRGB(150, 100, 255))
    AddFooterItem("IDLE", Color3.fromRGB(0, 255, 200))
    AddFooterItem("Connected to webserver", Color3.fromRGB(150, 100, 255))

    --// NOTIFICATION HOLDER
    NotificationHolder = Create("Frame", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -320, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        ZIndex = 199
    }, {
        Create("UIListLayout", { 
            SortOrder = Enum.SortOrder.LayoutOrder, 
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Top
        })
    })

    --// TABS & SECTIONS LOGIC
    local Window = {}
    local CurrentTab = nil
    local Categories = {}

    function Window:CreateTab(category, name)
        local CategoryData = Categories[category]
        
        if not CategoryData then
            local CatFrame = Create("Frame", {
                Name = "Cat_" .. category,
                Parent = Sidebar,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                LayoutOrder = #Categories * 1000
            })
            
            Create("TextLabel", {
                Parent = CatFrame,
                Text = string.upper(category),
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.Text,
                TextSize = 10,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -25, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ArrowBtn = Create("TextButton", {
                Name = "CollapseBtn",
                Parent = CatFrame,
                Text = "▲",
                TextColor3 = Theme.TextDim,
                TextSize = 8,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -20, 0, 0),
                Size = UDim2.new(0, 20, 1, 0),
                AutoButtonColor = false
            })
            
            local TabContainer = Create("Frame", {
                Name = "TabContainer",
                Parent = Sidebar,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = #Categories * 1000 + 1,
                ClipsDescendants = true
            }, {
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) })
            })
            
            CategoryData = {
                Frame = CatFrame,
                Arrow = ArrowBtn,
                Container = TabContainer,
                Expanded = true,
                Tabs = {}
            }
            table.insert(Categories, CategoryData)
            Categories[category] = CategoryData
            
            ArrowBtn.MouseButton1Click:Connect(function()
                CategoryData.Expanded = not CategoryData.Expanded
                
                TweenService:Create(ArrowBtn, TweenInfo.new(0.2), {
                    Rotation = CategoryData.Expanded and 0 or 180
                }):Play()
                
                if CategoryData.Expanded then
                    TabContainer.AutomaticSize = Enum.AutomaticSize.Y
                    for _, tab in pairs(CategoryData.Tabs) do
                        tab.Visible = true
                    end
                else
                    TabContainer.AutomaticSize = Enum.AutomaticSize.None
                    TweenService:Create(TabContainer, TweenInfo.new(0.2), {
                        Size = UDim2.new(1, 0, 0, 0)
                    }):Play()
                    for _, tab in pairs(CategoryData.Tabs) do
                        tab.Visible = false
                    end
                end
            end)
        else
            CategoryData = Categories[category]
        end

        -- FIXED: Removed PaddingLeft to align tabs properly
        local TabBtn = Create("TextButton", {
            Parent = CategoryData.Container,
            Text = name,
            Font = UI_CONFIG.FontBody,
            TextColor3 = Theme.TextDim,
            TextSize = 12,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = #CategoryData.Tabs
        })
        
        table.insert(CategoryData.Tabs, TabBtn)

        local Indicator = Create("Frame", {
            Parent = TabBtn,
            BackgroundColor3 = UI_CONFIG.Accent,
            Size = UDim2.new(0, 2, 0, 12),
            Position = UDim2.new(0, -10, 0.5, -6),
            Visible = false
        }, { Create("UICorner", { CornerRadius = UDim.new(0, 2) }) })

        TabBtn.MouseEnter:Connect(function()
            if CurrentTab and CurrentTab.Btn ~= TabBtn then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(180, 180, 180)}):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if CurrentTab and CurrentTab.Btn ~= TabBtn then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {TextColor3 = Theme.TextDim}):Play()
            end
        end)

        local Page = Create("ScrollingFrame", {
            Parent = PageContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Stroke,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        }, {
            Create("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 12) }),
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        })

        TabBtn.MouseButton1Click:Connect(function()
            if CurrentTab then
                TweenService:Create(CurrentTab.Btn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
                CurrentTab.Indicator.Visible = false
                CurrentTab.Page.Visible = false
            end
            
            CurrentTab = { Btn = TabBtn, Indicator = Indicator, Page = Page }
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            Indicator.Visible = true
            Page.Visible = true
        end)

        if not CurrentTab then
            CurrentTab = { Btn = TabBtn, Indicator = Indicator, Page = Page }
            TabBtn.TextColor3 = Theme.Text
            Indicator.Visible = true
            Page.Visible = true
        end

        local SectionFuncs = {}
        local SectionCount = 0

        function SectionFuncs:CreateSection(title)
            SectionCount = SectionCount + 1
            
            -- Add separator between sections (except first)
            if SectionCount > 1 then
                Create("Frame", {
                    Parent = Page,
                    BackgroundColor3 = Theme.Separator,
                    Size = UDim2.new(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    LayoutOrder = (SectionCount - 1) * 100 - 1
                })
            end
            
            local Box = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Theme.Section,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                LayoutOrder = SectionCount * 100
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                Create("UIPadding", { 
                    PaddingLeft = UDim.new(0, 15), 
                    PaddingRight = UDim.new(0, 15), 
                    PaddingBottom = UDim.new(0, 10), 
                    PaddingTop = UDim.new(0, 16) 
                }),
                Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
            })
            ApplyStroke(Box, Theme.Stroke, 1)

            -- FIXED: Increased section header size to 15 for better visibility
            Create("TextLabel", {
                Parent = Box,
                Text = string.upper(title),
                Font = Enum.Font.GothamBold,
                TextColor3 = Theme.TextDim,
                TextSize = 15,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 6),
                Size = UDim2.new(1, -30, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Elements = {}

            function Elements:CreateToggle(text, desc, default, callback, flag)
                flag = flag or text:gsub("%s+", "")
                Library.Flags[flag] = default or false
                
                local ToggleBtn = Create("TextButton", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 20
                })

                local TextLabel = Create("TextLabel", {
                    Parent = ToggleBtn,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -60, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local DescLabel = Create("TextLabel", {
                    Parent = ToggleBtn,
                    Text = desc or "",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 14),
                    Size = UDim2.new(1, -60, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true
                })
                
                AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)

                local ControlHolder = Create("Frame", {
                    Parent = ToggleBtn,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0, 60, 0, 24)
                })

                local GearBtn = Create("ImageButton", {
                    Parent = ControlHolder,
                    Image = "rbxassetid://6031280882",
                    ImageColor3 = UI_CONFIG.Accent,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7)
                })
                
                GearBtn.MouseEnter:Connect(function()
                    TweenService:Create(GearBtn, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(255, 100, 120)}):Play()
                end)
                GearBtn.MouseLeave:Connect(function()
                    TweenService:Create(GearBtn, TweenInfo.new(0.15), {ImageColor3 = UI_CONFIG.Accent}):Play()
                end)

                local Checkbox = Create("Frame", {
                    Parent = ControlHolder,
                    BackgroundColor3 = Theme.Main,
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(1, -18, 0.5, -9),
                }, { 
                    Create("UICorner", { CornerRadius = UDim.new(0, 4) }) 
                })
                local Stroke = ApplyStroke(Checkbox, Theme.Stroke, 1.2)

                local CheckIcon = Create("ImageLabel", {
                    Parent = Checkbox,
                    Image = "rbxassetid://6031094667",
                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(0.5, -6, 0.5, -6),
                    Visible = default
                })

                if default then
                    Checkbox.BackgroundColor3 = UI_CONFIG.Accent
                    Stroke.Color = UI_CONFIG.Accent
                end

                local active = default or false

                local function Toggle()
                    active = not active
                    CheckIcon.Visible = active
                    
                    if active then
                        TweenService:Create(Checkbox, TweenInfo.new(0.15), {BackgroundColor3 = UI_CONFIG.Accent}):Play()
                        Stroke.Color = UI_CONFIG.Accent
                    else
                        TweenService:Create(Checkbox, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Main}):Play()
                        Stroke.Color = Theme.Stroke
                    end
                    
                    Library.Flags[flag] = active
                    
                    if callback then 
                        Library.FlagCallbacks[flag] = callback
                        task.spawn(callback, active)
                    end
                end

                ToggleBtn.MouseButton1Click:Connect(Toggle)
                ToggleBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        Toggle()
                    end
                end)
                
                Create("UIPadding", { Parent = ToggleBtn, PaddingBottom = UDim.new(0, 2) })
                
                local element = {
                    Set = function(value)
                        if active ~= value then
                            Toggle()
                        end
                    end,
                    Get = function()
                        return active
                    end
                }
                
                Library.Options[flag] = element  -- Store for SaveManager
                return element
            end

            function Elements:CreateSlider(text, desc, min, max, default, callback, flag)
                flag = flag or text:gsub("%s+", "")
                Library.Flags[flag] = default
                
                local SliderFrame = Create("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 20
                })

                -- Label only (no value at top)
                Create("TextLabel", {
                    Parent = SliderFrame,
                    Text = text .. " (s)",
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 0, 12),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Description below label (tighter gap)
                local DescLabel = Create("TextLabel", {
                    Parent = SliderFrame,
                    Text = desc or "",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 13),
                    Size = UDim2.new(0.5, 0, 0, 10),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)

                -- Slider track background (darker) - positioned on the right side
                local Track = Create("TextButton", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                    AutoButtonColor = false,
                    Text = "",
                    Position = UDim2.new(0.5, 10, 0, 10),
                    Size = UDim2.new(0.5, -55, 0, 4),
                    BorderSizePixel = 0
                }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                -- Value label positioned next to the slider track (on the right)
                local ValueLabel = Create("TextLabel", {
                    Parent = SliderFrame,
                    Text = tostring(default),
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0, 12),
                    Size = UDim2.new(0, 40, 0, 12),
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local Percent = (default - min) / (max - min)

                -- Filled portion (accent color)
                local Fill = Create("Frame", {
                    Parent = Track,
                    BackgroundColor3 = UI_CONFIG.Accent,
                    Size = UDim2.new(Percent, 0, 1, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2
                }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                -- Knob (white circle)
                local Knob = Create("Frame", {
                    Parent = Track,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Size = UDim2.new(0, 12, 0, 12),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(Percent, 0, 0.5, 0),
                    BorderSizePixel = 0,
                    ZIndex = 3
                }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local currentValue = default
                local dragging = false
                
                local function Update(input)
                    local percent = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + (max - min) * percent * 100) / 100
                    
                    currentValue = val
                    Fill.Size = UDim2.new(percent, 0, 1, 0)
                    Knob.Position = UDim2.new(percent, 0, 0.5, 0)
                    ValueLabel.Text = tostring(val)
                    
                    Library.Flags[flag] = val
                    
                    if callback then 
                        Library.FlagCallbacks[flag] = callback
                        task.spawn(callback, val)
                    end
                end

                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Update(input)
                        TweenService:Create(Knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 14, 0, 14)}):Play()
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        Update(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
                        dragging = false
                        TweenService:Create(Knob, TweenInfo.new(0.1), {Size = UDim2.new(0, 12, 0, 12)}):Play()
                    end
                end)

                Create("UIPadding", { Parent = SliderFrame, PaddingBottom = UDim.new(0, 6) })
                
                local element = {
                    Set = function(value)
                        local clamped = math.clamp(value, min, max)
                        local percent = (clamped - min) / (max - min)
                        currentValue = clamped
                        Fill.Size = UDim2.new(percent, 0, 1, 0)
                        Knob.Position = UDim2.new(percent, 0, 0.5, 0)
                        ValueLabel.Text = tostring(clamped)
                        Library.Flags[flag] = clamped
                    end,
                    Get = function()
                        return currentValue
                    end
                }
                
                Library.Options[flag] = element  -- Store for SaveManager
                return element
            end

            function Elements:CreateLabel(text)
                Create("TextLabel", {
                    Parent = Box,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    ZIndex = 20
                })
            end


            function Elements:CreateButton(text, desc, callback)
                local BtnFrame = Create("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 20
                })

                -- Label on the left
                Create("TextLabel", {
                    Parent = BtnFrame,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -5, 0, 14),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Description below label (if provided)
                if desc and desc ~= "" then
                    local DescLabel = Create("TextLabel", {
                        Parent = BtnFrame,
                        Text = desc,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        TextSize = 10,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(0.5, -5, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true
                    })
                    AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)
                end

                -- Button on the right side (matching dropdown style)
                local Btn = Create("TextButton", {
                    Parent = BtnFrame,
                    BackgroundColor3 = Theme.Main,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0.5, -5, 0, 28),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 21
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) })
                })
                ApplyStroke(Btn, Theme.Stroke, 1)

                -- Button label centered inside
                local BtnLabel = Create("TextLabel", {
                    Parent = Btn,
                    Text = "Click",
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 22
                })

                -- Hover effect
                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), { 
                        BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
                    }):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.15), { 
                        TextColor3 = Color3.fromRGB(255, 255, 255) 
                    }):Play()
                end)

                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), { 
                        BackgroundColor3 = Theme.Main 
                    }):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.15), { 
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                end)

                -- Click effect
                Btn.MouseButton1Click:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.1), { 
                        BackgroundColor3 = UI_CONFIG.Accent 
                    }):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.1), { 
                        TextColor3 = Color3.fromRGB(255, 255, 255) 
                    }):Play()
                    
                    task.wait(0.15)
                    
                    TweenService:Create(Btn, TweenInfo.new(0.15), { 
                        BackgroundColor3 = Theme.Main 
                    }):Play()
                    TweenService:Create(BtnLabel, TweenInfo.new(0.15), { 
                    	TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    
                    if callback then pcall(callback) end
                end)
                
                -- Touch support for mobile
                Btn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch then
                        TweenService:Create(Btn, TweenInfo.new(0.1), { 
                            BackgroundColor3 = UI_CONFIG.Accent 
                        }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.1), { 
                            TextColor3 = Color3.fromRGB(255, 255, 255) 
                        }):Play()
                        
                        task.wait(0.15)
                        
                        TweenService:Create(Btn, TweenInfo.new(0.15), { 
                            BackgroundColor3 = Theme.Main 
                        }):Play()
                        TweenService:Create(BtnLabel, TweenInfo.new(0.15), { 
                            TextColor3 = UI_CONFIG.Accent 
                        }):Play()
                        
                        if callback then pcall(callback) end
                    end
                end)
                
                Create("UIPadding", { Parent = BtnFrame, PaddingBottom = UDim.new(0, 8) })
            end

            function Elements:CreateKeybind(text, desc, defaultKey, callback, flag)
                flag = flag or text:gsub("%s+", "")
                Library.Flags[flag] = defaultKey
                
                local KeybindFrame = Create("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 20
                })

                -- Label on the left
                Create("TextLabel", {
                    Parent = KeybindFrame,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -5, 0, 14),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Description below label
                if desc and desc ~= "" then
                    local DescLabel = Create("TextLabel", {
                        Parent = KeybindFrame,
                        Text = desc,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        TextSize = 10,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(0.5, -5, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true
                    })
                    AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)
                end

                -- Keybind button on the right
                local KeyBtn = Create("TextButton", {
                    Parent = KeybindFrame,
                    BackgroundColor3 = Theme.Main,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0.5, -5, 0, 28),
                    Text = defaultKey.Name or "None",
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 10,
                    AutoButtonColor = false,
                    ZIndex = 21
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) })
                })
                ApplyStroke(KeyBtn, Theme.Stroke, 1)

                local currentKey = defaultKey
                local listening = false
                
                KeybindFunctions[flag] = {
                    Key = currentKey,
                    Callback = callback
                }

                KeyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    KeyBtn.Text = "..."
                    
                    local connection
                    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = input.KeyCode
                            KeyBtn.Text = input.KeyCode.Name
                            Library.Flags[flag] = currentKey
                            KeybindFunctions[flag].Key = currentKey
                            listening = false
                            connection:Disconnect()
                        end
                    end)
                end)

                Create("UIPadding", { Parent = KeybindFrame, PaddingBottom = UDim.new(0, 8) })
                
                local element = {
                    Set = function(value)
                        currentKey = value
                        KeyBtn.Text = value.Name or "None"
                        Library.Flags[flag] = value
                        KeybindFunctions[flag].Key = value
                    end,
                    Get = function()
                        return currentKey
                    end
                }
                
                Library.Options[flag] = element  -- Store for SaveManager
                return element
            end

            function Elements:CreateDropdown(text, desc, options, default, callback, flag)
                flag = flag or text:gsub("%s+", "")
                Library.Flags[flag] = default or options[1]
                
                local DropdownFrame = Create("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 20
                })

                -- Label on the left
                Create("TextLabel", {
                    Parent = DropdownFrame,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -5, 0, 14),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Description below label
                if desc and desc ~= "" then
                    local DescLabel = Create("TextLabel", {
                        Parent = DropdownFrame,
                        Text = desc,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        TextSize = 10,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(0.5, -5, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true
                    })
                    AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)
                end

                -- Dropdown button on the right
                local DropBtn = Create("TextButton", {
                    Parent = DropdownFrame,
                    BackgroundColor3 = Theme.Main,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0.5, -5, 0, 28),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 21
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) })
                })
                ApplyStroke(DropBtn, Theme.Stroke, 1)

                local DropLabel = Create("TextLabel", {
                    Parent = DropBtn,
                    Text = default or options[1],
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -30, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })

                local Arrow = Create("TextLabel", {
                    Parent = DropBtn,
                    Text = "▼",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextSize = 9,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -10, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    ZIndex = 22
                })

                local OptionsFrame = Create("Frame", {
                    Parent = DropdownFrame,
                    BackgroundColor3 = Theme.Main,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 32),
                    Size = UDim2.new(0.5, -5, 0, 0),
                    Visible = false,
                    ZIndex = 30,
                    ClipsDescendants = true
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) })
                })
                ApplyStroke(OptionsFrame, Theme.Stroke, 1)

                local open = false

                for i, option in ipairs(options) do
                    local OptBtn = Create("TextButton", {
                        Parent = OptionsFrame,
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 24),
                        Text = option,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        TextSize = 10,
                        AutoButtonColor = false,
                        ZIndex = 31
                    })

                    OptBtn.MouseEnter:Connect(function()
                        OptBtn.BackgroundTransparency = 0
                        TweenService:Create(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.Text}):Play()
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        OptBtn.BackgroundTransparency = 1
                        TweenService:Create(OptBtn, TweenInfo.new(0.1), {TextColor3 = Theme.TextDim}):Play()
                    end)

                    OptBtn.MouseButton1Click:Connect(function()
                        DropLabel.Text = option
                        Library.Flags[flag] = option
                        if callback then
                            Library.FlagCallbacks[flag] = callback
                            pcall(callback, option)
                        end
                        
                        open = false
                        OptionsFrame.Visible = false
                        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        TweenService:Create(OptionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.5, -5, 0, 0)}):Play()
                    end)
                end

                DropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    OptionsFrame.Visible = open
                    
                    if open then
                        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
                        TweenService:Create(OptionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.5, -5, 0, #options * 24)}):Play()
                    else
                        TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        TweenService:Create(OptionsFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.5, -5, 0, 0)}):Play()
                    end
                end)

                Create("UIPadding", { Parent = DropdownFrame, PaddingBottom = UDim.new(0, 8) })
                
                local element = {
                    Set = function(value)
                        DropLabel.Text = value
                        Library.Flags[flag] = value
                        if callback then
                            pcall(callback, value)
                        end
                    end,
                    Get = function()
                        return Library.Flags[flag]
                    end
                }
                
                Library.Options[flag] = element  -- Store for SaveManager
                return element
            end

            function Elements:CreateInput(text, desc, placeholder, callback, flag)
                flag = flag or text:gsub("%s+", "")
                Library.Flags[flag] = ""
                
                local InputFrame = Create("Frame", {
                    Parent = Box,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 20
                })

                -- Label on the left
                Create("TextLabel", {
                    Parent = InputFrame,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, -5, 0, 14),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                -- Description below label
                if desc and desc ~= "" then
                    local DescLabel = Create("TextLabel", {
                        Parent = InputFrame,
                        Text = desc,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        TextSize = 10,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 14),
                        Size = UDim2.new(0.5, -5, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped = true
                    })
                    AddHoverEffect(DescLabel, Theme.TextDim, Theme.TextHover)
                end

                -- Input box on the right
                local InputBox = Create("TextBox", {
                    Parent = InputFrame,
                    BackgroundColor3 = Theme.Main,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.new(0.5, -5, 0, 28),
                    Text = "",
                    PlaceholderText = placeholder or "Enter text...",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.TextDim,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 21,
                    ClearTextOnFocus = false
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    Create("UIPadding", { 
                        PaddingLeft = UDim.new(0, 10), 
                        PaddingRight = UDim.new(0, 10) 
                    })
                })
                ApplyStroke(InputBox, Theme.Stroke, 1)

                InputBox.FocusLost:Connect(function()
                    Library.Flags[flag] = InputBox.Text
                    if callback then
                        Library.FlagCallbacks[flag] = callback
                        pcall(callback, InputBox.Text)
                    end
                end)

                Create("UIPadding", { 
                    Parent = InputFrame, 
                    PaddingBottom = UDim.new(0, 8) 
                })
                
                local element = {
                    Set = function(value)
                        InputBox.Text = value
                        Library.Flags[flag] = value
                        if callback then
                            pcall(callback, value)
                        end
                    end,
                    Get = function()
                        return InputBox.Text
                    end
                }
                
                Library.Options[flag] = element  -- Store for SaveManager
                return element
            end

            return Elements
        end
        
        SectionFuncs.AddSection = SectionFuncs.CreateSection
        
        return SectionFuncs
    end
    
    Window.AddTab = Window.CreateTab
    
    -- Toggle function - show/hide the UI
    function Window:Toggle()
        MainFrame.Visible = not MainFrame.Visible
        Library.Visible = MainFrame.Visible
    end
    
    -- Unload function - completely destroy the UI
    function Window:Unload()
        if ScreenGui then
            ScreenGui:Destroy()
        end
        Library.Visible = false
    end
    
    -- Store references for Library.Toggle and Library.Unload
    Library.MainFrame = MainFrame
    Library.ScreenGui = ScreenGui
    
    return Window
end

-- Add global toggle and unload functions
function Library:Toggle()
    if self.MainFrame then
        self.MainFrame.Visible = not self.MainFrame.Visible
        self.Visible = self.MainFrame.Visible
    end
end

function Library:Unload()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
        self.MainFrame = nil
    end
    self.Visible = false
end

-- Setup default toggle keybind (RightShift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Library.ToggleKey then
        Library:Toggle()
    end
end)

return Library
