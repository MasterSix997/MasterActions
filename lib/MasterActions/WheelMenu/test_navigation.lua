util.require_natives("3095a")
local wheel = require("MasterActions.lib.MasterActions.WheelMenu.wheel_navigation")

wheel:addMenu("test1")
local test2 = wheel:addMenu("test2")
test2:addMenu("Test2 sub1")
test2:addMenu("Test2 sub2")
test2:addMenu("Test2 sub3"):addMenu("Test_1")
local test3 = wheel:addMenu("test3")
test3:addMenu("Massive 1")
test3:addMenu("Massive 2")
test3:addMenu("Massive 3")
test3:addMenu("Massive 4")
test3:addMenu("Massive 5")
test3:addMenu("Massive 6")
test3:addMenu("Massive 7")
test3:addMenu("Massive 8")
test3:addMenu("Massive 9")
test3:addMenu("Massive 10")
test3:addMenu("Massive 11")
local test3_massive12 = test3:addMenu("Massive 12")
test3_massive12:addMenu("HAHAH 1")
test3_massive12:addMenu("HAHAH 2")
local test3_massive12_hey = test3_massive12:addMenu("Hey")
test3_massive12:addMenu("HAHAH 3")
test3_massive12:addMenu("HAHAH 4")
test3:addMenu("Massive 13")
test3:addMenu("Massive 14")
test3:addMenu("Massive 15")
test3:addMenu("Massive 16")
test3:addMenu("End 17")
wheel:addMenu("test4"):addMenu("Test1")

local log = ""

local function update_log()
    log = "[" .. wheel:current().name .. "] [" .. wheel:current().currentPage .. "/" .. wheel:current():pageCount() .."]\n"
    for index, value in ipairs(wheel:current():pageItens()) do
        log = log .. "\n" .. (index == wheel:current().selectedIndex and "*" or index)
        log = log .. " - " .. value.name .. (value:pageItensCount() > 0 and " (dir)" or " (file)")
    end
end
update_log()

menu:my_root():action("Up", {}, "", function ()
    local current = wheel:current()
    if current.selectedIndex <= 1 then
        current.selectedIndex = current:pageItensCount()
    else
        current.selectedIndex = current.selectedIndex - 1
    end
    update_log()
end)

menu:my_root():action("Down", {}, "", function ()
    local current = wheel:current()
    if current.selectedIndex >= current:pageItensCount() then
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

menu:my_root():action("Page Right", {}, "", function ()
    local current = wheel:current()
    if current.currentPage >= current:pageCount() then
        return
    else
        current.currentPage = current.currentPage + 1
        current.selectedIndex = 1
    end
    update_log()
end)

menu:my_root():action("Page Left", {}, "", function ()
    local current = wheel:current()
    if current.currentPage <= 1 then
        return
    else
        current.currentPage = current.currentPage - 1
        current.selectedIndex = 1
    end
    update_log()
end)

menu:my_root():action("Focus", {}, "", function ()
    wheel:focus(test3_massive12_hey)
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
