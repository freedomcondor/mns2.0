local pipuckDis = 0.5
local droneDis = 1.3
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
            positionV3 = vector3(pipuckDis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
    	        positionV3 = vector3(pipuckDis/2, 0, 0),
    	        orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
	}},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(pipuckDis/2, 0, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
	}},

	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	{	robotTypeS = "drone",
		positionV3 = vector3(droneDis/math.sqrt(2), -droneDis/math.sqrt(2), 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(droneDis/math.sqrt(2), droneDis/math.sqrt(2), 0),
		orientationQ = quaternion(0, vector3(0,0,1)),

	},
}}
