logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

function reset()
	vns.reset(vns)
	bt = BT.create{type = "sequence", children = {
		vns.create_preconnector_node(vns),
	}}
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount + 1) .. " ------------------------------------")
	api.preStep() 
	vns.preStep(vns)

	bt()

	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger("\t", idS)
		logger("\t\t position = ", robotR.positionV3)
		logger("\t\t orientation X = ", vector3(1,0,0):rotate(robotR.orientationQ))
		logger("\t\t             Y = ", vector3(0,1,0):rotate(robotR.orientationQ))
		logger("\t\t             Z = ", vector3(0,0,1):rotate(robotR.orientationQ))
	end

	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()
end

function destroy()
	api.destroy()
end