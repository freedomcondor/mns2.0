package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
--package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/VNS/?.lua"

pairs = require("RandomPairs")

logger = require("Logger")
local api = require("droneAPI")
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

	-- test pairs
	local tabletest = {"a", "b" , "c"}
	for i, v in pairs(tabletest) do print(i, v) end
	tabletest.aaa = "aaa"
	for i, v in pairs(tabletest) do print(i, v) end
	-- test vector3
	logger("vector3")
	logger(getmetatable(vector3()))
end

function step()
	logger(robot.id, "-----------------------")
	api.preStep()

	api.move(vector3(0.01, 0, 0), vector3(0,0,math.pi/100))

	bt()
	api.debug.drawArrow("blue", vector3(), vector3(1,0,0))

	api.droneMaintainHeight(1.5)
	api.postStep()
end

function reset()
	init()
end

function destroy()
end
