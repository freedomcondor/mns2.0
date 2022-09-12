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
local Transform = require("Transform")
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

	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_reaction_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = "spring"}),
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
	local stateCount = 0

	-- parameters ----------------
	local obstacle_type = 32
	local wall_brick_type = 34
	local gate_brick_type = 33
	local target_type = 27
	local max_gate_length = 1.6
	local totalGateNumber = 2
	local n_drone = 2

	local function sendChilrenNewState(vns, newState)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState})
		end
	end

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

	local function switchAndSendNewState(vns, _newState)
		newState(vns, _newState)
		sendChilrenNewState(vns, _newState)
	end

	return function()
		-- if I receive switch state cmd from parent
		if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
			switchAndSendNewState(vns, msgM.dataT.state)
		end end
		-------------------------------------------------------------
		-- waiting for sometime for the 1st formation
		if state == "waiting" then
			vns.stabilizer.force_pipuck_reference = true
			--vns.allocator.pipuck_bridge_switch = true
			stateCount = stateCount + 1
			--if stateCount == 150 + expScale * 50 then
			-- brain wait for sometime and say move_forward
			if vns.parentR == nil then
				--if stateCount > 75 and vns.driver.all_arrive == true then
				if (stateCount > 150) then
					switchAndSendNewState(vns, "move_forward")
				end
			end

		elseif state == "move_forward" then
			vns.stabilizer.force_pipuck_reference = nil
			--vns.allocator.pipuck_bridge_switch = nil
			stateCount = stateCount + 1

			-- everyone reports wall and gates
			ExperimentCommon.reportWall(vns, wall_brick_type)
			local _, _, gateNumber = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			--logger(robot.id, "gateNumber = ", gateNumber)

			-- referencing pipuck gives the moving forward command
				-- and listen newheading command from the brain
			if vns.stabilizer.referencing_me == true then
				vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
				for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "new_heading")) do
					vns.stabilizer.referencing_me_goal_overwrite = {orientationQ = vns.parentR.orientationQ * msgM.dataT.heading}
				end
				-- stop moving forward if other pipucks are in the way
				for idS, robotR in pairs(vns.connector.seenRobots) do
					if robotR.robotTypeS == "pipuck" and
					   robotR.positionV3.x > 0 and robotR.positionV3.x < 0.25 and
					   robotR.positionV3.y > -0.25 and robotR.positionV3.y < 0.25 then
						vns.goal.transV3.x = 0
					end
				end
			end

			-- brain checks the wall and adjust heading
			if vns.parentR == nil then
				if vns.stabilizer.referencing_robot == nil then
					vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
				end
				local receiveWall = ExperimentCommon.detectWall(vns, wall_brick_type)
				if receiveWall == nil then receiveWall = ExperimentCommon.detectWallFromReceives(vns, wall_brick_type) end
				if receiveWall ~= nil then
					vns.api.debug.drawArrow("red", vector3(),
						vns.api.virtualFrame.V3_VtoR(receiveWall.positionV3)
					)
			
					if vns.stabilizer.referencing_robot ~= nil then
						vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", {heading = vns.api.virtualFrame.Q_VtoR(receiveWall.orientationQ)})
					else
						vns.setGoal(vns, vns.goal.positionV3, receiveWall.orientationQ)
					end
		
					vns.api.debug.drawArrow("blue",  
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3)),
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3) + vector3(0.2, 0, 0):rotate(receiveWall.orientationQ))
					)

					-- brain checks gate and go to next state
					local disToTheWall = receiveWall.positionV3:dot(vector3(1,0,0):rotate(receiveWall.orientationQ))
					logger("disToTheWall = ", disToTheWall, "gateNumber = ", gateNumber)
					if gateNumber == totalGateNumber and disToTheWall < 1.5 then
						switchAndSendNewState(vns, "check_gate")
						logger(robot.id, "check_gate")
					end
				end
			end

		elseif state == "check_gate" then
			stateCount = stateCount + 1
			vns.Parameters.stabilizer_preference_robot = nil

			-- If I see the gate and I'm a drone
			local gateList, gate = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			if gate ~= nil and vns.robotTypeS == "drone" then
				-- remember this gate, I may lost it later
				vns.gate = gate
				-- break with my parent
				if vns.parentR ~= nil then
					vns.Msg.send(vns.parentR.idS, "dismiss")
					vns.deleteParent(vns)
				end
				vns.Connector.newVnsID(vns, 1 + gate.length, 1)
				vns.BrainKeeper.reset(vns)
				vns.allocator.mode_switch = "stationary"
				vns.setMorphology(vns, structure2)

				newState(vns, "break_and_recruit")
				logger(robot.id, "I have a gate, breaking and recruiting")
			end
		elseif state == "break_and_recruit" then
			stateCount = stateCount + 1

			if vns.parentR == nil and vns.scalemanager.scale["drone"] == n_drone and stateCount >= 20 then
				logger(robot.id, "I got everyone, switch to structure2")
				switchAndSendNewState(vns, "switch_to_structure2")
				vns.setMorphology(vns, structure2)
				vns.allocator.mode_switch = "allocate"
				--vns.Allocator.sendAllocate(vns) -- necessary ?
			end
		elseif state == "switch_to_structure2" then
			--vns.allocator.pipuck_bridge_switch = true
			stateCount = stateCount + 1
			-- If I see the gate and I'm a drone

			-- everyone reports wall and gates
			ExperimentCommon.reportWall(vns, wall_brick_type)
			local gateList, gate = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length, true) -- true means all report
			-- detect wall from myself, if not, from receives
			local wall = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall == nil then wall = ExperimentCommon.detectWallFromReceives(vns, wall_brick_type) end

			-- Brain detects gate, send gate and wall information to the referenced pipuck
			if vns.parentR == nil then
				--vns.stabilizer.force_pipuck_reference = true
				if gate ~= nil and math.abs(gate.length - vns.gate.length) < 0.2 then
					vns.gate = gate
					vns.setGoal(vns, gate.positionV3 + vector3(-0.5, 0, 0):rotate(gate.orientationQ), gate.orientationQ)
					-- TODO: go to next state
					local disV2 = gate.positionV3 + vector3(-0.5, 0, 0):rotate(gate.orientationQ)
					disV2.z = 0
					if disV2:length() < 0.1 then
						logger(robot.id, "I reach gate, switch to wait_forward_again")
						switchAndSendNewState(vns, "wait_forward_again")
					end
				else
					-- I don't see gate this step, move towards vns.gate
					if vns.gate ~= nil then
						local speed = vector3(vns.gate.positionV3)
						speed = speed:normalize() * 0.03
						vns.Spreader.emergency_after_core(vns, speed, vector3())
					end
				end
			end

			-- other robot try not exceed wall
			if vns.parentR ~= nil and vns.stabilizer.referencing_me ~= true then
				if wall ~= nil then
					local disV2 = vector3(wall.positionV3)
					disV2.z = 0
					local baseNormalV2 = vector3(1,0,0):rotate(wall.orientationQ)
					dis = disV2:dot(baseNormalV2)

					local color = "128,128,0,0"
					vns.api.debug.drawArrow(color,
					                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0.1)),
					                        vns.api.virtualFrame.V3_VtoR(baseNormalV2 * dis + vector3(0,0,0.1))
					                       )

					if dis < 0.2 then
						vns.goal.transV3 = vns.goal.transV3 + baseNormalV2 * (dis - 0.2)
					end
				end
			end

		elseif state == "wait_forward_again" then
			stateCount = stateCount + 1

			if vns.parentR == nil then
				if stateCount > 175 * 1 then
					switchAndSendNewState(vns, "forward_again")
					logger(robot.id, "forward_again")
				end
			end

		elseif state == "forward_again" then
			--vns.allocator.pipuck_bridge_switch = nil
			stateCount = stateCount + 1

			-- everyone reports wall and gates
			ExperimentCommon.reportWall(vns, wall_brick_type)
			local _, gate, gateNumber = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length)
			--logger(robot.id, "gateNumber = ", gateNumber)

			-- referencing pipuck gives the moving forward command
				-- and listen newheading command from the brain
			if vns.stabilizer.referencing_me == true then
				vns.Spreader.emergency_after_core(vns, vector3(0.03,0,0), vector3())
				for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "new_heading")) do
					vns.stabilizer.referencing_me_goal_overwrite = {orientationQ = vns.parentR.orientationQ * msgM.dataT.heading}
					if msgM.dataT.gate ~= nil then
						vns.Spreader.emergency_after_core(vns, vector3(0,msgM.dataT.gate.positionV3.y * 0.1,0), vector3())
					end
				end
			end

			-- brain checks the wall and adjust heading
			if vns.parentR == nil then
				vns.stabilizer.force_pipuck_reference = true
				local receiveWall = ExperimentCommon.detectWall(vns, wall_brick_type)
				if receiveWall == nil then receiveWall = ExperimentCommon.detectWallFromReceives(vns, wall_brick_type) end
				if receiveWall ~= nil then
					vns.api.debug.drawArrow("red", vector3(),
						vns.api.virtualFrame.V3_VtoR(receiveWall.positionV3)
					)
			
					if vns.stabilizer.referencing_robot ~= nil then
						vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", {
							heading = vns.api.virtualFrame.Q_VtoR(receiveWall.orientationQ),
							gate = gate,
						})
					end
		
					vns.api.debug.drawArrow("blue",  
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3)),
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3) + vector3(0.2, 0, 0):rotate(receiveWall.orientationQ))
					)

					-- brain checks target 
					local target = ExperimentCommon.detectTarget(vns, target_type)
					if target ~= nil then
						local disV2 = target.positionV3
						disV2.z = 0
						logger("disV2 = ", disV2:length())
						if disV2:length() < 1.5 then
							vns.target = target
							vns.stabilizer.force_pipuck_reference = nil
							switchAndSendNewState(vns, "structure3")
							logger(robot.id, "structure3")
							vns.setMorphology(vns, structure3)
						end
					end
				end
			end

			-- other drones that is not the brain checks the gate and try to stay middle of the gate
			if vns.robotTypeS == "drone" and vns.parentR ~= nil then
				if gate ~= nil then
					if vns.allocator.goal_overwrite == nil then
						vns.allocator.goal_overwrite = {
							positionV3 = {
								y = gate.positionV3.y
							}
						}
					end
				end
			end

		elseif state == "structure3" then
			if vns.parentR == nil then
				local target = ExperimentCommon.detectTarget(vns, target_type)
				-- update vns.target
				if target ~= nil then
					vns.target = target
				end

				-- move towards remembered vns.target
				if vns.target ~= nil then
					local new_target = Transform.AxBisC(vns.target, {positionV3 = vector3(-0.7,-0.7,0), orientationQ = quaternion()})
					vns.setGoal(vns, new_target.positionV3, new_target.orientationQ)
				end
			end
		end

		-- for debug
		vns.debugstate = {state = state, stateCount = stateCount}
		return false, true
	end
end