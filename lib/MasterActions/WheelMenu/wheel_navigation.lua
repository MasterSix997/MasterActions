local MAX_ITENS_PER_PAGE = 15

local Menu = {}
Menu.__index = Menu

function Menu:new(name, parent)
    local instance = setmetatable({}, Menu)
    instance.name = name
    instance.parent = parent or nil
    instance.children = {}
    instance.selectedIndex = 1
    instance.currentPage = 1

    instance.isText = true
    instance.text = name
    --instance.textColor = 
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

-- Count of pages
function Menu:pageCount()
    return math.ceil(#self.children / MAX_ITENS_PER_PAGE)
end

-- Get current page itens
function Menu:pageItens()
    local start_indice = (self.currentPage - 1) * MAX_ITENS_PER_PAGE + 1
    local end_indice = MAX_ITENS_PER_PAGE * self.currentPage

    if self:pageCount() == 1 then
        return self.children
    else
        return {table.unpack(self.children, start_indice, end_indice)}
    end
end

-- Number of items on current page
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

---------------------------
local WheelMenu = {}

local root = Menu:new("root")
local current_menu = root

function WheelMenu:root()
    return root
end

function WheelMenu:current()
    return current_menu
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

function WheelMenu:page_left()
    if current_menu.currentPage > 1 then
        current_menu.currentPage = current_menu.currentPage - 1
        current_menu.selectedIndex = 1
    end
end

function WheelMenu:page_right()
    if current_menu.currentPage < current_menu:pageCount() then
        current_menu.currentPage = current_menu.currentPage + 1
        current_menu.selectedIndex = 1
    end
end

local function up_recursive(menu, action)
    if menu.parent then
        action(menu, menu.parent)
        up_recursive(menu.parent, action)
    end
end

local function down_recursive(menu, action)
    if #menu.children > 0 then
        for index, child in ipairs(menu.children) do
            action(menu, child)
            down_recursive(child, action)
        end
    end
end

function WheelMenu:focus(menu)
    if menu and menu.children then
        if  #menu.children > 0 then
            current_menu = menu
        else
            current_menu = menu.parent
        end

        up_recursive(menu, function (current, parent)
            for index, value in ipairs(parent.children) do
                if value == current then
                    parent.currentPage = math.ceil(index / MAX_ITENS_PER_PAGE)
                    parent.selectedIndex = index - (MAX_ITENS_PER_PAGE * (parent.currentPage -1))
                end
            end
        end)
    end
end
return WheelMenu