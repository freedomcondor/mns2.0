local p_dis = 0.5
local d_dis = 1.0
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-p_dis, -p_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-p_dis, p_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis/2, p_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis/2, -p_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	---[[
	{	robotTypeS = "drone",
		positionV3 = vector3(-d_dis, -d_dis/2, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
            positionV3 = vector3(0, p_dis/2, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
            positionV3 = vector3(-p_dis/2, 0, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-d_dis, d_dis/2, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, -p_dis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-p_dis/2, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	--]]
}}
