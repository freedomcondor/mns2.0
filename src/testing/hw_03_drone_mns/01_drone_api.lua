logger = require("Logger")
api = require("droneAPI")
logger.enable()

function init()
	api.init()
end

function reset()
end

local target = vector3()
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

	local reference_robot = seenRobots["pipuck1"]
	if reference_robot ~= nil then
		target = reference_robot.positionV3 + vector3(0.5, 0, 0):rotate(reference_robot.orientationQ)
	end

	api.droneSetSpeed(target.x, target.y, 0, 0)
	api.droneMaintainHeight(1.5)

	api.postStep()
end

function destroy()
	api.destroy()
end