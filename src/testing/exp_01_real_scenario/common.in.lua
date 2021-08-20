package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

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
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval

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
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)

	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		create_reaction_node(vns),
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
	if myType == "drone" then api.droneMaintainHeight(1.5) end
	api.postStep()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)
	--api.debug.showObstacles(vns)
end

--- destroy
function destroy()
end

-- Strategy Tools -----------------------------------------------
function nearestObstacle(vns)
	local distance = math.huge
	local nearest = nil
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.positionV3:length() < distance then
			distance = obstacle.positionV3:length()
			nearest = obstacle
		end
	end
	if nearest == nil then
		-- TODO: get pipucks
	end
	return nearest
end

-- stablize pipuck virtual orientation based on nearby obstacle
function stablizeOrientation(vns)
	-- work only when I'm the brain
	if vns.robotTypeS ~= "pipuck" or vns.parentR ~= nil then return end
	-- if this is the first time I see an obstacle
	if vns.nearest_block == nil then
		vns.nearest_block = nearestObstacle(vns)
		return
	end
	-- If I have an obstacle remembered
	local current_nearest = nearestObstacle(vns)
	-- check if it is the same one
	if current_nearest == nil then vns.nearest_block = nil return end
	if (current_nearest.positionV3 - vns.nearest_block.positionV3):length() > 0.3 then
		vns.nearest_block = current_nearest
		return
	end
	-- all clear, adjust orientation based on difference between vns.nearest_block and current_nearest
	local lastX = vector3(1,0,0):rotate(vns.nearest_block.orientationQ)
	local currentX = vector3(1,0,0):rotate(current_nearest.orientationQ)
	local diff = currentX - lastX
	diff.z = 0
	currentX = lastX + diff
	local cross = lastX:cross(currentX)
	local th = math.asin(cross:length())
	if cross.z < 0 then th = -th end
	local diffQ = quaternion(th, vector3(0,0,1))
	local diffQinv = quaternion(th, vector3(0,0,1)):inverse()
	vns.api.virtualFrame.orientationQ = vns.api.virtualFrame.orientationQ * diffQ
	vns.nearest_block = current_nearest

	-- adjust orientation of detected objects based the new orientation
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		obstacle.orientationQ = obstacle.orientationQ * diffQinv
	end
	for i, robot in pairs(vns.connector.seenRobots) do
		robot.orientationQ = robot.orientationQ * diffQinv
	end
end

-- Strategy -----------------------------------------------
function create_reaction_node(vns)
	local state = "waiting"
	local stateCount = 0
	return function()
		--stablizeOrientation(vns)
		-- waiting for 30 step
		if state == "waiting" then
			stateCount = stateCount + 1
			if stateCount == 300 then
			--if stateCount == nil then
				stateCount = 0
				state = "move_forward"
			end
		-- move_forward
		elseif state == "move_forward" then
			if vns.parentR == nil then
				vns.Spreader.emergency(vns, vector3(0.03,0,0), vector3())
			end
		end
		return false, true
	end
end