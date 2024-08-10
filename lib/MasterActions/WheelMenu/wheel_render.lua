local menu = {}

local loadedTextures = {}

local function DrawCircle(cx, cy, outerRadius, innerRadius, segments, r, g, b, a)
    local angleStep = (2 * math.pi) / segments
    local angle = 0

    local screenWidth, screenHeight = directx.get_client_size()
    local aspectRatio = screenWidth / screenHeight

    for i = 1, segments do
        local x1Outer = cx + outerRadius * math.cos(angle)
        local y1Outer = cy + outerRadius * math.sin(angle) * aspectRatio
        local x2Outer = cx + outerRadius * math.cos(angle + angleStep)
        local y2Outer = cy + outerRadius * math.sin(angle + angleStep) * aspectRatio
        
        local x1Inner = cx + innerRadius * math.cos(angle)
        local y1Inner = cy + innerRadius * math.sin(angle) * aspectRatio
        local x2Inner = cx + innerRadius * math.cos(angle + angleStep)
        local y2Inner = cy + innerRadius * math.sin(angle + angleStep) * aspectRatio

        directx.draw_triangle_client(x1Inner, y1Inner, x1Outer, y1Outer, x2Outer, y2Outer, r, g, b, a)
        directx.draw_triangle_client(x1Inner, y1Inner, x2Outer, y2Outer, x2Inner, y2Inner, r, g, b, a)

        angle = angle + angleStep
    end
end

local function DrawCircleSlice(cx, cy, outerRadius, innerRadius, segments, totalSlices, sliceIndex, r, g, b, a)
    local sliceAngle = (2 * math.pi) / totalSlices
    local startAngle = sliceAngle * (sliceIndex - 1)
    local angleStep = sliceAngle / segments

    local screenWidth, screen_height = directx.get_client_size()
    local aspectRatio = screenWidth / screen_height

    local angle = startAngle

    for i = 1, segments do
        local x1Outer = cx + outerRadius * math.cos(angle)
        local y1Outer = cy + outerRadius * math.sin(angle) * aspectRatio
        local x2Outer = cx + outerRadius * math.cos(angle + angleStep)
        local y2Outer = cy + outerRadius * math.sin(angle + angleStep) * aspectRatio
        
        local x1Inner = cx + innerRadius * math.cos(angle)
        local y1Inner = cy + innerRadius * math.sin(angle) * aspectRatio
        local x2Inner = cx + innerRadius * math.cos(angle + angleStep)
        local y2Inner = cy + innerRadius * math.sin(angle + angleStep) * aspectRatio

        directx.draw_triangle_client(x1Inner, y1Inner, x1Outer, y1Outer, x2Outer, y2Outer, r, g, b, a)
        directx.draw_triangle_client(x1Inner, y1Inner, x2Outer, y2Outer, x2Inner, y2Inner, r, g, b, a)

        
        angle = angle + angleStep
    end
    directx.draw_line_client(
        cx + outerRadius * math.cos(angle),
        cy + outerRadius * math.sin(angle) * aspectRatio,
        cx + innerRadius * math.cos(angle),
        cy + innerRadius * math.sin(angle) * aspectRatio, 1, 1, 1, 1
    )
end

local function DrawSlicedCircle(cx, cy, outerRadius, innerRadius, totalSlices, totalSegments, data, exclude)
    for i = 1, totalSlices do
        if data["r"] then
            data[i] = {}
            data[i].color = data
        end
        data[i] = data[i] or {}
        local color = data[i].color or {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5}

        if not exclude or exclude ~= i then
            DrawCircleSlice(cx, cy, outerRadius, innerRadius, math.ceil(totalSegments / totalSlices), totalSlices, i, color["r"], color["g"], color["b"], color["a"])
        end
    end
end

local function DrawTextInSlice(text, cx, cy, radius, totalSlices, sliceIndex, scale, color, font)
    local sliceAngle = (2 * math.pi) / totalSlices
    local startAngle = sliceAngle * (sliceIndex - 1)
    local midAngle = startAngle + (sliceAngle / 2)

    local screenWidth, screen_height = directx.get_client_size()
    local aspectRatio = screenWidth / screen_height

    local textX = cx + radius * math.cos(midAngle)-- / aspectRatio
    local textY = cy + radius * math.sin(midAngle) * aspectRatio

    directx.draw_text_client(
        textX, textY, -- X, Y
        text, -- text
        5, -- align
        scale or 0.6, -- scale 
        color or {					-- colour
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0
        },
        false, -- force_in_bounds 
        font -- font 
    )
end

local function DrawTextureInSlice(textureID, cx, cy, radius, totalSlices, sliceIndex, scale, color)
    local sliceAngle = (2 * math.pi) / totalSlices
    local startAngle = sliceAngle * (sliceIndex - 1)
    local midAngle = startAngle + (sliceAngle / 2)

    local screenWidth, screen_height = directx.get_client_size()
    local aspectRatio = screenWidth / screen_height

    local textureX = cx + radius * math.cos(midAngle)-- / aspectRatio
    local textureY = cy + radius * math.sin(midAngle) * aspectRatio

    directx.draw_texture_client(textureID, scale or 0.01, scale or 0.01, textureX, textureY, textureX, textureY, 0, color or {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0})
end

local function DrawSliceType(cx, cy, size, radius, totalSlices, sliceIndex, color)
    local sliceAngle = (2 * math.pi) / totalSlices
    local startAngle = sliceAngle * (sliceIndex - 1)
    local midAngle = startAngle + (sliceAngle / 2)

    local screenWidth, screenHeight = directx.get_client_size()
    local aspectRatio = screenWidth / screenHeight

    local x = cx + radius * math.cos(midAngle)
    local y = cy + radius * math.sin(midAngle) * aspectRatio

    color = color or {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 0.6}
    directx.draw_circle_client(x, y, size, color, -1)
    directx.draw_line_client(x, y, cx, cy, color)
end

local function DrawDataInSlices(cx, cy, radius, totalSlices, data)
    for i = 1, totalSlices do
        if data[i].isText then
            DrawTextInSlice(data[i].text, cx, cy, radius, totalSlices, i, data[i].textScale, data[i].textColor, data[i].font)
        elseif data[i].isTexture then
            if directx.has_texture_loaded(loadedTextures[data[i].texture]) then
                DrawTextureInSlice(loadedTextures[data[i].texture], cx, cy, radius, totalSlices, i, data[i].textureScale, data[i].textureColor)
            else
                DrawTextInSlice("Loading Texture: " .. data[i].texture, cx, cy, radius, totalSlices, i, nil, {["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 1})
            end
        end
        if #data[i].children > 0 then
            DrawSliceType(cy, cy, 0.005, radius / 2, totalSlices, i, data[i].textColor)
        end
    end
end

function menu.draw_wheel_menu(cx, cy, outerRadius, innerRadius, circleSegments, data, selectedSlice, minSliceSize)
    if not data then
        return
    end

    local slices = #data

    DrawSlicedCircle(
        cx, cy,
        outerRadius, innerRadius,
        slices,
        circleSegments,
        data,
        selectedSlice
    )
    if selectedSlice and selectedSlice > 0 then
        DrawCircleSlice(cx, cy, outerRadius, innerRadius, math.ceil(circleSegments / slices), slices, selectedSlice, 0.5, 0.7, 1, 0.6)
    end

    DrawDataInSlices(cx, cy, (outerRadius - innerRadius) / 2 + 0.01, slices, data)

    DrawSlicedCircle(
        cx, cy,
        outerRadius + 0.003, outerRadius,
        slices,
        circleSegments,
        {["r"] = 0.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.9}
        --selectedSlice
    )

    if selectedSlice == 0 then
        DrawCircle(cx, cy, 0.01 + 0.005, 0, circleSegments, 1, 1, 0, 0.6)
    end
    DrawCircle(cx, cy, 0.01, 0, circleSegments, 1.0, 1.0, 1.0, 1.0)

    directx.draw_text_client(
        cx, cy,
        data[0].text,
        5,
        0.5,
        data[0].textColor,
        false,
        nil
    )
end

function menu.slice_in_mouse_position(cx, cy, outerRadius, innerRadius, total_slices)
    local mousePos = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
    return menu.slice_in_position(cx, cy, outerRadius, innerRadius, total_slices, mousePos.x, mousePos.y)
end

function menu.slice_in_analog_position(total_slices)
    -- Obter as coordenadas do analógico direito
    local analogPos = {x = PAD.GET_CONTROL_NORMAL(2, 220), y = PAD.GET_CONTROL_NORMAL(2, 221)}
    directx.draw_text_client(
        0.1, 0.1,
        "X: " .. analogPos.x .. " | Y:" .. analogPos.y, -- text
        5, -- align
        1, -- scale 
        1, 1, 1, 1, -- color
        false, -- force_in_bounds 
        nil -- font 
    )
    return menu.slice_in_position(0, 0, 1, 0.01, total_slices, analogPos.x, analogPos.y)
end

function menu.slice_in_position(cx, cy, outerRadius, innerRadius, total_slices, px, py)
    local screen_width, screen_height = directx.get_client_size()

    px = px * screen_width
    py = py * screen_height

    cx = cx * screen_width
    cy = cy * screen_height

    local dx = px - cx
    local dy = py - cy
    local distance = math.sqrt(dx^2 + dy^2) / screen_width

    if distance < innerRadius then
        return 0
    end

    if distance > outerRadius then
        return nil
    end

    local angle = math.atan2(dy, dx)
    if angle < 0 then
        angle = angle + 2 * math.pi
    end

    local sliceAngle = (2 * math.pi) / total_slices
    local sliceIndex = math.floor(angle / sliceAngle) + 1

    return sliceIndex
end

function menu.draw_page_informations(data, textX, textY, radius, scale, color)
    local midAngle = 4.7

    local screenWidth, screen_height = directx.get_client_size()
    local aspectRatio = screenWidth / screen_height

    textX = textX + radius * math.cos(midAngle)-- / aspectRatio
    textY = textY + radius * math.sin(midAngle) * aspectRatio

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

function menu.page_buttons(previous_enabled, next_enabled, center_x, center_y, radius, size, color)
    local screen_width, screen_height = directx.get_client_size()
    local aspectRatio = screen_width / screen_height

    local size_y = size * aspectRatio

    ---------------- INPUT CHECK ----------------
    local selected = 0

    local left_x_min = (center_x - size / 2) - radius
    local left_x_max = left_x_min + size
    local right_x_min = (center_x - size / 2) + radius
    local right_x_max = right_x_min + size
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
    local center_x = center_x - size / 2
    local center_y = center_y - size_y / 2

    color = color or {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 0.8}
    local selected_color = {["r"] = 1.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 0.8}
    local disabled_color = {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 0.1}

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
        size, size_y,
        left_color
    )

    directx.draw_rect_client(
        center_x + radius, center_y,
        size, size_y,
        right_color
    )

    return selected
end

return menu