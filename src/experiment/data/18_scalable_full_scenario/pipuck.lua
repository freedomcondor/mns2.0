package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.disable()
--logger.enable()
--logger.disable('Allocator')

-- datas ----------------
local bt
--local vns
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
		structure3,
	}
}

-- overwrite resetMorphology
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

-- function node ---------
local failed = false
function create_failure_node(vns)
failed = false
return function()
	if vns.parentR == nil then return false, true end

	if api.stepCount == 500 then
		local random_number = robot.random.uniform()
		if random_number < 0.5 then
			failed = true
			--vns.reset(vns)
			api.move(vector3(),vector3())
		end
	end

	if failed == false then
		return false, true
	else
		api.debug.drawRing("red", vector3(), 0.06)
		return false, false
	end
end end

function create_brain_chase_node(vns)
return function()
	if vns.parentR == nil and vns.brainkeeper.brain ~= nil then
		logger(vns.brainkeeper.brain.positionV3)
		local speed = vector3(vns.brainkeeper.brain.positionV3):normalize() * 0.04
		vns.Spreader.emergency_after_core(vns, speed, vector3(), nil)
	end
	return false, true
end end

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
	if vns.idS == "drone1" then vns.idN = 1 else vns.idN = 0 end
	vns.setGene(vns, gene)
	-- set Morphology to structure1
	vns.setMorphology(vns, structure1)
	vns.allocator.self_align = true
	bt = BT.create
	{ type = "sequence", children = {
		--create_failure_node(vns),
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, {connector_no_recruit = true}),
		create_brain_chase_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}
end

--- step
function step()
	-- prestep
	logger(robot.id, api.stepCount + 1, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()
	-- loop function message
	if failed == true then
		robot.debug.loop_functions("-2")
	elseif vns.allocator.target == nil then
		robot.debug.loop_functions("-1")
	else
		robot.debug.loop_functions(tostring(vns.allocator.target.idN))
	end

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
	--api.debug.showObstacles(vns)

	logger("Connector.lastid:")
	logger(vns.connector.lastid)
	logger("Connector.locker_count:")
	logger(vns.connector.locker_count)
	logger("target id:")
	if vns.allocator.target ~= nil then
		logger(vns.allocator.target.idN)
	end
	logger("vns.scale")
	logger(vns.scale)
	logger("parent")
	if vns.parentR ~= nil then
		logger("id = ", vns.parentR.idS)
		logger("scale = ")
		logger(vns.parentR.scale)
		logger("unseen_count = ", vns.parentR.unseen_count)
		logger("position = ", vns.parentR.positionV3)
		logger("position:length = ", vns.parentR.positionV3:length())
	end
	logger("children")
	for idS, childR in pairs(vns.childrenRT) do
		logger("id = ", idS)
		logger("scale = ")
		logger(childR.scale)
		logger("unseen_count = ", childR.unseen_count)
		logger("assign = ", childR.assignTargetS)
		logger("position = ", childR.positionV3)
		logger("position:length = ", childR.positionV3:length())
	end
end

--- destroy
function destroy()
end
