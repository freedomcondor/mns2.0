local dis = 1.0
local height = 1.8
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	--body
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, 0, height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis * 2, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, -dis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, dis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
}}
