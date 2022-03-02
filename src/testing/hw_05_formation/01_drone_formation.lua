logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.enableFileLog()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns
local structure = require("01_morphology")

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

function reset()
	vns.reset(vns)
	if robot.id == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount + 1) .. " ------------------------------------")
	api.preStep() 
	vns.preStep(vns)

	bt()

	--[[
	logger("cameras")
	for arm, camera in pairs(robot.cameras_system) do
		logger(camera.tags)
	end
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	logger("wifi")
	logger(robot.radios.wifi.recv)
	--]]
	--[[
	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger("\t", idS)
	end
	--]]

	vns.postStep(vns)
	api.droneMaintainHeight(1.8)
	api.postStep()

	vns.logLoopFunctionInfo(vns)
--[[
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
--]]
	signal_led_seenRobots(vns)
--[[
	logger("wifi")
	logger(robot.radios.wifi.recv)
--]]
end

function destroy()
	api.destroy()
end

function signal_led(vns)
	---[[
	if vns.parentR == nil then
		--vns.Driver.move(vector3(), vector3(0,0,0.1))
		robot.leds.set_leds(0,0,0)
	else
		robot.leds.set_leds("red")
	end
	--]]

	local count = 0
	for idS, childR in pairs(vns.childrenRT) do
		count = count + 1
		---[[
		if vns.parentR == nil then
			robot.leds.set_leds("blue")
		else
			robot.leds.set_leds("green")
		end
		--]]
	end

	if count == 2 and vns.parentR ~= nil then
		robot.leds.set_leds(200,200,200)
	end
end

function signal_led_seenRobots(vns)
	droneflag = false
	pipuckflag = false
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if robotR.robotTypeS == "drone" then
			droneflag = true
		end
		if robotR.robotTypeS == "pipuck" then
			pipuckflag = true
		end
	end
	if droneflag == true then
		robot.leds.set_leds("green")
	elseif pipuckflag == true then
		robot.leds.set_leds("blue")
	else
		robot.leds.set_leds(0,0,0)
	end
	--[[
	if vns.parentR == nil then
		--vns.Driver.move(vector3(), vector3(0,0,0.1))
		robot.leds.set_leds(0,0,0)
	else
		if vns.parentR.robotTypeS == "pipuck" then
			robot.leds.set_leds("blue")
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.robotTypeS == "drone" then
					robot.leds.set_leds("green")
				end
			end
		else
			robot.leds.set_leds("red")
		end
	end
	--]]
end