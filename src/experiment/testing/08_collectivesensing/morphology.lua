local dis = 0.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-2*dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(-2*dis, 0, 0),
			orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
			--orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
}}
