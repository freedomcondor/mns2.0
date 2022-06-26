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
logger.disable("Stabilizer")
logger.disable("droneAPI")

-- datas ----------------
local bt
--local vns
local structure1 = require("morphologies/morphology1")
local structure2 = require("morphologies/morphology2")
local structure3 = require("morphologies/morphology3")
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

-- VNS option
-- VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval -- default is oval

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

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
	vns.setMorphology(vns, structure1)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node(vns),
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
	if vns.parentR == nil then
		api.debug.showObstacles(vns)
	end
end

--- destroy
function destroy()
	api.destroy()
end

----------------------------------------------------------------------------------
function create_head_navigate_node(vns)
local state = 1
local obstacle_type = 34
local target_type = 33
return function()
	vns.state = state
	-- only run for brain
	if vns.parentR ~= nil then return false, true end

	vns.setGoal(vns, vector3(), quaternion())

	-- detect width
	local left = 5
	local right = -5
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.positionV3.y > 0 and ob.type == obstacle_type and
		   ob.positionV3.y < left then
			left = ob.positionV3.y
		end
		if ob.positionV3.y < 0 and ob.type == obstacle_type and
		   ob.positionV3.y > right then
			right = ob.positionV3.y
		end
	end
	for i, ob in ipairs(vns.collectivesensor.receiveList) do
		if ob.positionV3.y > 0 and ob.type == obstacle_type and
		   ob.positionV3.y < left then
			left = ob.positionV3.y
		end
		if ob.positionV3.y < 0 and ob.type == obstacle_type and
		   ob.positionV3.y > right then
			right = ob.positionV3.y
		end
	end

	local width = left - right

	-- State
	if state == 1 then
		if width < 5.0 then
			state = 2
			vns.setMorphology(vns, structure2)
			logger("state2")
		end
	elseif state == 2 then
		if width < 2.0 then
			state = 3
			vns.setMorphology(vns, structure3)
			logger("state3")
		end
	elseif state == 3 then
		for id, ob in ipairs(vns.avoider.obstacles) do
			if ob.type == target_type then
				state = 4
				vns.setMorphology(vns, structure1)
			end
		end
	elseif state == 4 then
		for id, ob in ipairs(vns.avoider.obstacles) do
			if ob.type == target_type then
				vns.setGoal(vns, ob.positionV3 - vector3(0.5, 0, 0), ob.orientationQ)
				return false, true
			end
		end
	end

	-- move
	if vns.api.stepCount < 250 then return false, true end

	-- align with the average direction of the obstacles
	if #vns.avoider.obstacles ~= 0 then
		local orientationAcc = Transform.createAccumulator()
		local left = 5
		local right = -5
		for id, ob in ipairs(vns.avoider.obstacles) do

			-- check left and right
			if ob.positionV3.y > 0 and ob.type == obstacle_type and
			   ob.positionV3.y < left then
				left = ob.positionV3.y
		 	end
			if ob.positionV3.y < 0 and ob.type == obstacle_type and
			   ob.positionV3.y > right then
				right = ob.positionV3.y
			end

			-- accumulate orientation
			Transform.addAccumulator(orientationAcc, {positionV3 = vector3(), orientationQ = ob.orientationQ})
		end

		local averageOri = Transform.averageAccumulator(orientationAcc).orientationQ

		if left > 0 and right < 0 and 
		   left ~= 5 and right ~= -5 then
			vns.goal.positionV3.y = (left + right) / 2
			vns.setGoal(vns, vns.goal.positionV3, averageOri)
		end
	end

	local speed = 0.05
	vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
	return false, true
end end