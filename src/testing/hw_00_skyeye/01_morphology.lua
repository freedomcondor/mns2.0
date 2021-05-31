local dis = 0.10
return {
	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis/2, -dis*math.sqrt(3)/2, 0),
				orientationQ = quaternion(),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis/2, dis*math.sqrt(3)/2, 0),
				orientationQ = quaternion(),
			},
		}},
	}
}