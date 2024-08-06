Translation = {
    menu = {
        name_settings = "",
        name_settings_language = "",
        description_settings_language = "",
        name_settings_dev_mode = "",
        description_settings_dev_mode = "",
        name_stop_action = ""
    }
}

local function lang_en()
    return {
        menu = {
            name_settings = "Settings",
            name_settings_language = "Language",
            description_settings_language = "The language of the script",
            name_stop_action = ""
        }
    }
end

local function lang_pt()
    return {
        menu = {
            name_settings = "Configurações",
            name_settings_language = "Linguagem",
            description_settings_language = "A linguagem do script",
            name_settings_dev_mode = "Modo desenvolvedor",
            description_settings_dev_mode = "Ativa o modo desenvolvedor, habilitando o envio de mensagens para fins de depuração",
            name_stop_action = "Parar Ação"
        }
    }
end

TranslationUtils = {
    languages_names = {
        {1, "English"},
        {2, "Português"},
    },
    languages_id = {
        "en-us",
        "pt-br"
    },
    current_language = 0,
}

function TranslationUtils.SetupLanguage(language)
    if language == "en-us" then
        Translation = lang_en()
        TranslationUtils.current_language = 1
    elseif(language == "pt-br") then
        Translation = lang_pt()
        TranslationUtils.current_language = 2
    end

    util.toast("Changed Language")
end

--return translations