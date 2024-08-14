local editor = {}

local function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end

local root
local is_root_created = false

local editor_menu = {}

editor_menu.current_file = ""

local function exists_name(action_table, name)
    if not action_table or #action_table < 1 then
        return false
    end
    for _, action in ipairs(action_table) do
        if action.name and action.name == name then
            return true
        elseif action.file_name and action.file_name == name then
            return true
        end
    end
    return false
end

local function get_valid_name(action_table, name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then
        name = "valid_name"
    end
    local number = 0
    while exists_name(action_table, name .. (number == 0 and "" or number)) do
        number = number + 1
    end
    if number ~= 0 then
        name = name .. number
    end
    return name
end

local function save_to_current_file()
    if editor_menu.current_file then
        data.SaveActionFile(editor_menu.current_file)
    end
end

-- Menu Utils

function editor_menu.add_action(action_table, index, parent_menu, path_name)
    -- table
    local current_table = action_table[index]
    current_table.actions = current_table.actions or {}
    table.insert(current_table.actions, {name = get_valid_name(current_table.actions, "New Action Group")})

    -- file
    save_to_current_file()

    -- menu
    --menu.replace(parent_menu:getChildren()[2], menu.detach(editor_menu.create_add_action_textslider(action_table, index, parent_menu, path_name)))

    editor_menu.create_action_menu(current_table.actions, #current_table.actions, parent_menu, path_name)
end

function editor_menu.delete_action(action_table, index, parent_menu, parent_path_name, is_file)
    if is_file then
        data.DeleteActionFile(editor_menu.current_file)

        local parent_from_other_childs = parent_menu:getParent()
        local base_menu_index = 1

        editor_menu.delete_menus(parent_from_other_childs, base_menu_index + index)

        for i = index, #action_table do
            if action_table[i] then
                editor_menu.create_action_menu(action_table, i, parent_from_other_childs, parent_path_name)
            end
        end
    else
        table.remove(action_table, index)
        save_to_current_file()

        local parent_from_other_childs = parent_menu:getParent()
        local base_menu_index = 3

        editor_menu.delete_menus(parent_from_other_childs, base_menu_index + index)

        for i = index, #action_table do
            if action_table[i] then
                editor_menu.create_action_menu(action_table, i, parent_from_other_childs, parent_path_name)
            end
        end
        
        --menu.replace(parent_from_other_childs:getChildren()[2], menu.detach(editor_menu.create_add_action_textslider(action_table, index, parent_menu, path_name)))
    end


    
end

---Delete childrens from the parent menu
---@param parent_menu any
---@param from any the first child (if nill, from = 1)
---@param to any the last child (if nill, to = childrens)
function editor_menu.delete_menus(parent_menu, from, to)
    local childrens = parent_menu:getChildren()
    from = from or 1
    to = to or #childrens

    for i = from, to do
        childrens[i]:delete()
    end
end

function editor_menu.rename_action(action_table, index, parent_menu, new_name, parent_path_name, is_file)
    new_name = get_valid_name(action_table, new_name)
    if not is_file then
        action_table[index].name = new_name
        save_to_current_file()
    elseif editor_menu.current_file then
        data.RenameActionFile(editor_menu.current_file, new_name)
        --action_table[index].file_name = new_name
    end

    editor_menu.create_action_menu(action_table, index, parent_menu:getParent(), parent_path_name)
    parent_menu:delete()
    --parent_menu.menu_name = new_name
    --name_field.value = new_name
    --name_field:setCommandNames({path_name_without_last .. new_name})
end

-- Menu creation

function editor_menu.create_add_action_textslider(action_table, index, parent_menu, path_name)
    --[[local options = {}
    local current_table = action_table[index]
    if current_table.actions then
        table.insert(options, Translation.menu.name_group)
    else
        if not current_table.animations and not current_table.props and not current_table.particles and not current_table.sounds then
            table.insert(options, Translation.menu.name_group)
        end
        table.insert(options, Translation.menu.name_animation)
        table.insert(options, Translation.menu.name_prop)
        table.insert(options, Translation.menu.name_particle)
        table.insert(options, Translation.menu.name_sound)
    end]]
    
    --[[return parent_menu:textslider(Translation.menu.name_add_action, {}, "", options, function (selected)
        if selected == 1 then
            if #options == 1 or #options == 5 then -- is group
                editor_menu.add_action(action_table, index, parent_menu, path_name)
            elseif #options == 4 then  -- is animation
                
            end
        elseif selected == 2 then -- animation
            
        elseif selected == 3 then -- prop
            
        elseif selected == 4 then -- particle
            
        elseif selected == 5 then -- sound
            
        end
    end)]]
    local options = {Translation.menu.name_group, Translation.menu.name_animation, Translation.menu.name_prop, Translation.menu.name_particle, Translation.menu.name_sound}
    local current_table = action_table[index]
    return parent_menu:textslider(Translation.menu.name_add_action, {}, "", options, function (selected)
        if selected == 1 then -- group
            if current_table.animations or current_table.props or current_table.particles or current_table.sounds then
                util.toast("Não é possivel adicionar um grupo dentro dessa ação")
                return
            end
            editor_menu.add_action(action_table, index, parent_menu, path_name)
        elseif selected == 2 then -- animation
            if current_table.file_name or current_table.actions then
                util.toast("Não é possivel adicionar este comportamento dentro dessa ação")
                return
            end
        elseif selected == 3 then -- prop
            if current_table.file_name or current_table.actions then
                util.toast("Não é possivel adicionar este comportamento dentro dessa ação")
                return
            end
        elseif selected == 4 then -- particle
            if current_table.file_name or current_table.actions then
                util.toast("Não é possivel adicionar este comportamento dentro dessa ação")
                return
            end
        elseif selected == 5 then -- sound
            if current_table.file_name or current_table.actions then
                util.toast("Não é possivel adicionar este comportamento dentro dessa ação")
                return
            end
        end
    end)
end

function editor_menu.create_action_menu(action_table, index, parent_menu, parent_path)
    if not action_table[index] then
        util.toast("BUG: action_table[index] is nil.")
        return
    end
    
    local name = action_table[index].name or action_table[index].file_name
    local path_name = parent_path .. "." .. name

    -- Menu Creation
    local current_menu = action_table[index].name and parent_menu:list(name, {}, "") or parent_menu:list(name, {}, "", function ()
        --util.toast("Click: " .. name)
        editor_menu.current_file = name
    end, function ()
        --util.toast("Back: " .. name)
        editor_menu.current_file = nil
    end, function ()
        --util.toast("Update: " .. name)
    end)
    local name_field = current_menu:text_input(Translation.menu.name_current_action, {path_name}, "", function (new_name)
        editor_menu.rename_action(action_table, index, current_menu, new_name, parent_path, action_table[index].file_name)
    end, name)
    local add_action_textslider = editor_menu.create_add_action_textslider(action_table, index, current_menu, path_name)
    current_menu:action("Recalculate options", {}, "", function ()
        menu.replace(parent_menu:getChildren()[2], menu.detach(editor_menu.create_add_action_textslider(action_table, index, current_menu, path_name)))
    end)
    local delete_action = current_menu:action(Translation.menu.name_delete_action, {}, "", function ()
        editor_menu.delete_action(action_table, index, current_menu, parent_path, action_table[index].file_name)
    end)

    if action_table[index].actions then
        editor_menu.create_action_menus(action_table[index].actions, current_menu, path_name)
    else

    end
end

function editor_menu.create_behaviour_menus(action_table, index, parent_menu, path_name)
    local current_action = action_table[index]
    if current_action.animations then
        for index, value in ipairs(current_action.animations) do
            
        end
    end
    if current_action.props then
        
    end
    if current_action.effects then
        
    end
    if current_action.sounds then
        
    end
end

--[[function editor_menu.recreate_actions_menu(action_table, index, parent_menu, path_name)
    local parent = parent_menu:getParent()
    parent_menu:delete()
    editor_menu.create_action_menu(action_table, index, parent, path_name)
end]]

function editor_menu.create_action_menus(action_table, parent_menu, path_name)
    for index, value in ipairs(action_table) do
        editor_menu.create_action_menu(action_table, index, parent_menu, path_name)
    end
end

function editor.create_editor_interface()
    if is_root_created then
        root:delete()
        menu.collect_garbage()
    end

    is_root_created = true
    root = menu.my_root():list(Translation.menu.name_editor, {}, Translation.menu.description_editor)
    menu.my_root():action("Log table", {}, "", function ()
        print_table(data.actions_files)
    end)

    root:action(Translation.menu.name_add_file, {}, "", function ()
        table.insert(data.actions_files, {file_name = "", actions = {}})
        data.actions_files[#data.actions_files].file_name = get_valid_name(data.actions_files, "New Actions")
        data.SaveActionFile(data.actions_files[#data.actions_files].file_name)
        editor_menu.create_action_menu(data.actions_files, #data.actions_files, root, "root")
    end)

    editor_menu.create_action_menus(data.actions_files, root, "root")
end

return editor
