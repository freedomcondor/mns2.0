local pipuckDis = 0.7
local droneDis = 1.5
local height = 1.8
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis, -pipuckDis/3, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
    	        positionV3 = vector3(pipuckDis/6, -pipuckDis/3, 0),
    	        orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
	}},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, pipuckDis/3, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(pipuckDis/6, pipuckDis/3, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
	}},

	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis * 0.3, 0, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		reference = true
	},

	{	robotTypeS = "drone",
		positionV3 = vector3(droneDis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
