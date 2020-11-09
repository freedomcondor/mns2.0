package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/testing/02_allocate/?.lua"

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
--local structure = require("morphology_classic_variation")
local structure = require("morphology")
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

	local number = tonumber(string.match(vns.idS, "%d+"))
	vns.idN = 0.5

	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))
end

--- step
function step()
	if vns.allocator.target == nil then
		robot.debug.loop_functions("-1")
	else
		robot.debug.loop_functions(tostring(vns.allocator.target.idN))
	end

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
