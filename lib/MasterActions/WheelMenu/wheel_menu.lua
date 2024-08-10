util.require_natives("3095a")
local wheel_nav = require("MasterActions.lib.MasterActions.WheelMenu.wheel_navigation")
local wheel_render = require("MasterActions.lib.MasterActions.WheelMenu.wheel_render")

local wheel = {}

wheel.root = wheel_nav
wheel.settings = {
    center_x = 0.5,
    center_y = 0.5,
    outer_radius = 0.1,
    inner_radius = 0.01,
    resolution = 24,
    close_wheel_on_back_in_root = true,
    close_wheel_on_play_action = false,
    close_wheel_on_outside_click = false,
    select_even_outside_the_wheel = true,
    reset_mouse_position_on_navigate = true,
    disable_the_wheel_instead_of_returning = false,
    key_input = {
        back = 202,
        close = 199,
        choose = 24,
        next_page = 14,
        previous_page = 15
    },
    gamepad_input = {
        back = 202,
        close = 200,
        choose = 24,
        next_page = 44,
        previous_page = 37
    }
}

local is_open = false
local current_data = {}
local selected_slice = nil

local is_looking_pressed = false
local mouse_pos_before_look = {x = 0, y = 0}
local has_back_key_pressed = false
local has_close_key_pressed = false
local has_choose_key_pressed = false
local has_next_page_key_pressed = false
local has_previous_page_key_pressed = false
local function calculate_selected_slice()
    local is_in_controller = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)

    if is_in_controller then
        selected_slice = wheel_render.slice_in_analog_position(#current_data, selected_slice, 0)
    else
        selected_slice = wheel_render.slice_in_mouse_position(wheel.settings.center_x, wheel.settings.center_y, wheel.settings.select_even_outside_the_wheel and 1 or wheel.settings.outer_radius, wheel.settings.inner_radius, #current_data, selected_slice, 0)
    end

    if selected_slice and selected_slice > 0 then
        wheel_nav:current().selectedIndex = selected_slice
    else
        wheel_nav:current().selectedIndex = 1
    end
end

local function update_data()
    current_data = wheel_nav:current():pageItens()
    current_data[0] = current_data[0] or {text = "STOP", textColor = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}}
    selected_slice = 0
end

local function go_to_parent()
    if not wheel_nav:current().parent then
        if wheel.settings.close_wheel_on_back_in_root then
            wheel.close()
        end
        return
    end
    wheel_nav:up()
    update_data()
    if wheel.settings.reset_mouse_position_on_navigate then
        PAD.SET_CURSOR_POSITION(wheel.settings.center_x, wheel.settings.center_y)
    end
end

local function update_tick()
    if not is_open then
        return false
    end

    --if show_cursor_on_screen then return true end
    PAD.DISABLE_CONTROL_ACTION(2, 25, true) --aim
    PAD.DISABLE_CONTROL_ACTION(2, 24, true) --attack
    PAD.DISABLE_CONTROL_ACTION(2, 257, true) --attack2
    PAD.DISABLE_CONTROL_ACTION(2, 140, true) --melee attack
    if wheel.settings.disable_the_wheel_instead_of_returning and PAD.IS_DISABLED_CONTROL_PRESSED(2, 25) then
        if not is_looking_pressed then
            is_looking_pressed = true
            mouse_pos_before_look = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
        end
        return true
    end
    if is_looking_pressed then
        is_looking_pressed = false
        PAD.SET_CURSOR_POSITION(mouse_pos_before_look.x, mouse_pos_before_look.y)
    end
    local is_in_controller = not PAD.IS_USING_KEYBOARD_AND_MOUSE(2)

    if not is_in_controller then
        HUD.SET_MOUSE_CURSOR_THIS_FRAME()
    end
    PAD.DISABLE_CONTROL_ACTION(2, 1, true) --look lr
    PAD.DISABLE_CONTROL_ACTION(2, 2, true) --look ud

    local binds = wheel.settings.key_input
    if(is_in_controller) then
        binds = wheel.settings.gamepad_input
    end

    PAD.DISABLE_CONTROL_ACTION(2, wheel.settings.gamepad_input.back, true)
    PAD.DISABLE_CONTROL_ACTION(2, wheel.settings.gamepad_input.close, true)
    PAD.DISABLE_CONTROL_ACTION(2, wheel.settings.gamepad_input.choose, true)
    PAD.DISABLE_CONTROL_ACTION(2, wheel.settings.gamepad_input.next_page, true)
    PAD.DISABLE_CONTROL_ACTION(2, wheel.settings.gamepad_input.previous_page, true)

    calculate_selected_slice()

    local current_menu = wheel_nav:current()
    local selected_page = 0
    if current_menu:pageCount() > 1 then
        wheel_render.draw_page_informations(current_menu, wheel.settings.center_x, wheel.settings.center_y, wheel.settings.outer_radius + 0.01, 1)

        if not is_in_controller then
            selected_page = wheel_render.page_buttons(current_menu.currentPage > 1, current_menu.currentPage < current_menu:pageCount(), wheel.settings.center_x, wheel.settings.center_y, wheel.settings.outer_radius + 0.02, 0.03)

            if selected_page ~= 0 then
                selected_slice = nil
                wheel_nav:current().selectedIndex = 1
            end
        end
    end

    if PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.back) or (not wheel.settings.disable_the_wheel_instead_of_returning and PAD.IS_DISABLED_CONTROL_PRESSED(2, 25)) then
        if not has_back_key_pressed then
            go_to_parent()
        end
        has_back_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.close) then
        if not has_close_key_pressed then
            wheel.close()
        end
        has_close_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.choose) then
        if not has_choose_key_pressed then
            if selected_page ~= 0 then
                wheel.change_page(selected_page)
            else
                wheel.select_current()
            end
        end
        has_choose_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.previous_page) then
        if not has_previous_page_key_pressed then
            wheel.change_page(-1)
        end
        has_previous_page_key_pressed = true
    elseif PAD.IS_DISABLED_CONTROL_PRESSED(2, binds.next_page) then
        if not has_next_page_key_pressed then
            wheel.change_page(1)
        end
        has_next_page_key_pressed = true
    else
        has_back_key_pressed = false
        has_close_key_pressed = false
        has_choose_key_pressed = false
        has_next_page_key_pressed = false
        has_previous_page_key_pressed = false
    end
    

    wheel_render.draw_wheel_menu(wheel.settings.center_x, wheel.settings.center_y, wheel.settings.outer_radius, wheel.settings.inner_radius, wheel.settings.resolution, current_data, selected_slice, 0)
end

function wheel.open()
    if is_open then
        return
    end

    is_open = true
    update_data()
    PAD.SET_CURSOR_POSITION(wheel.settings.center_x, wheel.settings.center_y)

    util.create_tick_handler(update_tick)
end

function wheel.close()
    wheel_nav:focus(wheel_nav:root())
    is_open = false
    selected_slice = nil
    current_data = nil
end

function wheel.select_current()
    if not selected_slice then
        if wheel.settings.close_wheel_on_outside_click then
            wheel.close()
        end
    elseif selected_slice == 0 then
        -- Stop Action
        wheel.close()
    else
        wheel_nav:enter()
        update_data()
        if wheel.settings.close_wheel_on_play_action then
            wheel.close()
        end
        if wheel.settings.reset_mouse_position_on_navigate then
            PAD.SET_CURSOR_POSITION(wheel.settings.center_x, wheel.settings.center_y)
        end
    end
end

function wheel.change_page(direction)
    if direction == -1 then
        wheel_nav:page_left()
        update_data()
    elseif direction == 1 then
        wheel_nav:page_right()
        update_data()
    end
end

function wheel.select(index)
    
end

return wheel