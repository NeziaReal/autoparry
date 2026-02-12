local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil

-- Kitsu stores values in Library.Flags[flag] = value
-- Kitsu stores callbacks in Library.FlagCallbacks[flag] = function

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
    local paths = {}
    local parts = self.Folder:split("/")
    local currentPath = ""
    
    for i, part in ipairs(parts) do
        currentPath = currentPath .. part
        table.insert(paths, currentPath)
        currentPath = currentPath .. "/"
    end
    
    for _, path in ipairs(paths) do
        if not isfolder(path) then
            makefolder(path)
        end
    end
end

function SaveManager:Save(name)
    if not self.Library then return false end
    self:BuildFolderTree()
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    local data = {
        objects = {}
    }
    
    -- Iterate through Kitsu Flags
    for flag, value in pairs(self.Library.Flags) do
        if not self.Ignore[flag] then
            data.objects[flag] = value
        end
    end
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        writefile(fullPath, encoded)
        if self.Library.Notify then
            self.Library:Notify("Config Saved", "Configuration '" .. name .. "' has been saved!", 3)
        end
        return true
    end
    
    return false
end

function SaveManager:Load(name)
    if not self.Library then return false end
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if not isfile(fullPath) then
        if self.Library.Notify then
            self.Library:Notify("Config Error", "Configuration '" .. name .. "' does not exist!", 3)
        end
        return false
    end
    
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(fullPath))
    end)
    
    if success and decoded.objects then
        for flag, value in pairs(decoded.objects) do
            -- Update the flag value
            self.Library.Flags[flag] = value
            
            -- Trigger the callback to update the game state
            -- Note: Visual UI elements (sliders/toggles) won't visually update 
            -- unless the specific element object was saved, but the logic will work.
            if self.Library.FlagCallbacks[flag] then
                pcall(function() 
                    self.Library.FlagCallbacks[flag](value) 
                end)
            end
        end
        
        if self.Library.Notify then
            self.Library:Notify("Config Loaded", "Configuration '" .. name .. "' has been loaded!", 3)
        end
        return true
    end
    
    return false
end

function SaveManager:DeleteConfig(name)
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if isfile(fullPath) then
        delfile(fullPath)
        if self.Library.Notify then
            self.Library:Notify("Config Deleted", "Configuration '" .. name .. "' has been deleted!", 3)
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
    writefile(self.Folder .. "/__autoload.txt", name)
end

function SaveManager:GetAutoloadConfig()
    local path = self.Folder .. "/__autoload.txt"
    if isfile(path) then
        return readfile(path)
    end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if name then
        task.wait(1.5) -- Wait for UI to load
        return self:Load(name)
    end
    return false
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({ "InterfaceTheme", "InterfaceTransparency" })
end

-- Matches Kitsu UI Syntax: Section:CreateInput, Section:CreateButton
function SaveManager:BuildConfigSection(section)
    
    local configName = ""
    
    section:CreateInput("Config Name", "Create or select a name", "Enter config name...", function(value)
        configName = value
    end)
    
    section:CreateButton("Save Config", "Save current settings", function()
        if configName ~= "" then
            self:Save(configName)
        else
            self.Library:Notify("Error", "Please enter a config name!", 2)
        end
    end)
    
    section:CreateButton("Load Config", "Load saved settings", function()
        if configName ~= "" then
            self:Load(configName)
        else
            self.Library:Notify("Error", "Please enter a config name!", 2)
        end
    end)
    
    section:CreateButton("Delete Config", "Remove saved configuration", function()
        if configName ~= "" then
            self:DeleteConfig(configName)
        else
            self.Library:Notify("Error", "Please enter a config name!", 2)
        end
    end)
    
    section:CreateButton("Refresh / List Configs", "Check console (F9) for list", function()
        local configs = self:ListConfigs()
        if #configs > 0 then
            -- Kitsu Notify is small, so we print list to console and notify user
            print("--- SAVED CONFIGS ---")
            for _, cfg in pairs(configs) do
                print(cfg)
            end
            self.Library:Notify("Saved Configs", "List printed to console (F9)", 3)
        else
            self.Library:Notify("No Configs", "No saved configurations found!", 2)
        end
    end)
    
    section:CreateButton("Set as Autoload", "Auto-load this config on startup", function()
        if configName ~= "" then
            self:SetAutoloadConfig(configName)
            self.Library:Notify("Autoload Set", "'" .. configName .. "' will load on start!", 3)
        else
            self.Library:Notify("Error", "Please enter a config name!", 2)
        end
    end)
end

return SaveManager
