package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/data/01_displace_mns/?.lua"

pairs = require("RandomPairs")
-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
VNS.PipuckConnector = require("PipuckOnlyConnector")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns
local structure = require("morphology")

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
	if robot.id == "pipuck2" then
		vns.idN = 1
	end
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
	api.debug.showChildren(vns)
end

--- destroy
function destroy()
end
