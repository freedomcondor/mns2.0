local dis = 1.0
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	--body
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0.1, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, -0.1, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
