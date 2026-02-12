--[[
    KITSU SAVE MANAGER - SIMPLE & WORKING
    Works with the updated UI library that has Library.Options
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "KitsuConfigs"
SaveManager.Ignore = {}
SaveManager.Library = nil

--// SETUP
function SaveManager:SetLibrary(library)
    self.Library = library
    print("[SaveManager] Library initialized")
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

--// SAVE
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
    local count = 0
    for flag, value in pairs(self.Library.Flags) do
        if not self.Ignore[flag] then
            data.settings[flag] = value
            count = count + 1
        end
    end
    
    print("[SaveManager] Saving", count, "settings...")
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if not success then
        warn("[SaveManager] Encode failed:", encoded)
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to encode!", 3)
        end
        return false
    end
    
    local writeSuccess = pcall(function()
        writefile(fullPath, encoded)
    end)
    
    if writeSuccess then
        if self.Library.Notify then
            self.Library:Notify("✓ Saved", "'" .. name .. "' (" .. count .. " settings)", 3)
        end
        print("[SaveManager] Saved:", name)
        return true
    else
        if self.Library.Notify then
            self.Library:Notify("Save Error", "Failed to write file!", 3)
        end
        return false
    end
end

--// LOAD
function SaveManager:Load(name)
    if not self.Library then 
        warn("[SaveManager] Library not set!")
        return false 
    end
    
    if not name or name == "" or name == "No configs found" then
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Select a valid config!", 3)
        end
        return false
    end
    
    local fullPath = self.Folder .. "/" .. name .. ".json"
    
    if not isfile(fullPath) then
        if self.Library.Notify then
            self.Library:Notify("Load Error", "'" .. name .. "' not found!", 3)
        end
        return false
    end
    
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(fullPath))
    end)
    
    if not success then
        warn("[SaveManager] Decode failed:", decoded)
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Failed to read!", 3)
        end
        return false
    end
    
    if decoded.settings then
        local loaded = 0
        
        for flag, value in pairs(decoded.settings) do
            -- Update flag
            self.Library.Flags[flag] = value
            
            -- Use element's Set method if available
            if self.Library.Options[flag] and self.Library.Options[flag].Set then
                pcall(function()
                    self.Library.Options[flag]:Set(value)
                end)
                loaded = loaded + 1
            -- Otherwise call callback
            elseif self.Library.FlagCallbacks[flag] then
                pcall(function()
                    self.Library.FlagCallbacks[flag](value)
                end)
                loaded = loaded + 1
            else
                loaded = loaded + 1
            end
        end
        
        if self.Library.Notify then
            self.Library:Notify("✓ Loaded", "'" .. name .. "' (" .. loaded .. " settings)", 3)
        end
        print("[SaveManager] Loaded:", name, "(" .. loaded .. " settings)")
        return true
    else
        if self.Library.Notify then
            self.Library:Notify("Load Error", "Invalid format!", 3)
        end
        return false
    end
end

--// DELETE
function SaveManager:Delete(name)
    if not name or name == "" or name == "No configs found" then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Select a valid config!", 3)
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
            self.Library:Notify("✓ Deleted", "'" .. name .. "' removed!", 3)
        end
        print("[SaveManager] Deleted:", name)
        return true
    else
        if self.Library and self.Library.Notify then
            self.Library:Notify("Delete Error", "Failed to delete!", 3)
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

--// AUTOLOAD
function SaveManager:SetAutoload(name)
    if not name or name == "" or name == "No configs found" then
        if self.Library and self.Library.Notify then
            self.Library:Notify("Autoload Error", "Select a valid config!", 3)
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
        print("[SaveManager] Autoload:", name)
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
            self.Library:Notify("✓ Cleared", "Autoload disabled!", 3)
        end
        return true
    end
    
    return false
end

function SaveManager:Autoload()
    local autoConfig = self:GetAutoload()
    
    if autoConfig and autoConfig ~= "" then
        print("[SaveManager] Auto-loading:", autoConfig)
        task.wait(1.5)
        return self:Load(autoConfig)
    end
    
    return false
end

--// BUILD UI
function SaveManager:BuildConfigSection(tab)
    if not self.Library then
        warn("[SaveManager] Library not set!")
        return
    end
    
    local Section = tab:CreateSection("Configuration")
    
    local currentConfigName = ""
    local selectedConfig = ""
    
    local function GetConfigList()
        local configs = self:ListConfigs()
        if #configs == 0 then
            return {"No configs found"}
        end
        return configs
    end
    
    local configList = GetConfigList()
    
    -- Dropdown
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
    
    -- Input
    Section:CreateInput(
        "Config Name",
        "Enter name for new config",
        "MyConfig",
        function(value)
            currentConfigName = value
        end,
        "SM_ConfigName"
    )
    
    -- Save
    Section:CreateButton(
        "Save Config",
        "Save current settings",
        function()
            if currentConfigName ~= "" and currentConfigName ~= "No configs found" then
                self:Save(currentConfigName)
                task.wait(0.5)
                configList = GetConfigList()
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Enter a config name!", 2)
                end
            end
        end
    )
    
    -- Load
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
    
    -- Delete
    Section:CreateButton(
        "Delete Config",
        "Remove selected config",
        function()
            local nameToDelete = selectedConfig ~= "" and selectedConfig or currentConfigName
            if nameToDelete ~= "" and nameToDelete ~= "No configs found" then
                self:Delete(nameToDelete)
                task.wait(0.5)
                configList = GetConfigList()
            else
                if self.Library.Notify then
                    self.Library:Notify("Error", "Select a config!", 2)
                end
            end
        end
    )
    
    -- Refresh
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
                    self.Library:Notify("No Configs", "No saved configs", 2)
                end
            end
        end
    )
    
    -- Set autoload
    Section:CreateButton(
        "Set Autoload",
        "Auto-load on startup",
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
    
    -- Clear autoload
    Section:CreateButton(
        "Clear Autoload",
        "Disable auto-loading",
        function()
            self:ClearAutoload()
        end
    )
    
    print("[SaveManager] Config section built")
end

return SaveManager
