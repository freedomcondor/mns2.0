package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
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

local Cgenerator = require("MorphologyCGenerator")

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
			vns.childrenRT = {}
		end
	end

	if failed == false then
		return false, true
	else
		api.debug.drawRing("red", vector3(), 0.15)
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

function create_gap_detection_node(vns) 
return function()
	-- append collective sensor to obstacles
	for i, v in ipairs(vns.collectivesensor.receiveList) do
		-- erase distance and direction reported from children
		-- calculate again later
		v.distance = nil 
		v.direction = nil
		table.insert(vns.avoider.obstacles, v)
	end

	-- find gap end direction
	for i, orange_ob in ipairs(vns.avoider.obstacles) do
		if orange_ob.type == 2 then -- orange
			-- find the nearest blue
			local distance = 0.7
			local index = nil
			for j, blue_ob in ipairs(vns.avoider.obstacles) do
				if blue_ob.type == 4 then -- blue
					if (blue_ob.positionV3 - orange_ob.positionV3):length() < distance then
						distance = (blue_ob.positionV3 - orange_ob.positionV3):length()
						index = j
					end
				end
			end
			if index ~= nil then 
				orange_ob.direction = orange_ob.positionV3 - vns.avoider.obstacles[index].positionV3
				orange_ob.partner = vns.avoider.obstacles[index]
			end
		end
	end

	-- match two ends to identify a gap
	local max_distance = 0
	local max_distance_index1 = nil
	local max_distance_index2 = nil

	for i, side1 in ipairs(vns.avoider.obstacles) do
		if side1.type == 2 and side1.direction ~= nil and side1.distance == nil then -- orange
			-- find the nearest side2 along side1's direction
			--local distance = math.huge
			local distance = 2.0 		-- a gate should be smaller than 2m
			local index = nil
			for j, side2 in ipairs(vns.avoider.obstacles) do
				if side2.type == 2 and side2.direction ~= nil and
				   (side1.positionV3 - side2.positionV3):length() < distance and
				   (side2.positionV3 - side1.positionV3):dot(side1.direction) > 0 then
					distance = (side1.positionV3 - side2.positionV3):length()
					index = j
				end
			end

			-- check this nearest side2 is in the opposite direction
			if index ~= nil then
				local side2 = vns.avoider.obstacles[index]
				if (side1.positionV3 - side2.positionV3):dot(side2.direction) < 0 then
					index = nil
				end
			end

			if index == nil then -- no match, the other end not in sight
				local half_sight = 1 -- approximately 2 * 2 meter^2
				local length1
				if side1.direction.x > 0 then
					length1 = half_sight - side1.positionV3.x
				else
					length1 = side1.positionV3.x + half_sight
				end
				length1 = math.abs(length1 * side1.direction:length() / side1.direction.x)

				local length2
				if side1.direction.y > 0 then
					length2 = half_sight - side1.positionV3.y 
				else
					length2 = side1.positionV3.y + half_sight 
				end
				length2 = math.abs(length2 * side1.direction:length() / side1.direction.y)
	
				distance = length1
				if length2 < distance then distance = length2 end

				vns.CollectiveSensor.addToSendList(vns, side1)
				vns.CollectiveSensor.addToSendList(vns, side1.partner)
			else
				-- there is a match, record the largest gate
				if max_distance < distance then
					max_distance = distance
					max_distance_index1 = i
					max_distance_index2 = index
				end
			end

			side1.distance = distance
			if index ~= nil then
				vns.avoider.obstacles[index].distance = distance
			end
		end
	end

	-- report the largest gate
	if max_distance_index1 ~= nil then
		--[[
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index1])
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index1].partner)
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index2])
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index2].partner)
		--]]
		vns.max_gate = vns.avoider.obstacles[max_distance_index1]
	else
		vns.max_gate = nil
	end
	return false, true
end end

function create_head_navigate_node(vns)
local count = 0
local state = "start"
return function()
	-- only run for brain
	--if vns.parentR ~= nil then return false, true end

	local speed = 0.02
	if state == "start" then
		count = count + 1
		if count >= 0 then
			state = "before_wall"
		end
	elseif state == "before_wall" then
		-- move forward
		if vns.parentR == nil then
			vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
		end

		-- check wall distance, look at the nearest wall obstacle
		local obstacle = nil
		local nearest = math.huge
		for i, ob in ipairs(vns.avoider.obstacles) do
			local dis
			if vns.parentR == nil then dis = ob.positionV3.x
			                      else dis = math.abs(ob.positionV3.y) end
			if dis < nearest then
				nearest = dis
				obstacle = ob
			end
		end
		if obstacle ~= nil then
			if nearest < 0.7 then
				logger("reach_wall")
				state = "choose_leader"
			end
		end
	elseif state == "choose_leader" then
		if vns.max_gate ~= nil then
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 1 + vns.max_gate.distance, 1)
			vns.BrainKeeper.reset(vns)
			--vns.setMorphology(vns, structure1)
			vns.allocator.mode_switch = "stationary"
			-- TODO: turn direction
			local gate_direction_dotproduct = math.abs(
				vector3(vns.max_gate.direction):normalize():dot(vector3(1,0,0))
			)
			logger("vns.max_gate.direction", vns.max_gate.direction)
			logger("gate_direction_dotproduct", gate_direction_dotproduct)
			if gate_direction_dotproduct > 0.5 and vns.max_gate.positionV3.y > 0 then
				-- turn left 90
				vns.api.virtualFrame.orientationQ = 
					vns.api.virtualFrame.orientationQ *
					quaternion(math.pi/2, vector3(0,0,1))
			elseif gate_direction_dotproduct > 0.5 and vns.max_gate.positionV3.y < 0 then
				-- turn right 90
				vns.api.virtualFrame.orientationQ = 
					vns.api.virtualFrame.orientationQ *
					quaternion(-math.pi/2, vector3(0,0,1))
			end
		end
		count = vns.scale["drone"] * 5
		logger("waiting leader, I have", vns.scale["drone"], "drones, I wait steps", vns.scale["drone"] * 5)
		state = "wait_leader"
	elseif state == "wait_leader" then
		count = count - 1
		if count <= 0 then
			count = 0
			state = "at_wall"
		end
	elseif state == "at_wall" and vns.parentR ~= nil then
		vns.allocator.mode_switch = "allocate"
		count = 0
		state = "wait_structure2"
	elseif state == "wait_structure2" and vns.parentR ~= nil then
		logger("waiting structure2, I have", vns.scale["drone"], "drones, I wait steps", (vns.scale["drone"]-2) * 1.0 / 0.03 * 5 * 1.5)
		logger("now counting", count)
		count = count + 1
		if count >= (vns.scale["drone"]-2) * 1.0 / 0.03 * 5 * 1.5 then
			state = "move_forward_after_structure2"
			logger("move_forward_after_structure2")
		end
	elseif state == "move_forward_after_structure2" and vns.parentR ~= nil then
		if vns.max_gate ~= nil and vns.parentR.positionV3.x > 0.8 then
			local middle =   vns.max_gate.positionV3
			               + vns.max_gate.direction:normalize()*(vns.max_gate.distance/2) 
			if vns.goal.positionV3 ~= nil then
				vns.goal.positionV3.y = middle.y
			end
		end
	elseif state == "at_wall" and vns.parentR == nil then
		-- ob is the largest gate, move in front of it
		local reach_goal = false
		if vns.max_gate ~= nil then
			-- calculate current gate
			local goal = vns.max_gate.positionV3
				+ vns.max_gate.direction:normalize()*(vns.max_gate.distance/2) 
				- vector3(0.5,0,0)
			goal.z = 0
			-- check last gate, to see if it is the same one
			---[[
			logger("goal =", goal)
			--]]
			if vns.last_max_gate ~= nil then
				if (vector3(goal):normalize() - vns.last_max_gate.goal):length() > 0.3 then
					vns.max_gate = vns.last_max_gate
				end
			end

			if goal:length() < 0.05 then reach_goal = true end
			---[[
			if goal:length() < 0.30 and vns.allocator.target ~= structure2 then 
				-- change to structure2
				vns.allocator.mode_switch = "allocate"
				vns.setMorphology(vns, structure2)
			end
			--]]
			goal = goal:normalize()
			vns.last_max_gate = vns.max_gate
			vns.last_max_gate.goal = goal
			vns.Spreader.emergency(vns, goal * speed, vector3(), nil, true)
		else
			if vns.last_max_gate ~= nil then
				vns.Spreader.emergency(vns, vns.last_max_gate.goal * speed, vector3(), nil, true)
			else
				logger("I didn't find a gate")
			end
		end

		if reach_goal == true then
			count = 0
			state = "wait_structure2"
			logger("wait_structure2")
		end
	elseif state == "wait_structure2" then
		logger("count = ", count)
		logger("reach = ", (vns.scale["drone"]-2) * 1.0 / 0.03 * 5 * 1.5)
		count = count + 1
			if count >= (vns.scale["drone"]-2) * 1.0 / 0.03 * 5 * 1.5 then
				state = "after_wall"
				logger("after_wall")
			end
		--end
	elseif state == "after_wall" then
		vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
		for i, obstacle in ipairs(vns.avoider.obstacles) do
			if obstacle.type == 0 then
				vns.setMorphology(vns, structure3)
				state = "reach_target"
			end
		end
	elseif state == "reach_target" then
		--vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
	end
	vns.state = state
	vns.state_count = count
	return false, true
end end

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	-- generate C code for formation
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp", "N_ROBOTS*3+1") end
end

--- reset
function reset()
	vns.reset(vns)

	-- initialize vns.id to specify the order
	if vns.idS == "drone1" then vns.idN = 1 
	--elseif vns.idS == "drone3" then vns.idN = 0.9 
	else vns.idN = 0.5 
	end

	-- set Gene
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
	-- set Morphology to structure1
	vns.setMorphology(vns, structure1)

	vns.allocator.self_align = true
	-- set BT 
	bt = BT.create
	{ type = "sequence", children = {
		--create_failure_node(vns),
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_gap_detection_node(vns),
		create_head_navigate_node(vns),
		create_brain_chase_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}
end

--- step
function step()
	-- log time
	if robot.id == "drone1" then
		if api.stepCount == 0 then
			os.execute("echo time log start > time_log")
		end
		if math.fmod(api.stepCount, 100) == 0 then
			os.execute("echo " .. tostring(api.stepCount) .. " >> time_log && @DATECOMMAND@ \"+        %T.%N\" >> time_log")
		end
	end
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
	api.droneMaintainHeight(1.5)
	if failed then
		api.droneMaintainHeight(0)
	end
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
	--if robot.id == "drone1" then
	--	api.debug.showObstacles(vns)
	--end

	--[[
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == 2 then -- orange
			api.debug.drawArrow("red", 
			                    vector3(0,0,0),
								api.virtualFrame.V3_VtoR(ob.positionV3)
			)
		end
	end
	--]]
	--if vns.parentR == nil and vns.max_gate ~= nil then
	if vns.max_gate ~= nil then
		ob = vns.max_gate
		api.debug.drawArrow("red", 
		                    api.virtualFrame.V3_VtoR(ob.positionV3+vector3(0,0,0.1)), 
		                    api.virtualFrame.V3_VtoR(ob.positionV3 +
		                                             (ob.direction:normalize()*ob.distance) +
		                                             vector3(0,0,0.1)
												    )
	                       )
	end

	logger("Connector.lastid:")
	logger(vns.connector.lastid)
	logger("Connector.locker_count:")
	logger(vns.connector.locker_count)
	logger("target id:")
	if vns.allocator.target ~= nil then
		logger(vns.allocator.target.idN)
	end
	logger("vns.goal")
	logger(vns.goal)
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
