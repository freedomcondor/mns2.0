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
		--[[
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, 0, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		--]]
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	if tilt_nose == true then
		node.children[2].positionV3 = vector3(pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height)
	end
	return node
end

local function create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ, left_or_right)
	local node = create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
	if left_or_right ~= "right" then
		table.insert(node.children,
			create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
				vector3(-droneDis/2, droneDis/2*math.sqrt(3), 0),
				quaternion()
			)
		)
	end
	if left_or_right ~= "left" then
		table.insert(node.children,
			create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
				vector3(-droneDis/2, -droneDis/2*math.sqrt(3), 0),
				quaternion()
			)
		)
	end
	return node
end

local function create_3drone_12pipuck_children_back_line_node(droneDis, pipuckDis, height, position, orientationQ)
	local node = create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
	local second_node = 
		create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
			vector3(-droneDis, 0, 0),
			quaternion()
		)

		--[[
		table.insert(second_node.children,
			create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
				vector3(-droneDis, 0, 0),
				quaternion()
			)
		)
		--]]

	table.insert(node.children,
		second_node
	)
	return node
end

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
			quaternion(),
			left_or_right
		)
	)
	return node
end

function create_3drone_12pipuck_children_back_line_chain(n, droneDis, pipuckDis, height, position, orientationQ)
	if n == 0 then return nil end
	local node = create_3drone_12pipuck_children_back_line_node(droneDis, pipuckDis, height, position, orientationQ)
	table.insert(node.children,
		create_3drone_12pipuck_children_back_line_chain(n-1, droneDis, pipuckDis, height, 
			position, orientationQ
		)
	)
	return node
end

function create_left_right_back_line_morphology(scale, droneDis, pipuckDis, height)
	local n = scale * 2 + 2
	local alpha = math.pi * 2 / n
	local th = (math.pi - alpha) / 2
	local x = droneDis * math.cos(th)
	local y = droneDis * math.sin(th)

	local node = create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, position, orientationQ)
	table.insert(node.children,
		create_3drone_12pipuck_children_back_line_chain(scale, droneDis, pipuckDis, height, 
			vector3(x, -y, 0),
			quaternion(alpha, vector3(0,0,1))
		)
	)
	table.insert(node.children,
		create_3drone_12pipuck_children_back_line_chain(scale, droneDis, pipuckDis, height, 
			vector3(x, y, 0),
			quaternion(-alpha, vector3(0,0,1))
		)
	)
	return node
end

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
	--[[
	create_1drone_4pipuck_children_node(droneDis, pipuckDis, height, 
		vector3(droneDis/2*math.sqrt(3), -droneDis/2, 0),
		quaternion(math.pi/2, vector3(0,0,1)),
		true
	),
	--]]
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
	--[[
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
	--]]
}}
end

function create_back_line_morphology(scale, droneDis, pipuckDis, height)
	local node = create_3drone_12pipuck_children_node(droneDis, pipuckDis, height, vector3(), quaternion())
	table.insert(node.children,
		create_3drone_12pipuck_children_chain(scale, droneDis, pipuckDis, height, 
			vector3(-droneDis, 0, 0), 
			quaternion()
		)
	)
	return node
end