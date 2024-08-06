--require("lib/MasterActions/translations")

local ui = {}

local is_created = false
local settings_menu

function ui.create_interface()
    if is_created then
        settings_menu:delete()
        menu.collect_garbage()
    end
    
    is_created = true
    settings_menu = menu.my_root():list(Translation.menu.name_settings, {}, "")

    settings_menu:list_select(Translation.menu.name_settings_language, {}, Translation.menu.description_settings_language, TranslationUtils.languages_names, TranslationUtils.current_language, function (selected)
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

    settings_menu.my_root():toggle(Translation.menu.name_settings_dev_mode, {}, Translation.menu.description_settings_dev_mode, function(value)
        data.settings.dev_mode = value
        data.SaveSettings()
    end, data.settings.dev_mode)
end

return ui