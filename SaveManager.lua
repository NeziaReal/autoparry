local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil

--// IGNORE LIST
function SaveManager:SetIgnoreIndexes(list)
    for _, key in next, list do
        self.Ignore[key] = true
    end
end

--// FOLDER SETUP
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

--// SAVE FUNCTION
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

--// LOAD FUNCTION
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
            
            -- Trigger the callback
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

--// DELETE CONFIG
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

--// LIST CONFIGS
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

--// AUTOLOAD HELPERS
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
        task.wait(1.5)
        return self:Load(name)
    end
    return false
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({ "InterfaceTheme", "InterfaceTransparency" })
end

--// UI BUILDER (FIXED FOR TAB vs SECTION ERROR)
function SaveManager:BuildConfigSection(container)
    
    -- Check if 'container' is a Tab (has CreateSection) or a Section (has CreateInput)
    local section = container
    
    -- If we passed a Tab, create a Section for it automatically
    if not container.CreateInput and container.CreateSection then
        section = container:CreateSection("Configuration Manager")
    elseif not container.CreateInput and not container.CreateSection then
        warn("[SaveManager] Invalid container passed to BuildConfigSection. Expected Tab or Section.")
        return
    end

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
            print("\n--- SAVED CONFIGS ---")
            for _, cfg in pairs(configs) do
                print(cfg)
            end
            print("---------------------\n")
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
