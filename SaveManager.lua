--[[
    KITSU SAVE MANAGER - FULLY FUNCTIONAL
    Saves and loads all UI settings (Toggles, Sliders, Dropdowns, Inputs, Keybinds)
    Features: Save, Load, Delete, Auto-load, Config list management
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.ConfigsList = {}

--// INTERNAL FUNCTIONS
function SaveManager:SetIgnoreIndexes(list)
    for _, key in pairs(list) do
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
    local success, err = pcall(function()
        if not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
    end)
    
    if not success then
        warn("[SaveManager] Failed to create folder:", err)
    end
end

function SaveManager:GetConfigPath(name)
    return self.Folder .. "/" .. name .. ".json"
end

--// SAVE FUNCTION
function SaveManager:Save(name)
    if not self.Library then 
        warn("[SaveManager] Library not set!")
        return false 
    end
    
    if not name or name == "" then
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Please enter a config name!", 3)
        end
        return false
    end
    
    self:BuildFolderTree()
    
    local fullPath = self:GetConfigPath(name)
    local data = {
        version = "1.0",
        timestamp = os.time(),
        settings = {}
    }
    
    -- Collect all flag values
    for flag, value in pairs(self.Library.Flags) do
        if not self.Ignore[flag] then
            data.settings[flag] = value
        end
    end
    
    -- Encode to JSON
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not success then
        warn("[SaveManager] Failed to encode config:", encoded)
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to encode configuration!", 3)
        end
        return false
    end
    
    -- Write to file
    local writeSuccess, writeErr = pcall(function()
        writefile(fullPath, encoded)
    end)
    
    if writeSuccess then
        if self.Library.Notify then
            self.Library:Notify("Config Saved", "'" .. name .. "' has been saved!", 3)
        end
        self:RefreshConfigsList()
        return true
    else
        warn("[SaveManager] Failed to write config:", writeErr)
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to write configuration file!", 3)
        end
        return false
    end
end

--// LOAD FUNCTION
function SaveManager:Load(name)
    if not self.Library then 
        warn("[SaveManager] Library not set!")
        return false 
    end
    
    if not name or name == "" or name == "No configs found" then
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Please select a valid config!", 3)
        end
        return false
    end
    
    local fullPath = self:GetConfigPath(name)
    
    -- Check if file exists
    if not isfile(fullPath) then
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Config '" .. name .. "' does not exist!", 3)
        end
        return false
    end
    
    -- Read and decode file
    local success, decoded = pcall(function()
        local content = readfile(fullPath)
        return HttpService:JSONDecode(content)
    end)
    
    if not success then
        warn("[SaveManager] Failed to decode config:", decoded)
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Failed to read configuration file!", 3)
        end
        return false
    end
    
    -- Apply settings
    if decoded.settings then
        for flag, value in pairs(decoded.settings) do
            -- Update the flag value
            self.Library.Flags[flag] = value
            
            -- Try to call the callback if it exists
            if self.Library.FlagCallbacks[flag] then
                pcall(function()
                    self.Library.FlagCallbacks[flag](value)
                end)
            end
        end
        
        if self.Library.Notify then
            self.Library:Notify("Config Loaded", "'" .. name .. "' has been loaded!", 3)
        end
        return true
    else
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Invalid config format!", 3)
        end
        return false
    end
end

--// DELETE FUNCTION
function SaveManager:Delete(name)
    if not name or name == "" or name == "No configs found" then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Please select a valid config!", 3)
        end
        return false
    end
    
    local fullPath = self:GetConfigPath(name)
    
    if not isfile(fullPath) then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Config does not exist!", 3)
        end
        return false
    end
    
    local success, err = pcall(function()
        delfile(fullPath)
    end)
    
    if success then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Config Deleted", "'" .. name .. "' has been deleted!", 3)
        end
        self:RefreshConfigsList()
        return true
    else
        warn("[SaveManager] Failed to delete config:", err)
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Failed to delete config!", 3)
        end
        return false
    end
end

--// LIST CONFIGS
function SaveManager:ListConfigs()
    self.ConfigsList = {}
    
    if not isfolder(self.Folder) then
        return self.ConfigsList
    end
    
    local success, files = pcall(function()
        return listfiles(self.Folder)
    end)
    
    if not success then
        warn("[SaveManager] Failed to list configs:", files)
        return self.ConfigsList
    end
    
    for _, file in pairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name and name ~= "__autoload" then
                table.insert(self.ConfigsList, name)
            end
        end
    end
    
    table.sort(self.ConfigsList)
    return self.ConfigsList
end

function SaveManager:RefreshConfigsList()
    self:ListConfigs()
end

--// AUTOLOAD FUNCTIONS
function SaveManager:SetAutoload(name)
    if not name or name == "" or name == "No configs found" then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Autoload Error", "Please select a valid config!", 3)
        end
        return false
    end
    
    local success, err = pcall(function()
        self:BuildFolderTree()
        writefile(self.Folder .. "/__autoload.txt", name)
    end)
    
    if success then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Autoload Set", "'" .. name .. "' will load on startup!", 3)
        end
        return true
    else
        warn("[SaveManager] Failed to set autoload:", err)
        return false
    end
end

function SaveManager:GetAutoload()
    local path = self.Folder .. "/__autoload.txt"
    
    if not isfile(path) then
        return nil
    end
    
    local success, content = pcall(function()
        return readfile(path)
    end)
    
    if success and content and content ~= "" then
        return content
    end
    
    return nil
end

function SaveManager:LoadAutoload()
    local autoloadConfig = self:GetAutoload()
    
    if autoloadConfig then
        print("[SaveManager] Auto-loading config:", autoloadConfig)
        task.wait(1) -- Wait for UI to fully initialize
        return self:Load(autoloadConfig)
    end
    
    return false
end

function SaveManager:ClearAutoload()
    local path = self.Folder .. "/__autoload.txt"
    
    if isfile(path) then
        pcall(function()
            delfile(path)
        end)
        
        if self.Library and self.Library.Notify then
            self.Library:Notify("Autoload Cleared", "Auto-load has been disabled!", 3)
        end
        return true
    end
    
    return false
end

--// BUILD CONFIG UI
function SaveManager:BuildConfigSection(tab)
    if not self.Library then
        warn("[SaveManager] Library not set! Cannot build config section.")
        return
    end
    
    local Section = tab:CreateSection("Configuration Manager")
    
    local currentConfigName = ""
    local configDropdownOptions = {}
    
    -- Function to get config list
    local function GetConfigList()
        local configs = self:ListConfigs()
        if #configs == 0 then
            return {"No configs found"}
        end
        return configs
    end
    
    -- Refresh configs on section creation
    configDropdownOptions = GetConfigList()
    
    -- Config selection dropdown
    Section:CreateDropdown(
        "Select Config",
        "Choose a configuration to load or delete",
        configDropdownOptions,
        configDropdownOptions[1],
        function(value)
            if value ~= "No configs found" then
                currentConfigName = value
            end
        end,
        "SaveManager_ConfigSelect"
    )
    
    -- New config name input
    Section:CreateInput(
        "New Config Name",
        "Enter a name for a new configuration",
        "MyConfig",
        function(value)
            currentConfigName = value
        end,
        "SaveManager_ConfigName"
    )
    
    -- Save button
    Section:CreateButton(
        "Save Configuration",
        "Save current settings to a config file",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:Save(currentConfigName)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Please enter a config name!", 3)
                end
            end
        end
    )
    
    -- Load button
    Section:CreateButton(
        "Load Configuration",
        "Load settings from selected config",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:Load(currentConfigName)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Please select a config!", 3)
                end
            end
        end
    )
    
    -- Delete button
    Section:CreateButton(
        "Delete Configuration",
        "Remove the selected config file",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:Delete(currentConfigName)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Please select a config!", 3)
                end
            end
        end
    )
    
    -- Refresh list button
    Section:CreateButton(
        "Refresh Config List",
        "Update the list of available configs",
        function()
            local configs = self:ListConfigs()
            if #configs > 0 then
                if self.Library.Notify then
                    self.Library:Notify("Available Configs", table.concat(configs, ", "), 5)
                end
            else
                if self.Library.Notify then
                    self.Library:Notify("No Configs", "No saved configurations found!", 3)
                end
            end
        end
    )
    
    -- Set autoload button
    Section:CreateButton(
        "Set as Autoload",
        "This config will load automatically on startup",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:SetAutoload(currentConfigName)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Please select a config!", 3)
                end
            end
        end
    )
    
    -- Clear autoload button
    Section:CreateButton(
        "Clear Autoload",
        "Disable automatic config loading",
        function()
            self:ClearAutoload()
        end
    )
end

--// IGNORE THEME SETTINGS (OPTIONAL)
function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({"BackgroundTransparency", "MenuKeybind"})
end

return SaveManager
