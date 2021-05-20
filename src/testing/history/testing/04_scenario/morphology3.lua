local p_dis = 0.6
local d_dis = 1.2
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis/4, p_dis/3, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis/4, -p_dis/3, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
}}
