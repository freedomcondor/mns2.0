package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns
--local structure = require("morphology_decentralize")
local structure = require("morphology_centralize")

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
	bt = BT.create(VNS.create_vns_node(vns))

	local vns_core
	if robot.id == "drone1" then
		vns_core = vns.create_vns_core_node(vns)
	else
		vns_core = vns.create_vns_core_node_no_recruit(vns)
		--vns_core = vns.create_vns_core_node(vns)
	end

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns_core,
		vns.Driver.create_driver_node(vns),
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
	api.droneMaintainHeight(3.5)
	api.postStep()

	-- debug
	--api.debug.showChildren(vns)
	api.debug.showParent(vns)
end

--- destroy
function destroy()
end
