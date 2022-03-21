--[[
--	drone api
--]]
logger.register("droneAPI")

local api = require("commonAPI")
if robot.params.simulation == true then local DroneRealistSimulator = require("DroneRealistSimulator") end
local Transform = require("Transform")

---- actuator --------------------------
-- Idealy, I would like to use robot.flight_system.set_targets only once per step
-- newPosition and newRad are recorded, and enforced at last in dronePostStep
api.actuator = {}
if robot.flight_system ~= nil then
	api.actuator.newPosition = robot.flight_system.position
	api.actuator.newRad = robot.flight_system.orientation.z
else
	api.actuator.newPosition = vector3()
	api.actuator.newRad = 0
end
function api.actuator.setNewLocation(locationV3, rad)
	api.actuator.newPosition = locationV3
	api.actuator.newRad = rad
end

-- drone flight preparation sequence
---- take off reparation -------------------
api.actuator.flight_preparation = {
	state = "pre_flight",
	state_duration = 25,
	state_count = 0,
}

api.actuator.flight_preparation.run_state = function()
	if robot.flight_system ~= nil and robot.flight_system.ready() then
		-- flight preparation state machine
		if api.actuator.flight_preparation.state == "pre_flight" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight
			api.actuator.newRad = 0

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "armed"
			end
		elseif api.actuator.flight_preparation.state == "armed" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight
			api.actuator.newRad = 0

			robot.flight_system.set_armed(true, false)
			robot.flight_system.set_offboard_mode(true)
			api.actuator.flight_preparation.state = "take_off"
			api.actuator.flight_preparation.state_count = 0
		elseif api.actuator.flight_preparation.state == "take_off" then
			api.actuator.newPosition.x = 0
			api.actuator.newPosition.y = 0
			api.actuator.newPosition.z = api.parameters.droneDefaultStartHeight

			api.actuator.flight_preparation.state_count =
				api.actuator.flight_preparation.state_count + 1
			if api.actuator.flight_preparation.state_count >= api.actuator.flight_preparation.state_duration * 2 then
				api.actuator.flight_preparation.state_count = 0
				api.actuator.flight_preparation.state = "navigation"
			end
		elseif api.actuator.flight_preparation.state == "navigation" then
			-- TODO: there may be a jump after navigation mode
			--do nothing
		end
	end
end

---- Virtual Frame and tilt ---------------------
api.virtualFrame.orientationQ = quaternion(math.pi/4, vector3(0,0,1))
api.virtualFrame.logicOrientationQ = api.virtualFrame.orientationQ
-- overwrite rotateInspeed to change logicOrientation
function api.virtualFrame.rotateInSpeed(speedV3)
	-- speedV3 in real frame
	local speedV3_in_Z = vector3(speedV3)
	speedV3_in_Z.x = 0
	speedV3_in_Z.y = 0
	local axis = vector3(speedV3_in_Z):normalize()
	if speedV3:length() == 0 then axis = vector3(1,0,0) end
	api.virtualFrame.logicOrientationQ =
		quaternion(speedV3:length() * api.time.period,
				   axis
		) * api.virtualFrame.logicOrientationQ
end

function api.droneTiltVirtualFrame()
	local tilt
	if robot.flight_system ~= nil then
		tilt = (quaternion(robot.flight_system.orientation.x, vector3(1,0,0)) *
		        quaternion(robot.flight_system.orientation.y, vector3(0,1,0))):inverse()
		-- TODO: better way to swtich tilt
		--tilt = quaternion()
	else
		tilt = quaternion()
	end
	api.virtualFrame.tiltQ = tilt
	api.virtualFrame.orientationQ = tilt * api.virtualFrame.logicOrientationQ
end

---- overload Step Function ---------------------
-- 5 step functions :
-- init, reset, destroy, preStep, postStep
api.commonInit = api.init
function api.init()
	api.commonInit()
	if robot.params.simulation == true then DroneRealistSimulator.init(api) end
	api.droneEnableCameras()
end

api.commonDestroy = api.destroy
function api.destroy()
	api.droneDisableCameras()
	api.commonDestroy()
end

api.commonPreStep = api.preStep
function api.preStep()
	api.commonPreStep()
	api.droneTags = nil
	if robot.params.simulation == true then DroneRealistSimulator.changeSensors(api) end
	api.droneTiltVirtualFrame()
end

api.commonPostStep = api.postStep
function api.postStep()
	if robot.flight_system ~= nil then
		api.actuator.flight_preparation.run_state()
		api.droneAdjustHeight(api.parameters.droneDefaultHeight)
		if robot.params.simulation == true then DroneRealistSimulator.changeActuators(api) end
		robot.flight_system.set_target_pose(api.actuator.newPosition, api.actuator.newRad)
		--api.updateLastSpeed()
		logger("droneAPI: set_target_pose = ", api.actuator.newPosition, api.actuator.newRad)
	end
	api.commonPostStep()
end

---- Height control --------------------
api.droneCheckHeightCountDown = api.actuator.flight_preparation.state_duration * 3
api.droneLastHeight = api.parameters.droneDefaultStartHeight

function api.droneAdjustHeight(z)
	if api.droneCheckHeightCountDown > 0 then
		api.actuator.newPosition.z = api.droneLastHeight
		api.droneCheckHeightCountDown = api.droneCheckHeightCountDown - 1
	elseif api.droneCheckHeightCountDown <= 0 then
		local currentHeight = api.droneEstimateHeight()
		if currentHeight == nil then
			api.actuator.newPosition.z = api.droneLastHeight
			return
		end
		local heightError = z - currentHeight
		local speed_limit = 0.1
		if heightError > speed_limit then heightError = speed_limit end
		if heightError < -speed_limit then heightError = -speed_limit end
		local ZScalar = 5
		if robot.params.hardware == true then ZScalar = 5 end
		-- TODO: there may be a jump here
		api.actuator.newPosition.z = robot.flight_system.position.z + heightError * api.time.period * ZScalar
		api.droneLastHeight = api.actuator.newPosition.z
		if math.abs(heightError) < 0.1 then
			api.droneCheckHeightCountDown = api.actuator.flight_preparation.state_duration * 3
		end
	end
end

function api.droneEstimateHeight()
	-- estimate height
	local average_height = 0
	local average_count = 0
	local tags = api.droneDetectTags()
	for _, tag in ipairs(tags) do
		-- tag see me
		local tagSeeMe = Transform.AxCis0(tag)

		average_height = average_height + tagSeeMe.positionV3.z
		average_count = average_count + 1
	end

	if average_count ~= 0 then
		average_height = average_height / average_count
		return average_height
	else
		return nil
	end
end

---- speed control --------------------
-- everything in robot hardware's coordinate frame
--[[
function api.rememberLastSpeed(x,y,z,th)
	api.actuator.justSetSpeed = {
		x = x, y = y, z = z, th = th,
	}
end

function api.updateLastSpeed()
	api.actuator.lastSetSpeed = {
		x = api.actuator.justSetSpeed.x,
		y = api.actuator.justSetSpeed.y,
		z = api.actuator.justSetSpeed.z,
		th = api.actuator.justSetSpeed.th,
	}
end
--]]

function api.droneSetSpeed(x, y, z, th)
	logger("set point speed = ", x, y, z, th)
	if robot.flight_system == nil then return end
	-- x, y, z in m/s, x front, z up, y left
	-- th in rad/s, counter-clockwise positive
	local rad = robot.flight_system.orientation.z
	local q = quaternion(rad, vector3(0,0,1))

	--[[
	api.rememberLastSpeed(x, y, z, th)

	if api.actuator.lastSetSpeed ~= nil then
		x = (x + api.actuator.lastSetSpeed.x) / 2
		y = (y + api.actuator.lastSetSpeed.y) / 2
		z = (z + api.actuator.lastSetSpeed.z) / 2
		th = (th + api.actuator.lastSetSpeed.th) / 2
	end
	--]]

	-- tune these scalars to make x,y,z,th match m/s and rad/s
		-- 6 and 0.5 are roughly calibrated for simulation
	local transScalar = 4
	local transScalarZ = 4
	local rotateScalar = 0.5
	if robot.params.hardware == true then
		transScalar = 20
		transScalarZ = 10
		rotateScalar = 0.1
	end

	x = x * transScalar * api.time.period
	y = y * transScalar * api.time.period
	z = z * transScalarZ * api.time.period
	th = th * rotateScalar * api.time.period

	api.actuator.setNewLocation(
		vector3(x,y,z):rotate(q) + robot.flight_system.position,
		rad + th
	)
end

api.setSpeed = api.droneSetSpeed
--api.move is implemented in commonAPI

---- Cameras -------------------------
function api.droneEnableCameras()
	for index, camera in pairs(robot.cameras_system) do
		camera.enable()
	end 
end

function api.droneDisableCameras()
	for index, camera in pairs(robot.cameras_system) do
		camera.disable()
	end
end

function api.droneDetectLeds()
	-- detect led is depricated by argos-srocs and resume in the future.
	for _, camera in pairs(robot.cameras_system) do
		if camera.detect_led == nil then return end
	end

	-- takes tags in camera_frame_reference
	local led_dis = 0.02 -- distance between leds to the center
	local led_loc_for_tag = {
	vector3(led_dis, 0, 0),
	vector3(0, led_dis, 0),
	vector3(-led_dis, 0, 0),
	vector3(0, -led_dis, 0)
	} -- start from x+ , counter-closewise

	for _, camera in pairs(robot.cameras_system) do
		for _, tag in ipairs(camera.tags) do
			tag.type = 0
			for j, led_loc in ipairs(led_loc_for_tag) do
				local led_loc_for_camera = vector3(led_loc):rotate(tag.orientation) + tag.position
				local color_number = camera.detect_led(led_loc_for_camera)
				if color_number ~= tag.type and color_number ~= 0 then
					tag.type = color_number
				end
			end
		end
	end
end


function api.droneDetectTags()
	if api.droneTags ~= nil then return api.droneTags end
	-- This function returns a tags table, in real robot coordinate frame
	api.droneDetectLeds()

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
					flag = 1
					break
				end
			end

			tags[#tags + 1] = {
				id = newTag.id,
				type = newTag.type,
				positionV3 = positionV3,
				orientationQ = orientationQ
			}
		end
	end

	api.droneTags = tags
	return tags
end

api.tagLabelIndex = {
	block = {
		from = tonumber(robot.params.block_label_from or 0),
		to = tonumber(robot.params.block_label_to or 0),
	},

	pipuck = {
		from = tonumber(robot.params.pipuck_label_from or 1),
		to = tonumber(robot.params.pipuck_label_to or 500),
	},

	builderbot = {
		from = tonumber(robot.params.builderbot_label_from or 501),
		to = tonumber(robot.params.builderbot_label_to or 1000),
	},
}

function api.droneAddSeenRobots(tags, seenRobotsInRealFrame)
	-- this function adds robots (in real frame) from seen tags (in real robot frames)
	for i, tag in ipairs(tags) do
		local robotTypeS = nil
		for typeS, index in pairs(api.tagLabelIndex) do
			if index.from <= tag.id and tag.id <= index.to then
				robotTypeS = typeS
				break
			end
		end
		if robotTypeS == nil then robotTypeS = "unknown" end

		if robotTypeS ~= "unknown" and robotTypeS ~= "block" then
			local idS = robotTypeS .. math.floor(tag.id)
			seenRobotsInRealFrame[idS] = {
				idS = idS,
				robotTypeS = robotTypeS,
				positionV3 = tag.positionV3 + vector3(0,0,-0.08):rotate(tag.orientationQ),
				orientationQ = tag.orientationQ,
			}
		end
	end
end

function api.droneAddObstacles(tags, obstaclesInRealFrame) -- tags is an array of R
	for i, tag in ipairs(tags) do
		if api.tagLabelIndex.block.from <= tag.id and
		   api.tagLabelIndex.block.to >= tag.id then
			obstaclesInRealFrame[#obstaclesInRealFrame + 1] = {
				type = tag.id,
				robotTypeS = "block",
				positionV3 = tag.positionV3 + vector3(0,0,-0.1):rotate(tag.orientationQ),
				orientationQ = tag.orientationQ,
			}
		end
	end
end

return api
