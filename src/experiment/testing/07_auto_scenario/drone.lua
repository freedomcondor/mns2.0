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
return function()
	if vns.parentR == nil then
		local ob = nil
		local maxDistance = 0
		for i, obstacle in ipairs(vns.avoider.obstacles) do
			if obstacle.positionV3.x > 0 and
			   obstacle.distance ~= nil and
			   obstacle.distance > maxDistance then
				maxDistance = obstacle.distance
				ob = obstacle
			end
		end

		if ob ~= nil then
			local goal = ob.positionV3 + ob.direction:normalize()*(ob.distance/2)
			goal = (goal - vector3(0.0, 0, 0)):normalize()
			vns.Spreader.emergency(vns, goal * 0.02, vector3())
		else
			vns.Spreader.emergency(vns, vector3(0.02,0,0), vector3())
		end
	end
end end

function create_gap_detection_node(vns) 
return function()
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
end end

function create_reaction_node(vns, file)
return function()
	-- detect obstacle/predator and send emergency flag
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.type == 4 then -- blue
			vns.Spreader.emergency(vns, vector3(), vector3(), "wall")
		end
		if obstacle.type == 0 and obstacle.positionV3.x > 0 then -- black
			vns.Spreader.emergency(vns, vector3(), vector3(), "target")
			--vns.setMorphology(vns, structure3)
		end
	end
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if idS == "pipuck40" then
			local runawayV3 = vector3()
			--runawayV3 = Avoider.add(vector3(), obstacle.positionV3, runawayV3, predator_distance)
			runawayV3 = vector3() - robotR.positionV3
			runawayV3.z = 0
			runawayV3:normalize()
			runawayV3 = runawayV3 * 0.03
			vns.Spreader.emergency(vns, runawayV3, vector3())
		end
	end

	-- detect gaps
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.distance ~= nil and
		   obstacle.positionV3.x > 0 and
		   vns.idN < 1 + obstacle.distance then -- orange
			if vns.parentR ~= nil then 
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.Connector.newVnsID(vns, 1 + obstacle.distance)
			vns.setMorphology(vns, structure2)
		end
	end

	-- the brain change structures accordingly
	if vns.parentR == nil then
		if vns.spreader.spreading_speed.flag == "wall" then
			if vns.allocator.target ~= structure2 then
				logger("transform to structure2 : ", stepCount)
				file:write(tostring(stepCount) .. "\n")
			end
			vns.setMorphology(vns, structure2)
		elseif vns.spreader.spreading_speed.flag == "target" then
			if vns.allocator.target ~= structure3 then
				logger("transform to structure3 : ", stepCount)
				file:write(tostring(stepCount) .. "\n")
				file:close()
			end
			vns.setMorphology(vns, structure3)
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

	tranformStepCSV = io.open("jumpStep.csv", "w");

	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		create_gap_detection_node(vns),
		create_reaction_node(vns, tranformStepCSV),
		create_head_navigate_node(vns),
		vns.create_vns_core_node(vns),
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

--- destroy
function destroy()
end
