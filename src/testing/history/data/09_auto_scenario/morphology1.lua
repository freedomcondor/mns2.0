local p_dis = 0.5
local p_dis_y = 0.7
local d_dis = 1.3
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-p_dis, -p_dis_y, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-p_dis, p_dis_y, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis, p_dis_y, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(p_dis, -p_dis_y, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	---[[
	{	robotTypeS = "drone",
		positionV3 = vector3(0, -d_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		---[[
		children = {
		{	robotTypeS = "pipuck",
            positionV3 = vector3(-p_dis, -p_dis, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
            positionV3 = vector3(p_dis, -p_dis, 0),
            orientationQ = quaternion(0, vector3(0,0,1)),
		},
		}--]]
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, d_dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		---[[
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(p_dis, p_dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-p_dis, p_dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		}--]]
	},
	--]]
}}
