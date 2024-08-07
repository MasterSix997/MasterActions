local render = require("wheel_render")

-- Class Menu
local Menu = {
    Name = "",
    Data = {},
    IsShowing = false,
    Parent = {},
    ParentIndex = 0,
    Childs = {},
    MainMenu = {},
    CurrentPage = 0
}

function Menu:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Menu:AddMenu(name)
    local child_menu = Menu:new()
    child_menu.Name = name
    child_menu.MainMenu = self.MainMenu

    child_menu.Parent = self
    child_menu.ParentIndex = #self.Childs + 1
    table.insert(self.Childs, child_menu)
    table.insert(self.Data, {text = name})
    --self.Data = render.create_wheel_data(self.Data)
    return child_menu
end

function Menu:CreateData()
    self.Data = render.create_wheel_data(self.Data)
end

function Menu:Show()
    self.IsShowing = true
    self.MainMenu:ShowMenu(self)
end

function Menu:Hide()
    if self.IsShowing then
        self.IsShowing = false
        self.MainMenu:HideMenu()
    end
end

function Menu:ShowParent()
    self.IsShowing = false
    self.Parent:Show()
end

function Menu:ShowChild(child)
    self.IsShowing = false
    self.Childs[child]:Show()
end

function Menu:GetPageData()
    return self.Data
end

-- Class Wheel

local wheel = Menu:new()
wheel.MainMenu = wheel
local current_showing = nil
local is_open = false

local selectedSlice = 0
local minSize = 0.01
local data = {}

local function open_wheel()
    if is_open then
        return
    end

    is_open = true

    util.create_tick_handler(function ()
        if not current_showing then
            return false
        end

        local isInController = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)

        if isInController then
            selectedSlice = render.slice_in_analog_position(#data, selectedSlice, minSize)
        else
            selectedSlice = render.slice_in_mouse_position(0.5, 0.5, 0.1, 0.01, #data, selectedSlice, minSize)
        end

        if render.show_cursor_on_screen() then return true end

        render.draw_wheel_menu(0.5, 0.5, 0.1, 0.01, 24, data, selectedSlice, minSize)
    end)
end

local function close_wheel()
    is_open = false
    current_showing = nil
    selectedSlice = 0
    data = {}
end

function wheel:ShowMenu(menuToShow)
    current_showing = menuToShow
    data = current_showing:GetPageData()
    --data = {{isText = true, text = "AAHHAHA"}, {isText = true, text = "ASJSJK"}, isCreated = true}
    if not is_open then
        open_wheel()
    end
end

function wheel:HideMenu()
    if is_open then
        close_wheel()
    end
end

return wheel