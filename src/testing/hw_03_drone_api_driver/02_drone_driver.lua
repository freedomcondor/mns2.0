logger = require("Logger")
api = require("droneAPI")
VNS = require("VNS")
BT = require("BehaviorTree")
logger.enable()

local vns
local bt

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

function reset()
	vns.reset(vns)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		--create_simple_prereaction_node(vns),
		create_reaction_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end


function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount) .. " ------------------------------------")
	api.preStep() 
	vns:preStep()

	bt()

	vns.debug.logVNSInfo(vns, {
		goal = true,
	})

	vns:postStep()
	api.droneMaintainHeight(1.5)
	api.postStep()
end

function destroy()
	api.destroy()
end

------------------------
function create_simple_prereaction_node(vns)
return function()
	-- add tags into seen Robots
	vns.api.droneAddSeenRobots(
		vns.api.droneDetectTags(),
		vns.connector.seenRobots
	)
end
end

function create_reaction_node()
	local target = vector3()
	local lostCount = 0

return function()
	logger("seenRobots")
	logger(vns.connector.seenRobots)
	logger("lostCount = ", lostCount)

	-- set target based on seenRobots
	-- reset target to vector3() if lost robot for too long
	local reference_robot = vns.connector.seenRobots["pipuck3"]
	if reference_robot ~= nil then
		robot.leds.set_leds(200,200,200)
		target = reference_robot.positionV3 + vector3(0.5, 0, 0):rotate(reference_robot.orientationQ)
		vns.goal.positionV3 = target
		lostCount = 0
	else
		robot.leds.set_leds(0,0,0)
		lostCount = lostCount + 1
		if lostCount >= 10 then
			target = vector3()
			lostCount = 10
		end
	end
	--vns.goal.positionV3 = vector3(0.5, 0, 0)

	return false, true
end
end