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
        name_duplicate = "",
        description_duplicate = "",
        name_delete = "",
        description_delete = "",
        name_action = "",
        name_group = "",
        name_animation = "",
        name_prop = "",
        name_effect = "",
        name_sound = "",
        name_actions = "",
        name_groups = "",
        name_animations = "",
        name_props = "",
        name_effects = "",
        name_sounds = "",
        name_animation_blendin = "",
        description_animation_blendin = "",
        name_animation_blendout = "",
        description_animation_blendout = "",
        name_animation_duration = "",
        description_animation_duration = "",
        name_animation_play_back_rate = "",
        description_animation_play_back_rate = "",
        name_animation_repeatflag = "",
        description_animation_repeatflag = "",
        name_animation_stop_last_frame_flag = "",
        description_animation_stop_last_frame_flag = "",
        name_animation_upper_body_flag = "",
        description_animation_upper_body_flag = "",
        name_animation_player_control_flag = "",
        description_animation_player_control_flag = "",
        name_animation_cancelable_flag = "",
        description_animation_cancelable_flag = "",
        name_prop_id = "",
        description_prop_id = "",
        name_attached = "",
        description_attached = "",
        name_bone = "",
        description_bone = "",
        name_bone_head = "",
        name_bone_neck = "",
        name_bone_spine = "",
        name_bone_pelvis = "",
        name_bone_left_arm = "",
        name_bone_right_arm = "",
        name_bone_left_leg = "",
        name_bone_right_leg = "",
        name_bone_left_foot = "",
        name_bone_right_foot = "",
        name_position = "",
        name_rotation = "",
        name_additive = "",
        description_additive = "",
        name_require_force_stop = "",
        description_require_force_stop = "",
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
            name_duplicate = "Duplicar",
            description_duplicate = "",
            name_delete = "Deletar",
            description_delete = "",
            name_action = "Ação",
            name_group = "Grupo",
            name_animation = "Animação",
            name_prop = "Objeto",
            name_effect = "Efeito",
            name_sound = "Som",
            name_actions = "Ações",
            name_groups = "Grupos",
            name_animations = "Animações",
            name_props = "Objetos",
            name_effects = "Efeitos",
            name_sounds = "Sons",
            name_animation_blendin = "Mistura de inicio",
            description_animation_blendin = "",
            name_animation_blendout = "Mistura de saida",
            description_animation_blendout = "",
            name_animation_duration = "Duração",
            description_animation_duration = "",
            name_animation_play_back_rate = "Taxa de reprodução",
            description_animation_play_back_rate = "",
            name_animation_repeatflag = "Repetir em loop",
            description_animation_repeatflag = "",
            name_animation_stop_last_frame_flag = "Parar no ultimo frame",
            description_animation_stop_last_frame_flag = "",
            name_animation_upper_body_flag = "Somente na parte de cima",
            description_animation_upper_body_flag = "",
            name_animation_player_control_flag = "Controlar",
            description_animation_player_control_flag = "",
            name_animation_cancelable_flag = "Cancelavel",
            description_animation_cancelable_flag = "",
            name_prop_id = "Prop",
            description_prop_id = "",
            name_attached = "Grudado",
            description_attached = "",
            name_bone = "Osso",
            description_bone = "",
            name_bone_head = "Cabeça",
            name_bone_neck = "Pescoço",
            name_bone_spine = "Espinha",
            name_bone_pelvis = "Pélvis",
            name_bone_left_arm = "Braço esquerdo",
            name_bone_right_arm = "Braço direito",
            name_bone_left_leg = "Perna esquerda",
            name_bone_right_leg = "Perna direita",
            name_bone_left_foot = "Pé esquerdo",
            name_bone_right_foot = "Pé direito",
            name_position = "Posição",
            name_rotation = "Rotação",
            name_additive = "Aditivo",
            description_additive = "",
            name_require_force_stop = "Requer forçar a parada",
            description_require_force_stop = "",
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

local function update_translation(existing_translation, new_translation)
    for key, value in pairs(new_translation) do
        if type(value) == "table" then
            if type(existing_translation[key]) ~= "table" then
                existing_translation[key] = {}
            end
            -- Chamada recursiva para lidar com subchaves
            update_translation(existing_translation[key], value)
        else
            existing_translation[key] = value
        end
    end
end

function TranslationUtils.SetupLanguage(language)
    local new_translation

    if language == "en-us" then
        new_translation = lang_en()
        TranslationUtils.current_language = 1
    elseif(language == "pt-br") then
        new_translation = lang_pt()
        TranslationUtils.current_language = 2
    end

    update_translation(Translation, new_translation)
end

--return translations