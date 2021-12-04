logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns
local structure = require("01_morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()
end

function reset()
	vns.reset(vns)
	if robot.id == "pipuck1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))
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
		goal = true,
		positionV3 = true,
	})

	logger(" virtual orientationQ : X = ", vector3(1,0,0):rotate(vns.api.virtualFrame.orientationQ)) 
	logger("                        Y = ", vector3(0,1,0):rotate(vns.api.virtualFrame.orientationQ)) 
	logger("                        Z = ", vector3(0,0,1):rotate(vns.api.virtualFrame.orientationQ)) 

	signal_led(vns)
end

function destroy()
	api.destroy()
end

function signal_led(vns)
	if vns.parentR == nil then
		robot.leds.set_ring_leds(true)
	else
		vns.api.pipuckShowLED(vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3))
	end
end