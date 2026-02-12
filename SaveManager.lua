--[[
    KITSU SAVE MANAGER - FIXED VERSION
    Actually works with your UI library structure
    Saves toggles, sliders, dropdowns, inputs, and keybinds properly
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.Options = {} -- Store element objects here

--// SETUP FUNCTIONS
function SaveManager:SetLibrary(library)
    self.Library = library
    
    -- Make sure the library has the required tables
    if not self.Library.Flags then
        self.Library.Flags = {}
    end
    if not self.Library.FlagCallbacks then
        self.Library.FlagCallbacks = {}
    end
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function SaveManager:BuildFolderTree()
    pcall(function()
        if not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
    end)
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in pairs(list) do
        self.Ignore[key] = true
    end
end

function SaveManager:RegisterOption(flag, optionObject)
    if flag and optionObject then
        self.Options[flag] = optionObject
    end
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
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    local data = {
        version = "1.0",
        timestamp = os.time(),
        settings = {}
    }
    
    -- Save all flags
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
        warn("[SaveManager] Failed to encode:", encoded)
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to encode configuration!", 3)
        end
        return false
    end
    
    -- Write file
    local writeSuccess = pcall(function()
        writefile(fullPath, encoded)
    end)
    
    if writeSuccess then
        if self.Library.Notify then
            self.Library:Notify("✓ Config Saved", "'" .. name .. "' saved successfully!", 3)
        end
        print("[SaveManager] Config saved:", name)
        return true
    else
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to write file!", 3)
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
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    -- Check if file exists
    if not isfile(fullPath) then
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Config '" .. name .. "' not found!", 3)
        end
        return false
    end
    
    -- Read and decode
    local success, decoded = pcall(function()
        local content = readfile(fullPath)
        return HttpService:JSONDecode(content)
    end)
    
    if not success then
        warn("[SaveManager] Failed to decode:", decoded)
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Failed to read config!", 3)
        end
        return false
    end
    
    -- Apply settings
    if decoded.settings then
        local loadedCount = 0
        
        for flag, value in pairs(decoded.settings) do
            -- Update flag value
            self.Library.Flags[flag] = value
            
            -- If we have the option object, use its Set method
            if self.Options[flag] and self.Options[flag].Set then
                pcall(function()
                    self.Options[flag]:Set(value)
                end)
                loadedCount = loadedCount + 1
            -- Otherwise try to call the callback
            elseif self.Library.FlagCallbacks[flag] then
                pcall(function()
                    self.Library.FlagCallbacks[flag](value)
                end)
                loadedCount = loadedCount + 1
            end
        end
        
        if self.Library.Notify then
            self.Library:Notify("✓ Config Loaded", "'" .. name .. "' loaded (" .. loadedCount .. " settings)!", 3)
        end
        print("[SaveManager] Config loaded:", name, "(" .. loadedCount .. " settings)")
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
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if not isfile(fullPath) then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Config doesn't exist!", 3)
        end
        return false
    end
    
    local success = pcall(function()
        delfile(fullPath)
    end)
    
    if success then
        if self.Library and self.Library.Notify then
            self.Library:Notify("✓ Config Deleted", "'" .. name .. "' has been deleted!", 3)
        end
        print("[SaveManager] Config deleted:", name)
        return true
    else
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Failed to delete config!", 3)
        end
        return false
    end
end

--// LIST CONFIGS
function SaveManager:ListConfigs()
    local configs = {}
    
    if not isfolder(self.Folder) then
        return configs
    end
    
    local success, files = pcall(function()
        return listfiles(self.Folder)
    end)
    
    if not success then
        return configs
    end
    
    for _, file in pairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name and name ~= "__autoload" then
                table.insert(configs, name)
            end
        end
    end
    
    table.sort(configs)
    return configs
end

function SaveManager:RefreshConfigsList()
    return self:ListConfigs()
end

--// AUTOLOAD FUNCTIONS
function SaveManager:SetAutoload(name)
    if not name or name == "" or name == "No configs found" then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Autoload Error", "Please select a valid config!", 3)
        end
        return false
    end
    
    local success = pcall(function()
        self:BuildFolderTree()
        writefile(self.Folder .. "/__autoload.txt", name)
    end)
    
    if success then
        if self.Library and self.Library.Notify then
            self.Library:Notify("✓ Autoload Set", "'" .. name .. "' will load on startup!", 3)
        end
        print("[SaveManager] Autoload set:", name)
        return true
    else
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

function SaveManager:ClearAutoload()
    local path = self.Folder .. "/__autoload.txt"
    
    if isfile(path) then
        pcall(function()
            delfile(path)
        end)
        
        if self.Library and self.Library.Notify then
            self.Library:Notify("✓ Autoload Cleared", "Auto-load disabled!", 3)
        end
        return true
    end
    
    return false
end

function SaveManager:Autoload()
    local autoConfig = self:GetAutoload()
    
    if autoConfig and autoConfig ~= "" then
        print("[SaveManager] Auto-loading config:", autoConfig)
        task.wait(1) -- Wait for UI to initialize
        return self:Load(autoConfig)
    end
    
    return false
end

--// BUILD CONFIG UI
function SaveManager:BuildConfigSection(tab)
    if not self.Library then
        warn("[SaveManager] Library not set!")
        return
    end
    
    local Section = tab:CreateSection("Configuration")
    
    local currentConfigName = ""
    local selectedConfig = ""
    
    -- Get initial config list
    local function GetConfigList()
        local configs = self:ListConfigs()
        if #configs == 0 then
            return {"No configs found"}
        end
        return configs
    end
    
    local configList = GetConfigList()
    
    -- Dropdown for selecting configs
    Section:CreateDropdown(
        "Select Config",
        "Choose a saved configuration",
        configList,
        configList[1],
        function(value)
            if value ~= "No configs found" then
                selectedConfig = value
                currentConfigName = value
            end
        end,
        "SM_SelectConfig"
    )
    
    -- Input for new config name
    Section:CreateInput(
        "Config Name",
        "Enter name for new config",
        "MyConfig",
        function(value)
            currentConfigName = value
        end,
        "SM_ConfigName"
    )
    
    -- Save button
    Section:CreateButton(
        "Save Config",
        "Save current settings",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:Save(currentConfigName)
                task.wait(0.5)
                -- Update dropdown list
                configList = GetConfigList()
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Enter a config name!", 2)
                end
            end
        end
    )
    
    -- Load button
    Section:CreateButton(
        "Load Config",
        "Load saved settings",
        function()
            local nameToLoad = currentConfigName ~= "" and currentConfigName or selectedConfig
            if nameToLoad ~= "" and nameToLoad ~= "No configs found" then
                self:Load(nameToLoad)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Select a config!", 2)
                end
            end
        end
    )
    
    -- Delete button
    Section:CreateButton(
        "Delete Config",
        "Remove selected config",
        function()
            local nameToDelete = selectedConfig ~= "" and selectedConfig or currentConfigName
            if nameToDelete ~= "" and nameToDelete ~= "No configs found" then
                self:Delete(nameToDelete)
                task.wait(0.5)
                -- Update dropdown list
                configList = GetConfigList()
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Select a config!", 2)
                end
            end
        end
    )
    
    -- Refresh list button
    Section:CreateButton(
        "Refresh List",
        "Update config list",
        function()
            configList = GetConfigList()
            if #configList > 0 and configList[1] ~= "No configs found" then
                if self.Library.Notify then
                    self.Library:Notify("Configs", table.concat(configList, ", "), 4)
                end
            else
                if self.Library.Notify then
                    self.Library:Notify("No Configs", "No saved configs found", 2)
                end
            end
        end
    )
    
    -- Set autoload button
    Section:CreateButton(
        "Set Autoload",
        "Load this config on startup",
        function()
            local nameToSet = currentConfigName ~= "" and currentConfigName or selectedConfig
            if nameToSet ~= "" and nameToSet ~= "No configs found" then
                self:SetAutoload(nameToSet)
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Select a config!", 2)
                end
            end
        end
    )
    
    -- Clear autoload button
    Section:CreateButton(
        "Clear Autoload",
        "Disable auto-loading",
        function()
            self:ClearAutoload()
        end
    )
    
    print("[SaveManager] Config section built successfully")
end

return SaveManager
