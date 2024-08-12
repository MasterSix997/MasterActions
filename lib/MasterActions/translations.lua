Translation = {
    menu = {
        name_settings = "",
        name_settings_language = "",
        description_settings_language = "",
        name_settings_dev_mode = "",
        description_settings_dev_mode = "",
        name_stop_action = "",
        --editor
        name_editor = "",
        description_editor = "",
        name_current_file = "",
        name_add_file = "",
        name_delete_file = "",
        name_add_action = "",
        name_add_group = "",
        name_current_action = "",
        name_current_group = "",
        name_delete_action = "",
        name_delete_group = "",
        name_behaviours = "",
        name_add_behaviour = "",
        name_actions = "",
        name_group = "",
        name_animation = "",
        name_prop = "",
        name_particle = "",
        name_sound = "",
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
            name_stop_action = "Parar Ação",
            --editor
            name_editor = "Editor",
            description_editor = "Permite editar, adicionar e remover as ações, arquivos e comportamentos, sem precisar sair do jogo",
            name_current_file = "Arquivo atual",
            name_add_file = "Adicionar arquivo",
            name_delete_file = "Deletar arquivo",
            name_add_action = "Adicionar ação",
            name_add_group = "Adicionar grupo",
            name_current_action = "Ação atual",
            name_current_group = "Grupo atual",
            name_delete_action = "Deletar ação",
            name_delete_group = "Deletar grupo",
            name_behaviours = "Comportamentos",
            name_add_behaviour = "Adicionar comportamento",
            name_actions = "Ações",
            name_group = "Grupo",
            name_animation = "Animação",
            name_prop = "Objeto",
            name_particle = "Partícula",
            name_sound = "Som",
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
end

--return translations