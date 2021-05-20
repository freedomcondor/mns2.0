--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]

local DroneConnector = {}

function DroneConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function DroneConnector.step(vns)
	-- add tags into seen Robots
	local seenRobots = {}
	vns.api.droneAddSeenRobots(
		vns.api.droneDetectTags(),
		seenRobots
	)

	-- report my sight to all seen pipucks, and drones in parent and children
	for idS, robotR in pairs(seenRobots) do
		vns.Msg.send(idS, "reportSight", {mySight = seenRobots})
	end
end

function DroneConnector.create_droneconnector_node(vns)
	return function()
		vns.DroneConnector.step(vns)
		return false, true
	end
end

return DroneConnector
