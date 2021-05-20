local droneDis = 1.0

local function create_children_node(n)
	if n == 0 then return nil end
	return
	{ 	robotTypeS = "drone",
		positionV3 = vector3(droneDis, 0, 0),
		orientationQ = quaternion(),
		children = {
		{	robotTypeS = "drone",
			positionV3 = vector3(0, droneDis, 0),
			orientationQ = quaternion(),
		},
		{	robotTypeS = "drone",
			positionV3 = vector3(0, -droneDis, 0),
			orientationQ = quaternion(),
		},
		create_children_node(n-1)
	}}
	end

return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "drone",
		positionV3 = vector3(0, droneDis, 0),
		orientationQ = quaternion(),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, -droneDis, 0),
		orientationQ = quaternion(),
	},
	create_children_node(N_NODE),
}}
