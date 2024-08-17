local WheelRender = {}

local loaded_textures = {}

local default_style = {
    center_x = 0.5,
    center_y = 0.5,
    outer_radius = 0.1,
    inner_radius = 0.01,
    circle_resolution = 24,
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
        text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
        wheel_text_out_focus = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
        selected_text = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
        circle = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5},
        circle_divider = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5},
        selected = {["r"] = 0.5, ["g"] = 0.7, ["b"] = 1, ["a"] = 0.6},
        border = {["r"] = 0.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.9},
        selected_border = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.6},
        stop = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
        stop_text = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1},
        page_button = {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1},
    }
}

local function draw_circle(center_x, center_y, outer_radius, inner_radius, total_segments, color)
    local angle_step = (2 * math.pi) / total_segments
    local current_angle = 0

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    for i = 1, total_segments do
        local x1_outer = center_x + outer_radius * math.cos(current_angle)
        local y1_outer = center_y + outer_radius * math.sin(current_angle) * aspect_ratio
        local x2_outer = center_x + outer_radius * math.cos(current_angle + angle_step)
        local y2_outer = center_y + outer_radius * math.sin(current_angle + angle_step) * aspect_ratio
        
        local x1_inner = center_x + inner_radius * math.cos(current_angle)
        local y1_inner = center_y + inner_radius * math.sin(current_angle) * aspect_ratio
        local x2_inner = center_x + inner_radius * math.cos(current_angle + angle_step)
        local y2_inner = center_y + inner_radius * math.sin(current_angle + angle_step) * aspect_ratio

        directx.draw_triangle_client(x1_inner, y1_inner, x1_outer, y1_outer, x2_outer, y2_outer, color)
        directx.draw_triangle_client(x1_inner, y1_inner, x2_outer, y2_outer, x2_inner, y2_inner, color)

        current_angle = current_angle + angle_step
    end
end

local function draw_circle_slice(center_x, center_y, outer_radius, inner_radius, segments_per_slice, total_slices, slice_index, color, divider_color)
    local slice_angle = (2 * math.pi) / total_slices
    local start_angle = slice_angle * (slice_index - 1)
    local angle_step = slice_angle / segments_per_slice

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    local current_angle = start_angle

    for i = 1, segments_per_slice do
        local x1_outer = center_x + outer_radius * math.cos(current_angle)
        local y1_outer = center_y + outer_radius * math.sin(current_angle) * aspect_ratio
        local x2_outer = center_x + outer_radius * math.cos(current_angle + angle_step)
        local y2_outer = center_y + outer_radius * math.sin(current_angle + angle_step) * aspect_ratio
        
        local x1_inner = center_x + inner_radius * math.cos(current_angle)
        local y1_inner = center_y + inner_radius * math.sin(current_angle) * aspect_ratio
        local x2_inner = center_x + inner_radius * math.cos(current_angle + angle_step)
        local y2_inner = center_y + inner_radius * math.sin(current_angle + angle_step) * aspect_ratio

        directx.draw_triangle_client(x1_inner, y1_inner, x1_outer, y1_outer, x2_outer, y2_outer, color)
        directx.draw_triangle_client(x1_inner, y1_inner, x2_outer, y2_outer, x2_inner, y2_inner, color)

        current_angle = current_angle + angle_step
    end

    directx.draw_line_client(
        center_x + (outer_radius) * math.cos(current_angle),
        center_y + (outer_radius) * math.sin(current_angle) * aspect_ratio,
        center_x + inner_radius * math.cos(current_angle),
        center_y + inner_radius * math.sin(current_angle) * aspect_ratio, divider_color or color
    )
end

local function draw_sliced_circle(center_x, center_y, outer_radius, inner_radius, total_slices, total_segments, data, exclude, default_color, divider_color)
    for i = 1, total_slices do
        if data["r"] then
            data[i] = {}
            data[i].color = data
        end
        data[i] = data[i] or {}
        local color = data[i].color or default_color

        if not exclude or exclude ~= i then
            draw_circle_slice(center_x, center_y, outer_radius, inner_radius, math.ceil(total_segments / total_slices), total_slices, i, color, divider_color)
        end
    end
end

local function draw_text_in_slice(text, center_x, center_y, radius, total_slices, slice_index, scale, color, font)
    local slice_angle = (2 * math.pi) / total_slices
    local start_angle = slice_angle * (slice_index - 1)
    local mid_angle = start_angle + (slice_angle / 2)

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    local text_x = center_x + radius * math.cos(mid_angle)
    local text_y = center_y + radius * math.sin(mid_angle) * aspect_ratio

    directx.draw_text_client(
        text_x, text_y,
        text,
        5,
        scale,
        color,
        false,
        font
    )
end

local function draw_texture_in_slice(texture_id, center_x, center_y, radius, total_slices, slice_index, scale, color)
    local slice_angle = (2 * math.pi) / total_slices
    local start_angle = slice_angle * (slice_index - 1)
    local mid_angle = start_angle + (slice_angle / 2)

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    local texture_x = center_x + radius * math.cos(mid_angle)
    local texture_y = center_y + radius * math.sin(mid_angle) * aspect_ratio

    directx.draw_texture_client(texture_id, scale, scale, texture_x, texture_y, texture_x, texture_y, 0, color)
end

--if is group, indicative
local function draw_slice_type(center_x, center_y, size, radius, total_slices, slice_index, color)
    local slice_angle = (2 * math.pi) / total_slices
    local start_angle = slice_angle * (slice_index - 1)
    local mid_angle = start_angle + (slice_angle / 2)

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    local x = center_x + radius * math.cos(mid_angle)
    local y = center_y + radius * math.sin(mid_angle) * aspect_ratio

    color["a"] = 0.6
    directx.draw_circle_client(x, y, size, color, -1)
    directx.draw_line_client(x, y, center_x, center_y, color)
end

local function draw_data_in_slices(center_x, center_y, radius, total_slices, data, highlight_index, style)
    for i = 1, total_slices do
        
        if data[i].drawMode == 0 then
            local color = data[i].textSettings.color or style.colors.wheel_text_out_focus
            local scale = data[i].textSettings.scale or style.sizes.text
            if highlight_index == i then
                color = style.colors.selected_text
            end

            draw_text_in_slice(data[i].text, center_x, center_y, radius, total_slices, i, scale, color, data[i].textSettings.font)

        elseif data[i].drawMode == 1 then
            if directx.has_texture_loaded(loaded_textures[data[i].textureSettings.path]) then
                local color = data[i].textureSettings.color or {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1}
                local scale = data[i].textureSettings.scale or style.sizes.texture
                draw_texture_in_slice(loaded_textures[data[i].textureSettings.path], center_x, center_y, radius, total_slices, i, scale, color)
            else
                draw_text_in_slice("Loading Texture: ", center_x, center_y, radius, total_slices, i, style.sizes.text, {["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 1})
            end

        elseif data[i].drawMode == 2 then
            local text_color = data[i].textSettings.color or style.colors.wheel_text_out_focus
            local text_scale = data[i].textSettings.scale or style.sizes.text
            if highlight_index == i then
                text_color = style.colors.selected_text
            end
            local texture_color = data[i].textureSettings.color or {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1}
            local texture_scale = data[i].textureSettings.scale or style.sizes.texture

            draw_text_in_slice(data[i].text, center_x, center_y, radius - style.sizes.text_and_texture_distance, total_slices, i, text_scale, text_color, data[i].textSettings.font)
            if directx.has_texture_loaded(loaded_textures[data[i].textureSettings.path]) then
                draw_texture_in_slice(loaded_textures[data[i].textureSettings.path], center_x, center_y, radius + style.sizes.text_and_texture_distance, total_slices, i, texture_scale, texture_color)
            end
        end

        if #data[i].children > 0 then
            local color = data[i].textSettings.color or style.colors.wheel_text_out_focus
            if highlight_index == i then
                color = style.colors.selected_text
            end

            draw_slice_type(center_y, center_y, 0.005, radius / 2, total_slices, i, color)
        end
    end
end

function WheelRender.draw_wheel_menu(data, selected_slice, style)
    if not data then
        return
    end

    style = style or default_style

    local slices = #data

    -- circle slices
    draw_sliced_circle(
        style.center_x, style.center_y,
        style.outer_radius, style.inner_radius,
        slices,
        style.circle_resolution,
        data,
        selected_slice,
        style.colors.circle, style.colors.circle_divider
    )
    -- selected slice
    if selected_slice and selected_slice > 0 then
        draw_circle_slice(style.center_x, style.center_y, style.outer_radius, style.inner_radius, math.ceil(style.circle_resolution / slices), slices, selected_slice, style.colors.selected)
    end

    draw_data_in_slices(style.center_x, style.center_y, style.sizes.data_distance, slices, data, selected_slice, style)

    -- wheel border
    draw_sliced_circle(
        style.center_x, style.center_y,
        style.outer_radius + style.sizes.border, style.outer_radius,
        slices,
        style.circle_resolution,
        data,
        selected_slice,
        style.colors.border
    )
    -- selected wheel border
    if selected_slice and selected_slice > 0 then
        draw_circle_slice(style.center_x, style.center_y, style.outer_radius + style.sizes.border, style.outer_radius, math.ceil(style.circle_resolution / slices), slices, selected_slice, style.colors.selected_border)
    end

    -- selected stop circle
    if selected_slice == 0 then
        draw_circle(style.center_x, style.center_y, style.inner_radius + style.sizes.stop_border, 0, style.circle_resolution, style.colors.selected)
    end
    -- stop circle
    draw_circle(style.center_x, style.center_y, style.inner_radius, 0, style.circle_resolution, style.colors.stop)

    -- stop text
    directx.draw_text_client(
        style.center_x, style.center_y,
        data[0].text,
        5,
        0.5,
        style.colors.stop_text,
        false,
        nil
    )
end

function WheelRender.slice_in_mouse_position(cx, cy, outer_radius, inner_radius, total_slices)
    local mousePos = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
    return WheelRender.slice_in_position(cx, cy, outer_radius, inner_radius, total_slices, mousePos.x, mousePos.y)
end

function WheelRender.slice_in_analog_position(total_slices)
    local analog_pos = {x = PAD.GET_CONTROL_NORMAL(2, 220), y = PAD.GET_CONTROL_NORMAL(2, 221)}
    -- DEBUG
    --[[directx.draw_text_client(
        0.1, 0.1,
        "X: " .. analog_pos.x .. " | Y:" .. analog_pos.y, -- text
        5, -- align
        1, -- scale 
        1, 1, 1, 1, -- color
        false, -- force_in_bounds 
        nil -- font 
    )]]
    return WheelRender.slice_in_position(0, 0, 1, 0.01, total_slices, analog_pos.x, analog_pos.y)
end

function WheelRender.slice_in_position(cx, cy, outer_radius, inner_radius, total_slices, px, py)
    local screen_width, screen_height = directx.get_client_size()

    px = px * screen_width
    py = py * screen_height

    cx = cx * screen_width
    cy = cy * screen_height

    local dx = px - cx
    local dy = py - cy
    local distance = math.sqrt(dx^2 + dy^2) / screen_width

    if distance < inner_radius then
        return 0
    end

    if distance > outer_radius then
        return nil
    end

    local angle = math.atan2(dy, dx)
    if angle < 0 then
        angle = angle + 2 * math.pi
    end

    local slice_angle = (2 * math.pi) / total_slices
    local slice_index = math.floor(angle / slice_angle) + 1

    return slice_index
end

function WheelRender.draw_page_informations(data, textX, textY, radius, scale, color)
    local mid_angle = 4.7

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    textX = textX + radius * math.cos(mid_angle)-- / aspectRatio
    textY = textY + radius * math.sin(mid_angle) * aspect_ratio

    directx.draw_text_client(
        textX, textY, -- X, Y
        data.currentPage .. "/" .. data:pageCount(), -- text
        5, -- align
        scale or 0.6, -- scale 
        color or {					-- colour
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0
        },
        false, -- force_in_bounds 
        nil -- font 
    )
end

function WheelRender.draw_selected_description(data, selected, textX, textY, radius, scale, color)
    if not selected or selected < 1 or not data[selected].description then
        return false
    end

    local mid_angle = 4.7

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    textX = textX + radius * math.cos(mid_angle)
    textY = textY - radius * math.sin(mid_angle) * aspect_ratio

    directx.draw_text_client(
        textX, textY,
        data[selected].description,
        5,
        scale or 0.6,
        color or {
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0
        },
        false,
        nil
    )
end

function WheelRender.page_buttons(previous_enabled, next_enabled, center_x, center_y, radius, style)
    style = style or default_style

    local screen_width, screen_height = directx.get_client_size()
    local aspect_ratio = screen_width / screen_height

    local size_y = default_style.sizes.page_button * aspect_ratio


    ---------------- INPUT CHECK ----------------
    local selected = 0

    local left_x_min = (center_x - default_style.sizes.page_button / 2) - radius
    local left_x_max = left_x_min + default_style.sizes.page_button
    local right_x_min = (center_x - default_style.sizes.page_button / 2) + radius
    local right_x_max = right_x_min + default_style.sizes.page_button
    local y_min = center_y - size_y / 2
    local y_max = y_min + size_y

    local px, py = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)

    if px >= left_x_min and px <= left_x_max and py >= y_min and py <= y_max then
        selected = -1
    end

    if px >= right_x_min and px <= right_x_max and py >= y_min and py <= y_max then
        selected = 1
    end

    ---------------- DRAW ----------------
    center_x = center_x - default_style.sizes.page_button / 2
    center_y = center_y - size_y / 2

    local color = style.colors.page_button
    local selected_color = style.colors.selected
    local disabled_color = {["r"] = color["r"], ["g"] = color["g"], ["b"] = color["b"], ["a"] = 0.1}

    local left_color = color
    local right_color = color
    
    if previous_enabled and selected == -1 then
        left_color = selected_color
    elseif not previous_enabled then
        left_color = disabled_color
    end

    if next_enabled and selected == 1 then
        right_color = selected_color
    elseif not next_enabled then
        right_color = disabled_color
    end

    directx.draw_rect_client(
        center_x - radius, center_y,
        default_style.sizes.page_button, size_y,
        left_color
    )

    directx.draw_rect_client(
        center_x + radius, center_y,
        default_style.sizes.page_button, size_y,
        right_color
    )

    return selected
end

function WheelRender.create_textures(data)
    for i, menu_item in ipairs(data) do
        if menu_item.drawMode == 1 or 2 and menu_item.textureSettings then
            if not loaded_textures[menu_item.textureSettings.path] then
                if filesystem.exists(menu_item.textureSettings.path) then
                    loaded_textures[menu_item.textureSettings.path] = directx.create_texture(menu_item.textureSettings.path)
                else
                    menu_item.drawMode = 0
                    menu_item.text = "INVALID_TEXTURE"
                    menu_item.textSettings = {color = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}}
                    menu_item.textureSettings = {}
                end
            end
            -- Small texture
            --if menu_item.drawMode == 2 then
            --    menu_item.text = menu_item.text .. "\n" .. directx.get_texture_character(loaded_textures[menu_item.textureSettings.path])
            --end
        end

        if menu_item.children and #menu_item.children > 0 then
            WheelRender.create_textures(menu_item.children)
        end
    end
end

local blurId

local function cleanup()
    directx.blurrect_free(blurId)
end

function WheelRender.blur(blur_force)
    if not blurId then
        blurId = directx.blurrect_new()
        util.on_pre_stop(cleanup)
    end

    if blur_force > 0 and blur_force <= 255 then
        directx.blurrect_draw_client(blurId, 0, 0, 1, 1, blur_force)        
    end
end

return WheelRender