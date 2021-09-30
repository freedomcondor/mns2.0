local dis = 0.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, 0, dis),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, 0, dis/2),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, dis * 2),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
