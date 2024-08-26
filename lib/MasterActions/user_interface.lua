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

local start_action_callback
local stop_action_callback
local master_wheel = wheel.new()
local input = {
    master_control = false,
    is_open_root_pressed = false,
}
local function create_menu_from_settings(settings, parent_menu)
    for key, value in pairs(settings) do
        local item_type = type(value)
        local item_name = Translation.menu["name_" .. key] or key

        if item_type == "boolean" then
            parent_menu:toggle(item_name, {}, "", function(toggle_value)
                settings[key] = toggle_value
                data.SaveSettings()
            end, value)
        
        elseif item_type == "number" then
            print(item_name .. ": " .. value)
            parent_menu:slider(item_name, {}, "", -100000, 100000, value * 1000, 1, function(slider_value)
                settings[key] = slider_value / 1000
                data.SaveSettings()
            end)
        
        elseif item_type == "table" and not value.r then
            local sub_menu = parent_menu:list(item_name, {}, "")
            create_menu_from_settings(value, sub_menu)
        
        --elseif item_type == "string" then
        --    parent_menu:text_input(item_name, {}, "", value, function(text_value)
        --        settings[key] = text_value
        --       data.SaveSettings()
        --   end)
        
        elseif item_type == "table" and value.r and value.g and value.b and value.a then
            parent_menu:colour(item_name, {}, "", value, true, function(color_value)
                settings[key] = color_value
                data.SaveSettings()
            end)

        else
            if data.settings.dev_mode then
                util.toast("Falied create settings menu to: '" .. item_name .. "' of type: '" .. item_type .. "'")
            end
        end
    end
end

local function generate_menu_code(settings, parent_menu_name, settings_path)
    -- Função para contar casas decimais
    local function count_decimal_places(number)
        local num_str = tostring(number)
        local _, decimal_part = string.match(num_str, "^(%-?%d*)%.(%d+)$")
    
        if decimal_part then
            return #decimal_part
        else
            return 0
        end
    end

    -- Inicializa o código vazio
    local code = ""

    -- Itera por cada item na tabela de configurações
    for key, value in pairs(settings) do
        local item_type = type(value)
        local item_name = "Translation.menu.name_wheel_" .. key
        local full_key_path = settings_path .. key

        if item_type == "boolean" then
            code = code .. string.format(
                "%s:toggle(%s, {}, '', function(toggle_value, click_type)\n    if click_type == 4 then\n        return\n    end\n    %s = toggle_value\n    data.SaveSettings()\nend, %s)\n\n",
                parent_menu_name, item_name, full_key_path, full_key_path
            )
        
        elseif item_type == "number" then
            -- Função para gerar o código do slider ou slider_float
            local function generate_slider_code(full_key_path, value)
                local num_decimals = count_decimal_places(value)
                local code = ""
            
                if num_decimals == 0 then
                    code = string.format(
                        "%s:slider(%s, {}, '', 0, 1000, %s, 1, function(slider_value, _, click_type)\n    if click_type == 4 then\n        return\n    end\n    %s = slider_value\n    data.SaveSettings()\nend)\n\n",
                        parent_menu_name, item_name, full_key_path, full_key_path
                    )
                else
                    code = string.format(
                        "%s:slider_float(%s, {}, '', 0, 10000, %s * 1000, 1, function(slider_value, _, click_type)\n    if click_type == 4 then\n        return\n    end\n    %s = slider_value / 1000\n    data.SaveSettings()\nend).precision = 3\n\n",
                        parent_menu_name, item_name, full_key_path, full_key_path
                    )
                end
            
                return code
            end
            code = code .. generate_slider_code(full_key_path, value)
        
        elseif item_type == "table" and not (value.r and value.g and value.b and value.a) then
            local sub_menu_name = parent_menu_name .. "_" .. key
            code = code .. string.format(
                "local %s = %s:list(%s, {}, '')\n",
                sub_menu_name, parent_menu_name, item_name
            )
            code = code .. generate_menu_code(value, sub_menu_name, full_key_path .. ".")
        
        elseif item_type == "string" then
            code = code .. string.format(
                "%s:text_input(%s, {}, '', '%s', function(text_value)\n    %s = text_value\n    data.SaveSettings()\nend)\n\n",
                parent_menu_name, item_name, full_key_path, full_key_path
            )
        
        elseif item_type == "table" and value.r and value.g and value.b and value.a then
            code = code .. string.format(
                "%s:colour(%s, {}, '', %s, true, function(color_value, _, click_type)\n    if click_type == 4 then\n        return\n    end\n    %s = color_value\n    data.SaveSettings()\nend)\n\n",
                parent_menu_name, item_name, full_key_path, full_key_path
            )
        end
    end

    return code
end

local function generate_translation_names(settings, settings_path)
    local translation_code = ""

    local function recursive_generate_translation_names(sub_settings, current_path)
        for key, value in pairs(sub_settings) do
            local full_key = key
            translation_code = translation_code .. string.format("name_wheel_%s = \"\",\n", full_key)

            if type(value) == "table" and not (value.r and value.g and value.b and value.a) then
                -- Adiciona a própria tabela à lista de traduções
                translation_code = translation_code .. string.format("name_wheel_%s = \"\",\n", current_path and current_path .. "_" .. key or key)
                recursive_generate_translation_names(value, full_key)
            end
        end
    end

    recursive_generate_translation_names(settings, settings_path)

    return translation_code
end


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

    -- =============== ACTIONS ===============
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

    -- =============== WHEEL ===============
    local function create_wheel_settings_menu(settings_wheel_menu)
        local example_wheel = wheel.new(data.settings.wheel)
        for i = 1, 35, 1 do
            example_wheel.nav:addMenu("Testing Item: " .. i, "Test '" .. i .. "' Description")
        end
        
        --[[local settings_wheel_menu = parent_menu:list(Translation.menu.name_wheel, {}, "", function ()
            if not master_wheel.is_open then
                example_wheel:open()
            end
        end, function ()
            example_wheel:close()
        end)]]

        local settings_wheel_menu_key_input = settings_wheel_menu:list(Translation.menu.name_wheel_key_input, {}, '')
        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_master_control, {}, '', 0, 1000, data.settings.wheel.key_input.master_control, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.master_control = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_close, {}, '', 0, 1000, data.settings.wheel.key_input.close, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.close = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_choose, {}, '', 0, 1000, data.settings.wheel.key_input.choose, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.choose = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_back, {}, '', 0, 1000, data.settings.wheel.key_input.back, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.back = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_previous_page, {}, '', 0, 1000, data.settings.wheel.key_input.previous_page, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.previous_page = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_open_root, {}, '', 0, 1000, data.settings.wheel.key_input.open_root, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.open_root = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_key_input:slider(Translation.menu.name_wheel_next_page, {}, '', 0, 1000, data.settings.wheel.key_input.next_page, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.key_input.next_page = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_reset_wheel_menu_on_play_action, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.reset_wheel_menu_on_play_action = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.reset_wheel_menu_on_play_action)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_disable_the_wheel_instead_of_returning, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.disable_the_wheel_instead_of_returning = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.disable_the_wheel_instead_of_returning)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_reset_mouse_position_on_navigate, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.reset_mouse_position_on_navigate = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.reset_mouse_position_on_navigate)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_close_wheel_on_play_action, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.close_wheel_on_play_action = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.close_wheel_on_play_action)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_close_wheel_on_outside_click, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.close_wheel_on_outside_click = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.close_wheel_on_outside_click)

        local settings_wheel_menu_gamepad_input = settings_wheel_menu:list(Translation.menu.name_wheel_gamepad_input, {}, '')
        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_master_control, {}, '', 0, 1000, data.settings.wheel.gamepad_input.master_control, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.master_control = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_close, {}, '', 0, 1000, data.settings.wheel.gamepad_input.close, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.close = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_choose, {}, '', 0, 1000, data.settings.wheel.gamepad_input.choose, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.choose = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_back, {}, '', 0, 1000, data.settings.wheel.gamepad_input.back, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.back = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_previous_page, {}, '', 0, 1000, data.settings.wheel.gamepad_input.previous_page, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.previous_page = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_open_root, {}, '', 0, 1000, data.settings.wheel.gamepad_input.open_root, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.open_root = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_gamepad_input:slider(Translation.menu.name_wheel_next_page, {}, '', 0, 1000, data.settings.wheel.gamepad_input.next_page, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.gamepad_input.next_page = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu:toggle(Translation.menu.name_wheel_close_wheel_on_back_in_root, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.close_wheel_on_back_in_root = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.close_wheel_on_back_in_root)

        local settings_wheel_menu_style = settings_wheel_menu:list(Translation.menu.name_wheel_style, {}, '')
        local settings_wheel_menu_style_colors = settings_wheel_menu_style:list(Translation.menu.name_wheel_colors, {}, '')
        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_text, {}, '', data.settings.wheel.style.colors.text, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.text = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_stop, {}, '', data.settings.wheel.style.colors.stop, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.stop = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_selected_text, {}, '', data.settings.wheel.style.colors.selected_text, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.selected_text = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_stop_text, {}, '', data.settings.wheel.style.colors.stop_text, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.stop_text = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_page_button, {}, '', data.settings.wheel.style.colors.page_button, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.page_button = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_selected_border, {}, '', data.settings.wheel.style.colors.selected_border, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.selected_border = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_circle_divider, {}, '', data.settings.wheel.style.colors.circle_divider, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.circle_divider = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_wheel_text_out_focus, {}, '', data.settings.wheel.style.colors.wheel_text_out_focus, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.wheel_text_out_focus = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_border, {}, '', data.settings.wheel.style.colors.border, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.border = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_selected, {}, '', data.settings.wheel.style.colors.selected, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.selected = color_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style_colors:colour(Translation.menu.name_wheel_circle, {}, '', data.settings.wheel.style.colors.circle, true, function(color_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.colors.circle = color_value
            data.SaveSettings()
        end)

        local settings_wheel_menu_style_sizes = settings_wheel_menu_style:list(Translation.menu.name_wheel_sizes, {}, '')
        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_data_distance, {}, '', 0, 10000, data.settings.wheel.style.sizes.data_distance * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.data_distance = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_text, {}, '', 0, 10000, data.settings.wheel.style.sizes.text * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.text = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_stop_border, {}, '', 0, 10000, data.settings.wheel.style.sizes.stop_border * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.stop_border = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_border, {}, '', 0, 10000, data.settings.wheel.style.sizes.border * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.border = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_texture, {}, '', 0, 10000, data.settings.wheel.style.sizes.texture * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.texture = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_page_button, {}, '', 0, 10000, data.settings.wheel.style.sizes.page_button * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.page_button = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style_sizes:slider_float(Translation.menu.name_wheel_text_and_texture_distance, {}, '', 0, 10000, data.settings.wheel.style.sizes.text_and_texture_distance * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.sizes.text_and_texture_distance = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style:slider(Translation.menu.name_wheel_circle_resolution, {}, '', 0, 1000, data.settings.wheel.style.circle_resolution, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.circle_resolution = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style:slider(Translation.menu.name_wheel_blur_force, {}, '', 0, 1000, data.settings.wheel.style.blur_force, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.blur_force = slider_value
            data.SaveSettings()
        end)

        settings_wheel_menu_style:slider_float(Translation.menu.name_wheel_inner_radius, {}, '', 0, 10000, data.settings.wheel.style.inner_radius * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.inner_radius = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style:slider_float(Translation.menu.name_wheel_outer_radius, {}, '', 0, 10000, data.settings.wheel.style.outer_radius * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.outer_radius = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style:slider_float(Translation.menu.name_wheel_center_y, {}, '', 0, 10000, data.settings.wheel.style.center_y * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.center_y = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu_style:slider_float(Translation.menu.name_wheel_center_x, {}, '', 0, 10000, data.settings.wheel.style.center_x * 1000, 1, function(slider_value, _, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.style.center_x = slider_value / 1000
            data.SaveSettings()
        end).precision = 3

        settings_wheel_menu:toggle(Translation.menu.name_wheel_select_even_outside_the_wheel, {}, '', function(toggle_value, click_type)
            if click_type == 4 then
                return
            end
            data.settings.wheel.select_even_outside_the_wheel = toggle_value
            data.SaveSettings()
        end, data.settings.wheel.select_even_outside_the_wheel)
    end
    local is_wheel_settings_created = false

    local settings_wheel_menu
    settings_wheel_menu = settings_menu:list(Translation.menu.name_wheel, {}, "", function ()
        if not is_wheel_settings_created then
            create_wheel_settings_menu(settings_wheel_menu)
            is_wheel_settings_created = true
        end
    end)
    
    settings_menu:toggle(Translation.menu.name_settings_dev_mode, {}, Translation.menu.description_settings_dev_mode, function(value)
        data.settings.dev_mode = value
        data.SaveSettings()
    end, data.settings.dev_mode)
    
    if data.settings.dev_mode then
        settings_menu:action("Generate and print settings menu code", {}, "", function ()
        local code = generate_menu_code(data.settings.wheel, "settings_wheel_menu", "data.settings.wheel.")
        print("\n======================================\n\nMASTER ACTIONS\nGENERATED CODE\n\n======================================")
        print("\n" .. code)
        print("\n======================================\n\nMASTER ACTIONS\nGENERATED CODE\n\n======================================")
        local translation = generate_translation_names(data.settings.wheel, "")
        print("\n" .. translation)
        end)
    end
end

local function create_utils_menu()
    utils_section.utils_divider = menu:my_root():divider("Utils")
    utils_section.stop_textslider = menu:my_root():textslider("Stop actions", {"actionstop"}, "", {"Normal", "Force"}, function (stop_mode)
        if stop_mode == 1 then
            stop_action_callback()
        elseif stop_mode == 2 then
            stop_action_callback(true)
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
            start_action_callback(current_action)
        end)

        -- wheel
        parent_wheel:addMenu(name):onEnter(function ()
            start_action_callback(current_action)
        end)
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

function ui.create_interface(start_action, stop_action)
    if is_created then
        delete_menus(menu:my_root(), 6)
        settings_menu:delete()
        editor_menu:delete()
        utils_section.utils_divider:delete()
        utils_section.stop_textslider:delete()
        utils_section.misc_menu:delete()
        menu.collect_garbage()
    else
        start_action_callback = start_action
        stop_action_callback = stop_action
        util.create_tick_handler(wheel_ui_update)
        master_wheel = wheel.new(data.settings.wheel)
        master_wheel:onStopClicked(function ()
            stop_action_callback()
        end)
    end
    
    is_created = true

    create_settings_menu()
    editor_menu = editor_ui.create_editor_interface()
    create_utils_menu()

    data.CreateActionsTable()
    actions_ui.create_action_menus(data.actions, menu:my_root(), master_wheel.nav, "Groups")
end

return ui