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

local function DrawCircleSlice(cx, cy, outerRadius, innerRadius, segments, startAngle, sliceSize, r, g, b, a)
    local angleStep = sliceSize / segments

    local screenWidth, screenHeight = directx.get_client_size()
    local aspectRatio = screenWidth / screenHeight

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
end

local function DrawSlicedCircle(cx, cy, outerRadius, innerRadius, totalSlices, totalSegments, data, exclude, sizes)
    local startAngle = 0

    for i = 1, totalSlices do
        if data["r"] then
            data[i] = {}
            data[i].color = data
        end
        data[i] = data[i] or {}
        local color = data[i].color or {["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 0.5}

        if not exclude or exclude ~= i then
            local sliceSegments = math.ceil(sizes[i] / (2 * math.pi) * totalSegments)
            DrawCircleSlice(cx, cy, outerRadius, innerRadius, sliceSegments, startAngle, sizes[i], color["r"], color["g"], color["b"], color["a"])
        end

        startAngle = startAngle + sizes[i]
    end
end

local function DrawTextInSlice(text, cx, cy, radius, sliceAngle, startAngle, scale, color, font)
    -- Não exibir texto se o pedaço for muito pequeno
    --if sliceAngle < 0.1 then
    --    return
    --end
    
    local midAngle = startAngle + (sliceAngle / 2)

    local screenWidth, screenHeight = directx.get_client_size()
    local aspectRatio = screenWidth / screenHeight

    local textX = cx + radius * math.cos(midAngle)
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

local function DrawTextureInSlice(textureID, cx, cy, radius, sliceAngle, startAngle, scale, color)
    -- Não exibir textura se o pedaço for muito pequeno
    --if sliceAngle < 0.1 then
    --    return
    --end

    local midAngle = startAngle + (sliceAngle / 2)

    local screenWidth, screenHeight = directx.get_client_size()
    local aspectRatio = screenWidth / screenHeight

    local textureX = cx + radius * math.cos(midAngle)
    local textureY = cy + radius * math.sin(midAngle) * aspectRatio

    directx.draw_texture_client(textureID, scale or 0.01, scale or 0.01, textureX, textureY, textureX, textureY, 0, color or {["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0})
end

local function DrawDataInSlices(cx, cy, radius, totalSlices, data, sizes)
    local startAngle = 0
    local maxSliceSize = 0.4
    for i = 1, totalSlices do
        local sliceSize = sizes[i]
        local scale = math.min(0.6 * (sliceSize / maxSliceSize), 0.6)
        if data[i].isText then
            DrawTextInSlice(data[i].text, cx, cy, radius, sliceSize, startAngle, scale, data[i].textColor, data[i].font)
        elseif data[i].isTexture then
            if directx.has_texture_loaded(loadedTextures[data[i].texture]) then
                DrawTextureInSlice(loadedTextures[data[i].texture], cx, cy, radius, sliceSize, startAngle, scale, data[i].textureColor)
            else
                DrawTextInSlice("Loading Texture: " .. data[i].texture, cx, cy, radius, sliceSize, startAngle, nil, {["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 1})
            end
        end
        startAngle = startAngle + sliceSize
    end
end

local function CalculateSegmentSizes(totalSlices, selectedSlice, minSliceSize)
    local sizes = {}
    
    local equalSize = (2 * math.pi) / totalSlices
    if not selectedSlice or selectedSlice == 0 or equalSize >= minSliceSize then
        -- Se nenhum pedaço está selecionado, todos os pedaços terão o mesmo tamanho
        local equalSize = (2 * math.pi) / totalSlices
        for i = 1, totalSlices do
            sizes[i] = equalSize
        end
    else
        -- Se um pedaço está selecionado, calcular tamanhos ajustados
        local adjustedMinSize = minSliceSize--math.max(minSliceSize, equalSize)
        
        local remainingAngle = 2 * math.pi - adjustedMinSize
        sizes[selectedSlice] = adjustedMinSize
        local baseSize = remainingAngle / (totalSlices - 1)

        for i = 1, totalSlices do
            if i ~= selectedSlice then
                local distance = math.abs(i - selectedSlice)
                if distance > totalSlices / 2 then
                    distance = totalSlices - distance
                end
                sizes[i] = baseSize * (1 - (distance / (totalSlices - 1)))
            end
        end

        -- Normalizar os tamanhos para garantir que somam 2 * math.pi
        local totalAngle = 0
        for i = 1, totalSlices do
            totalAngle = totalAngle + sizes[i]
        end

        local normalizationFactor = (2 * math.pi) / totalAngle
        for i = 1, totalSlices do
            sizes[i] = sizes[i] * normalizationFactor
        end
    end

    return sizes
end

function menu.create_wheel_data(data)
    data = data or {}

    for index, value in ipairs(data) do
        if value.texture then
            data[index].isTexture = true
            if not loadedTextures[value.texture] then
                if filesystem.exists(value.texture) then
                    loadedTextures[value.texture] = directx.create_texture(value.texture)
                else
                    data[index].texture = false
                    data[index].text = "INVALID_TEXTURE"
                    data[index].textColor = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}
                    data[index].isText = true
                end
            end
        elseif value.text then
            data[index].isText = true
        else
            data[index].text = "INVALID_DATA"
            data[index].textColor = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}
            data[index].isText = true
        end
    end

    data[0] = data[0] or {text = "STOP", textColor = {["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1}}

    data.isCreated = true
    return data
end

function menu.draw_wheel_menu(cx, cy, outerRadius, innerRadius, circleSegments, data, selectedSlice, minSliceSize)
    if not data then
        return
    end

    local slices = #data
    local sizes = CalculateSegmentSizes(slices, selectedSlice, minSliceSize)

    DrawSlicedCircle(
        cx, cy,
        outerRadius, innerRadius,
        slices,
        circleSegments,
        data,
        selectedSlice,
        sizes
    )
    if selectedSlice and selectedSlice > 0 then
        local startAngle = 0
        for i = 1, selectedSlice - 1 do
            startAngle = startAngle + sizes[i]
        end
        DrawCircleSlice(cx, cy, outerRadius, innerRadius, math.ceil(sizes[selectedSlice] / (2 * math.pi) * circleSegments), startAngle, sizes[selectedSlice], 0.5, 0.7, 1, 0.6)
    end

    DrawDataInSlices(cx, cy, (outerRadius - innerRadius) / 2 + 0.015, slices, data, sizes)

    DrawSlicedCircle(
        cx, cy,
        outerRadius + 0.003, outerRadius,
        slices,
        circleSegments,
        {["r"] = 0.1, ["g"] = 0.1, ["b"] = 0.1, ["a"] = 0.9},
        -5,
        sizes
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

function menu.slice_in_mouse_position(cx, cy, outerRadius, innerRadius, total_slices, lastSelectedSlice, minSliceSize)
    local mousePos = {x = PAD.GET_DISABLED_CONTROL_NORMAL(2, 239), y = PAD.GET_DISABLED_CONTROL_NORMAL(2, 240)}
    return menu.slice_in_position(cx, cy, outerRadius, innerRadius, total_slices, mousePos.x, mousePos.y, lastSelectedSlice, minSliceSize)
end

function menu.slice_in_analog_position(total_slices, selectedSlice, minSliceSize)
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
    return menu.slice_in_position(0, 0, 1, 0.01, total_slices, analogPos.x, analogPos.y, selectedSlice, minSliceSize)
end

function menu.slice_in_position(cx, cy, outerRadius, innerRadius, total_slices, px, py, selectedSlice, minSliceSize)
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

    local sizes = CalculateSegmentSizes(total_slices, selectedSlice, minSliceSize)

    local accumulatedAngle = 0
    for i = 1, total_slices do
        accumulatedAngle = accumulatedAngle + sizes[i]
        if angle <= accumulatedAngle then
            return i
        end
    end

    return nil
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