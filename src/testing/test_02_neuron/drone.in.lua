package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor
local structure = require("morphology")

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	--bt = BT.create(VNS.create_vns_node(vns))
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
			--vns.Connector.create_connector_node(vns),
			--vns.Assigner.create_assigner_node(vns),
			--vns.ScaleManager.create_scalemanager_node(vns),
			--vns.BrainKeeper.create_brainkeeper_node(vns),
		}}
end

--- step
function step()
	-- prestep
	logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.8)
	api.postStep()

	-- debug
	--api.debug.showChildren(vns)
	api.debug.showParent(vns)

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		goal = true,
		target = true,
		assigner = true,
		allocator = true,
	})
end

--- destroy
function destroy()
end
