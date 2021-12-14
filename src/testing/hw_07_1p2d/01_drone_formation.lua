logger = require("Logger")
local api = require("droneAPI")
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
	vns = VNS.create("drone")
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
	logger("cameras")
	for arm, camera in pairs(robot.cameras_system) do
		logger(camera.tags)
	end
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	--]]
	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger("\t", idS)
	end

	vns.postStep(vns)
	api.droneMaintainHeight(1.8)
	api.postStep()
--[[
	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		connector = true,
		goal = true,
		positionV3 = true,
	})

--]]
	signal_led(vns)
end

function destroy()
	api.destroy()
end

function signal_led(vns)
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