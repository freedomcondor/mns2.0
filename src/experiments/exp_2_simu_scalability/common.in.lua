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

-- get scalability scale
local expScale = tonumber(robot.params.exp_scale or 0)
local n_drone = tonumber(robot.params.n_drone or 1)
local morphologiesGenerator = robot.params.morphologiesGenerator
local totalGateNumber = tonumber(robot.params.gate_number or 1)

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
require(morphologiesGenerator)
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

--logger.enableFileLog()

-- datas ----------------
local bt
--local vns
local droneDis = 1.5
local pipuckDis = 0.7
local height = api.parameters.droneDefaultHeight
local structure1 = create_left_right_line_morphology(expScale, droneDis, pipuckDis, height)
--local structure1 = create_3drone_12pipuck_children_chain(1, droneDis, pipuckDis, height, vector3(), quaternion())
local structure2 = create_back_line_morphology(expScale * 2, droneDis, pipuckDis, height, vector3(), quaternion())
--local structure2 = create_back_line_morphology(expScale, droneDis, pipuckDis, height)
local structure3 = create_left_right_back_line_morphology(expScale, droneDis, pipuckDis, height)
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
	-- log step
	if robot.id == "drone1" then
		if api.stepCount % 100 == 0 then
			logger("---- step ", api.stepCount, "-------------")
		end
	end

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
	local state = robot.params.start_state or "waiting"
	--local state = "allocate_test"
	local stateCount = 0
	local stateCountMark = nil

	-- parameters ----------------
	local obstacle_type = 255
	local wall_brick_type = 254
	local gate_brick_type = 253
	local target_type = 252
	local max_gate_length = 4.2

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
		vns.allocator.self_align = true
		-- if I receive switch state cmd from parent
		if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
			switchAndSendNewState(vns, msgM.dataT.state)
		end end

		-- waiting for sometime for the 1st formation
		if state == "waiting" then
			vns.allocator.pipuck_bridge_switch = true
			stateCount = stateCount + 1
			--if stateCount == 150 + expScale * 50 then
			-- brain wait for sometime and say move_forward
			if vns.parentR == nil then
				--if stateCount > 75 and vns.driver.all_arrive == true then
				if (stateCount > 250 * expScale) then
					logger(robot.id, "move_forward")
					switchAndSendNewState(vns, "move_forward")
				end
			end

		elseif state == "move_forward" then
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
				vns.stabilizer.force_pipuck_reference = true
				local receiveWall = ExperimentCommon.detectWall(vns, wall_brick_type)
				if receiveWall == nil then receiveWall = ExperimentCommon.detectWallFromReceives(vns, wall_brick_type) end
				if receiveWall ~= nil then
					vns.api.debug.drawArrow("red", vector3(),
						vns.api.virtualFrame.V3_VtoR(receiveWall.positionV3)
					)
			
					if vns.stabilizer.referencing_robot ~= nil then
						vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", {heading = vns.api.virtualFrame.Q_VtoR(receiveWall.orientationQ)})
					end
		
					vns.api.debug.drawArrow("blue",  
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3)),
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3) + vector3(0.2, 0, 0):rotate(receiveWall.orientationQ))
					)

					-- brain checks gate and go to next state
					local disToTheWall = receiveWall.positionV3:dot(vector3(1,0,0):rotate(receiveWall.orientationQ))
					logger("disToTheWall = ", disToTheWall, "gateNumber = ", gateNumber)
					if gateNumber == totalGateNumber and disToTheWall < 1.75 then
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
				logger(robot.id, "I have a gate, breaking and recruiting, gate length = ", vns.gate.length)
			end
		elseif state == "break_and_recruit" then
			stateCount = stateCount + 1

			if vns.parentR == nil and vns.scalemanager.scale["drone"] == n_drone and stateCount >= expScale * 3 then
				logger(robot.id, "I got everyone, switch to structure2")
				switchAndSendNewState(vns, "switch_to_structure2")
				vns.setMorphology(vns, structure2)
				vns.allocator.mode_switch = "allocate"
				--vns.Allocator.sendAllocate(vns) -- necessary ?
			end
		elseif state == "switch_to_structure2" then
			vns.allocator.pipuck_bridge_switch = true
			stateCount = stateCount + 1
			-- If I see the gate and I'm a drone

			gate_difference_threshold = 0.5

			-- everyone reports wall and gates
			ExperimentCommon.reportWall(vns, wall_brick_type)
			local gateList, gate = ExperimentCommon.detectAndReportGates(vns, gate_brick_type, max_gate_length, true) -- true means all report
			-- detect wall from myself, if not, from receives
			local wall = ExperimentCommon.detectWall(vns, wall_brick_type)
			if wall == nil then wall = ExperimentCommon.detectWallFromReceives(vns, wall_brick_type) end

			-- Brain detects gate, send gate and wall information to the referenced pipuck
			if vns.parentR == nil then
				vns.stabilizer.force_pipuck_reference = true
				-- send both gate and wall
				local sendingGate, sendingWall, memoryGate

				-- if I see a gate, check if it is the same gate, otherwise do nothing
				if gate ~= nil then
					--if vns.gate ~= nil and math.abs(vns.gate.length - gate.length) > gate_difference_threshold then
					if vns.gate ~= nil and gate.length - vns.gate.length < -gate_difference_threshold then
						-- not the same gate, do nothing
						logger(robot.id, "Not the same gate, remember gate length = ", vns.gate.length, "seeing gate length = ", gate.length)
					else
						-- I see the target gate, update vns.gate, and prepare to send this gate
						vns.gate = gate

						if gate ~= nil then
							sendingGate = {
								positionV3 = vns.api.virtualFrame.V3_VtoR(gate.positionV3),
								orientationQ = vns.api.virtualFrame.Q_VtoR(gate.orientationQ),
								length = gate.length,
							}
						end
					end
				end
				if vns.gate ~= nil then
					memoryGate = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(vns.gate.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(vns.gate.orientationQ),
						length = vns.gate.length,
					}
				else
					logger(robot.id, "warning, for brain, vns.gate is nil, while there should always be one")
				end
				if wall ~= nil then
					sendingWall = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(wall.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(wall.orientationQ),
					}
				end

				--send to referencing robot
				if vns.stabilizer.referencing_robot ~= nil then
					vns.Msg.send(vns.stabilizer.referencing_robot.idS, "wall_and_gate", {
						gate = sendingGate, wall = sendingWall, memoryGate = memoryGate,
					})

					for _, msgM in ipairs(vns.Msg.getAM(vns.stabilizer.referencing_robot.idS, "structure2_reach")) do
						if stateCountMark == nil then
							stateCountMark = stateCount
							logger(robot.id, "reach gate, start counting")
						else
							if stateCount - stateCountMark > 175 * expScale then
								switchAndSendNewState(vns, "forward_again")
								logger(robot.id, "forward_again")
							end
							--switchAndSendNewState(vns, "wait_forward_again")
							--logger(robot.id, "wait_forward_again")
						end
					end
				end
			end

			--referencing pipuck lead the swarm to move
			if vns.stabilizer.referencing_me == true then
				-- if get gate update vns.gate
				for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "wall_and_gate")) do
					if msgM.dataT.gate ~= nil then
						-- The brain sees a gate, update my vns.gate
						vns.gate = Transform.AxBisC(vns.parentR, msgM.dataT.gate)
						vns.gate.length = msgM.dataT.gate.length
					else
						-- The brain doesn't see a gate, use my vns.gate
						-- if I don't have a vns.gate, use brain's memory
						if vns.gate == nil then 
							if msgM.dataT.memoryGate ~= nil then
								vns.gate = Transform.AxBisC(vns.parentR, msgM.dataT.memoryGate)
								vns.gate.length = msgM.dataT.memoryGate.length
							else
								logger(robot.id, "warning, for reference pipuck, vns.gate is nil, and brain isn't sending one")
							end
						end
						-- otherwise
						-- I have vns.gate, use vns.gate
					end
					if msgM.dataT.wall ~= nil then
						vns.wall = Transform.AxBisC(vns.parentR, msgM.dataT.wall)
					end
				end

				-- calculate myGoal location and orientation from vns.gate and vns.wall and my target branch
				-- calculate brainGoal
				local brainGoal = {positionV3 = vns.allocator.parentGoal.positionV3, orientationQ = vns.allocator.parentGoal.orientationQ}
				local myGoal = {positionV3 = vector3(), orientationQ = quaternion()}
				if vns.gate ~= nil then
					brainGoal.positionV3 = vns.gate.positionV3

					local color = "128,128,128,0"
					vns.api.debug.drawArrow(color,
					                        vns.api.virtualFrame.V3_VtoR(vns.gate.positionV3),
					                        vns.api.virtualFrame.V3_VtoR(vns.gate.positionV3 + vector3(0.2,0,0):rotate(vns.gate.orientationQ))
					                       )
					local color = "128,128,128,0"
					vns.api.debug.drawArrow(color,
					                        vns.api.virtualFrame.V3_VtoR(vector3()),
					                        vns.api.virtualFrame.V3_VtoR(vns.gate.positionV3)
					                       )
				end
				if vns.wall ~= nil then
					brainGoal.orientationQ = vns.wall.orientationQ
					brainGoal.positionV3 = brainGoal.positionV3 + vector3(0.3, 0, 0):rotate(vns.wall.orientationQ)
				end
				if vns.allocator.target ~= nil and vns.allocator.target.idN ~= -1 then
					Transform.AxBisC(brainGoal, vns.allocator.target, myGoal)
					myGoal.positionV3.z = 0
				else
					logger(robot.id, "referencing robot doesn't have a target")
				end

				local color = "128,128,128,0"
				vns.api.debug.drawArrow(color,
				                        vns.api.virtualFrame.V3_VtoR(vector3()),
				                        vns.api.virtualFrame.V3_VtoR(myGoal.positionV3)
				                       )
				vns.api.debug.drawArrow(color,
				                        vns.api.virtualFrame.V3_VtoR(myGoal.positionV3),
				                        vns.api.virtualFrame.V3_VtoR(myGoal.positionV3 + vector3(0.2,0,0):rotate(myGoal.orientationQ))
				                       )

				-- move to myGoal
				local disV2 = vector3(myGoal.positionV3)
				disV2.z = 0
				if disV2:length() > 0.2 then
					vns.Spreader.emergency_after_core(vns, disV2:normalize() * 0.03, vector3())
				end
				-- adjust my direction
				vns.stabilizer.referencing_me_goal_overwrite = {positionV3 = vns.goal.positionV3, orientationQ = myGoal.orientationQ}

				-- check interfering pipucks
				local frontPoint = vector3(vns.goal.transV3):normalize() * 0.15
				frontPoint.z = 0
				for idS, robotR in pairs(vns.connector.seenRobots) do
					if robotR.robotTypeS == "pipuck" and
					   (robotR.positionV3 - frontPoint):length() < 0.15 then
						vns.goal.transV3 = vector3()
					end
				end

				-- check reach
				local headingDis = (vector3(1,0,0) - vector3(1,0,0):rotate(myGoal.orientationQ)):length()
				if vns.gate ~= nil and disV2:length() < 0.2 and headingDis < 0.1 then
					vns.Msg.send(vns.parentR.idS, "structure2_reach")
				end
			end

			-- other robot try not exceed wall
			if vns.parentR ~= nil and vns.stabilizer.referencing_me ~= true and
			   vns.parentR.idS ~= vns.idS then
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
						vns.goal.transV3 = vns.goal.transV3 + baseNormalV2 * (dis - 0.2) * 5
					end
				end
			end

		--[[
		elseif state == "wait_forward_again" then
			stateCount = stateCount + 1

			if vns.parentR == nil then
				if stateCount > 175 * expScale then
					switchAndSendNewState(vns, "forward_again")
					logger(robot.id, "forward_again")
				end
			end
		--]]

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
						vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", {heading = vns.api.virtualFrame.Q_VtoR(receiveWall.orientationQ)})
					end
		
					vns.api.debug.drawArrow("blue",  
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3)),
						api.virtualFrame.V3_VtoR(vector3(receiveWall.positionV3) + vector3(0.2, 0, 0):rotate(receiveWall.orientationQ))
					)
				end

				-- brain checks target
				local target = ExperimentCommon.detectTarget(vns, target_type)
				if target ~= nil then
					local disV2 = target.positionV3
					disV2.z = 0
					logger("disV2 = ", disV2:length())
					if disV2:length() < 1.6 then
						vns.target = target
						vns.stabilizer.force_pipuck_reference = nil
						switchAndSendNewState(vns, "structure3")
						logger(robot.id, "structure3")
						vns.setMorphology(vns, structure3)
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

			-- other pipucks try to go middle of the gate
			if vns.robotTypeS == "pipuck" and vns.stabilizer.referencing_me ~= true then 
				-- check obstacle for side of the gate
				for i, ob in ipairs(vns.avoider.obstacles) do
					if ob.type == gate_brick_type and ob.positionV3:length() < 0.3 then
						vns.goal.transV3 = vns.goal.transV3 + vector3(1,0,0):rotate(ob.orientationQ) * 0.3
					end

					local color = "255,0,0,0"
					vns.api.debug.drawArrow(color,
											vns.api.virtualFrame.V3_VtoR(vector3(0,0,0.1)),
											vns.api.virtualFrame.V3_VtoR(vns.goal.transV3 * 1 + vector3(0,0,0.1))
										   )
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
					local new_target = Transform.AxBisC(vns.target, {positionV3 = vector3(-1.0,0,0), orientationQ = quaternion()})
					vns.setGoal(vns, new_target.positionV3, new_target.orientationQ)
				end
			end

			-- other pipucks try to go middle of the gate
			if vns.robotTypeS == "pipuck" and vns.stabilizer.referencing_me ~= true then 
				-- check obstacle for side of the gate
				for i, ob in ipairs(vns.avoider.obstacles) do
					if ob.type == gate_brick_type and ob.positionV3:length() < 0.3 then
						vns.goal.transV3 = vns.goal.transV3 + vector3(1,0,0):rotate(ob.orientationQ) * 0.3
					end

					local color = "255,0,0,0"
					vns.api.debug.drawArrow(color,
											vns.api.virtualFrame.V3_VtoR(vector3(0,0,0.1)),
											vns.api.virtualFrame.V3_VtoR(vns.goal.transV3 * 1 + vector3(0,0,0.1))
										   )
				end

			end
		end

		-- for debug
		vns.debugstate = {state = state, stateCount = stateCount}
		return false, true
	end
end
