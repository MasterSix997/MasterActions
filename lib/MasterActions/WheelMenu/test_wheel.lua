local wheel_menu = require("MasterActions.lib.MasterActions.WheelMenu.wheel_menu")

local wheel = wheel_menu.new()

wheel.nav:addMenu("Test1")
wheel.nav:addMenu("Test2"):addMenu("Inside test 2")
local test3 = wheel.nav:addMenu("Test3", "Varios submenus para testar paginas")
test3.drawMode = 1
test3.textureSettings = {path = "C:\\Users\\zanog\\AppData\\Roaming\\Stand\\Lua Scripts\\resources\\JS.png"}
test3:addMenu("t3 sub 1")
test3:addMenu("t3 sub 2")
test3:addMenu("t3 sub 3")
local test3_sub4 = test3:addMenu("t3 sub 4", "Eu tenho uma textura ;D")
test3_sub4.drawMode = 2
test3_sub4.textureSettings = {path = "C:\\Users\\zanog\\AppData\\Roaming\\Stand\\Lua Scripts\\resources\\JS.png"}
test3_sub4:addMenu("H")
test3_sub4:addMenu("HH")
test3_sub4:addMenu("HHH")
test3_sub4:addMenu("HHHH")
test3:addMenu("t3 sub 5")
test3:addMenu("t3 sub 6")
test3:addMenu("t3 sub 7")
test3:addMenu("t3 sub 8")
test3:addMenu("t3 sub 9")
local test3_sub10 = test3:addMenu("t3 sub 10", "Era para eu ter uma textura D;")
test3_sub10.drawMode = 1
test3_sub10.textureSettings = {path = "C:\\Users\\invalid_hahah"}
test3:addMenu("t3 sub 11")
test3:addMenu("t3 sub 12")
test3:addMenu("t3 sub 13")
test3:addMenu("t3 sub 14")
test3:addMenu("t3 sub 15")
test3:addMenu("t3 sub 16")
test3:addMenu("t3 sub 17")
test3:addMenu("t3 sub 18")
test3:addMenu("t3 sub 19")
test3:addMenu("t3 sub 20")
test3:addMenu("t3 sub 21")
test3:addMenu("t3 sub 22")
wheel.nav:addMenu("Test4")

wheel:create_textures()
wheel:open()