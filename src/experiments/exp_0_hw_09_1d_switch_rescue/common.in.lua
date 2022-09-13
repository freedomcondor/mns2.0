local myType = robot.params.my_type

--[[
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"
--]]
if robot.params.hardware ~= "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu/?.lua"
end

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
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local structure4 = require("morphology4")
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
	local marker = nil
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == 100 then
			target = {
				positionV3 = ob.positionV3,
				orientationQ = ob.orientationQ,
			}
		end
		if ob.type == 101 then
			marker = {
				positionV3 = ob.positionV3,
				orientationQ = ob.orientationQ,
			}
		end
	end

	-- State
	if state == "reach" then
		-- move
		local speed = 0.03
		local disV2 = nil
		if target == nil then
			vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
		else
			local goal = target.positionV3 + vector3(-1.2, 0.8, 0):rotate(target.orientationQ)
			vns.setGoal(vns, goal, vns.goal.orientationQ)
			disV2 = vector3(goal)
			disV2.z = 0
		end

		if disV2 ~= nil and disV2:length() < 0.10 then
			state = "stretch"
			logger("stretch")
			count = 0
			vns.setMorphology(vns, structure2)
		end
	elseif state == "stretch" then
		local disV2 = nil
		if target ~= nil then
			local goal = target.positionV3 + vector3(-1, 0, 0)
			vns.setGoal(vns, goal, target.orientationQ)
			disV2 = vector3(goal)
			disV2.z = 0
		end

		if disV2 ~= nil and disV2:length() < 0.30 and vns.driver.all_arrive == true then
			count = count + 1
		end
		if count == 100 then
			state = "push"
			logger("push")
			count = 0
			vns.setMorphology(vns, structure3)
		end

	elseif state == "push" then
		count = count + 1
		vns.Allocator.calcBaseValue = function() return 0 end

		if vns.robotTypeS == "drone" then
			vns.api.parameters.droneDefaultHeight = 1.2
		end

		vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
		if target ~= nil then
			vns.setGoal(vns, vns.goal.positionV3, target.orientationQ)
		end

		if marker ~= nil and marker.positionV3.x < 0 then
			state = "resume"
			logger("resume")
			count = 0
			vns.setMorphology(vns, structure1)
		end
	elseif state == "resume" then
		vns.Allocator.calcBaseValue = vns.Allocator.calcBaseValue_oval
		count = count + 1

		if marker ~= nil then
			local goal = marker.positionV3 + vector3(-1.0, -0.5, 0):rotate(marker.orientationQ)
			vns.setGoal(vns, goal, marker.orientationQ)
			disV2 = vector3(goal)
			disV2.z = 0
		end

		if vns.robotTypeS == "drone" then
			vns.api.parameters.droneDefaultHeight = 1.5
			vns.api.tagLabelIndex.pipuck.from = 1
		end

		if count == 200 then
			state = "end"
			logger("end")
			count = 0
		end

	elseif state == "end" then
		vns.Spreader.emergency_after_core(vns, vector3(-0.03,0,0), vector3())
		vns.stabilizer.force_pipuck_reference = true

	--[[
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

		vns.Spreader.emergency_after_core(vns, vector3(-0.01,0,0), vector3())

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
		vns.Parameters.dangerzone_pipuck = 0
		vns.Parameters.deadzone_pipuck = 0

		vns.Spreader.emergency_after_core(vns, vector3(-0.03,0,0), vector3())

		count = count + 1
		if count == 250 then
			state = "end"
			logger("end")
			vns.Parameters.dangerzone_pipuck = 0.4
			vns.Parameters.deadzone_pipuck = 0.2
			vns.setMorphology(vns, structure1)
		end
	--]]
	end

	return false, true
end end