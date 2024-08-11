local json = require("json")

local default_settings = {
    language = "pt-br",
    dev_mode = true
}

local default_actions = {
    {
        name = "Group 1",
        actions = {
            {
                name = "Action 1"
            },
            {
                name = "Action 2"
            },
            {
                name = "Action 3"
            }
        }
    },
    {
        name = "Group 2",
        actions = {
            {
                name = "sub group 1",
                actions = {
                    {
                        name = "Action 1 from sub"
                    },
                    {
                        name = "Action 2 from sub"
                    },
                    {
                        name = "Action 3 from sub"
                    }
                }
            }
        }
    }
}

local default_folder = filesystem.store_dir() .. "\\MasterActions\\"
local actions_folder = default_folder .. "Actions\\"

local MasterData = {}

MasterData.actions_files = {}
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

function MasterData.LoadAllActions()
    if not filesystem.exists(actions_folder) then
        filesystem.mkdirs(actions_folder)
        writeToFile("Actions\\" .. "Default_Actions.json", default_actions)
    end

    for index, file in ipairs(filesystem.list_files(actions_folder)) do
        if not filesystem.is_dir(file) then
            local file_name = string.sub(file, #actions_folder + 1, #file)
            local file_actions = {file_name = file_name}
            file_actions.actions = readFromFile("Actions\\" .. file_name)
            if file_actions.actions then
                table.insert(MasterData.actions_files, file_actions)
            end
        end
    end
end

function MasterData.LoadActionFile(filename)
    if not filesystem.exists(actions_folder) then
        filesystem.mkdirs(actions_folder)
        writeToFile("Actions\\" .. "Default_Actions.json", default_actions)
    end
    if not filesystem.exists(actions_folder .. filename) then
        return nil
    end
    
    local file_actions = {file_name = filename}
    file_actions.actions = readFromFile("Actions\\" .. filename)
    if file_actions.actions then
        for index, stored_file in ipairs(MasterData.actions_files) do
            if stored_file.file_name == file_actions.file_name then
                MasterData.actions_files[index] = file_actions
                return MasterData.actions_files[index]
            end
        end
        table.insert(MasterData.actions_files, file_actions)
        return MasterData.actions_files[#MasterData.actions_files]
    end
    return nil
end

function MasterData.SaveActionFile(filename)
    for index, stored_file in ipairs(MasterData.actions_files) do
        if stored_file.file_name == filename then
            writeToFile("Actions\\" .. filename, stored_file.actions)
        end
    end
end

function MasterData.DeleteActionFile(filename)
    for index, stored_file in ipairs(MasterData.actions_files) do
        if stored_file.file_name == filename then
            os.remove(actions_folder .. filename)
            table.remove(MasterData.actions_files, index)
        end
    end
end

function MasterData.RenameActionFile(filename, new_name)
    for index, stored_file in ipairs(MasterData.actions_files) do
        if stored_file.file_name == filename then
            os.rename(actions_folder .. filename, actions_folder .. new_name)
            MasterData.actions_files[index].file_name = new_name
        end
    end
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