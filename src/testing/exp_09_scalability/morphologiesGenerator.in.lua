local function create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ, tilt_nose)
	if orientationQ == nil then orientationQ = quaternion() end
local node =
{ 	robotTypeS = "drone",
	positionV3 = position,
	orientationQ = orientationQ,
	children = {
	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(0, 0, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--]]
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, 0, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis/2, pipuckDis/2 * math.sqrt(3), -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--]]
}}
if tilt_nose == true then
	node.children[2].positionV3 = vector3(pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height)
end
return node
end

--local function create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
local function create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ, left_or_right)
local node = create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
if left_or_right ~= "right" then
table.insert(node.children,
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(-droneDis/2, droneDis/2*math.sqrt(3), 0),
		quaternion()
	)
)
elseif left_or_right ~= "left" then
table.insert(node.children,
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(-droneDis/2, -droneDis/2*math.sqrt(3), 0),
		quaternion()
	)
)
end
return node
end

--function create_3drone_12pipuck_children_chain(n, droneDis, pipuckDis, height, position, orientationQ)
function create_3drone_12pipuck_children_chain(n, droneDis, pipuckDis, height, position, orientationQ, left_or_right)
	if n == 0 then return nil end
	if n == 1 then 
		return create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
	end
	--local node = create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
	local node = create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ, left_or_right)
	table.insert(node.children,
		create_3drone_12pipuck_children_chain(n-1, droneDis, pipuckDis, height, 
			vector3(-droneDis, 0, 0),
			--quaternion()
			quaternion(),
			left_or_right
		)
	)
	return node
end

--[[
local function create_children_node(n, th, droneDis, pipuckDis, height, orientationQ)
	if n == 0 then return nil end
	if orientationQ == nil then orientationQ = quaternion() end
local node = 
{ 	robotTypeS = "drone",
	positionV3 = vector3(-droneDis * math.cos(th), 
						 -droneDis * math.sin(th),
						 0):rotate(orientationQ),
	orientationQ = orientationQ * quaternion(th, vector3(0,0,1)),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	create_children_node(n-1, th, droneDis, pipuckDis, height)
}}
if n == 1 then
	node.children[3] = 
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		}
end
return node
end
--]]

function create_left_right_line_morphology(scale, droneDis, pipuckDis, height)
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2*math.sqrt(3), pipuckDis/2, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		reference = true,
	},
	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis/2*math.sqrt(3), pipuckDis/2, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--]]
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2*math.sqrt(3), -pipuckDis/2, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis/2*math.sqrt(3), -pipuckDis/2, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	--]]
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(droneDis/2*math.sqrt(3), droneDis/2, 0),
		quaternion(-math.pi/2, vector3(0,0,1))
	),
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(droneDis/2*math.sqrt(3), -droneDis/2, 0),
		quaternion(math.pi/2, vector3(0,0,1)),
		true
	),
	--[[
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(-droneDis/2*math.sqrt(3), droneDis/2, 0),
		quaternion(-math.pi/2, vector3(0,0,1)),
		true
	),
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(-droneDis/2*math.sqrt(3), -droneDis/2, 0),
		quaternion(math.pi/2, vector3(0,0,1))
	),
	--]]
	create_3drone_12pipuck_children_chain(scale, droneDis, pipuckDis, height, 
		vector3(0, droneDis, 0), 
		quaternion(-math.pi/2, vector3(0,0,1)),
		"left"
	),
	create_3drone_12pipuck_children_chain(scale, droneDis, pipuckDis, height, 
		vector3(0, -droneDis, 0), 
		quaternion(math.pi/2, vector3(0,0,1)),
		"right"
	),
}}
end

function create_back_line_morphology(scale, droneDis, pipuckDis, height)
return 
{	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
		reference = true,
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis, -pipuckDis, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	create_children_node(scale * 2, 0, droneDis, pipuckDis, height),
}}
end