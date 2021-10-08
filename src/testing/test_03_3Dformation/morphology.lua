local dis = 1.2
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,1,0)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(dis, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},

	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(math.pi/2, vector3(0,1,0)),
		},
	}},

	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, dis),
		orientationQ = quaternion(-math.pi/2, vector3(1,0,0)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, dis),
			orientationQ = quaternion(math.pi/2, vector3(0,1,0)),
		},
	}},
}}
