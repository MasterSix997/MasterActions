local json = require("pretty.json")
local dkjson = require("test_json")

local default_settings = {
    version = "0.0.1",
    language = "pt-br",
    dev_mode = true,
    actions = {
        separate_by_files = false,
        create_default_commands = true,
    },
    wheel = {
        close_wheel_on_back_in_root = true,
        close_wheel_on_play_action = true,
        reset_wheel_menu_on_play_action = false,
        close_wheel_on_outside_click = false,
        select_even_outside_the_wheel = true,
        reset_mouse_position_on_navigate = true,
        disable_the_wheel_instead_of_returning = false,
        key_input = {
            master_control = 44,--171,
            open_root = 22,
            back = 202,
            close = 199,
            choose = 24,
            next_page = 14,
            previous_page = 15
        },
        gamepad_input = {
            master_control = 44,
            open_root = 47,
            back = 202,
            close = 200,
            choose = 24,
            next_page = 44,
            previous_page = 37
        },
        style = {
            center_x = 0.5,
            center_y = 0.5,
            outer_radius = 0.1,
            inner_radius = 0.01,
            circle_resolution = 24,
            blur_force = 7,
            sizes = {
                border = 0.003,
                stop_border = 0.003,
                page_button = 0.03,
                data_distance = 0.07,
                text = 0.6,
                texture = 0.01,
                text_and_texture_distance = 0.01
            },
            colors = {
                circle = {["r"] = 0, ["g"] = 0, ["b"] = 0, ["a"] = 0.5},
                circle_divider = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5},
                wheel_text_out_focus = {["r"] = 1, ["g"] = 0.498, ["b"] = 0.6, ["a"] = 1},
                text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
                selected_text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
                selected = {["r"] = 1, ["g"] = 0.0196, ["b"] = 0.2667, ["a"] = 0.6},
                border = {["r"] = 0, ["g"] = 0, ["b"] = 0, ["a"] = 0.9},
                selected_border = {["r"] = 1, ["g"] = 0.0196, ["b"] = 0.2667, ["a"] = 1},
                stop = {["r"] = 1, ["g"] = 0.0196, ["b"] = 0.2667, ["a"] = 1},
                stop_text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
                page_button = {["r"] = 0, ["g"] = 0, ["b"] = 0, ["a"] = 0.8},
            }
        }
    }
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

local default_folder = filesystem.store_dir() .. "MasterActions\\"
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
    file:write(json.stringify(data, nil, 4))
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
    return json.parse(content)
end

local function readFromLargeFile(filename)
    local file, _ = io.open(default_folder .. filename, "r")
    if file == nil then
      return nil
    end
    local content = file:read("*all")
    file:close()
    return dkjson.decode(content)
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
            local file_name = string.sub(file, #actions_folder + 1, #file - 5)
            if string.sub(file, -5) == ".json" then
                local file_actions = {file_name = file_name}
                file_actions.actions = readFromFile("Actions\\" .. file_name .. ".json")
                if file_actions.actions then
                    table.insert(MasterData.actions_files, file_actions)
                end
            end
        end
    end
end

function MasterData.LoadActionFile(filename)
    if not filesystem.exists(actions_folder) then
        filesystem.mkdirs(actions_folder)
        writeToFile("Actions\\" .. "Default_Actions.json", default_actions)
    end
    if not filesystem.exists(actions_folder .. filename .. ".json") then
        return nil
    end
    
    local file_actions = {file_name = filename}
    file_actions.actions = readFromFile("Actions\\" .. filename .. ".json")
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
            writeToFile("Actions\\" .. filename .. ".json", stored_file.actions)
        end
    end
end

function MasterData.DeleteActionFile(filename)
    for index, stored_file in ipairs(MasterData.actions_files) do
        if stored_file.file_name == filename then
            os.remove(actions_folder .. filename .. ".json")
            table.remove(MasterData.actions_files, index)
        end
    end
end

function MasterData.RenameActionFile(filename, new_name)
    for index, stored_file in ipairs(MasterData.actions_files) do
        if stored_file.file_name == filename then
            os.rename(actions_folder .. filename .. ".json", actions_folder .. new_name .. ".json")
            MasterData.actions_files[index].file_name = new_name
        end
    end
end

function MasterData.CreateActionsTable()
    MasterData.actions = {}
    for i, action_file in ipairs(MasterData.actions_files) do
        if MasterData.settings.actions.separate_by_files then
            table.insert(MasterData.actions, {name = action_file.file_name, actions = action_file.actions})
        else
            for action_i, action in ipairs(action_file.actions) do
                table.insert(MasterData.actions, action)
            end
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
function MasterData.LoadDumpFile(filename)
    return readFromLargeFile("Dumps\\" ..filename)
end

local function update_settings(current_settings, new_settings)
    for key, value in pairs(new_settings) do
        if type(value) == "table" then
            --if type(current_settings[key]) ~= "table" then
                --current_settings[key] = {}
            --end
            -- Chamada recursiva para lidar com subchaves
            update_settings(current_settings[key], value)
        else
            current_settings[key] = value
        end
    end
end

function MasterData.LoadSettings()
    if not CreateFileIfNeed("Settings.json", default_settings) then
        util.toast("Failed to create initial file")
    end
    --MasterData.settings = readFromFile("Settings.json")
    local settings_loaded = readFromFile("Settings.json")
    update_settings(MasterData.settings, settings_loaded)
end

function MasterData.SaveSettings()
    local writed = writeToFile("Settings.json", MasterData.settings)
    if not writed then
        util.toast("Failed to encode JSON to Settings.json and Write")
    else
    end
end

return MasterData