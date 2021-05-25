package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
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
			vns.Spreader.emergency(vns, vector3(0.01, 0, 0), vector3())
		end
	end

	-- the brain change structures accordingly
	if robot.id == "drone1" then
		if vns.spreader.spreading_speed.flag == "wall" then
			if vns.allocator.target ~= structure2 then
				logger("transform to structure2 : ", stepCount)
				file:write(tostring(stepCount) .. "\n")
			end
			vns.setMorphology(vns, structure2)
		end
		if vns.spreader.spreading_speed.flag == "target" then
			if vns.allocator.target ~= structure3 then
				logger("transform to structure3 : ", stepCount)
				file:write(tostring(stepCount) .. "\n")
				file:close()
			end
			vns.setMorphology(vns, structure3)
		end
	end
end
end

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
		create_reaction_node(vns, tranformStepCSV),
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

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)
	--api.debug.showObstacles(vns)
end

--- destroy
function destroy()
end
