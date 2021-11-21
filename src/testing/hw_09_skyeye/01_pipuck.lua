logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

local structure = require("01_morphology")

function VNS.Allocator.calcBaseValue(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	base_target_V3.z = 0
	base_current_V3.z = 0
	local dot = base_current_V3:dot(base_target_V3:normalize())
	if dot < 0 then 
		return dot 
	else
		local x = dot
		local x2 = dot ^ 2
		local l = base_current_V3:length()
		local y2 = l ^ 2 - x2
		elliptic_distance2 = x2 + (1/4) * y2
		return elliptic_distance2
	end
end

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
	vns = VNS.create("pipuck")
	reset()
end

function reset()
	vns.reset(vns)

	if robot.id == "pipuck2" then vns.idN = 1 end

	vns.setGene(vns, structure)

	local option = nil
	--if robot.id ~= "pipuck1" then
	--	option = {connector_no_recruit = true}
	--end
	bt = BT.create
		{type = "sequence", children = {
			vns.create_preconnector_node(vns),
			vns.create_vns_core_node(vns, option),
			vns.Driver.create_driver_node(vns),
		}}
end

function step()
	-- prestep
	logger(robot.id, robot.system.time, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	--[[
	logger("seenRobots")
	for idS, robotR in pairs(vns.connector.seenRobots) do
		logger(idS)
		logger(robotR, 1)
		logger("\tX", vector3(1,0,0):rotate(robotR.orientationQ))
		logger("\tY", vector3(0,1,0):rotate(robotR.orientationQ))
		logger("\tZ", vector3(0,0,1):rotate(robotR.orientationQ))
	end
	--]]
	vns.debug.logInfo(vns)
	logger("wifi")
	logger(robot.wifi.rx_data)
	--[[
	logger("waiting")
	logger(vns.connector.waitingRobots)
	--]]

	---[[
	if vns.parentR ~= nil then
		api.pipuckShowLED(api.virtualFrame.V3_VtoR(vns.parentR.positionV3))
	else
		api.pipuckShowAllLEDs()
	end
	--]]
	--[[
	logger("vns")
	logger(vns)
	--]]
end

function destroy()
	api.destroy()
end