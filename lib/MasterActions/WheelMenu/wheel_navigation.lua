local MAX_ITEMS_PER_PAGE = 15

local DRAW_MODES = {
    TEXT = 0,
    TEXTURE = 1,
    TEXT_DOWN_TEXTURE_UP = 2,
}

local MenuItem = {}
MenuItem.__index = MenuItem

function MenuItem:new(name, description, parent)
    local instance = setmetatable({}, self)
    instance.name = name
    instance.description = description
    instance.parent = parent or nil
    instance.children = {}
    instance.selectedIndex = 1
    instance.currentPage = 1
    instance.isFolder = true
    instance.onEnterCallbacks = nil

    instance.text = name
    instance.drawMode = 0
    instance.textSettings = {}
    instance.textureSettings = nil
    return instance
end

function MenuItem:addMenu(name, description)
    local submenu = MenuItem:new(name, description, self)
    table.insert(self.children, submenu)
    return submenu
end

function MenuItem:enter(index, onEnterAction)
    index = index + ((self.currentPage - 1) * MAX_ITEMS_PER_PAGE)
    local child = self.children[index]
    if child then
        if child.onEnterCallbacks then
            for _, callback in ipairs(child.onEnterCallbacks) do
                callback()
            end
        end
        
        if #child.children > 0 then
            return child
        elseif onEnterAction then
            onEnterAction(child)
        end
    end
end

function MenuItem:up()
    self.selectedIndex = 1
    if self.parent then
        return self.parent
    else
        return self
    end
end

function MenuItem:pageCount()
    return math.ceil(#self.children / MAX_ITEMS_PER_PAGE)
end

function MenuItem:pageItems()
    local startIndex = (self.currentPage - 1) * MAX_ITEMS_PER_PAGE + 1
    local endIndex = math.min(startIndex + MAX_ITEMS_PER_PAGE - 1, #self.children)
    return {table.unpack(self.children, startIndex, endIndex)}
end

function MenuItem:pageItemsCount()
    return #self:pageItems()
end

function MenuItem:onEnter(callback)
    self.onEnterCallbacks = self.onEnterCallbacks or {}
    table.insert(self.onEnterCallbacks, callback)
end

local MenuManager = {}
MenuManager.__index = MenuManager

function MenuManager:new()
    local instance = setmetatable({}, self)
    instance.root = MenuItem:new("root")
    instance.current = instance.root
    return instance
end

function MenuManager:addMenu(name, description)
    return self.root:addMenu(name, description)
end

function MenuManager:enter(index, on_enter_action)
    local submenu = self.current:enter(index or self.current.selectedIndex, on_enter_action)
    if submenu then
        self.current = submenu
    end
    return self.current
end

function MenuManager:up()
    self.current = self.current:up()
    return self.current
end

function MenuManager:pageLeft()
    if self.current.currentPage > 1 then
        self.current.currentPage = self.current.currentPage - 1
        self.current.selectedIndex = 1
    end
end

function MenuManager:pageRight()
    if self.current.currentPage < self.current:pageCount() then
        self.current.currentPage = self.current.currentPage + 1
        self.current.selectedIndex = 1
    end
end

local function upRecursive(menu_item, action)
    if menu_item.parent then
        action(menu_item, menu_item.parent)
        upRecursive(menu_item.parent, action)
    end
end

local function downRecursive(menu_item, action)
    if #menu_item.children > 0 then
        for _, child in ipairs(menu_item.children) do
            action(menu_item, child)
            downRecursive(child, action)
        end
    end
end

function MenuManager:focus(menu_item)
    if menu_item and menu_item.children then
        self.current = #menu_item.children > 0 and menu_item or menu_item.parent
        upRecursive(menu_item, function(current, parent)
            for index, value in ipairs(parent.children) do
                if value == current then
                    parent.currentPage = math.ceil(index / MAX_ITEMS_PER_PAGE)
                    parent.selectedIndex = index - (MAX_ITEMS_PER_PAGE * (parent.currentPage - 1))
                    break
                end
            end
        end)
    end
end

return MenuManager