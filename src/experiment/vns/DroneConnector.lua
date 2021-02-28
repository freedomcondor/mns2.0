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
	vns.api.droneAddSeenRobots(
		vns.api.droneDetectTags(),
		vns.connector.seenRobots
	)

	vns.api.droneAddObstacles(
		vns.api.droneDetectTags(),
		vns.avoider.obstacles
	)

	-- report my sight to all seen pipucks, and drones in parent and children
	--[[
	if vns.parentR ~= nil and vns.parentR.robotTypeS == "drone" then
		vns.Msg.send(vns.parentR.idS, "reportSight", {mySight = vns.connector.seenRobots})
	end

	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.robotTypeS == "drone" then
			vns.Msg.send(idS, "reportSight", {mySight = vns.connector.seenRobots})
		end
	end

	for idS, robotR in pairs(vns.connector.seenRobots) do
		vns.Msg.send(idS, "reportSight", {mySight = vns.connector.seenRobots})
	end
	--]]

	---[[
	-- broadcast my sight so other drones would see me
	vns.Msg.send("ALLMSG", "reportSight", {mySight = vns.connector.seenRobots, myObstacles = vns.avoider.obstacles})
	--]]

	-- for sight report, generate quadcopters
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadR(msgM.fromS, vns.connector.seenRobots, msgM.dataT.mySight)
	end

	-- convert vns.connector.seenRobots from real frame into virtual frame
	local seenRobotinR = vns.connector.seenRobots
	vns.connector.seenRobots = {}
	for idS, robotR in pairs(seenRobotinR) do
		vns.connector.seenRobots[idS] = {
			idS = idS,
			robotTypeS = robotR.robotTypeS,
			positionV3 = vns.api.virtualFrame.V3_RtoV(robotR.positionV3),
			orientationQ = vns.api.virtualFrame.Q_RtoV(robotR.orientationQ),
		}
	end

	-- convert vns.avoider.obstacles from real frame into virtual frame
	local obstaclesinR = vns.avoider.obstacles
	vns.avoider.obstacles = {}
	for i, v in ipairs(obstaclesinR) do
		vns.avoider.obstacles[i] = {
			idN = i,
			type = v.type,
			robotTypeS = v.robotTypeS,
			positionV3 = vns.api.virtualFrame.V3_RtoV(v.positionV3),
			orientationQ = vns.api.virtualFrame.Q_RtoV(v.orientationQ),
		}
	end
end

function DroneConnector.calcQuadR(idS, myVehiclesTR, yourVehiclesTR)
	local quadR = nil
	for _, robotR in pairs(yourVehiclesTR) do
		if myVehiclesTR[robotR.idS] ~= nil and
		   myVehiclesTR[robotR.idS].robotTypeS ~= "drone" then
			local myRobotR = myVehiclesTR[robotR.idS]
			local positionV3 = 
							myRobotR.positionV3 +
				             vector3(-robotR.positionV3):rotate(
							 	--robotR.orientationQ:inverse() * myRobotR.orientationQ
							 	myRobotR.orientationQ * robotR.orientationQ:inverse() 
							 )

			if positionV3:length() < 1.5 then
				quadR = {
					idS = idS,
					positionV3 = positionV3,
					--[[
					positionV3 = myRobotR.positionV3 +
					             vector3(-robotR.positionV3):rotate(
								 	--robotR.orientationQ:inverse() * myRobotR.orientationQ
								 	myRobotR.orientationQ * robotR.orientationQ:inverse() 
								 ),
					--]]
					--orientationQ = robotR.orientationQ:inverse() * myRobotR.orientationQ,
					orientationQ = myRobotR.orientationQ * robotR.orientationQ:inverse(),
					robotTypeS = "drone",
				}
				break
			end
		end
	end
	return quadR
end

function DroneConnector.create_droneconnector_node(vns)
	return function()
		vns.DroneConnector.step(vns)
		return false, true
	end
end

return DroneConnector
