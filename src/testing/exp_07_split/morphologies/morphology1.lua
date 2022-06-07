MorphologyCommon = require("MorphologyCommon")

local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8

local morph = MorphologyCommon.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height)
morph.children[1].reference = true

local last_child = MorphologyCommon.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height, vector3(-droneDis, 0, 0), quaternion())
last_child.split = true

table.insert(morph.children, 
             last_child
            )

table.insert(morph.children, 
             MorphologyCommon.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height, vector3(droneDis, 0, 0), quaternion())
            )

return morph


--[[
local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		reference = true
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(-droneDis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			split = true,
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-pipuckDis, pipuckDis, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
	}},
}}
--]]