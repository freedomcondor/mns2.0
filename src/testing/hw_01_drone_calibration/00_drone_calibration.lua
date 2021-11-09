local distance = 0.5
function init()
	for id, camera in pairs(robot.cameras_system) do    
		camera.enable()
	end
end

function FromToQuaternion(vec1, vec2)
	-- assuming vec1 and vec2 are normal vectors
	if vec1 == vec2 then return quaternion() end
	local axis = vector3(vec1):cross(vec2)
	local angle = math.acos(vec1:dot(vec2))
	return quaternion(angle, axis:normalize())
end

function FromTo2VecQuaternion(vec1_from, vec1_to, vec2_from, vec2_to)
	local rotate1 = FromToQuaternion(vec1_from, vec1_to)
	local vec2_middle = vector3(vec2_to):rotate(rotate1:inverse())
	local rotate2 = FromToQuaternion(vec2_from, vec2_middle)
	return rotate1 * rotate2
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
		-- get 4 points
		local p = {}
		local tags = {}
		for i, tag in ipairs(camera.tags) do
			p[i] = tag.position
			tags[i] = tag
		end
		-- calculate middle of the 4 points
		local m = vector3()
		for i = 1 , 4 do
			m = m + p[i]
		end
		m = m * 0.25

		-- calculate normal vector (Z)
		local n1 = (p[1] - p[2]):cross(p[1] - p[3]):normalize()
		local n2 = (p[1] - p[2]):cross(p[1] - p[4]):normalize()
		local n3 = (p[1] - p[3]):cross(p[1] - p[4]):normalize()
		local n4 = (p[2] - p[3]):cross(p[2] - p[4]):normalize()
		if n1:dot(m) > 0 then n1 = -n1 end
		if n2:dot(m) > 0 then n2 = -n2 end
		if n3:dot(m) > 0 then n3 = -n3 end
		if n4:dot(m) > 0 then n4 = -n4 end
		local Z = ((n1 + n2 + n3 + n4) * 0.25):normalize()

		-- calculate X
		local refX = vector3(1,0,0):rotate(tags[1].orientation)
		-- find a nearX
		local r = {}
		r[1] = (p[1] - p[2]):normalize()
		r[2] = (p[1] - p[3]):normalize()
		r[3] = (p[1] - p[4]):normalize()
		r[4] = (p[2] - p[3]):normalize()
		r[5] = (p[2] - p[4]):normalize()
		r[6] = (p[3] - p[4]):normalize()
		local nearX = vector3()
		local n = 0
		for i = 1, 6 do
			if (r[i] - refX):length() < 0.5 then
				nearX = nearX + r[i]
				n = n + 1
			elseif (-r[i] - refX):length() < 0.5 then
				nearX = nearX - r[i]
				n = n + 1
			end
		end
		nearX = nearX * (1.0/n)
		-- rotate Z to the direction of X by 90 to get a real X
		local axis = vector3(Z):cross(nearX)
		local X = vector3(Z):rotate(quaternion(math.pi/2, axis))

		-- calculate quaternion based on X and Z
		local q1, q2, orientation = FromTo2VecQuaternion(vector3(1,0,0), X, vector3(0,0,1), Z)

		-- overwrite tag orientations
		for i, tag in ipairs(camera.tags) do tag.orientation = orientation end

		if robot.debug ~= nil then
			local from = camera.transform.position + vector3(m):rotate(camera.transform.orientation)
			local to   = camera.transform.position + vector3(m+vector3(1,0,0):rotate(orientation)):rotate(camera.transform.orientation)
			robot.debug.draw("arrow(blue)(" .. 
			                 tostring(from) .. ")(" ..
			                 tostring(to) .. ")"
			)

			local from = camera.transform.position + vector3(m):rotate(camera.transform.orientation)
			local to   = camera.transform.position + vector3(m+vector3(0,1,0):rotate(orientation)):rotate(camera.transform.orientation)
			robot.debug.draw("arrow(red)(" .. 
			                 tostring(from) .. ")(" ..
			                 tostring(to) .. ")"
			)

			local from = camera.transform.position + vector3(m):rotate(camera.transform.orientation)
			local to   = camera.transform.position + vector3(m+vector3(0,0,1):rotate(orientation)):rotate(camera.transform.orientation)
			robot.debug.draw("arrow(green)(" .. 
			                 tostring(from) .. ")(" ..
			                 tostring(to) .. ")"
			)
		end
	end

	-- calculate camera relative locations
	local cameras = {}
	for id, camera in pairs(robot.cameras_system) do 
		cameras[#cameras + 1] = camera
	end
end

 
function reset()
end
 
function destroy()
	for i, camera in ipairs(robot.cameras_system) do    
		camera.disable()
	end
end