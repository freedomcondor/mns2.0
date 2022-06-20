MorphologyGenerator = {}

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
	elseif end_flag == "back_end" then
		node.children[3].positionV3 = vector3(-pipuckDis, 0, -height)
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

return MorphologyGenerator