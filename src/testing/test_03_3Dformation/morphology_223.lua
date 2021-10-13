local dis = 1.2
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, -dis),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(),
		},
	}},

	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, -dis),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},

	{	robotTypeS = "drone",
		positionV3 = vector3(0, -dis, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 0, -dis),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, 0, 0),
				orientationQ = quaternion(),
			},
		}},
	}},
}}
