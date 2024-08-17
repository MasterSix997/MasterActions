local editor_ui = require("lib.MasterActions.ui_editor_mode")
local wheel = require("MasterActions.lib.MasterActions.WheelMenu.wheel_menu")
local scaleform = require("ScaleformLib")
local sf = scaleform('instructional_buttons')

local ui = {}
local actions_ui = {}

local is_created = false
local settings_menu
local editor_menu
local utils_section = {utils_divider = {}, stop_textslider = {}, misc_menu = {}}

local master_wheel = wheel.new()
local input = {
    master_control = false,
    is_open_root_pressed = false,
}

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

local function create_utils_menu()
    utils_section.utils_divider = menu:my_root():divider("Utils")
    utils_section.stop_textslider = menu:my_root():textslider("Stop actions", {"actionstop"}, "", {"Normal", "Force"}, function (stop_mode)
        if stop_mode == 1 then
            util.toast("Stop1")
        elseif stop_mode == 2 then
            util.toast("Stop2")
        end
    end)

    utils_section.misc_menu = menu:my_root():list("Misc", {"misc"}, "")
    local misc = utils_section.misc_menu
    misc:toggle("MasterControl", {"masteractcontrol"}, "", function (value)
        input.master_control = value
    end, false)
    misc:toggle("Open Master Wheel", {}, "", function(value)
        if value then
            master_wheel:open()
        else
            master_wheel:close()
        end
    end, false)
end

function actions_ui.create_action_menu(actions_table, action_index, parent_menu, parent_wheel)
    local current_action = actions_table[action_index]
    local name = current_action[TranslationUtils.languages_id[TranslationUtils.current_language]] or current_action.name
    if current_action.actions and #current_action.actions > 0 then
        local action_menu = parent_menu:list(name, {}, "")
        -- wheel
        local action_wheel = parent_wheel:addMenu(name)

        actions_ui.create_action_menus(current_action.actions, action_menu, action_wheel, name)
        
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

        -- wheel
        parent_wheel:addMenu(name)
    end
end

function actions_ui.create_action_menus(actions_table, parent_menu, parent_wheel, divider_name)
    if divider_name then
        parent_menu:divider(divider_name)
    end
    for i, action in ipairs(actions_table) do
        actions_ui.create_action_menu(actions_table, i, parent_menu, parent_wheel)
    end
end

local function delete_menus(parent_menu, from, to)
    local childrens = parent_menu:getChildren()
    from = from or 1
    to = to or #childrens

    for i = from, to do
        childrens[i]:delete()
    end

    --if master_wheel.is_open() then
    master_wheel:close()
    --end
    master_wheel.nav:focus(master_wheel.nav.root)
    master_wheel.nav.root.children = {}
end

function actions_ui.recreate_menus()
    delete_menus(menu:my_root(), 4)
    menu.collect_garbage()
    data.CreateActionsTable()
    actions_ui.create_action_menus(data.actions, menu:my_root(), master_wheel.nav, "Groups")
end

local function wheel_ui_update()
    local is_in_controller = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    local binds = data.settings.wheel.key_input
    if(is_in_controller) then
        binds = data.settings.wheel.gamepad_input
    end

    local is_master_presed = input.master_control
    if not is_master_presed then 
        if is_in_controller then
            is_master_presed = PAD.IS_CONTROL_PRESSED(2, binds.master_control)
        else
            PAD.DISABLE_CONTROL_ACTION(2, binds.master_control, true)
            is_master_presed = PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.master_control)
        end
    end

    if is_master_presed then
        PAD.DISABLE_CONTROL_ACTION(2, binds.open_root, true)
        if PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.open_root) then
            if not input.is_open_root_pressed then
                master_wheel:open()
            end
            input.is_open_root_pressed = true
        else
            input.is_open_root_pressed = false
        end
        
        local function scaleform_update()
            sf.CLEAR_ALL()
            sf.TOGGLE_MOUSE_BUTTONS(false)
    
            --sf.SET_DATA_SLOT(0,PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, 171, true) , "Master ")
            sf.SET_DATA_SLOT(0, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.open_root, true), "Open Menu")
            sf.DRAW_INSTRUCTIONAL_BUTTONS()
            sf:draw_fullscreen()
        end
        if not master_wheel.is_open then
            scaleform_update()
        end
    end

end

function ui.create_interface()
    if is_created then
        delete_menus(menu:my_root(), 6)
        settings_menu:delete()
        editor_menu:delete()
        utils_section.utils_divider:delete()
        utils_section.stop_textslider:delete()
        utils_section.misc_menu:delete()
        menu.collect_garbage()
    else
        util.create_tick_handler(wheel_ui_update)
        master_wheel = wheel.new(data.settings.wheel)
    end
    
    is_created = true

    create_settings_menu()
    editor_menu = editor_ui.create_editor_interface()
    create_utils_menu()

    data.CreateActionsTable()
    actions_ui.create_action_menus(data.actions, menu:my_root(), master_wheel.nav, "Groups")
end

return ui