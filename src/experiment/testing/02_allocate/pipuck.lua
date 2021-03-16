package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")
-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns
--local structure = require("morphology_classic_variation")
local structure = require("morphology_classic")
--local structure = require("morphology_5_children")

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
	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))
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

	-- debug
	--api.debug.showChildren(vns)
	api.debug.showParent(vns)

	if vns.brainkeeper.brain ~= nil then
		robotR = vns.brainkeeper.brain
		api.debug.drawArrow("red", vector3(), api.virtualFrame.V3_VtoR(vector3(robotR.positionV3)))
		api.debug.drawArrow("red", 
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
			vector3(0.1, 0, 0):rotate(
				api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
			)
		)
	end
end

--- destroy
function destroy()
end
