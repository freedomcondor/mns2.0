package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
			vns.Connector.create_connector_node(vns),
			vns.Assigner.create_assigner_node(vns),
			vns.ScaleManager.create_scalemanager_node(vns),
			vns.Driver.create_driver_node(vns),
		}}

	vns.goal.positionV3 = vector3(1,0,0)
	vns.goal.orientationQ = quaternion(math.pi/2, vector3(0,0,1))
end

--- step
function step()
	-- prestep
	logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	-- set children goal point to 0.5m to the back
	for idS, childR in pairs(vns.childrenRT) do
		childR.goal = {}
		childR.goal.positionV3 = vector3(-0.5,0,0)
		childR.goal.orientationQ = quaternion(0, vector3(0,0,1))
	end

	-- find the nearest children to the goal point, assign others to it
	local minChildR = nil 
	local minDis = math.huge
	for idS, childR in pairs(vns.childrenRT) do
		local distance = (childR.positionV3 - childR.goal.positionV3):length()
		if distance < minDis then
			minDis = distance
			minChildR = childR
		end
	end
	for idS, childR in pairs(vns.childrenRT) do
		if childR ~= minChildR then
			vns.Assigner.assign(vns, idS, minChildR.idS)
		end
	end
	
	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
end

--- destroy
function destroy()
end