logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

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
	
	if robot.id == "pipuck1" then
		vns.idN = 1
	elseif robot.id == "drone2" then
		vns.idN = 0.8
	elseif robot.id == "pipuck2" then
		vns.idN = 0.6
	end

	bt = BT.create{type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.Connector.create_connector_node(vns),
		create_reaction_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount + 1) .. " ------------------------------------")
	api.preStep() 
	vns.preStep(vns)

	bt()

	logger("cameras")
	for arm, camera in pairs(robot.cameras_system) do
		logger(camera.tags)
	end
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	logger("wifi")
	logger(robot.radios.wifi.recv)

	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		connector = true,
	})
end

function destroy()
	api.destroy()
end

function create_reaction_node(vns)
return function()
	if vns.parentR == nil then
		vns.Driver.move(vector3(), vector3(0,0,0.1))
	end

	for idS, childR in pairs(vns.childrenRT) do
		childR.goal = {
			positionV3 = vector3(-0.5, 0, 0),
			orientationQ = quaternion(),
		}
	end

	return false, true
end
end