function ShowTable(table, number, skipindex)
	-- number means how many indents when printing
	if number == nil then number = 0 end
	if type(table) ~= "table" then return nil end
 
	for i, v in pairs(table) do
	   local str = "DebugMSG:\t\t"
	   for j = 1, number do
		  str = str .. "\t"
	   end
 
	   str = str .. tostring(i) .. "\t"
 
	   if i == skipindex then
		  print(str .. "SKIPPED")
	   else
		  if type(v) == "table" then
			 print(str)
			 ShowTable(v, number + 1, skipindex)
		  else
			 str = str .. tostring(v)
			 print(str)
		  end
	   end
	end
end

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

-- reverse calculation
-- A.positionV3, A.orientationQ
-- in A's eye, I'm at
--   position:     (-A.positionV3):rotate(A.orientationQ:inverse())
--   orientation:  A.orientationQ:inverse()

function step()
	-- for each camera
	for id, camera in pairs(robot.cameras_system) do 
		local calibrated = false
		-- for each tag
		for _, tag in ipairs(camera.tags) do
			-- for each reference_tag
			for _, reference_tag in ipairs(reference_tags) do
				if tag.id == reference_tag.id then
					local camera_to_tag = {
						position = (-tag.position):rotate(tag.orientation:inverse()),
						orientation = tag.orientation:inverse(),
					}
					camera.camera_to_robot = {
						position = reference_tag.position + camera_to_tag.position:rotate(reference_tag.orientation),
						orientation = reference_tag.orientation * camera_to_tag.orientation,
					}
					calibrated = true
					break
				end
			end
			if calibrated == true then
				break
			end
		end
	end

	ShowTable("cameras_system")
	ShowTable(robot.cameras_system)
end

 
function reset()
end
 
function destroy()
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end
end