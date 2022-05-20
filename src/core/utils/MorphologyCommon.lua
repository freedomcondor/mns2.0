MorphologyGenerator = {}

function MorphologyGenerator.create_1drone_4pipuck_tri_arm_node(droneDis, pipuckDis, height, position, orientationQ)
	if orientationQ == nil then orientationQ = quaternion() end
	local node =
	{ 	robotTypeS = "drone",
		positionV3 = position,
		orientationQ = orientationQ,
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(0, 0, -height),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(pipuckDis, 0, -height),
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
	if tilt_nose == true then
		node.children[2].positionV3 = vector3(pipuckDis/2, -pipuckDis/2 * math.sqrt(3), -height)
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