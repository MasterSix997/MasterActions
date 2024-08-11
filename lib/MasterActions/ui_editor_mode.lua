local editor = {}

-- Menus
local root
local file_name_input
local files_selector
--
local files = {}
local current_file = 1

local function copy_table(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[copy_table(k)] = copy_table(v) end
    return res
end

local function list_actions(current_root, actions, path)
    for index, action_group in ipairs(actions) do
        local name = action_group.name or "??????"
        local delete_action_group_name = Translation.menu.name_delete_action
        local current_action_group_name = Translation.menu.name_current_action
        if action_group.actions then
            name = "> " .. name
            delete_action_group_name = Translation.menu.name_delete_group
            current_action_group_name = Translation.menu.name_current_group
        end

        local action_root = current_root:list(name, {}, "")
        action_root:text_input(current_action_group_name, {"masteract_renameact" .. math.random() .. name}, "", function (new_name)
            
        end, name)

        action_root:textslider(Translation.menu.name_add_action, {"masteract_addaction"}, "", 
        {Translation.menu.name_group,
        Translation.menu.name_animation,
        Translation.menu.name_prop,
        Translation.menu.name_particle,
        Translation.menu.name_sound}, function (selected)
            
        end)
        action_root:action(delete_action_group_name, {}, "", function ()
                
        end)
    
        if action_group.actions then
            local this_path = 
            list_actions(action_root, action_group.actions, )
        end
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
-- Root Menu
local function rename_file()
    
end

local function create_file()
    
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
    
    root:action(Translation.menu.name_add_file, {"masteract_addfile"}, "", function ()
        local new_file_name = "new file.json"
        data.actions_files[#data.actions_files+1] = {file_name = new_file_name, actions = {}}
        data.SaveActionFile(new_file_name)
        current_file = #files + 1
        create_root_editor()
    end)

    root:action(Translation.menu.name_delete_file, {"masteract_deletefile"}, "", function ()
        data.DeleteActionFile(files[current_file][2])
        current_file = 1
        create_root_editor()
    end)

    root:textslider(Translation.menu.name_add_action, {"masteract_addaction"}, "", 
    {Translation.menu.name_group,
    Translation.menu.name_animation,
    Translation.menu.name_prop,
    Translation.menu.name_particle,
    Translation.menu.name_sound}, function (selected)
        
    end)

    root:divider(Translation.menu.name_actions)

    list_actions(root, data.actions_files[current_file].actions, {data.actions_files[current_file].file_name})
end

function editor.create_editor_interface()
    create_root_editor()
end

return editor