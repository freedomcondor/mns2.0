-- Driver -----------------------------------------
------------------------------------------------------
local Driver = {}
local Transform = require("Transform")

function Driver.create(vns)
	vns.goal = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
		transV3 = vector3(),
		rotateV3 = vector3(),
		--[[last = {
			transV3 = vector3(),
			rotateV3 = vector3(),
		}
		--]]
	}
end

function Driver.addChild(vns, robotR)
	-- childR.goal is optional, default nil
	-- only effective when mannualy set
	--[[
	robotR.goal = {
		positionV3 = robotR.positionV3,	
		orientationQ = robotR.orientationQ,
		--transV3 = vector3(),
		--rotateV3 = vector3(),
	}
	--]]
end

function Driver.preStep(vns)
	-- reverse Pos and Ori are old location relative to new location
	local inverseOri = quaternion(vns.api.estimateLocation.orientationQ):inverse()
	vns.goal.positionV3 = (vns.goal.positionV3 - vns.api.estimateLocation.positionV3):rotate(inverseOri)
	vns.goal.orientationQ = vns.goal.orientationQ * inverseOri
--	vns.goal.last.transV3 = vns.goal.transV3
--	vns.goal.last.rotateV3 = vns.goal.rotateV3
	vns.goal.transV3 = vector3()
	vns.goal.rotateV3 = vector3()
end

function Driver.deleteParent(vns)
	vns.goal.positionV3 = vector3()
	vns.goal.orientationQ = quaternion()
	vns.goal.transV3 = vector3()
	vns.goal.rotateV3 = vector3()
end

function Driver.setGoal(vns, positionV3, orientationQ)
	vns.goal.positionV3 = positionV3
	vns.goal.orientationQ = orientationQ
end

function Driver.step(vns, waiting)
	-- waiting is a flag, true or false or nil,
	--	   means whether robot stop moving when neighbour out of the safe zone

	-- receive goal from parent to overwrite vns.goal.position and orientation
	if vns.parentR ~= nil then
		for _, msgM in pairs(vns.Msg.getAM(vns.parentR.idS, "drive")) do
			vns.goal.positionV3 = vns.parentR.positionV3 +
				vector3(msgM.dataT.positionV3):rotate(vns.parentR.orientationQ)
			vns.goal.orientationQ = vns.parentR.orientationQ * msgM.dataT.orientationQ
		end
	end

	local color = "0,255,255,0"
	--[[
	vns.api.debug.drawArrow(color, 
	                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
	                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 + vector3(0.1,0,0):rotate(vns.goal.orientationQ))
	                       )
	vns.api.debug.drawRing(color, 
	                       vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
	                       0.05
	                      )
	--]]
	vns.api.debug.drawArrow(color,
	                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0)),
	                        vns.api.virtualFrame.V3_VtoR(vector3(vns.goal.positionV3 + vector3(0,0,0.1)))
	                       )
	--]]

	-- calculate transV3 and rotateV3 from goal.positionV3 and orientation
	local transV3 = vector3()
	local rotateV3 = vector3()

	-- read parameters
	local speed = vns.Parameters.driver_default_speed
	local threshold = vns.Parameters.driver_slowdown_zone
	local reach_threshold = vns.Parameters.driver_stop_zone
	local rotate_speed_scalar = vns.Parameters.driver_default_rotate_scalar

	-- calc transV3
	local dV3 = vector3(vns.goal.positionV3)
	--dV3.z = 0
	local d = dV3:length()
	if d > threshold then
		transV3 = dV3:normalize() * speed
	elseif d < reach_threshold then
		transV3 = vector3()
	else
		transV3 = dV3:normalize() * speed * (d / threshold)
	end

	-- calc rotateV3
	local angle, axis = vns.goal.orientationQ:toangleaxis()
	if angle ~= angle then angle = 0 end -- sometimes toangleaxis returns nan

	if angle > math.pi then angle = angle - math.pi * 2 end

	local rotateV3 = axis * angle * rotate_speed_scalar

	-- respond to goal.transV3 from avoider and spreader
	transV3 = transV3 + vns.goal.transV3
	rotateV3 = rotateV3 + vns.goal.rotateV3

	-- safezone check -- stop the robot if it is going to seperate with neighbours
	if waiting == true then
		local safezone_half

		-- predict next point
		local predict_location = vns.api.time.period * transV3

		-- check parent
		if vns.parentR ~= nil then
			if vns.robotTypeS == "drone" and vns.parentR.robotTypeS == "drone" then
				safezone_half = vns.Parameters.safezone_drone_drone
			elseif vns.robotTypeS == "drone" and vns.parentR.robotTypeS == "pipuck" or
			       vns.robotTypeS == "pipuck" and vns.parentR.robotTypeS == "drone" then
				safezone_half = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and vns.parentR.robotTypeS == "pipuck" then
				safezone_half = vns.Parameters.safezone_pipuck_pipuck
			end

			local predict_distanceV3 = predict_location - vns.parentR.positionV3
			predict_distanceV3.z = 0
			local predict_distance = predict_distanceV3:length()
			local real_distanceV3 = vector3(vns.parentR.positionV3)
			real_distanceV3.z = 0
			local real_distance = real_distanceV3:length()
			if predict_distance > safezone_half and predict_distance > real_distance then
				local new_predict_distanceV3 = predict_distanceV3 * (real_distance / predict_distance)
				local new_predict_location = vns.parentR.positionV3 + new_predict_distanceV3
				new_predict_location.z = 0
				transV3 = new_predict_location * (1/vns.api.time.period)
			end
		end

		-- TODO: not leave children too
		-- check children
		for idS, robotR in pairs(vns.childrenRT) do
			if vns.robotTypeS == "drone" and robotR.robotTypeS == "drone" then
				safezone_half = vns.Parameters.safezone_drone_drone
			elseif vns.robotTypeS == "drone" and robotR.robotTypeS == "pipuck" or
			       vns.robotTypeS == "pipuck" and robotR.robotTypeS == "drone" then
				safezone_half = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and robotR.robotTypeS == "pipuck" then
				safezone_half = vns.Parameters.safezone_pipuck_pipuck
			end

			local predict_distanceV3 = predict_location - robotR.positionV3
			predict_distanceV3.z = 0
			local predict_distance = predict_distanceV3:length()
			local real_distanceV3 = vector3(robotR.positionV3)
			real_distanceV3.z = 0
			local real_distance = real_distanceV3:length()
			if predict_distance > safezone_half and predict_distance > real_distance then
				transV3 = vector3()
				vns.goal.transV3 = vector3()

				vns.api.debug.drawArrow("255, 255, 0",
					vns.api.virtualFrame.V3_VtoR(vector3()),
					vns.api.virtualFrame.V3_VtoR(robotR.positionV3)
				)
			end
		end
	end

	Driver.move(transV3, rotateV3)

	-- send drive to children
	for _, childR in pairs(vns.childrenRT) do
		if childR.goal ~= nil then
			vns.Msg.send(childR.idS, "drive",
			{
				positionV3 = vns.api.virtualFrame.V3_VtoR(childR.goal.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(childR.goal.orientationQ),
			})
		end
	end
end

function Driver.adjustHeight(vns)
	-- estimate height
	local average_height = 0
	local average_count = 0
	for i, ob in ipairs(vns.avoider.obstacles) do
		-- obstacle see goal, obstacle x X = new goal
		local obSeeGoal = {}
		Transform.AxCisB(ob, vns.goal, obSeeGoal)
		average_height = average_height + obSeeGoal.positionV3.z
		average_count = average_count + 1
	end

	for idS, robot in pairs(vns.connector.seenRobots) do
		if robot.robotTypeS == "pipuck" then
			local robotSeeGoal = {}
			Transform.AxCisB(robot, vns.goal, robotSeeGoal)
			average_height = average_height + robotSeeGoal.positionV3.z
			average_count = average_count + 1
		end
	end

	if average_count ~= 0 then
		average_height = average_height / average_count
		local altitudeError = vns.api.parameters.droneDefaultHeight - average_height
		vns.setGoal(vns, vns.goal.positionV3 + vector3(0,0,altitudeError):rotate(vns.goal.orientationQ), vns.goal.orientationQ)
	end

	-- signal api to lock z or not
	if vns.api.droneCheckHeightCountDown > 0 then return end
	if -0.1 < vns.goal.positionV3.z and vns.goal.positionV3.z < 0.1 then vns.api.droneCheckHeightCountDown = 150 end
end

function Driver.create_driver_node(vns, option)
	-- option = {
	--      waiting = true or false or nil
	-- }
	if option == nil then option = {} end
	return function()
		if vns.robotTypeS == "drone" then Driver.adjustHeight(vns) end
		Driver.step(vns, option.waiting)
		return false, true
	end
end

function Driver.move(transV3, rotateV3)
	print("VNS.Driver.move needs to be implemented")
end

return Driver
