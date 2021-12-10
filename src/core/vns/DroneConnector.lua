--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]

require("DeepCopy")

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
		local myRobotRT = DeepCopy(vns.connector.seenRobots)
		--[[
		for idS, robotR in pairs(vns.childrenRT) do
			if myRobotRT[idS] == nil and robotR.robotTypeS == "pipuck" then 
				myRobotRT[idS] = {
					idS = idS,
					positionV3 = vns.api.virtualFrame.V3_VtoR(robotR.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(robotR.orientationQ),
				} 
			end
		end
		if vns.parentR ~= nil and vns.parentR.robotTypeS == "pipuck" and myRobotRT[vns.parentR.idS] == nil then
			myRobotRT[vns.parentR.idS] = {
				idS = vns.parentR.idS,
				positionV3 = vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ),
			}
		end
		--]]
		vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadR(msgM.fromS, myRobotRT, msgM.dataT.mySight)
		--vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadR(msgM.fromS, vns.connector.seenRobots, msgM.dataT.mySight)
		--vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadRHW(vns, msgM.fromS, msgM.dataT.mySight)
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
	local n = 0
	local totalPositionV3 = vector3()
	local totalOrientationQ = quaternion() 
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
			local orientationQ = myRobotR.orientationQ * robotR.orientationQ:inverse()

			totalPositionV3 = totalPositionV3 + positionV3
			totalOrientationQ = orientationQ -- TODO: find a better way to average quaternion

			n = n + 1
		end
	end
	if n >= 1 then
		local AverageOrientationQ = totalOrientationQ
		quadR = {
			idS = idS,
			positionV3 = totalPositionV3 * (1.0/n),
			orientationQ = AverageOrientationQ,
			robotTypeS = "drone",
		}
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
