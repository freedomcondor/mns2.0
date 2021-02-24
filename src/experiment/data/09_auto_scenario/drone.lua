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

function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

----   count step and record tranform step
local stepCount
local tranformStepCSV

function create_head_navigate_node(vns)
local state = "before_wall"
return function()
	local speed = 0.02
	local structure2_changed = false
	if vns.parentR == nil then
		if state == "before_wall" then
			-- command forward
			vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
			-- check gate is near enough
			for i, obstacle in ipairs(vns.avoider.obstacles) do
				if obstacle.distance ~= nil and
				   obstacle.positionV3.x < 0.7 then
					logger("reach wall")
					state = "at_wall"
					-- change to structure2
					--vns.setMorphology(vns, structure2)
				end
			end
		elseif state == "at_wall" then
			-- find the largest gate
			local ob = nil
			local maxDistance = 0
			for i, obstacle in ipairs(vns.avoider.obstacles) do
				if obstacle.distance ~= nil and
				   obstacle.distance > maxDistance then
					maxDistance = obstacle.distance
					ob = obstacle
				end
			end
			-- ob is the largest gate, move in front of it
			local reach_goal = false
			if ob ~= nil then
				local goal = ob.positionV3 + ob.direction:normalize()*(ob.distance/2) - vector3(0.5,0,0)
				goal.z = 0
				if goal:length() < 0.05 then reach_goal = true end
				if goal:length() < 1.00 and structure2_changed == false then 
					-- change to structure2
					vns.setMorphology(vns, structure2)
					structure2_changed = true
				end
				goal = goal:normalize()
				vns.Spreader.emergency(vns, goal * speed, vector3(), nil, true)
			else
				logger("I didn't find a gate")
			end

			if reach_goal == true then
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
			vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
		end
	end
	return false, true
end end

function create_gap_detection_node(vns) 
return function()
	if vns.parentR ~= nil then return false, true end

	-- append collective sensor to obstacles
	for i, v in ipairs(vns.collectivesensor.receiveList) do
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
			end
		end
	end
	-- match two ends to identify a gap
	for i, side1 in ipairs(vns.avoider.obstacles) do
		if side1.type == 2 and side1.direction ~= nil and side1.distance == nil then -- orange
			-- find the nearest match (a match means a pair in reverse direction)
			local distance = math.huge
			local index = nil
			for j, side2 in ipairs(vns.avoider.obstacles) do
				if side2.type == 2 and side2.direction ~= nil and
				   (side1.positionV3 - side2.positionV3):length() < distance and
				   (side2.positionV3 - side1.positionV3):dot(side1.direction) > 0 and
				   (side1.positionV3 - side2.positionV3):dot(side2.direction) > 0 then
					distance = (side1.positionV3 - side2.positionV3):length()
					index = j
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
			end

			side1.distance = distance
			if index ~= nil then
				vns.avoider.obstacles[index].distance = distance
			end
		end
	end
	return false, true
end end

function create_reaction_node(vns, file)
return function()
	-- detect predator
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if idS == "pipuck40" then
			local runawayV3 = vector3()
			--runawayV3 = Avoider.add(vector3(), obstacle.positionV3, runawayV3, predator_distance)
			runawayV3 = vector3() - robotR.positionV3
			runawayV3.z = 0
			runawayV3:normalize()
			runawayV3 = runawayV3 * 0.03
			vns.Spreader.emergency(vns, runawayV3, vector3(), nil, true)
		end
	end
end end

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)

	if robot.id == "drone1" then
		Cgenerator(gene, "Ccode.cpp")
	end
	if robot.id == "drone2" then
		api.virtualFrame.orientationQ = quaternion(math.pi*2/3, vector3(0,0,1))
		vns.idN = 0.999
	end

	tranformStepCSV = io.open("jumpStep.csv", "w");

	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
		create_gap_detection_node(vns),
		create_reaction_node(vns, tranformStepCSV),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node(vns),
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

	-- loop function message
	if vns.allocator.target == nil then
		robot.debug.loop_functions("-1")
	else
		robot.debug.loop_functions(tostring(vns.allocator.target.idN))
	end

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
	-- show gates
	if vns.parentR == nil then
	--api.debug.showObstacles(vns)
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.direction ~= nil and ob.distance ~= nil then
			api.debug.drawArrow("red", 
				ob.positionV3+vector3(0,0,0.1), 
				ob.positionV3 +
				(ob.direction:normalize()*ob.distance) +
				vector3(0,0,0.1)
			)
		end
	end
	end
end

--- destroy
function destroy()
end
