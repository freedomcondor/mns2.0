function init()
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
end
 
function step()
	print("-----------------------------")
	robot.leds.set_leds(0,0,0)
	for id, camera in pairs(robot.cameras_system) do 
		for j, tag in ipairs(camera.tags) do
			print("tag", tag.id)
			robot.leds.set_leds(200,200,200)
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