logger = require("Logger")
api = require("droneAPI")
logger.enable()

local target = vector3()
local lostCount = 0

function init()
	api.init()
end

function reset()
end


function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount) .. " ------------------------------------")
	api.preStep() 

	-- add tags into seen Robots
	local seenRobots = {}
	api.droneAddSeenRobots(
		api.droneDetectTags(),
		seenRobots
	)

	logger("seenRobots")
	logger(seenRobots)
	logger("lostCount = ", lostCount)

	-- set target based on seenRobots
	-- reset target to vector3() if lost robot for too long
	local reference_robot = seenRobots["pipuck1"]
	if reference_robot ~= nil then
		robot.leds.set_leds(200,200,200)
		target = reference_robot.positionV3 + vector3(1.0, 0, 0):rotate(reference_robot.orientationQ)
		lostCount = 0
	else
		robot.leds.set_leds(0,0,0)
		lostCount = lostCount + 1
		if lostCount >= 10 then
			target = vector3()
			lostCount = 10
		end
	end

	-- fly towards the target
	local speed = target
	speed.z = 0
	local speed = speed:normalize() * 0.05
	api.droneSetSpeed(speed.x, speed.y, 0, 0)
	--api.move(vector3(0.1, 0, 0), vector3())

	api.droneMaintainHeight(1.8)

	api.postStep()
end

function destroy()
	api.destroy()
end