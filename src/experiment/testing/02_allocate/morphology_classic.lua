local dis = 0.5
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--body
	{	robotTypeS = "drone",
		positionV3 = vector3(-2*dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, -dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		-- left wing
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -2*dis, 0),
			orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
		-- right wing
		{	robotTypeS = "drone",
			positionV3 = vector3(0, 2*dis, 0),
			orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
		}},
		-- tail
		{	robotTypeS = "drone",
			positionV3 = vector3(-2*dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		---[[
			-- tail tip
			{	robotTypeS = "drone",
				positionV3 = vector3(-2*dis, 0, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
				children = {
				---[[
				{	robotTypeS = "pipuck",
					positionV3 = vector3(-dis, -dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
				{	robotTypeS = "pipuck",
					positionV3 = vector3(-dis, dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
				--]]
			}},
		--]]
		}},
	}},
}}
