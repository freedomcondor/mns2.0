function init()
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
end
 
function step()
	print("time = " .. tostring(robot.system.time))
	local str = "temperatures = "
	for i, temp in ipairs(robot.system.temperatures) do
		str = str .. tostring(temp) .. " "
	end
	print(str)
	for id, camera in pairs(robot.cameras_system) do 
		print("camera " .. id .. ", timestamp = " .. camera.timestamp)
		for j, tag in ipairs(camera.tags) do
			print("  tag " .. j .. ": " .. tostring(tag.center))
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