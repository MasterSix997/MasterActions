local editor = {}

-- Menus
local root
local file_name_input
local files_selector
--
local files = {}
local current_file = 1

local function list_actions(current_root, actions, file_name)
    for index, action_group in ipairs(actions) do
        local name = action_group.name
        local delete_action_group_name = Translation.menu.name_delete_action
        local current_action_group_name = Translation.menu.name_current_action
        local add_action_table = {Translation.menu.name_group}

        if action_group.actions then
            delete_action_group_name = Translation.menu.name_delete_group
            current_action_group_name = Translation.menu.name_current_group
        else
            table.insert(add_action_table, Translation.menu.name_animation)
            table.insert(add_action_table, Translation.menu.name_prop)
            table.insert(add_action_table, Translation.menu.name_particle)
            table.insert(add_action_table, Translation.menu.name_sound)
        end

        local uuid = math.random(1, 100) .. name

        local action_root = current_root:list(name, {}, "")
        action_root:text_input(current_action_group_name, {"masteract_renameact" .. uuid }, "", function (new_name)
            actions[index].name = new_name
            action_root.menu_name = new_name
            data.SaveActionFile(files[current_file][2])
        end, name)

        local add_action_slider = action_root:textslider(Translation.menu.name_add_action, {}, "", add_action_table, function (selected)
            if selected == 1 then
                actions[index].actions = actions[index].actions or {}
                table.insert(actions[index].actions, {name = "new action"})
                data.SaveActionFile(files[current_file][2])
            elseif selected == 2 then
                
            elseif selected == 3 then

            elseif selected == 4 then

            elseif selected == 5 then
            end
        end)

        action_root:action(delete_action_group_name, {}, "", function ()
            actions[index] = nil
            data.SaveActionFile(files[current_file][2])
            action_root:delete()
        end)
    
        if action_group.actions then
            list_actions(action_root, action_group.actions)
        end
    end
end

local function clear_actions_list()
    for index, child in ipairs(root:getChildren()) do
        if index > 5 then
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
        list_actions(root, data.actions_files[current_file].actions)
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

    root:action(Translation.menu.name_add_group, {}, "", function ()
        data.actions_files[current_file].actions = data.actions_files[current_file].actions or {}
        table.insert(data.actions_files[current_file].actions, {name = "new group"})
        data.SaveActionFile(files[current_file][2])
        clear_actions_list()
        list_actions(root, data.actions_files[current_file].actions)
    end)

    root:divider(Translation.menu.name_actions)

    list_actions(root, data.actions_files[current_file].actions)
end

function editor.create_editor_interface()
    create_root_editor()
end

return editor