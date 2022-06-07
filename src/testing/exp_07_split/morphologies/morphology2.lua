MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

local morph = MorphologyCommon.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height)
morph.ranger = true 
return morph