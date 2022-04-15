local myType = robot.params.my_type

package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

-- get scalability scale
local expScale = tonumber(robot.params.exp_scale or 0)

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
require("morphologiesGenerator")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")
logger.disable("Stabilizer")
logger.disable("droneAPI")

--logger.enableFileLog()

-- datas ----------------
local bt
--local vns
local droneDis = 1.5
local pipuckDis = 0.7
local height = api.parameters.droneDefaultHeight
local structure1 = create_left_right_line_morphology(2, droneDis, pipuckDis, height)
--local structure1 = create_3drone_12pipuck_children_chain(1, droneDis, pipuckDis, height, vector3(), quaternion())
local structure2 = create_3drone_12pipuck_children_chain(1, droneDis, pipuckDis, height, vector3(), quaternion())
--local structure2 = create_back_line_morphology(expScale, droneDis, pipuckDis, height)
local structure3 = create_left_right_line_morphology(expScale, droneDis, pipuckDis, height)
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
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_vertical

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
	if vns.robotTypeS == "pipuck" then vns.idN = 0 end
	vns.setGene(vns, gene)

	--if vns.robotTypeS == "pipuck" then option = {connector_no_recruit = true} end
	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, option),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_reaction_node(vns),
		--vns.Driver.create_driver_node(vns, {waiting = true}),
		vns.Driver.create_driver_node(vns, {waiting = "spring"}),
	}}
end

--- step
function step()
	-- prestep
	--logger(robot.id, api.stepCount, "-----------------------")
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
	if vns.robotTypeS == "drone" then api.debug.showObstacles(vns) end

	--ExperimentCommon.detectGates(vns, 253, 1.5) -- gate brick id and longest possible gate size
end

--- destroy
function destroy()
	api.destroy()
end

-- Strategy -----------------------------------------------
function create_reaction_node(vns)
	local state = "waiting"
	--local state = "allocate_test"
	local stateCount = 0

	-- parameters ----------------
	local obstacle_type = 255
	local wall_brick_type = 254
	local gate_brick_type = 253
	local target_type = 252
	local max_gate_length = 2.0

	return function()
		vns.allocator.self_align = true
		-------------------------------------------------------------
		--[[ stationary stabilizer test
		if state == "allocate_test" then
			stateCount = stateCount + 1
			if vns.parentR == nil and stateCount > 100 then
				vns.allocator.mode_switch = "stationary"
				state = "stationary_test"
				logger("stationary_test")
				stateCount = 0
			end
		elseif state == "stationary_test" then
			stateCount = stateCount + 1
			--if vns.parentR == nil and stateCount < -1 then
			if vns.parentR == nil and stateCount > 100 then
				vns.allocator.mode_switch = "allocate"
				state = "allocate_test"
				logger("allocate_test")
				stateCount = 0
			end
		--]]

		-- waiting for sometime for the 1st formation
		if state == "waiting" then
			stateCount = stateCount + 1
			--if stateCount == 150 + expScale * 50 then
			--if stateCount == 150 then
			if stateCount == nil then
				stateCount = 0
				state = "move_forward"
				logger("move forward")
			end
			if vns.parentR == nil then
				--if stateCount > 75 and vns.driver.all_arrive == true then
				if stateCount > 250 then
				--if false then
					stateCount = 0
					state = "move_forward"
					logger("move forward")
					for idS, childR in pairs(vns.childrenRT) do
						vns.Msg.send(idS, "switch_to_state", {state = "move_forward"})
					end
				end
			end

		-------------------------------------------------------------
		-- move_forward : brain:
		--     start the emergency command
		--     from vns.collectivesensor.receiveList, adjust directions based on the wall
		elseif state == "move_forward" and vns.parentR == nil then
			local _, _, gateNumber = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			logger(robot.id, "gateNumber = ", gateNumber)

			if gateNumber == 2 then
				state = "check_gate"
				logger(robot.id, "check_gate")
				for idS, childR in pairs(vns.childrenRT) do
					vns.Msg.send(idS, "switch_to_state", {state = "check_gate"})
				end
			end

			if vns.parentR == nil then
				vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
			end

			-- adjust heading based on collective sensed wall
			for i, ob in pairs(vns.collectivesensor.receiveList) do
				vns.api.debug.drawArrow("red", vector3(),
					vns.api.virtualFrame.V3_VtoR(ob.positionV3)
				)

				if vns.stabilizer.referencing_robot ~= nil then
					vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", {heading = vns.api.virtualFrame.Q_VtoR(ob.orientationQ)})
				else
					vns.setGoal(vns, vns.goal.positionV3, ob.orientationQ)
				end
				-- TODO: it won't effect because brain is referencing pipucks

				vns.api.debug.drawArrow("blue",  
				                    api.virtualFrame.V3_VtoR(vector3(ob.positionV3)),
				                    api.virtualFrame.V3_VtoR(vector3(ob.positionV3) + vector3(0.2, 0, 0):rotate(ob.orientationQ))
				                   )
				break
			end

			-- if sees a wall brick myself
			--[[
			local wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall_brick ~= nil then
				state = "stay_in_front_of_the_wall"
				logger(robot.id, "stay in front of the wall")
			end
			--]]

		-- move_forward : body
		--     report wall up
		--     and drone would anchor itself according to the wall
		elseif state == "move_forward" and vns.parentR ~= nil then
			ExperimentCommon.reportWall(vns, wall_brick_type)
			local _, _, gateNumber = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			logger(robot.id, "gateNumber = ", gateNumber)

			--[[ it is handled at the end of the this function
			-- If the brain sees the wall, it sends signal, I should turn to stay_in_front_of_the_wall state
			for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "stay_in_front_of_the_wall")) do
				state = "stay_in_front_of_the_wall"
				logger(robot.id, "stay in front of the wall")
				for idS, childR in pairs(vns.childrenRT) do
					vns.Msg.send(idS, "stay_in_front_of_the_wall")
				end
			end
			--]]

			-- If I'm referenced, the brain may tell me to adjust heading
			for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "new_heading")) do
				vns.stabilizer.referencing_me_goal_overwrite = {orientationQ = vns.parentR.orientationQ * msgM.dataT.heading}
			end

		-------------------------------------------------------------
		elseif state == "stay_in_front_of_the_wall" then
			if vns.parentR ~= nil then
				-- keep reporting if I'm a child
				ExperimentCommon.reportWall(vns, wall_brick_type)
				local _, _, gateNumber = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
				logger(robot.id, "gateNumber = ", gateNumber)

				-- keep transfering stay_in_front_of_the_wall signal to the swarm
				--[[
				for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "stay_in_front_of_the_wall")) do
					for idS, childR in pairs(vns.childrenRT) do
						vns.Msg.send(idS, "stay_in_front_of_the_wall")
					end
				end
				--]]
			else
				-- keep sending stay_in_front_of_the_wall signal to the swarm
				for idS, childR in pairs(vns.childrenRT) do
					vns.Msg.send(idS, "switch_to_state", {state = "stay_in_front_of_the_wall"})
				end
			end

			-- if I see the wall, anchor myself
			local wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall_brick == nil then
				if vns.parentR == nil then
					logger("Brain lost the wall")
					vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
				end
			else
				if vns.robotTypeS == "drone" then
					-- distance to the wall
					local distance = (wall_brick.positionV3 - vns.goal.positionV3):dot(vector3(1,0,0):rotate(wall_brick.orientationQ))
					local newPos = vns.goal.positionV3 + 
						vector3(1,0,0):rotate(wall_brick.orientationQ) * (distance - 1.0)
					local newOri = vns.goal.orientationQ
					if vns.parentR == nil then
						newOri = wall_brick.orientationQ
					end
					vns.setGoal(vns, newPos, newOri)
				end
			end

			-- check if all my children all can see the wall
			for idS, childR in pairs(vns.childrenRT) do
				for _, msgM in ipairs(vns.Msg.getAM(idS, "I_can_see_the_wall")) do
					childR.see_the_wall = true
				end
				for _, msgM in ipairs(vns.Msg.getAM(idS, "I_can_NOT_see_the_wall")) do
					childR.see_the_wall = false
				end
			end

			local flag = true
			if wall_brick == nil then 
				flag = false
			else
				local distance = wall_brick.positionV3:dot(vector3(1,0,0):rotate(wall_brick.orientationQ))
				--logger(robot.id, "distance = ", distance)
				if vns.robotTypeS == "drone" and distance > 1.2 then flag = false end
			end
			for idS, childR in pairs(vns.childrenRT) do
				if childR.see_the_wall ~= true then flag = false end
			end

			if vns.parentR ~= nil then
				-- I'm not brain, I send see wall signal
				if flag == true then
					vns.Msg.send(vns.parentR.idS, "I_can_see_the_wall")
				else
					vns.Msg.send(vns.parentR.idS, "I_can_NOT_see_the_wall")
				end

				--[[
				for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "check_gate")) do
					state = "check_gate"
					logger(robot.id, "check_gate")
					for idS, childR in pairs(vns.childrenRT) do
						vns.Msg.send(idS, "check_gate")
					end
				end
				--]]
			else
				-- I'm brain, I send check gate signal
				if flag == true then
					state = "check_gate"
					logger(robot.id, "check_gate")
					for idS, childR in pairs(vns.childrenRT) do
						vns.Msg.send(idS, "switch_to_state", {state = "check_gate"})
					end
				end
			end


		-------------------------------------------------------------
		elseif state == "check_gate" then
			-- If I see the gate and I'm a drone
			local gateList, gate = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			if gate ~= nil and vns.robotTypeS == "drone" then
				if vns.parentR ~= nil then
					vns.Msg.send(vns.parentR.idS, "dismiss")
					vns.deleteParent(vns)
					vns.allocator.mode_switch = "stationary"
				end
				vns.Connector.newVnsID(vns, 1 + gate.length, 1)
				vns.BrainKeeper.reset(vns)
				--[[
				vns.setMorphology(vns, structure2)

				vns.setGoal(vns,
				            gate.positionV3 + vector3(-0.4, 0, 0):rotate(gate.orientationQ),
				            gate.orientationQ
				)
				--]]

				state = "prepare_to_structure2"
				logger(robot.id, "prepare_to_structure2 to structure 2")

				stateCount = 0
			end
			--]]

		-------------------------------------------------------------
		elseif state == "prepare_to_structure2" then
			stateCount = stateCount + 1
			if stateCount >= expScale * 2 then
				logger(robot.id, "checking scale")
				if vns.parentR == nil and vns.scalemanager.scale["drone"] == expScale * 2 + 1 then
					logger(robot.id, "I got everyone, switch to structure2")
					stateCount = 0
					state = "switch_to_structure2" 
					vns.setMorphology(vns, structure2)
					vns.allocator.mode_switch = "allocate"
					vns.Allocator.sendAllocate(vns)
				end
			end

		-------------------------------------------------------------
		elseif state == "switch_to_structure2" then
			local gateList, gate = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			if vns.parentR == nil then
				-- move towards the gate
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
				--if stateCount == 500 then
				if stateCount > 50 and vns.driver.all_arrive == true then
				--if stateCount == nil then
					stateCount = 0
					state = "move_forward_again"
					logger(robot.id, "move forward again")
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
		vns.debugstate = {state = state, stateCount = stateCount}
		return false, true
	end
end