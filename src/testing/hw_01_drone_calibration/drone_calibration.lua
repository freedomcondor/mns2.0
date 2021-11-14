function init()
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
end

local dis = 1.5
local height = 1.5
local reference_tags = {
	{id = 1, position = vector3( dis, dis,-height), orientation = quaternion()},
	{id = 2, position = vector3(-dis, dis,-height), orientation = quaternion()},
	{id = 3, position = vector3(-dis,-dis,-height), orientation = quaternion()},
	{id = 4, position = vector3( dis,-dis,-height), orientation = quaternion()},
}

function step()
	-- for each camera
	for id, camera in pairs(robot.cameras_system) do 
		-- for each tag
		for 
	end
end

 
function reset()
end
 
function destroy()
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end
end