local dis = 0.5
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--body
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-2*dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, -dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(-dis, dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		-- left wing
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, -2*dis, 0),
			orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		}},
		-- right wing
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, 2*dis, 0),
			orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
		}},
		-- tail
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-2*dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, -dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
			{	robotTypeS = "drone",
				positionV3 = vector3(-dis, dis, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
			},
		---[[
			-- tail tip
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-2*dis, 0, 0),
				orientationQ = quaternion(0, vector3(0,0,1)),
				children = {
				---[[
				{	robotTypeS = "drone",
					positionV3 = vector3(-dis, -dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
				{	robotTypeS = "drone",
					positionV3 = vector3(-dis, dis, 0),
					orientationQ = quaternion(0, vector3(0,0,1)),
				},
				--]]
			}},
		--]]
		}},
	}},
}}
