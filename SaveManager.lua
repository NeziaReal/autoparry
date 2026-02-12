local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.Parser = {
    Toggle = {
        Save = function(idx, object) return { type = "Toggle", idx = idx, value = object.Value } end,
        Load = function(idx, data) 
            if SaveManager.Library and SaveManager.Library.Options and SaveManager.Library.Options[idx] then
                pcall(function() SaveManager.Library.Options[idx]:SetValue(data.value) end)
            end
        end
    },
    Slider = {
        Save = function(idx, object) return { type = "Slider", idx = idx, value = object.Value } end,
        Load = function(idx, data) 
            if SaveManager.Library and SaveManager.Library.Options and SaveManager.Library.Options[idx] then
                pcall(function() SaveManager.Library.Options[idx]:SetValue(data.value) end)
            end
        end
    },
    Dropdown = {
        Save = function(idx, object) 
            return { 
                type = "Dropdown", 
                idx = idx, 
                value = object.Value, 
                multi = type(object.Value) == "table" 
            }
        end,
        Load = function(idx, data) 
            if SaveManager.Library and SaveManager.Library.Options and SaveManager.Library.Options[idx] then
                pcall(function() SaveManager.Library.Options[idx]:SetValue(data.value) end)
            end
        end
    },
    Input = {
        Save = function(idx, object) return { type = "Input", idx = idx, value = object.Value } end,
        Load = function(idx, data) 
            if SaveManager.Library and SaveManager.Library.Options and SaveManager.Library.Options[idx] then
                pcall(function() SaveManager.Library.Options[idx]:SetValue(data.value) end)
            end
        end
    }
}

function SaveManager:SetIgnoreIndexes(list)
    for _, key in next, list do
        self.Ignore[key] = true
    end
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:BuildFolderTree()
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

function SaveManager:Save(name)
    if not self.Library then return false end
    self:BuildFolderTree()
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    local data = {
        version = "1.0",
        timestamp = os.time(),
        objects = {}
    }
    
    for idx, option in next, self.Library.Options do
        if not self.Ignore[idx] then
            local saveData = nil
            
            if type(option.Value) == "boolean" then
                saveData = self.Parser.Toggle.Save(idx, option)
            elseif type(option.Value) == "number" then
                saveData = self.Parser.Slider.Save(idx, option)
            elseif type(option.Value) == "string" then
                saveData = self.Parser.Input.Save(idx, option)
            elseif type(option.Value) == "table" then
                saveData = self.Parser.Dropdown.Save(idx, option)
            end
            
            if saveData then
                table.insert(data.objects, saveData)
            end
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        local writeSuccess = pcall(function()
            writefile(fullPath, encoded)
        end)
        
        if writeSuccess then
            if self.Library.Notify then
                self.Library:Notify({
                    Title = "Config Saved",
                    Content = "Configuration '" .. name .. "' has been saved!",
                    Duration = 3
                })
            end
            return true
        end
    end
    
    return false
end

function SaveManager:Load(name)
    if not self.Library then return false end
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if not isfile(fullPath) then
        if self.Library.Notify then
            self.Library:Notify({
                Title = "Config Error",
                Content = "Configuration '" .. name .. "' does not exist!",
                Duration = 3
            })
        end
        return false
    end
    
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(fullPath))
    end)
    
    if success then
        for _, item in next, decoded.objects do
            local parser = self.Parser[item.type]
            if parser then
                pcall(function() parser.Load(item.idx, item) end)
            end
        end
        
        if self.Library.Notify then
            self.Library:Notify({
                Title = "Config Loaded",
                Content = "Configuration '" .. name .. "' has been loaded!",
                Duration = 3
            })
        end
        return true
    end
    
    return false
end

function SaveManager:DeleteConfig(name)
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if isfile(fullPath) then
        pcall(function() delfile(fullPath) end)
        if self.Library.Notify then
            self.Library:Notify({
                Title = "Config Deleted",
                Content = "Configuration '" .. name .. "' has been deleted!",
                Duration = 3
            })
        end
        return true
    end
    
    return false
end

function SaveManager:ListConfigs()
    local configs = {}
    
    if not isfolder(self.Folder) then
        return configs
    end
    
    local files = listfiles(self.Folder)
    for _, file in next, files do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    return configs
end

function SaveManager:SetAutoloadConfig(name)
    pcall(function()
        writefile(self.Folder .. "/__autoload.txt", name)
    end)
end

function SaveManager:GetAutoloadConfig()
    local path = self.Folder .. "/__autoload.txt"
    if isfile(path) then
        return pcall(function() return readfile(path) end) or nil
    end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if name then
        task.wait(1)
        return self:Load(name)
    end
    return false
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({ "InterfaceTheme", "InterfaceTransparency" })
end

function SaveManager:BuildConfigSection(tab)
    tab:CreateLabel("Configuration: Manage Saved Configs")
    
    local configName = ""
    
    tab:CreateInput("SaveManager_ConfigName", {
        Title = "Config Name",
        Default = "",
        Placeholder = "Enter config name...",
        Callback = function(value)
            configName = value
        end
    })
    
    tab:AddButton({
        Title = "Save Config",
        Description = "Save current settings",
        Callback = function()
            if configName ~= "" then
                self:Save(configName)
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Error",
                        Content = "Please enter a config name!",
                        Duration = 3
                    })
                end
            end
        end
    })
    
    tab:AddButton({
        Title = "Load Config",
        Description = "Load saved settings",
        Callback = function()
            if configName ~= "" then
                self:Load(configName)
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Error",
                        Content = "Please enter a config name!",
                        Duration = 3
                    })
                end
            end
        end
    })
    
    tab:AddButton({
        Title = "Delete Config",
        Description = "Remove saved configuration",
        Callback = function()
            if configName ~= "" then
                self:DeleteConfig(configName)
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Error",
                        Content = "Please enter a config name!",
                        Duration = 3
                    })
                end
            end
        end
    })
    
    tab:AddButton({
        Title = "List Configs",
        Description = "Show all saved configurations",
        Callback = function()
            local configs = self:ListConfigs()
            if #configs > 0 then
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Saved Configs",
                        Content = table.concat(configs, ", "),
                        Duration = 5
                    })
                end
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "No Configs",
                        Content = "No saved configurations found!",
                        Duration = 3
                    })
                end
            end
        end
    })
    
    tab:AddButton({
        Title = "Set as Autoload",
        Description = "Auto-load this config on startup",
        Callback = function()
            if configName ~= "" then
                self:SetAutoloadConfig(configName)
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Autoload Set",
                        Content = "'" .. configName .. "' will auto-load on startup!",
                        Duration = 3
                    })
                end
            else
                if self.Library and self.Library.Notify then
                    self.Library:Notify({
                        Title = "Error",
                        Content = "Please enter a config name!",
                        Duration = 3
                    })
                end
            end
        end
    })
end

return SaveManager
