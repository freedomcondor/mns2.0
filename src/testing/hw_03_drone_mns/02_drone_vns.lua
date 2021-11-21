logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
local vns

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
		vns.Connector.create_connector_node(vns),
	}}
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount) .. " ------------------------------------")
	api.preStep() 
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		goal = true,
		target = true,
		assigner = true,
		allocator = true,
	})
end

function destroy()
	api.destroy()
end