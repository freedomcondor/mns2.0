package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
--package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/VNS/?.lua"

logger = require("Logger")
local api = require("droneAPI")
local BT = require("BehaviorTree")
logger.enable()

local bt

function init()
	api.init()
	bt = BT.create
		{type = "sequence", children = {
			function()
				logger("I am a btnode")
				api.debug.drawArrow("blue", vector3(), vector3(1,0,0))
				return false, true
			end,
		}}
end

function step()
	DMSG(robot.id, "-----------------------")
	api.preStep()

	api.move(vector3(0.01, 0, 0), vector3(0,0,math.pi/100))

	api.droneAddSeenRobots(
		api.droneDetectTags(),
		vns.connector.seenRobots
	)

	bt()

	api.droneMaintainHeight(1.5)
	api.postStep()
end

function reset()
	init()
end

function destroy()
end
