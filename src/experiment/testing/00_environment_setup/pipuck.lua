package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
--package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/VNS/?.lua"

pairs = require("RandomPairs")

logger = require("Logger")
local api = require("pipuckAPI")
local BT = require("BehaviorTree")
logger.enable()

local bt

function init()
	logger(robot.id, "-----------------------")
	logger("robot")
	logger(robot)

	api.init()
	bt = BT.create
		{type = "sequence", children = {
			function()
				logger("I am a btnode")
				return false, true
			end,
		}}
end

function step()
	logger(robot.id, "-----------------------")
	api.preStep()

	api.move(vector3(0.01, 0, 0), vector3(0,0,math.pi/100))

	robot.directional_leds.set_all_colors('black')
	robot.directional_leds.set_single_color(2, 'white')

	bt()
	api.debug.drawArrow("blue", vector3(), vector3(1,0,0))

	api.postStep()
end

function reset()
	init()
end

function destroy()
end
