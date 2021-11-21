logger = require("Logger")
api = require("droneAPI")
logger.enable()

function init()
	api.init()
end

function reset()
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount) .. " ------------------------------------")
	api.preStep() 

	api.droneSetSpeed(0.1, 0, 0, 10)
	api.droneMaintainHeight(1.5)

	api.postStep()
end

function destroy()
	api.destroy()
end