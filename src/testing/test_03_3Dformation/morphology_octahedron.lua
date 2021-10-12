local dis = 1.0
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, -dis, -dis*math.sqrt(2)),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, dis, -dis*math.sqrt(2)),
			orientationQ = quaternion(),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, dis, -dis*math.sqrt(2)),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, dis, -dis*math.sqrt(2)),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, -dis, -dis*math.sqrt(2)),
		orientationQ = quaternion(),
	},
}}
