local InterfaceManager = {}
InterfaceManager.Folder = "KitsuInterfaces"
InterfaceManager.Library = nil
InterfaceManager.CurrentTheme = "dark"
InterfaceManager.Transparency = 0

function InterfaceManager:SetLibrary(library)
    self.Library = library
end

function InterfaceManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function InterfaceManager:BuildFolderTree()
    pcall(function()
        local paths = {}
        for i = 1, #self.Folder do
            local str = string.sub(self.Folder, 1, i)
            if string.sub(self.Folder, i, i) == "/" then
                table.insert(paths, str)
            end
        end
        table.insert(paths, self.Folder)
        
        for _, path in next, paths do
            if not isfolder(path) then
                makefolder(path)
            end
        end
    end)
end

function InterfaceManager:ApplyTheme(isDark)
    if not self.Library or not self.Library.Theme then return end
    
    local Theme = self.Library.Theme
    
    if isDark then
        Theme.Main = Color3.fromRGB(10, 10, 10)
        Theme.Sidebar = Color3.fromRGB(10, 10, 10)
        Theme.Section = Color3.fromRGB(16, 16, 16)
        Theme.Stroke = Color3.fromRGB(35, 35, 35)
        Theme.Text = Color3.fromRGB(240, 240, 240)
        Theme.TextDim = Color3.fromRGB(100, 100, 100)
        Theme.Separator = Color3.fromRGB(25, 25, 25)
        Theme.Divider = Color3.fromRGB(25, 25, 25)
    else
        Theme.Main = Color3.fromRGB(245, 245, 245)
        Theme.Sidebar = Color3.fromRGB(250, 250, 250)
        Theme.Section = Color3.fromRGB(255, 255, 255)
        Theme.Stroke = Color3.fromRGB(200, 200, 200)
        Theme.Text = Color3.fromRGB(20, 20, 20)
        Theme.TextDim = Color3.fromRGB(120, 120, 120)
        Theme.Separator = Color3.fromRGB(210, 210, 210)
        Theme.Divider = Color3.fromRGB(210, 210, 210)
    end
    
    self.CurrentTheme = isDark and "dark" or "light"
    
    if self.Library.Gui then
        for _, v in ipairs(self.Library.Gui:GetDescendants()) do
            if v.Name == "MainFrame" then
                v.BackgroundColor3 = Theme.Main
            elseif v.ClassName == "TextLabel" and v.TextColor3 == (isDark and Color3.fromRGB(100,100,100) or Color3.fromRGB(120,120,120)) then
                v.TextColor3 = Theme.TextDim
            end
        end
    end
end

function InterfaceManager:ApplyTransparency(percent)
    if not self.Library then return end
    
    local alpha = 1 - (percent / 100)
    self.Transparency = percent
    
    local gui = self.Library.Gui
    if gui then
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("Frame") or v:IsA("ScrollingFrame") or v:IsA("TextButton") then
                if v.BackgroundTransparency < 1 and v ~= gui:FindFirstChild("NotificationHolder") then
                    v.BackgroundTransparency = alpha
                end
            end
        end
    end
end

function InterfaceManager:BuildInterfaceSection(tab)
    tab:AddParagraph({
        Title = "Interface Manager",
        Content = "Customize your interface settings"
    })
    
    local themeToggle = tab:CreateToggle("InterfaceTheme", {
        Title = "Dark Theme",
        Default = true,
        Callback = function(value)
            self:ApplyTheme(value)
        end
    })
    
    local transparencySlider = tab:CreateSlider("InterfaceTransparency", {
        Title = "Transparency",
        Description = "Adjust interface transparency",
        Default = 0,
        Min = 0,
        Max = 70,
        Callback = function(value)
            self:ApplyTransparency(value)
        end
    })
    
    tab:AddButton({
        Title = "Reset Interface",
        Description = "Reset to default theme",
        Callback = function()
            if self.Library and self.Library.Options then
                if self.Library.Options.InterfaceTheme then
                    self.Library.Options.InterfaceTheme:SetValue(true)
                end
                if self.Library.Options.InterfaceTransparency then
                    self.Library.Options.InterfaceTransparency:SetValue(0)
                end
            end
            self:ApplyTheme(true)
            self:ApplyTransparency(0)
        end
    })
    
    tab:AddParagraph({
        Title = "Info",
        Content = "Interface settings are managed separately from configs"
    })
end

return InterfaceManager