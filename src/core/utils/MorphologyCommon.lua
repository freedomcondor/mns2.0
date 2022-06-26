MorphologyGenerator = {}

--[[
              x
              |
              o
            /- -\
        x -/     \- x
--]]
function MorphologyGenerator.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height, position, orientationQ, reverse)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, pipuckDis/3, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, -pipuckDis/3, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	if reverse == true then
		for id, child in ipairs(node.children) do
			child.positionV3.x = -child.positionV3.x
		end
	end
	return node
end

--[[
              x 
              |/-x
              o
           x-/|
              x
--]]
function MorphologyGenerator.create_1drone_4pipuck_front_back_hex_node(droneDis, pipuckDis, height, position, orientationQ, end_flag)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(droneDis/2, pipuckDis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-droneDis/2, -pipuckDis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, -pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	if end_flag == "front_end" then
		node.children[1].positionV3 = vector3(pipuckDis, 0, -height)
	elseif end_flag == "front_double_end" then
		node.children[5] =
			{	robotTypeS = "pipuck",
				positionV3 = vector3(droneDis/2, -pipuckDis/2, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
	elseif end_flag == "back_end" then
		node.children[3].positionV3 = vector3(-pipuckDis, 0, -height)
	elseif end_flag == "back_double_end" then
		node.children[5] =
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-droneDis/2, pipuckDis/2, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
	end
	return node
end

function MorphologyGenerator.create_1drone_4pipuck_left_right_hex_node(droneDis, pipuckDis, height, position, orientationQ, end_flag)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, 0, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, 0, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, droneDis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, -droneDis/2, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	if end_flag == "left_end" then
		node.children[3].positionV3 = vector3(0, pipuckDis, -height)
	elseif end_flag == "left_double_end" then
		node.children[5] =
			{	robotTypeS = "pipuck",
				positionV3 = vector3(pipuckDis/2, droneDis/2, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
	elseif end_flag == "right_end" then
		node.children[4].positionV3 = vector3(0, -pipuckDis, -height)
	elseif end_flag == "right_double_end" then
		node.children[5] =
			{	robotTypeS = "pipuck",
				positionV3 = vector3(-pipuckDis/2, -droneDis/2, -height),
				orientationQ = quaternion(0, vector3(0,0,1)),
			}
	end
	return node
end

function MorphologyGenerator.create_1drone_4pipuck_qua_arm_node(droneDis, pipuckDis, height, position, orientationQ)
	if position == nil then position = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	return node
end

------------ square node ------------------
function MorphologyGenerator.create_1drone_4pipuck_square_node(droneDis, pipuckDis, height, position, orientationQ)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, -pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	return node
end

function MorphologyGenerator.create_1drone_2pipuck_square_node(droneDis, pipuckDis, height, position, orientationQ)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	return node
end

------------ rectangular node ------------------
function MorphologyGenerator.create_1drone_4pipuck_rectangular_node(length_half, width_half, height, positionV3, orientationQ)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(length_half, width_half, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(length_half, -width_half, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-length_half, -width_half, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-length_half, width_half, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}}
	return node
end

function MorphologyGenerator.create_1drone_2pipuck_rectangular_node(length_half, width_half, height, positionV3, orientationQ, direction)
	if positionV3 == nil then positionV3 = vector3() end
	if orientationQ == nil then orientationQ = quaternion() end

	local front_left_node = 
	{	robotTypeS = "pipuck",
		positionV3 = vector3(length_half, width_half, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	}
	local front_right_node = 
	{	robotTypeS = "pipuck",
		positionV3 = vector3(length_half, -width_half, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	}
	local back_right_node = 
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-length_half, -width_half, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	}
	local back_left_node = 
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-length_half, width_half, -height),
		orientationQ = quaternion(0, vector3(0,0,1)),
	}

	local node =
	{ 	robotTypeS = "drone",
		positionV3 = positionV3,
		orientationQ = orientationQ,
		children = {},
	}

	if direction == "front" then
		table.insert(node.children, front_left_node)
		table.insert(node.children, front_right_node)
	elseif direction == "back" then
		table.insert(node.children, back_left_node)
		table.insert(node.children, back_right_node)
	elseif direction == "left" then
		table.insert(node.children, front_left_node)
		table.insert(node.children, back_left_node)
	elseif direction == "right" then
		table.insert(node.children, front_right_node)
		table.insert(node.children, back_right_node)
	end

	return node
end

return MorphologyGenerator