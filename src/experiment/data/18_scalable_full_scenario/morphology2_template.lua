local pipuckDis = 0.5
local droneDis = 0.9
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
---[[
	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis, -droneDis/6, 0),
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
DRONE_CHILDREN
	}},
--]]
}}
