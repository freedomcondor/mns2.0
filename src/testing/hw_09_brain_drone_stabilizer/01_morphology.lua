local dis = 1.0
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	--body
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis * 2, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, dis/2, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
