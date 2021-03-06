local pipuckDis = 0.6
local droneDis = 1.3
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

	{	robotTypeS = "drone",
		positionV3 = vector3(0, -droneDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis, -pipuckDis, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
            positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
}}
