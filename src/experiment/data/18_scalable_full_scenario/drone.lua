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
logger.enable()

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
			local distance = math.huge
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
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index1])
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index1].partner)
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index2])
		vns.CollectiveSensor.addToSendList(vns, vns.avoider.obstacles[max_distance_index2].partner)
		vns.max_gate = vns.avoider.obstacles[max_distance_index1]
	else
		vns.max_gate = nil
	end
	return false, true
end end

function create_head_navigate_node(vns)
local count = 0
local state = "before_wall"
return function()
	-- only run for brain
	if vns.parentR ~= nil then return false, true end

	local speed = 0.02
	if state == "before_wall" then
		-- move forward
		vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)

		-- check gate
		if vns.max_gate ~= nil and vns.max_gate.positionV3.x < 0.7 then
			logger("reach_wall")
			state = "at_wall"
			--vns.setMorphology(vns, structure2)
		end
	elseif state == "at_wall" then
		-- ob is the largest gate, move in front of it
		local reach_goal = false
		if vns.max_gate ~= nil then
			local goal = vns.max_gate.positionV3
				+ vns.max_gate.direction:normalize()*(vns.max_gate.distance/2) 
				- vector3(0.6,0,0)
			goal.z = 0
			if goal:length() < 0.05 then reach_goal = true end
			if goal:length() < 0.30 and vns.allocator.target ~= structure2 then 
				-- change to structure2
				vns.setMorphology(vns, structure2)
			end
			goal = goal:normalize()
			vns.Spreader.emergency(vns, goal * speed, vector3(), nil, true)
		else
			logger("I didn't find a gate")
		end

		if reach_goal == true then
			state = "wait_structure2"
			logger("wait_structure2")
		end
	elseif state == "wait_structure2" then
		-- count how many child
		local total = 0
		local the_child = nil
		for idS, childR in pairs(vns.childrenRT) do
			if childR.robotTypeS == "drone" then
				total = total + 1
				the_child = childR
			end
		end
		if total == 1 and (the_child.positionV3 - vector3(-1,0,0)):length() < 0.1 then
			state = "after_wall"
			logger("after_wall")
		end
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
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
end

--- reset
function reset()
	vns.reset(vns)

	-- initialize vns.id to specify the order
	if vns.idS == "drone1" then vns.idN = 1 
	elseif vns.idS == "drone3" then vns.idN = 0.9 
	else vns.idN = 0.5 
	end

	-- set Gene
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
	-- set Morphology to structure1
	vns.setMorphology(vns, structure1)
	-- set BT 
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_gap_detection_node(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node_wait(vns),
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
	if vns.allocator.target == nil then
		robot.debug.loop_functions("-1")
	else
		robot.debug.loop_functions(tostring(vns.allocator.target.idN))
	end

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
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
	if vns.parentR == nil and vns.max_gate ~= nil then
		ob = vns.max_gate
		api.debug.drawArrow("red", 
		                    api.virtualFrame.V3_VtoR(ob.positionV3+vector3(0,0,0.1)), 
		                    api.virtualFrame.V3_VtoR(ob.positionV3 +
		                                             (ob.direction:normalize()*ob.distance) +
		                                             vector3(0,0,0.1)
												    )
	                       )
	end
end

--- destroy
function destroy()
end
