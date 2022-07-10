MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

local morph = MorphologyCommon.create_1drone_4pipuck_left_right_hex_node(droneDis, pipuckDis, height, vector3(), quaternion(), "right_double_end")
morph.children[1].reference = true

table.insert(morph.children, 
             MorphologyCommon.create_1drone_4pipuck_left_right_hex_node(droneDis, pipuckDis, height, vector3(0, droneDis, 0), quaternion(), "left_double_end")
            )

return morph

