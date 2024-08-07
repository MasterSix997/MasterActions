util.require_natives("3095a")
local wheel = require("wheel_menu")

wheel:addMenu("test1")
local test2 = wheel:addMenu("test2")
test2:addMenu("Test2 sub1")
test2:addMenu("Test2 sub2")
test2:addMenu("Test2 sub3"):addMenu("Test_1")
wheel:addMenu("test3")
wheel:addMenu("test4"):addMenu("Test1")

local log = ""

local function update_log()
    log = "[" .. wheel:current().name .. "] [" .. wheel.current().selectedIndex .. "/" .. #wheel.current().children .."]\n"
    for index, value in ipairs(wheel:current().children) do
        log = log .. "\n" .. (index == wheel.current().selectedIndex and "*" or index)
        log = log .. " - " .. value.name .. (#value.children > 0 and " (dir)" or " (file)")
    end
end
update_log()

menu:my_root():action("Up", {}, "", function ()
    local current = wheel:current()
    if current.selectedIndex <= 1 then
        current.selectedIndex = #current.children
    else
        current.selectedIndex = current.selectedIndex - 1
    end
    update_log()
end)

menu:my_root():action("Down", {}, "", function ()
    local current = wheel:current()
    if current.selectedIndex >= #current.children then
        current.selectedIndex = 1
    else
        wheel:current().selectedIndex = current.selectedIndex + 1
    end
    update_log()
end)

menu:my_root():action("Select", {}, "", function ()
    wheel.enter()
    update_log()
end)

menu:my_root():action("Back", {}, "", function ()
    wheel.up()
    update_log()
end)

util.create_tick_handler(function ()
    directx.draw_text_client(
        0.4, 0.4,
        log, -- text
        5, -- align
        1, -- scale 
        1, 1, 1, 1, -- color
        false, -- force_in_bounds 
        nil -- font 
    )
end)
