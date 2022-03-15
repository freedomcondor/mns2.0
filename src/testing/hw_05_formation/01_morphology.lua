local dis = 0.4
local height = 1.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	--body
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, dis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis, dis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		reference = true,
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, -dis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis, -dis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
