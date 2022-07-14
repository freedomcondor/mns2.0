local myType = robot.params.my_type

package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
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
local structure4 = require("morphologies/morphology4")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
		structure3,
		structure4,
	}
}

-- VNS option
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_vertical -- default is oval

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

	if vns.parentR == nil then
		api.debug.showObstacles(vns)
	end

	--ExperimentCommon.detectGates(vns, 253, 1.5) -- gate brick id and longest possible gate size
end

--- destroy
function destroy()
	api.destroy()
end

----------------------------------------------------------------------------------
function create_head_navigate_node(vns)
local state = "reach"
local count = 0
return function()
	-- only run for brain
	if vns.parentR ~= nil then return false, true end
	if vns.api.stepCount < 250 then return false, true end

	-- detect target
	local target = nil
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == 100 then
			target = {
				positionV3 = ob.positionV3 - vector3(0.8,0,0),
				orientationQ = ob.orientationQ,
			}
		end
	end

	-- State
	if state == "reach" then
		-- move
		local speed = 0.03
		if target == nil then
			vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
		else
			vns.setGoal(vns, target.positionV3, target.orientationQ)
			target.positionV3.z = 0
		end

		--local disV2 = vector3(target.positionV3)
		if target ~= nil and target.positionV3:length() < 1.00 then
			state = "stretch"
			logger("stretch")
			count = 0
			vns.setMorphology(vns, structure2)
		end
	elseif state == "stretch" then
		count = count + 1

		if target ~= nil then
			vns.setGoal(vns, target.positionV3, target.orientationQ)
			target.positionV3.z = 0
		end
		
		if count == 300 then
			state = "clutch"
			logger("clutch")
			count = 0
			vns.setMorphology(vns, structure3)
		end
	elseif state == "clutch" then
		count = count + 1

		if target ~= nil then
			vns.setGoal(vns, target.positionV3, target.orientationQ)
			target.positionV3.z = 0
		end

		if count == 200 then
			state = "retrieve"
			logger("retrieve")
			count = 0
			vns.setMorphology(vns, structure4)
		end
	elseif state == "retrieve" then
		vns.stabilizer.force_pipuck_reference = true
		vns.Parameters.stabilizer_preference_robot = nil

		vns.Spreader.emergency_after_core(vns, vector3(-0.03,0,0), vector3())

		count = count + 1
		if count == 250 then
			state = "end"
			logger("end")
			vns.setMorphology(vns, structure1)
		end
	end

	return false, true
end end