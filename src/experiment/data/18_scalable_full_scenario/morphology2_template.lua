local pipuckDis = 0.6
local droneDis = 1.0
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
--[[
	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis/4, droneDis, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis/4, -droneDis, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
--]]
DRONE_CHILDREN
}}
