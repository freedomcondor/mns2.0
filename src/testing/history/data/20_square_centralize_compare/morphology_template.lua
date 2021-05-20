local dis = 1.0
return 
SQUARE_STRUCTURE
--[[
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
}}
--]]
