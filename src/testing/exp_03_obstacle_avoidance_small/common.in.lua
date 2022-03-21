local myType = robot.params.my_type

package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
local Transform = require("Transform")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")
logger.disable("droneAPI")

-- datas ----------------
local bt
--local vns
local gene = require("morphology")

-- VNS option
-- VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval -- default is oval

-- argos functions -----------------------------------------------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create(myType)
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	--if vns.idS == "pipuck1" then vns.idN = 1 end
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, gene)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}
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
	api.destroy()
end

function create_head_navigate_node(vns)
return function()
	if #vns.avoider.obstacles ~= 0 then
		local orientationAcc = Transform.createAccumulator()
		for id, ob in ipairs(vns.avoider.obstacles) do
			Transform.addAccumulator(orientationAcc, {positionV3 = vector3(), orientationQ = ob.orientationQ})
		end
		local averageOri = Transform.averageAccumulator(orientationAcc).orientationQ
		vns.setGoal(vns, vns.goal.positionV3, averageOri)
	end

	if vns.api.stepCount < 150 then return false, true end
	---[[
	if vns.parentR ~= nil or vns.robotTypeS == "pipuck" then return false, true end
	local speed = 0.02
	local speedx = speed
	local speedy = speed * math.cos(math.pi * api.stepCount/500)
	vns.Spreader.emergency_after_core(vns, vector3(speedx,speedy,0), vector3(), nil, true)
	--]]
	return false, true
end end