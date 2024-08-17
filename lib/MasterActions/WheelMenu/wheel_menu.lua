--util.require_natives("3095a")
local wheel_nav = require("MasterActions.lib.MasterActions.WheelMenu.wheel_navigation")
local wheel_render = require("MasterActions.lib.MasterActions.WheelMenu.wheel_render")
local scaleform = require("ScaleformLib")
local sf = scaleform('instructional_buttons')

local default_settings = {
    close_wheel_on_back_in_root = true,
    close_wheel_on_play_action = true,
    reset_wheel_menu_on_play_action = false,
    close_wheel_on_outside_click = false,
    select_even_outside_the_wheel = true,
    reset_mouse_position_on_navigate = true,
    disable_the_wheel_instead_of_returning = false,
    key_input = {
        master_control = 44,--171,
        open_root = 22,
        back = 202,
        close = 199,
        choose = 24,
        next_page = 14,
        previous_page = 15
    },
    gamepad_input = {
        master_control = 44,
        open_root = 47,
        back = 202,
        close = 200,
        choose = 24,
        next_page = 44,
        previous_page = 37
    },
    style = {
        center_x = 0.5,
        center_y = 0.5,
        outer_radius = 0.1,
        inner_radius = 0.01,
        circle_resolution = 24,
        blur_force = 7,
        sizes = {
            border = 0.003,
            stop_border = 0.015,
            page_button = 0.03,
            data_distance = 0.08,
            text = 0.6,
            texture = 0.01,
            text_and_texture_distance = 0.01
        },
        colors = {
            circle = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5},
            circle_divider = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5},
            text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
            selected_text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
            selected = {["r"] = 0.5, ["g"] = 0.7, ["b"] = 1, ["a"] = 0.6},
            border = {["r"] = 0.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.9},
            selected_border = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.6},
            stop = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
            stop_text = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1},
            page_button = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
        }
    }
}

local function scaleform_update(self, is_in_controller, binds)
    sf.CLEAR_ALL()
    sf.TOGGLE_MOUSE_BUTTONS(false)

    sf.SET_DATA_SLOT(0, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.back, true), "Back")
    sf.SET_DATA_SLOT(1, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.close, true), "Close")
    sf.SET_DATA_SLOT(2, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.choose, true), "Choose")
    sf.SET_DATA_SLOT(3, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.next_page, true), "Next Page")
    sf.SET_DATA_SLOT(4, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, binds.previous_page, true), "Previous Page")
    if not self.settings.disable_the_wheel_instead_of_returning then
        sf.SET_DATA_SLOT(5, PAD.GET_CONTROL_INSTRUCTIONAL_BUTTONS_STRING(2, 25, true), "Back")
    end
    sf.DRAW_INSTRUCTIONAL_BUTTONS()
    sf:draw_fullscreen()
end

local WheelMenu = {}
WheelMenu.__index = WheelMenu

function WheelMenu:new(settings)
    local instance = setmetatable({}, self)
    instance.nav = wheel_nav:new()
    instance.settings = settings or default_settings
    instance.is_open = false
    instance.current_data = {}
    instance.selected_slice = nil
    instance.is_looking_pressed = false
    instance.mouse_pos_before_look = {x = 0, y = 0}
    instance.has_back_key_pressed = false
    instance.has_close_key_pressed = false
    instance.has_choose_key_pressed = false
    instance.has_next_page_key_pressed = false
    instance.has_previous_page_key_pressed = false
    return instance
end

function WheelMenu:calculate_selected_slice()
    local is_in_controller = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)

    if is_in_controller then
        local new_selected = wheel_render.slice_in_analog_position(#self.current_data)
        if new_selected and new_selected > 0 then
            self.selected_slice = new_selected
        end
    else
        self.selected_slice = wheel_render.slice_in_mouse_position(
            self.settings.style.center_x,
            self.settings.style.center_y,
            self.settings.select_even_outside_the_wheel and 1 or self.settings.style.outer_radius,
            self.settings.style.inner_radius,
            #self.current_data
        )
    end

    if self.selected_slice and self.selected_slice > 0 then
        self.nav.current.selectedIndex = self.selected_slice
    else
        self.nav.current.selectedIndex = 1
    end
end

function WheelMenu:update_data()
    self.current_data = self.nav.current:pageItems()
    self.current_data[0] = self.current_data[0] or {text = "STOP", textColor = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}}
    self.selected_slice = 0
end

function WheelMenu:go_to_parent()
    if not self.nav.current.parent then
        if self.settings.close_wheel_on_back_in_root then
            self:close()
        end
        return
    end
    self.nav:up()
    self:update_data()
    if self.settings.reset_mouse_position_on_navigate then
        PAD.SET_CURSOR_POSITION(self.settings.style.center_x, self.settings.style.center_y)
    end
end

function WheelMenu:update_tick()
    if not self.is_open then return false end

    -- Bloquear certas ações
    PAD.DISABLE_CONTROL_ACTION(2, 25, true)
    PAD.DISABLE_CONTROL_ACTION(2, 24, true)
    PAD.DISABLE_CONTROL_ACTION(2, 257, true)
    PAD.DISABLE_CONTROL_ACTION(2, 140, true)

    if self.settings.disable_the_wheel_instead_of_returning and PAD.IS_DISABLED_CONTROL_PRESSED(2, 25) then
        if not self.is_looking_pressed then
            self.is_looking_pressed = true
            self.mouse_pos_before_look = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
        end
        return true
    end

    if self.is_looking_pressed then
        self.is_looking_pressed = false
        PAD.SET_CURSOR_POSITION(self.mouse_pos_before_look.x, self.mouse_pos_before_look.y)
    end

    local is_in_controller = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)
    if not is_in_controller then
        HUD.SET_MOUSE_CURSOR_THIS_FRAME()
    end

    PAD.DISABLE_CONTROL_ACTION(2, 1, true)
    PAD.DISABLE_CONTROL_ACTION(2, 2, true)

    local binds = self.settings.key_input
    if is_in_controller then
        binds = self.settings.gamepad_input
    end

    PAD.DISABLE_CONTROL_ACTION(2, binds.back, true)
    PAD.DISABLE_CONTROL_ACTION(2, binds.close, true)
    PAD.DISABLE_CONTROL_ACTION(2, binds.choose, true)
    PAD.DISABLE_CONTROL_ACTION(2, binds.next_page, true)
    PAD.DISABLE_CONTROL_ACTION(2, binds.previous_page, true)

    self:calculate_selected_slice()

    local current_menu = self.nav.current
    local selected_page = 0

    if self.settings.style.blur_force > 0 then
        wheel_render.blur(self.settings.style.blur_force)
    end

    if current_menu:pageCount() > 1 then
        wheel_render.draw_page_informations(current_menu, self.settings.style.center_x, self.settings.style.center_y, self.settings.style.outer_radius + 0.01, 1, self.settings.style.colors.text)

        if not is_in_controller then
            selected_page = wheel_render.page_buttons(
                current_menu.currentPage > 1,
                current_menu.currentPage < current_menu:pageCount(),
                self.settings.style.center_x,
                self.settings.style.center_y,
                self.settings.style.outer_radius + 0.02,
                self.settings.style
            )

            if selected_page ~= 0 then
                self.selected_slice = nil
                self.nav.current.selectedIndex = 1
            end
        end
    end

    if PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.back) or 
       (not self.settings.disable_the_wheel_instead_of_returning and PAD.IS_DISABLED_CONTROL_PRESSED(2, 25)) then
        if not self.has_back_key_pressed then
            self:go_to_parent()
        end
        self.has_back_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.close) then
        if not self.has_close_key_pressed then
            self:close()
        end
        self.has_close_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.choose) then
        if not self.has_choose_key_pressed then
            if selected_page ~= 0 then
                self:change_page(selected_page)
            else
                self:select_current()
            end
        end
        self.has_choose_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.previous_page) then
        if not self.has_previous_page_key_pressed then
            self:change_page(-1)
        end
        self.has_previous_page_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.next_page) then
        if not self.has_next_page_key_pressed then
            self:change_page(1)
        end
        self.has_next_page_key_pressed = true
    else
        self.has_back_key_pressed = false
        self.has_close_key_pressed = false
        self.has_choose_key_pressed = false
        self.has_next_page_key_pressed = false
        self.has_previous_page_key_pressed = false
    end

    --scaleform_update(self, is_in_controller, binds)

    wheel_render.draw_selected_description(self.current_data, self.selected_slice, self.settings.style.center_x, self.settings.style.center_y, self.settings.style.outer_radius + 0.01, 1, self.settings.style.colors.text)

    wheel_render.draw_wheel_menu(self.current_data, self.selected_slice, self.settings.style)
end

function WheelMenu:open()
    if self.is_open then return end

    self.is_open = true
    self:update_data()
    PAD.SET_CURSOR_POSITION(self.settings.style.center_x, self.settings.style.center_y)
    util.create_tick_handler(function() return self:update_tick() end)
end

function WheelMenu:close()
    self.is_open = false
    self.selected_slice = nil
    self.current_data = nil
end

function WheelMenu:select_current()
    if not self.selected_slice then
        if self.settings.close_wheel_on_outside_click then
            self:close()
        end
    elseif self.selected_slice == 0 then
        self:close()
    else
        self.nav:enter(nil, function (action_menu)
            if self.settings.close_wheel_on_play_action then
                self:close()
                util.toast("Play action: " .. action_menu.name)
            end
            if self.settings.reset_wheel_menu_on_play_action then
                self.nav:focus(self.nav.root)
            end
        end)

        self:update_data()
        if self.settings.reset_mouse_position_on_navigate then
            PAD.SET_CURSOR_POSITION(self.settings.style.center_x, self.settings.style.center_y)
        end
    end
end

function WheelMenu:change_page(direction)
    if direction == -1 then
        self.nav:pageLeft()
    elseif direction == 1 then
        self.nav:pageRight()
    end
    self:update_data()
end

function WheelMenu:create_textures()
    wheel_render.create_textures(self.nav.root.children)
end
return {
    new = function(settings)
        return WheelMenu:new(settings)
    end
}
