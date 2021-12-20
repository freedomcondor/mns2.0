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

local dis = 0.25 / math.sqrt(2)
local height = 0
local dis2 = 0.16
local ori_45 = quaternion(-math.pi/4, vector3(0,0,1)) *
               quaternion(math.pi, vector3(1,0,0))
local reference_tags = {
	--[[
	{id = 3, position = vector3( dis, dis, -height),
	         orientation = quaternion(math.pi, vector3(1,0,0))},   -- for arm0 to see
	{id = 0, position = vector3( -dis, dis,-height), 
	         orientation = quaternion(math.pi, vector3(1,0,0))},   -- for arm1 to see
	{id = 1, position = vector3( -dis, -dis,-height), 
	         orientation = quaternion(math.pi, vector3(1,0,0))},   -- for arm2 to see
	{id = 2, position = vector3( dis, -dis,-height), 
	         orientation = quaternion(math.pi, vector3(1,0,0))},   -- for arm3 to see
	--]]

	{id = 4, position = vector3( dis2, 0, -height),
	         orientation = ori_45},   -- for arm0 to see
	{id = 5, position = vector3( 0, dis2,-height), 
	         orientation = ori_45},   -- for arm1 to see
	{id = 6, position = vector3( -dis2, 0,-height), 
	         orientation = ori_45},   -- for arm2 to see
	{id = 7, position = vector3( 0, -dis2,-height), 
	         orientation = ori_45},   -- for arm3 to see
}

cameras_to_robot = {}

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
					cameras_to_robot[id] = {
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

	ShowTable("robot.cameras_system")
	ShowTable(robot.cameras_system)

	print("-------------------- I see tags --------------")
	for id, camera in pairs(robot.cameras_system) do 
		print("camera id :", id)
		for _, tag in ipairs(camera.tags) do
			print("tag id = ", tag.id)
			print("  from camera")
			print("    position = ", tag.position)
			print("    orientation = ", tag.orientation)
			print("              X = ", vector3(1,0,0):rotate(tag.orientation))
			print("              Y = ", vector3(0,1,0):rotate(tag.orientation))
			print("              Z = ", vector3(0,0,1):rotate(tag.orientation))
			print("  from drone")
			print("    position = ", camera.transform.position + vector3(tag.position):rotate(camera.transform.orientation))
			print("    orientation = ", camera.transform.orientation * tag.orientation)
			print("              X = ", vector3(1,0,0):rotate(camera.transform.orientation * tag.orientation))
			print("              Y = ", vector3(0,1,0):rotate(camera.transform.orientation * tag.orientation))
			print("              Z = ", vector3(0,0,1):rotate(camera.transform.orientation * tag.orientation))
		end
	end
	print("cameras_to_robot")
	ShowTable(cameras_to_robot)
	for id, camera in pairs(cameras_to_robot) do
		print("id = ", id)
		print("  position = ", camera.position)
		print("  orientation = ", camera.orientation)
		print("            X = ", vector3(1,0,0):rotate(camera.orientation))
		print("            Y = ", vector3(0,1,0):rotate(camera.orientation))
		print("            Z = ", vector3(0,0,1):rotate(camera.orientation))
	end
end

 
function reset()
end
 
function destroy()
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end

	if robot.params.big_tag_test == "true" then return end

	local str = "<?xml version=\"1.0\" ?>\n<calibration>\n"
	for id, camera in pairs(cameras_to_robot) do    
		str = str .. "  <arm id=\"" .. id .. "\"\n"
		str = str .. "       position=\"" .. tostring(camera.position) .. "\"\n"
		str = str .. "       orientation=\"" .. tostring(camera.orientation) .. "\"\n"
		str = str .. "  />\n"
	end
	str = str .. "</calibration>"
	local file = io.open("lua_calibration.xml",'w')
	file:write(str)
	file:close()
	print("lua_calibration.xml file saved!")
end
