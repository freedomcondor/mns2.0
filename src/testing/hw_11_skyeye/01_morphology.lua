local dis = 0.4

function create_arm_formation(vec1, vec2, n)
	if n == 1 then
		return 
		{	robotTypeS = "pipuck",
			positionV3 = vec1 + vec2,
			orientationQ = quaternion(0, vector3(0,0,1)),
		}
	else
		return 
		{	robotTypeS = "pipuck",
			positionV3 = vec1 + vec2,
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
				create_arm_formation(vec1, vec2, n - 1)
			}
		}
	end
end

function create_square_formation(vec1, vec2, n)
	if n == 1 then
		return 
		{	robotTypeS = "pipuck",
			positionV3 = vec1 + vec2,
			orientationQ = quaternion(0, vector3(0,0,1)),
		}
	else
		return 
		{	robotTypeS = "pipuck",
			positionV3 = vec1 + vec2,
			orientationQ = quaternion(0, vector3(0,0,1)),
			children = {
				create_arm_formation(vec1, vector3(), n - 1),
				create_arm_formation(vector3(), vec2, n - 1),
				create_square_formation(vec1, vec2, n - 1),
			}
		}
	end
end

return create_square_formation(vector3(-dis, 0, 0), vector3(0, -dis, 0), 4)
--[[
return 
{	robotTypeS = "pipuck",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, 0, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, -dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	--body
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-dis, -dis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, 0, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, -dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-dis, -dis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
}}
--]]
