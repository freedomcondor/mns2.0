local pipuckDis = 0.5
local droneDis = 1.0

local function create_children_node(n, th)
	if n == 0 then return nil end
	return
	{ 	robotTypeS = "drone",
		positionV3 = vector3(-droneDis * math.cos(th), 
							 -droneDis * math.sin(th),
							 0),
		orientationQ = quaternion(th, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	
		---[[
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		--]]
		create_children_node(n-1, th),
	}}
end

return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, -droneDis, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},

		---[[
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},		
		--]]
		create_children_node(N_NODE, TH),
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(0, droneDis, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},

		---[[
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		--]]
		create_children_node(N_NODE, -(TH)),
	}},
}}
