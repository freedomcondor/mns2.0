--[[
--	Pipuck connector
--	the Pipuck listen to drone's recruit message, with deny
--]]

local PipuckConnector = {}

function PipuckConnector.preStep(vns)
	vns.connector.seenRobots = {}
end

function PipuckConnector.step(vns)
	-- For any sight report, update quadcopter and other pipucks to seenRobots
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
				if idS ~= vns.Msg.myIDS() and vns.connector.seenRobots[idS] == nil and 
				   R.robotTypeS ~= "drone" then -- TODO average
					vns.connector.seenRobots[idS] = {
						idS = idS,
						positionV3 = quad.positionV3 + 
						             vector3(R.positionV3):rotate(quad.orientationQ),
						--orientationQ = quad.orientationQ * R.orientationQ,
						orientationQ = R.orientationQ * quad.orientationQ,
						robotTypeS = R.robotTypeS,
					}
				end
			end

			-- add obstacles
			if msgM.dataT.myObstacles ~= nil then
				for i, obstacle in ipairs(msgM.dataT.myObstacles) do
					local positionV3 = quad.positionV3 + 
									   vector3(obstacle.positionV3):rotate(quad.orientationQ) +
									   vector3(0,0,0.08)
					local orientationQ = obstacle.orientationQ * quad.orientationQ

					-- check positionV3 in existing obstacles
					local flag = true
					for j, existing_ob in ipairs(vns.avoider.obstacles) do
						if (existing_ob.positionV3 - positionV3):length() < 0.02 then
							flag = false
							break
						end
					end

					if flag == true then
						vns.avoider.obstacles[#vns.avoider.obstacles + 1] = {
							idN = #vns.avoider.obstacles + 1,
							type = obstacle.type,
							robotTypeS = "block",
							positionV3 = positionV3,
							orientationQ = orientationQ,
						}
					end
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

function PipuckConnector.create_pipuckconnector_node(vns)
	return function()
		vns.PipuckConnector.step(vns)
		return false, true
	end
end

return PipuckConnector
