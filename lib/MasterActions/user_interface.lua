local editor_ui = require("lib.MasterActions.ui_editor_mode")
local wheel = require("MasterActions.lib.MasterActions.WheelMenu.wheel_menu")

local ui = {}
local actions_ui = { }

local is_created = false
local settings_menu
local editor_menu

local function create_settings_menu()
    settings_menu = menu.my_root():list(Translation.menu.name_settings, {}, "")

    settings_menu:list_select(Translation.menu.name_settings_language, {}, Translation.menu.description_settings_language, TranslationUtils.languages_names, TranslationUtils.current_language, function (selected, click_type)
        if click_type == 4 then
            return
        end

        if selected == 1 then
            TranslationUtils.SetupLanguage("en-us")
            ui.create_interface()
        end
        if selected == 2 then
            TranslationUtils.SetupLanguage("pt-br")
            ui.create_interface()
        end
        data.settings.language = TranslationUtils.languages_id[TranslationUtils.current_language]
        data.SaveSettings()
    end)

    local actions_settings_menu = settings_menu:list(Translation.menu.name_settings_actions, {}, Translation.menu.description_settings_actions)
    actions_settings_menu:toggle(Translation.menu.name_settings_actions_separate_by_files, {}, Translation.menu.description_settings_actions_separate_by_files, function (value, click_type)
        if click_type == 4 then
            return
        end
        data.settings.actions.separate_by_files = value
        actions_ui.recreate_menus()
        data.SaveSettings()
    end, data.settings.actions.separate_by_files)
    actions_settings_menu:toggle(Translation.menu.name_settings_actions_create_default_commands, {}, Translation.menu.description_settings_actions_create_default_commands, function (value, click_type)
        if click_type == 4 then
            return
        end
        data.settings.actions.create_default_commands = value
        actions_ui.recreate_menus()
        data.SaveSettings()
    end, data.settings.actions.create_default_commands)

    settings_menu:toggle(Translation.menu.name_settings_dev_mode, {}, Translation.menu.description_settings_dev_mode, function(value)
        data.settings.dev_mode = value
        data.SaveSettings()
    end, data.settings.dev_mode)
end

function actions_ui.create_action_menu(actions_table, action_index, parent_menu, parent_wheel)
    local current_action = actions_table[action_index]
    local name = current_action[TranslationUtils.languages_id[TranslationUtils.current_language]] or current_action.name
    if current_action.actions and #current_action.actions > 0 then
        local action_menu = parent_menu:list(name, {}, "")
        actions_ui.create_action_menus(current_action.actions, action_menu, name)
        
        -- wheel
        
    else
        local command = {}
        if current_action.command then
            command = "e" .. current_action.command
        elseif data.settings.actions.create_default_commands then
            command = {"e" .. name}
        end

        parent_menu:action(name, command, "", function ()
            util.toast("Execute action: " ..name)
        end)
    end
end

function actions_ui.create_action_menus(actions_table, parent_menu, parent_wheel, divider_name)
    if divider_name then
        parent_menu:divider(divider_name)
    end
    for i, action in ipairs(actions_table) do
        actions_ui.create_action_menu(actions_table, i, parent_menu)
    end
end

local function delete_menus(parent_menu, from, to)
    local childrens = parent_menu:getChildren()
    from = from or 1
    to = to or #childrens

    for i = from, to do
        childrens[i]:delete()
    end
end

function actions_ui.recreate_menus()
    delete_menus(menu:my_root(), 4)
    menu.collect_garbage()
    data.CreateActionsTable()
    actions_ui.create_action_menus(data.actions, menu:my_root(), "Groups")
end

function ui.create_interface()
    if is_created then
        delete_menus(menu:my_root(), 4)
        settings_menu:delete()
        editor_menu:delete()
        menu.collect_garbage()
    end
    
    is_created = true
    create_settings_menu()
    editor_menu = editor_ui.create_editor_interface()
    data.CreateActionsTable()
    actions_ui.create_action_menus(data.actions, menu:my_root(), "Groups")
end

return ui