package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	bt = BT.create(
	{ type = "sequence", children = {
		VNS.create_preconnector_node(vns),
		function()
			-- find the nearest drone
			local nearest_length = math.huge
			local nearest_drone = nil
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.robotTypeS == "drone" and robotR.positionV3:length() < nearest_length then
					nearest_length = robotR.positionV3:length() 
					nearest_drone = robotR
				end
			end
			if nearest_drone ~= nil then
				api.move(vector3(nearest_drone.positionV3):normalize() * 0.010, vector3())
			else
				api.move(vector3(0.010, 0, 0), vector3())
			end
			return false, true
		end,
	}}
	)
end

--- step
function step()
	-- prestep
	--logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)
	--api.debug.showObstacles(vns)
end

--- destroy
function destroy()
end
