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
logger.disable("Allocator")
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
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval

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
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)

	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),

		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_reaction_node(vns),

		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}

	stepCount = 0
end

--- step
function step()
	stepCount = stepCount + 1
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

	--ExperimentCommon.detectGates(vns, 253, 1.5) -- gate brick id and longest possible gate size
end

--- destroy
function destroy()
	api.destroy()
end

-- Strategy -----------------------------------------------
function create_reaction_node(vns)
	local state = "waiting"
	local stateCount = 0

	-- parameters ----------------
	local obstacle_type = 255
	local wall_brick_type = 254
	local gate_brick_type = 253
	local target_type = 252

	return function()
		-------------------------------------------------------------
		-- waiting for sometime for the 1st formation
		if state == "waiting" then
			stateCount = stateCount + 1
			if stateCount == 300 then
			--if stateCount == nil then
				stateCount = 0
				state = "move_forward"
				logger("move forward")
			end

		-------------------------------------------------------------
		-- move_forward : brain:
		--     start the emergency command
		--     from vns.collectivesensor.receiveList, adjust directions based on the wall
		elseif state == "move_forward" and vns.parentR == nil then
			if vns.parentR == nil then
				vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
			end

			-- adjust heading based on collective sensed wall
			for i, ob in pairs(vns.collectivesensor.receiveList) do
				vns.api.debug.drawArrow("red", vector3(),
					vns.api.virtualFrame.V3_VtoR(ob.positionV3)
				)
				vns.setGoal(vns, vns.goal.positionV3, ob.orientationQ)
				break
			end

			-- if sees a wall brick myself
			local wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall_brick ~= nil then
				state = "stay_in_front_of_the_wall"
				logger("stay in front of the wall")
			end

		-- move_forward : body
		--     report wall up
		--     and drone would anchor itself according to the wall
		elseif state == "move_forward" and vns.parentR ~= nil then
			ExperimentCommon.reportWall(vns, wall_brick_type)

			local wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall_brick ~= nil then
				state = "stay_in_front_of_the_wall"
				logger("stay in front of the wall")
			end
			-- if I see a wall, I adjust my distance and orientation
			--[[
			for i, ob in pairs(vns.collectivesensor.receiveList) do
				vns.api.debug.drawArrow("red", vector3(),
					vns.api.virtualFrame.V3_VtoR(ob.positionV3)
				)
			end
			--]]

		-------------------------------------------------------------
		elseif state == "stay_in_front_of_the_wall" then
			-- keep reporting if I'm a child
			if vns.parentR ~= nil then
				ExperimentCommon.reportWall(vns, wall_brick_type)
			end

			-- if I still see the wall, anchor myself
			local wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall_brick == nil then
				--logger("I lost the wall")
			else
				-- if I'm the brain
				-- anchor position
				if vns.parentR == nil then
					local newOri = wall_brick.orientationQ
					vns.goal.orientationQ = wall_brick.orientationQ
					-- distance to the wall
					local distance = (wall_brick.positionV3 - vns.goal.positionV3):dot(vector3(1,0,0):rotate(wall_brick.orientationQ))
					local newPos = vns.goal.positionV3 + 
						vector3(1,0,0):rotate(wall_brick.orientationQ) * (distance - 0.4)
					vns.setGoal(vns, newPos, newOri)
				end
				-- eliminate vertical component in transV3
				--[[
				vns.goal.transV3 = vns.goal.transV3 - 
					vns.goal.transV3:dot(vector3(1,0,0):rotate(wall_brick.orientationQ)) *
					vector3(1,0,0):rotate(wall_brick.orientationQ)
				--]]
			end

			-- If I see the gate and I'm a drone
			local gateList, gate = ExperimentCommon.detectGates(vns, gate_brick_type, 1.5)
			if gate ~= nil and vns.robotTypeS == "drone" then
				if vns.parentR ~= nil then
					vns.Msg.send(vns.parentR.idS, "dismiss")
					vns.deleteParent(vns)
				end
				vns.Connector.newVnsID(vns, 1 + gate.length, 1)
				vns.BrainKeeper.reset(vns)
				vns.setMorphology(vns, structure2)

				vns.setGoal(vns,
				            gate.positionV3 + vector3(-0.4, 0, 0):rotate(gate.orientationQ),
				            gate.orientationQ
				)
			--[[
				vns.goal.positionV3 = gate.positionV3 + vector3(-0.4, 0, 0):rotate(gate.orientationQ)
				vns.goal.orientationQ = gate.orientationQ
				-- tell adjust stablizer based on the orientation
				if vns.stabilizer.reference ~= nil then
					vns.stabilizer.reference_offset.positionV3 = 
						(vns.goal.positionV3 - vns.stabilizer.reference.positionV3):rotate(
							vns.stabilizer.reference.orientationQ:inverse()
						)
					vns.stabilizer.reference_offset.orientationQ = vns.stabilizer.reference.orientationQ:inverse() *
					                                               vns.goal.orientationQ
				end
			--]]

				state = "switch_to_structure2"
				logger("switch to structure 2")

				stateCount = 0
			end



		-------------------------------------------------------------
		elseif state == "switch_to_structure2" then
			if vns.parentR == nil then
				-- move towards the gate
				local gateList, gate = ExperimentCommon.detectGates(vns, gate_brick_type, 1.5)
				if gate ~= nil then
					vns.setGoal(vns,
					            gate.positionV3 + vector3(-0.4, 0, 0):rotate(gate.orientationQ),
					            gate.orientationQ
					           )
				end

				-- tell everyone that we should switch to new state
				-- most of the children are still in "stay_in_front_of_wall" state
				for idS, childR in pairs(vns.childrenRT) do
					vns.Msg.send(idS, "switch_to_state", {state = "switch_to_structure2"})
				end
				-- wait, count and move forward
				stateCount = stateCount + 1
				if stateCount == 500 then
				--if stateCount == nil then
					stateCount = 0
					state = "move_forward_again"
					logger("move forward again")
				end
			end
		-------------------------------------------------------------
		elseif state == "move_forward_again" and vns.parentR == nil then
			vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())

			-- If I see target
			local target = ExperimentCommon.detectTarget(vns, target_type)
			if target ~= nil then
				state = "switch_to_structure3"
				logger("switch to structure3")
				vns.setMorphology(vns, structure3)
			end

		-------------------------------------------------------------
		elseif state == "switch_to_structure3" and vns.parentR == nil then
			if vns.parentR == nil then
				-- move towards the gate
				local target = ExperimentCommon.detectTarget(vns, target_type)
				if target ~= nil then
					vns.setGoal(vns,
					            target.positionV3 + vector3(-0.8, 0, 0):rotate(target.orientationQ),
					            target.orientationQ
					)
				end
			end

		end -- end of state

		-- if I receive switch state cmd from parent
		if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
			state = msgM.dataT.state
			for idS, childR in pairs(vns.childrenRT) do
				vns.Msg.send(idS, "switch_to_state", {state = msgM.dataT.state})
			end
		end end

		-- for debug
		vns.debugstate = state
		return false, true
	end
end