package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"

-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
pairs = require("RandomPairs")
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
	bt = BT.create(VNS.create_vns_node(vns))
end

--- step
function step()
	-- prestep
	logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	for idS, childR in pairs(vns.childrenRT) do
		childR.goal.positionV3 = vector3(-0.5,0,0)
		childR.goal.orientationQ = quaternion(0, vector3(0,0,1))
	end

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