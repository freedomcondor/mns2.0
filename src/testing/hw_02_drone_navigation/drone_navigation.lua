local tracking = vector3()
function init()
	-- set fsm 
	streaming_dur = 100
	stream_count = 0
	state = 'pre_flight'
	input = vector3(0,0,1.5)

	-- open camera
	---[[
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
	--]]
end

 
function step()
	if robot.flight_system.ready() then
		print("Argos position = ", robot.flight_system.position, 
		      "yaw = ", robot.flight_system.orientation.z / math.pi * 180)
		-- fsm iteration
		if state == 'pre_flight' then
			if stream_count <= streaming_dur then
				robot.flight_system.set_target_pose(input, 0)
				stream_count = stream_count + 1
			else
				state = 'armed'
				print("go to armed state")
				stream_count = 0
			end
		elseif state == 'armed'  then
			robot.flight_system.set_armed(true, false)
			state = 'off_board'
		elseif state == 'off_board' then
			robot.flight_system.set_offboard_mode(true)
			state = 'take_off' 
			print("go to take off state")
		elseif state == 'take_off' then
			robot.flight_system.set_target_pose(input, 0)
			if stream_count <= streaming_dur*2 then
				stream_count = stream_count + 1
			else
				state = 'nav'
				print("go to nav state")
				stream_count = 0
			end
		elseif state == 'nav' then
			---[[
			local tags = droneDetectTags()
			print("I see tags")
			ShowTable(tags)
			for id, tag in ipairs(tags) do
				if tag.id == 3 then
					tracking = tag.positionV3
					break
				end
			end
			print("tracking = ", tracking)
			local targetLocation = tracking - vector3(0.0, 0.5, 0)
			targetLocation = targetLocation * 2
			droneSetTarget(targetLocation.x, targetLocation.y, 0, 10) 
			--]]
			--droneSetTarget(0, 0, 0, 10 * math.pi / 180) 
			--droneSetTarget(0, 0, 0, -math.pi / 18) 
			--droneSetTarget(0, 0, 0, 0) 
		end
	end
	--print("position = ", robot.flight_system.position)
	--print("orientation = ", robot.flight_system.orientation)
end
 
function reset()
end
 
function destroy()
	-- stop camera
	---[[
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end
	--]]

	robot.flight_system.set_armed(false, false)
	robot.flight_system.set_offboard_mode(false)
end
 
----------------------------------------------------------------
function droneSetTarget(x, y, z, th)
	if robot.flight_system == nil then return end
	-- x, y, z in m, x front, z up, y left
	-- th in rad, counter-clockwise positive
	local rad = robot.flight_system.orientation.z 
	local q = quaternion(rad, vector3(0,0,1))

	local constZ = 1.5
	local newPosition = vector3(x,y,z):rotate(q) + robot.flight_system.position
	newPosition.z = constZ

	local newRad = rad + th

	robot.flight_system.set_target_pose(
		newPosition,
		newRad
	)
end

---------------------------------------------------
---[[
function droneDetectTags()
	-- This function returns a tags table, in real robot coordinate frame

	-- add tags 
	tags = {}
	for _, camera in pairs(robot.cameras_system) do
		for _, newTag in ipairs(camera.tags) do
			local positionV3 = 
			  (
			    camera.transform.position + 
			    vector3(newTag.position):rotate(camera.transform.orientation)
			  )

			local orientationQ = 
				camera.transform.orientation * 
				newTag.orientation * quaternion(math.pi, vector3(1,0,0))

			-- check existed
			local flag = 0
			for i, existTag in ipairs(tags) do
				if (existTag.positionV3 - positionV3):length() < 0.02 then
					existTag.positionV3 = (existTag.positionV3 * existTag.seenCount + positionV3) * (1/ (existTag.seenCount + 1))
					existTag.seenCount = existTag.seenCount + 1
					flag = 1
					break
				end
			end

			if flag == 0 then
				tags[#tags + 1] = {
					--idS = "pipuck" .. math.floor(tag.id),
					--idS = robotTypeS .. math.floor(tag.id),
					id = newTag.id,
					positionV3 = positionV3,
					orientationQ = orientationQ,
					seenCount = 1
				}
			end
		end
	end

	return tags
end
--]]

-------------------------------------------------------------
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