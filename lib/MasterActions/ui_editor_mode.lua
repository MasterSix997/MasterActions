local editor = {}

-- Menus
local root
local file_name_input
local files_selector
--
local files = {}
local current_file = 1
--[[
actions = {
    {
        name = "Group_1"
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
        ]
    },
    {
        name = "Dances"
        actions = {
            {
                name = "Slow dance",
                animations = {
                    { name = "animation_1" }
                }
            },
            {
                name = "normal dance",
                animations = }
                    { name = "animation_1" }
                },
                props = {
                    { name = "prop_3" }
                }
            },
            {
                name = "erotic",
                actions = {}
                    {
                        name = "lap dance"
                    },
                    {
                        name = "chair dance"
                    }
                }
            }
        }
    },
}

Regras
    - Quando for adicionado, renomeado, ou removido uma action: deve ser atualizado a table e o menu
    - Caso uma action esteja vazia {name = "action"} é permitido adicionar (action, animation, prop, particle e sound)
    - Caso uma action contenha outra(s) action dentro {name = "action", actions = {{name = "subaction"}}} só é permitido adicionar novas actions (action)
    - Caso uma action contenha outra coisa dentro que não é uma action {name = "action", animations = {{name = "animation_1"}}, sounds = {{name = "sound_1"}}} não é mais permitido adicionar outras coisas alem dessas (animation, prop, particle, sound)
    - Quando for adicionado ou removido actions e outras coisas as opções dentro do textslider de adicionar coisas, deve ser atualizadas para somente as coisas permitidas
]]

local edit_menu = {}

local function exists_name(root_table, name)
    if not root_table.actions then util.toast("BUG: actions table is missing.") return false end
    for i, action in ipairs(root_table.actions) do
        if action.name == name then
            return true
        end
    end
    return false
end

local function get_valid_name(root_table, name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then
        name = "valid_name"
    end
    local number = 0
    while exists_name(root_table, name .. (number == 0 and "" or number)) do
        number = number + 1
    end
    if number ~= 0 then
        name = name .. number
    end

    return name
end

function edit_menu.add_action(root_table, root_menu, path)
    -- Data
    root_table.actions = root_table.actions or {}

    table.insert(root_table.actions, {name = get_valid_name(root_table, "new action")})

    -- Menu
    edit_menu.create_action_menu(root_table.actions, #root_table.actions, root_menu, path)
    menu.replace(root_menu:getChildren()[2], menu.detach(edit_menu.create_add_action_textslider(root_table, root_menu, path)))
end

function edit_menu.remove_action(root_table, action_index, action_menu, root_menu, path)
    root_table[action_index] = nil
    action_menu:delete()
    
    if #root_table < 1 then
        root_table = nil
        local textSlider = root_menu:getChildren()[2]
        if textSlider:getType() == 5 then
            textSlider:setTextsliderOptions({Translation.menu.name_group, Translation.menu.name_animation, Translation.menu.name_prop, Translation.menu.name_particle, Translation.menu.name_sound})
        end
    end
end

function edit_menu.rename_action(parent_table, action_index, new_name, action_menu)
    new_name = get_valid_name(parent_table, new_name)
    parent_table[action_index].name = new_name
    action_menu.menu_name = new_name
end

function edit_menu.create_add_action_textslider(root_table, root_menu, path)
    local options = {}
    if root_table.actions then
        table.insert(options, Translation.menu.name_group)
    else
        if not root_table.animations and not root_table.props and not root_table.particles and not root_table.sounds then
            table.insert(options, Translation.menu.name_group)
        end
        table.insert(options, Translation.menu.name_animation)
        table.insert(options, Translation.menu.name_prop)
        table.insert(options, Translation.menu.name_particle)
        table.insert(options, Translation.menu.name_sound)
    end

    return root_menu:textslider(Translation.menu.name_add_action, {}, "", options, function (selected)
        if selected == 1 then
            if #options == 1 or #options == 5 then -- is group
                edit_menu.add_action(root_table, root_menu, path)
            elseif #options == 4 then  -- is animation

            end
        elseif selected == 2 then -- animation
            
        elseif selected == 3 then -- prop

        elseif selected == 4 then -- particle

        elseif selected == 5 then -- sound
        end
    end)
end

function edit_menu.create_action_menu(root_table, index, root_menu, path)
    local action = root_table[index]
    local action_path = path .. "." .. action.name

    local action_menu = root_menu:list(action.name, {}, "")
    local action_name_field = action_menu:text_input(Translation.menu.name_current_action, {action_path}, "", function (new_name)
        edit_menu.rename_action(root_table, index, new_name, action_menu)
    end, action.name)
    local action_add = edit_menu.create_add_action_textslider(root_table, action_menu, action_path)
    local action_delete = action_menu:action(Translation.menu.name_delete_action, {}, "", function ()
        edit_menu.remove_action(root_table, index, action_menu, root_menu, path)
    end)
end

-- Add an action, to menu list
function edit_menu.create_actions_list(root_table, root_menu, path)
    for i, action in ipairs(root_table) do
        edit_menu.create_action_menu(root_table, i, root_menu, path)
    end
end

local function clear_actions_list()
    for index, child in ipairs(root:getChildren()) do
        if index > 6 then
            child:delete()
        end
    end
    menu.collect_garbage()
end

local is_root_created = false
local function create_root_editor()
    if is_root_created then
        root:delete()
        menu.collect_garbage()
    end

    is_root_created = true

    root = menu.my_root():list(Translation.menu.name_editor, {"masteract_editor"}, Translation.menu.description_editor)

    files = {}
    for index, file_actions in ipairs(data.actions_files) do
        table.insert(files, {index, file_actions.file_name})
    end
    if #files < 1 then
        root:action(Translation.menu.name_add_file, {"masteract_addfile"}, "", function ()
            local new_file_name = "new file"
            data.actions_files[#data.actions_files+1] = {file_name = new_file_name, actions = {}}
            data.SaveActionFile(new_file_name)
            current_file = #files + 1
            create_root_editor()
        end)
        return
    end

    files_selector = root:list_select(Translation.menu.name_current_file, {"masteract_curfile"}, "", files, current_file, function (selected)
        current_file = selected
        clear_actions_list()
        edit_menu.create_actions_list(data.actions_files[current_file].actions, root, "root")
        file_name_input.value = files[current_file][2]
    end)

    file_name_input = root:text_input(Translation.menu.name_current_file, {"masteract_renamefile"}, "", function (new_name)
        data.RenameActionFile(files[current_file][2], new_name)
        files[current_file][2] = new_name
        files_selector:setListActionOptions(files)
    end, files[current_file][2])


    root:action(Translation.menu.name_delete_file, {"masteract_deletefile"}, "", function ()
        data.DeleteActionFile(files[current_file][2])
        current_file = 1
        create_root_editor()
    end)

    root:action(Translation.menu.name_add_file, {"masteract_addfile"}, "", function ()
        local new_file_name = "new file"
        data.actions_files[#data.actions_files+1] = {file_name = new_file_name, actions = {}}
        data.SaveActionFile(new_file_name)
        current_file = #files + 1
        create_root_editor()
    end)

    root:action(Translation.menu.name_add_group, {}, "", function ()
        data.actions_files[current_file].actions = data.actions_files[current_file].actions or {}
        table.insert(data.actions_files[current_file].actions, {name = "new group"})
        data.SaveActionFile(files[current_file][2])
        clear_actions_list()
        edit_menu.create_actions_list(data.actions_files[current_file].actions, root, "root")
    end)

    root:divider(Translation.menu.name_actions)

    --list_actions(root, data.actions_files[current_file].actions)
    edit_menu.create_actions_list(data.actions_files[current_file].actions, root, "root")
end

function editor.create_editor_interface()
    create_root_editor()
end

return editor