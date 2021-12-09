logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-------- read my id ---------------------------------------
function read_id()
	local f = io.open("/home/root/my_id.txt", "r")
	local id = f:read("l")
	return id
end

-------- argos step ---------------------------------------
function init()
	robot.id = read_id()

	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

function reset()
	vns.reset(vns)

	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
			--vns.Connector.create_connector_node(vns),
			--vns.Assigner.create_assigner_node(vns),
			--vns.ScaleManager.create_scalemanager_node(vns),
			--vns.BrainKeeper.create_brainkeeper_node(vns),
		}}
end

function step()
	-- prestep
	logger(robot.id, api.stepCount, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	---[[
	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger(idS)
		logger(robotR, 1)
		logger("\tX", vector3(1,0,0):rotate(robotR.orientationQ))
		logger("\tY", vector3(0,1,0):rotate(robotR.orientationQ))
		logger("\tZ", vector3(0,0,1):rotate(robotR.orientationQ))
	end
	--]]
	---[[
	for camera_id, camera in pairs(robot.cameras_system) do
		logger(camera_id)
		for i, newTag in ipairs(camera.tags) do
			logger("\t", i)
			logger(newTag, 3)
			logger("\t\t\tX", vector3(1,0,0):rotate(newTag.orientation))
			logger("\t\t\tY", vector3(0,1,0):rotate(newTag.orientation))
			logger("\t\t\tZ", vector3(0,0,1):rotate(newTag.orientation))
		end
	end
	--]]
end

function destroy()
	api.destroy()
end