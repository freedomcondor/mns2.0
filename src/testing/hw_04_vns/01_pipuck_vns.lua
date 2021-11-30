logger = require("Logger")
local api = require("pipuckAPI")
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
	vns = VNS.create("pipuck")
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

	--[[
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	logger("wifi")
	logger(robot.radios.wifi.recv)
	--]]
	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger("\t", idS)
	end

	vns.postStep(vns)
	api.postStep()

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		connector = true,
	})
	api.pipuckShowLED(api.virtualFrame.V3_VtoR(vector3(-1,0,0)))
end

function destroy()
	api.destroy()
end

function create_reaction_node(vns)
return function()
	if vns.parentR == nil then
		--vns.Driver.move(vector3(), vector3(0,0,0.01))
		robot.leds.set_ring_leds(true)
	else
		vns.api.pipuckShowLED(vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3))
	end

	for idS, childR in pairs(vns.childrenRT) do
		childR.goal = {
			positionV3 = vector3(-0.5, 0, 0),
			orientationQ = quaternion(),
		}
	end
end
end