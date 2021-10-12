--[[
--	Drone connector
--	the drone will always try to recruit seen pipucks
--]]

DeepCopy = require("DeepCopy")

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
	vns.Msg.send("ALLMSG", "reportSight", {mySight = DeepCopy(vns.connector.seenRobots), myObstacles = vns.avoider.obstacles})
	--]]

	-- for sight report, generate quadcopters
	-- add those who can see the a common robot with me
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		if vns.connector.seenRobots[msgM.fromS] == nil then
			vns.connector.seenRobots[msgM.fromS] = DroneConnector.calcQuadR(msgM.fromS, vns.connector.seenRobots, msgM.dataT.mySight)
		end
	end
	-- add those who can see me
	-- add also what they see
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "reportSight")) do
		if msgM.dataT.mySight[vns.Msg.myIDS()] ~= nil then
			-- I'm seen in this report sight, add this drone into seenRobots
			local common = msgM.dataT.mySight[vns.Msg.myIDS()]
			local quad = {
				idS = msgM.fromS,
				positionV3 =
					vector3(-common.positionV3):rotate(
					common.orientationQ:inverse()),
				orientationQ =
					common.orientationQ:inverse(),
				robotTypeS = "drone",
			}

			if vns.connector.seenRobots[quad.idS] == nil then --TODO average
				vns.connector.seenRobots[quad.idS] = quad
			end

			-- add other pipucks to seenRobots
			for idS, R in pairs(msgM.dataT.mySight) do
				if idS ~= vns.Msg.myIDS() and vns.connector.seenRobots[idS] == nil then
				--   R.robotTypeS ~= "drone" then -- TODO average
					vns.connector.seenRobots[idS] = {
						idS = idS,
						positionV3 = quad.positionV3 +
						             vector3(R.positionV3):rotate(quad.orientationQ),
						orientationQ = quad.orientationQ * R.orientationQ,
						robotTypeS = R.robotTypeS,
					}
				end
			end
		end
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
		if myVehiclesTR[robotR.idS] ~= nil then
		--   myVehiclesTR[robotR.idS].robotTypeS ~= "drone" then
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
