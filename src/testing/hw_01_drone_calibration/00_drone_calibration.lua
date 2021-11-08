function init()
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
end
 
function step()
	-- each camera should detect 4 tags to see a plane
	for id, camera in pairs(robot.cameras_system) do 
		if #camera.tags ~= 4 then
			-- no hit
			return
		end
	end

	-- detect plane
	for id, camera in pairs(robot.cameras_system) do 
		-- for each camera, calculate plane
		-- middle of the 4 points
		local middle = vector3()
		for j, tag in ipairs(camera.tags) do
			middle = middle + tag.position
		end
	end
end
 
function reset()
end
 
function destroy()
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end
end