local MAX_ITENS_PER_PAGE = 5

local Menu = {}
Menu.__index = Menu

function Menu:new(name, parent)
    local instance = setmetatable({}, Menu)
    instance.name = name
    instance.parent = parent or nil
    instance.children = {}
    instance.selectedIndex = 1
    instance.currentPage = 1
    return instance
end

function Menu:addMenu(name)
    local submenu = Menu:new(name, self)
    table.insert(self.children, submenu)
    return submenu
end

function Menu:enter(index)
    index = index + ((self.currentPage - 1) * MAX_ITENS_PER_PAGE)
    local child = self.children[index]
    if child then
        if #child.children > 0 then
            return child
        else
            -- Is action
            util.toast(child.name)
        end
    end
end

function Menu:up()
    self.selectedIndex = 1
    if self.parent then
        return self.parent
    else
        -- É o root
        return self
    end
end

function Menu:pageCount()
    return math.ceil(#self.children / MAX_ITENS_PER_PAGE)
end

function Menu:pageItens()
    local start_indice = (self.currentPage - 1) * MAX_ITENS_PER_PAGE + 1
    local end_indice = MAX_ITENS_PER_PAGE * self.currentPage

    if self:pageCount() == 1 then
        return self.children
    else
        return {table.unpack(self.children, start_indice, end_indice)}
    end
end

function Menu:pageItensCount()
    if self:pageCount() == 1 then
        return #self.children
    else
        local start_indice = (self.currentPage - 1) * MAX_ITENS_PER_PAGE
        local end_indice = MAX_ITENS_PER_PAGE * self.currentPage
        end_indice = math.min(end_indice, #self.children)
        return end_indice - start_indice
    end
end

local WheelMenu = {}

local root = Menu:new("root")
local current_menu = root

function WheelMenu.current()
    return current_menu
end

function WheelMenu.setCurrent(menu)
    current_menu = menu
end

function WheelMenu:addMenu(name)
    return root:addMenu(name)
end

function WheelMenu:enter(index)
    if not index then
        index = current_menu.selectedIndex
    end

    local submenu = current_menu:enter(index)
    if submenu then
        current_menu = submenu
        return current_menu
    end
    return current_menu
end

function WheelMenu:up()
    current_menu = current_menu:up()
    return current_menu
end

function WheelMenu:focus(menu)
    if menu and menu.children then
        if  #menu.children > 0 then
            
            current_menu = menu
        else
            current_menu = menu.parent
        end
    end
end

function WheelMenu:list()
    local list = {}
    for i, child in ipairs(current_menu.children) do
        --if child.name then
            table.insert(list, child.name .. (#child.children > 0 and " (dir)" or " (file)"))
            
        --end
        --print(i, child.name, #child.children > 0 and "(dir)" or "(file)")
    end
    return list
end

return WheelMenu