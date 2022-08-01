MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

local morph = MorphologyCommon.create_1drone_4pipuck_front_back_hex_node(droneDis, pipuckDis, height)
morph.children[1].reference = true

local two_drone_child = MorphologyCommon.create_1drone_4pipuck_front_back_hex_node(droneDis, pipuckDis, height, vector3(-droneDis, 0, 0), quaternion())
table.insert(two_drone_child.children,
             MorphologyCommon.create_1drone_4pipuck_front_back_hex_node(droneDis, pipuckDis, height, vector3(-droneDis, 0, 0), quaternion(), "back_end")
            )

table.insert(morph.children, 
             two_drone_child
            )

table.insert(morph.children, 
             MorphologyCommon.create_1drone_4pipuck_front_back_hex_node(droneDis, pipuckDis, height, vector3(droneDis, 0, 0), quaternion(), "front_end")
            )

--[[
local morph = MorphologyCommon.create_1drone_4pipuck_square_node(droneDis, pipuckDis, height)
morph.children[1].reference = true

table.insert(morph.children, 
             MorphologyCommon.create_1drone_2pipuck_square_node(droneDis, pipuckDis, height, vector3(droneDis, 0, 0), quaternion(math.pi, vector3(0,0,1)))
            )

table.insert(morph.children, 
             MorphologyCommon.create_1drone_2pipuck_square_node(droneDis, pipuckDis, height, vector3(-droneDis, 0, 0), quaternion())
            )
--]]

return morph

