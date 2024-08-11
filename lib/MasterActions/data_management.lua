local json = require("json")

local default_settings = {
    language = "pt-br",
    dev_mode = true
}
local default_folder = filesystem.store_dir() .. "\\MasterActions\\"

local MasterData = {}

MasterData.actions = {}
MasterData.hasActions = function ()
    if type(MasterData.actions) == "table" and #MasterData.actions > 0 then
        return true
    else
        return false
    end
end

MasterData.settings_flags = {
    selection_mode = {
        WHEN_CLOSE_MENU = 1,
        WHEN_CLICK_ON_ITEM = 2
    },
    when_holding_right_button = {
        MOVE_CAMERA =  1,
        BACK_MENU_ITEM = 2
    },
    open_wheel_mode = {
        USING_GTA_KEY_FROM_SETTINGS = 1,
        USING_STAND_KEY_BIND = 2
    }
}
MasterData.settings = default_settings

--function MasterData.LoadData()
--    MasterData.actions = default_config
--end

-- Encode table data to json and save file config
local function writeToFile(filename, data)
    local file, _ = io.open(default_folder .. filename, "w")
    if file == nil then
        util.toast("Failed to write to " .. filename)
      return false
    end
    file:write(json.encode(data))
    file:close()
    return true
end

-- Read file config and decode json to table 
local function readFromFile(filename)
    local file, _ = io.open(default_folder .. filename, "r")
    if file == nil then
      return nil
    end
    local content = file:read("*all")
    file:close()
    return json.decode(content)
end

local function CreateFileIfNeed(filename, default_data)
    if not filesystem.exists(default_folder) then
        filesystem.mkdirs(default_folder)
    end

    if not readFromFile(filename) then
        util.toast(filename .. " file not found, creating a default")
      if not writeToFile(filename, default_data) then
        return false
      end
    end

    return true
end

--[[function MasterData.LoadData()
    if not CreateFileIfNeed("MasterActions.json", default_actions) then
        util.toast("Failed to create initial file")
    end

    MasterData.actions = readFromFile("MasterActions.json")

    util.toast("AnimData Updated")
end

function MasterData.SaveData()
    local writed = writeToFile("MasterActions.json", MasterData.actions)
    if not writed then
        util.toast("Failed to encode JSON to MasterActions.json and Write")
    else
    end
end]]

function MasterData.LoadSettings()
    if not CreateFileIfNeed("Settings.json", default_settings) then
        util.toast("Failed to create initial file")
    end
    MasterData.settings = readFromFile("Settings.json")
end

function MasterData.SaveSettings()
    local writed = writeToFile("Settings.json", MasterData.settings)
    if not writed then
        util.toast("Failed to encode JSON to Settings.json and Write")
    else
    end
end

return MasterData