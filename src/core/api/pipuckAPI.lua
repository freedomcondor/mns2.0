--[[
--	pipuck api
--]]

local api = require("commonAPI")

---- actuator --------------------------
api.actuator = {}
-- idealy, I would like to use robot.diff_drive.set_t_velocity only once per step
-- newLeft and newRight are recorded, and enforced at last in dronePostStep
api.actuator = {}
api.actuator.newLeft = 0
api.actuator.newRight = 0
function api.actuator.setNewWheelSpeed(x, y)
	api.actuator.newLeft = x
	api.actuator.newRight = y
end

---- Step Function ---------------------
--function api.preStep() api.preStep() end

api.commonPreStep = api.preStep
function api.preStep()
	if robot.leds ~= nil then
		robot.leds.set_ring_leds(false)
	end
	api.commonPreStep()
end

api.commonPostStep = api.postStep
function api.postStep()
	robot.differential_drive.set_linear_velocity(
		api.actuator.newLeft, 
		api.actuator.newRight
	)
	api.commonPostStep()
end

---- speed control --------------------
-- everything in robot hardware's coordinate frame
function api.pipuckSetWheelSpeed(x, y)
	-- x, y in m/s
	-- the scalar is to make x,y match m/s
	local limit = 0.05
	if x > limit then x = limit end
	if x < -limit then x = -limit end
	if y > limit then y = limit end
	if y < -limit then y = -limit end
	api.actuator.setNewWheelSpeed(x, y)
end

function api.pipuckSetRotationSpeed(x, th)
	-- x, in m/s, x front,
	-- th in rad/s, counter-clockwise positive
	local scalar = 0.01
	local aug = scalar * th
	api.pipuckSetWheelSpeed(x - aug, x + aug)
	local virtual_frame_scalar = 0.25
	api.virtualFrame.rotateInSpeed(vector3(0,0,1) * (-th * virtual_frame_scalar))
end

function api.pipuckSetSpeed(x, y)
	local th = math.atan(y/x)
	if x == 0 and y == 0 then th = 0 end
	--local limit = math.pi / 3 * 2
	--if th > limit then th = limit
	--elseif th < -limit then th = -limit end
	api.pipuckSetRotationSpeed(x, th)
end

api.setSpeed = api.pipuckSetSpeed
--api.move is implemented in commonAPI

---- Debugs --------------------
api.debug.commonShowChildren = api.debug.showChildren -- TODO: change to show parent
function api.debug.showChildren(vns)
	api.debug.commonShowChildren(vns)
	-- draw children location
	if vns.parentR ~= nil then
		api.pipuckShowLED(api.virtualFrame.V3_VtoR(vector3(vns.parentR.positionV3)))
	else
		if robot.leds ~= nil then
			robot.leds.set_body_led(true)
		end
	end
end

---- LEDs --------------------
-- everything in robot hardware's coordinate frame
function api.pipuckShowAllLEDs()
	for count = 1, 8 do
		robot.leds.set_ring_led_index(count, true)
	end
end

function api.pipuckShowLED(vec)
	-- direction is a vector3, x front, y left
	-- th = 0 front, clockwise, -180 to 180
	local th
	if vec.x == 0 and vec.y > 0 then th = -90
	elseif vec.x == 0 and vec.y < 0 then th = 90
	elseif vec.x == 0 and vec.y == 0 then th = 0
	elseif vec.x > 0 then th = math.atan(-vec.y / vec.x) * 180 / math.pi
	elseif vec.x < 0 then th = math.atan(-vec.y / vec.x) * 180 / math.pi
		if vec.y > 0 then th = th - 180
		else th = th + 180
		end
	end

	local count = math.floor((th + 22.5) / 45)
	count = count % 8 + 1

	if robot.leds ~= nil then
		robot.leds.set_ring_led_index(count, true)
	end
end

return api
