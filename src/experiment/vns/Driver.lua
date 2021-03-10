-- Driver -----------------------------------------
------------------------------------------------------
local Driver = {}

function Driver.create(vns)
	vns.goal = {
		positionV3 = nil,
		orientationQ = nil,
		transV3 = vector3(),
		rotateV3 = vector3(),
	}
end

function Driver.addChild(vns, robotR)
	-- each child has a goal position/orientation for destiny
	--            and a goal speed trans and rotate for obstacle avoidance
	robotR.goal = {
		positionV3 = robotR.positionV3,	
		orientationQ = robotR.orientationQ,
		transV3 = vector3(),
		rotateV3 = vector3(),
	}
end

function Driver.preStep(vns)
	vns.goal.positionV3 = nil
	vns.goal.orientationQ = nil
	vns.goal.transV3 = vector3()
	vns.goal.rotateV3 = vector3()

	for idS, childR in pairs(vns.childrenRT) do
		childR.goal.positionV3 = childR.positionV3
		childR.goal.orientationQ = childR.orientationQ
		childR.goal.transV3 = vector3()
		childR.goal.rotateV3 = vector3()
	end
end

function Driver.deleteParent(vns)
	vns.goal = {
		positionV3 = nil,
		orientationQ = nil,
		transV3 = vector3(),
		rotateV3 = vector3(),
	}
end

function Driver.step(vns, waiting)
	-- receive goal from parent
	local transV3 = vector3()
	local rotateV3 = vector3()
	local receive_drive_flag = false
	if vns.parentR ~= nil then
		for _, msgM in pairs(vns.Msg.getAM(vns.parentR.idS, "drive")) do
			receive_drive_flag = true
			local receivedPositionV3 = vns.parentR.positionV3 +
				vector3(msgM.dataT.positionV3):rotate(vns.parentR.orientationQ)
			local receivedOrientationQ = vns.parentR.orientationQ * msgM.dataT.orientationQ
			local receivedTransV3 = vector3(msgM.dataT.transV3):rotate(vns.parentR.orientationQ)
			local receivedRotateV3 = vector3(msgM.dataT.rotateV3):rotate(vns.parentR.orientationQ)

			if vns.goal.positionV3 ~= nil then receivedPositionV3 = vns.goal.positionV3 end
			if vns.goal.orientationQ ~= nil then receivedOrientationQ = vns.goal.orientationQ end

			-- calc speed
			-- the speed to go to goal point (received position)
			local goalPointTransV3, goalPointRotateV3

			local speed = 0.03
			local rotate_speed_scalar = 0.3
			local threshold = 0.35
			local reach_threshold = 0.01
			local dV3 = vector3(receivedPositionV3)
			dV3.z = 0
			local d = dV3:length()
			if d > threshold then 
				goalPointTransV3 = dV3:normalize() * speed
			elseif d < reach_threshold then
				goalPointTransV3 = vector3()
			else
				--goalPointTransV3 = dV3:normalize() * speed * math.sqrt(d / threshold)
				goalPointTransV3 = dV3:normalize() * speed * (d / threshold)
			end

			local rotateQ = receivedOrientationQ
			local angle, axis = rotateQ:toangleaxis()
			if angle ~= angle then angle = 0 end -- sometimes toangleaxis returns nan

			if angle > math.pi then angle = angle - math.pi * 2 end
			local goalPointRotateV3 = axis * angle * rotate_speed_scalar

			transV3 = goalPointTransV3 + receivedTransV3 + vns.goal.transV3
			rotateV3 = goalPointRotateV3 + receivedRotateV3 + vns.goal.rotateV3
		end
	end
	-- if no drive command received, respond only to goal.transV3 from avoider and spreader
	if receive_drive_flag == false then
		transV3 = transV3 + vns.goal.transV3
		rotateV3 = rotateV3 + vns.goal.rotateV3
	end

	if waiting == true then
		local safezone_half_pipuck = 0.9
		local safezone_half_drone = 1.35
		local safezone_half

		-- predict next point
		local predict_location = vns.api.time.period * transV3
		logger("predict location", predict_location)

		-- check parent
		if vns.parentR ~= nil then
			if vns.robotTypeS == "drone" and vns.parentR.robotTypeS == "drone" then
				safezone_half = safezone_half_drone
			else
				safezone_half = safezone_half_pipuck
			end

			local predict_distanceV3 = predict_location - vns.parentR.positionV3
			predict_distanceV3.z = 0
			local predict_distance = predict_distanceV3:length()
			local real_distanceV3 = vector3(vns.parentR.positionV3)
			real_distanceV3.z = 0
			local real_distance = real_distanceV3:length()
			if predict_distance > safezone_half and predict_distance > real_distance then
				logger("parent stop ", vns.parentR.idS)
				logger("safezone_half", safezone_half)
				logger("predict_distance ", predict_distance)
				logger("real_distance", real_distance)
				local new_predict_distanceV3 = predict_distanceV3 * (real_distance / predict_distance)
				local new_predict_location = vns.parentR.positionV3 + new_predict_distanceV3
				new_predict_location.z = 0
				transV3 = new_predict_location * (1/vns.api.time.period)
				logger("new_transV3", transV3)
			end
		end

		-- check children
		for idS, robotR in pairs(vns.childrenRT) do
			if vns.robotTypeS == "drone" and robotR.robotTypeS == "drone" then
				safezone_half = safezone_half_drone
			else
				safezone_half = safezone_half_pipuck
			end

			local predict_distanceV3 = predict_location - robotR.positionV3
			predict_distanceV3.z = 0
			local predict_distance = predict_distanceV3:length()
			local real_distanceV3 = vector3(robotR.positionV3)
			real_distanceV3.z = 0
			local real_distance = real_distanceV3:length()
			if predict_distance > safezone_half and predict_distance > real_distance then
				logger("child stop ", idS)
				logger("safezone_half", safezone_half)
				logger("predict_distance ", predict_distance)
				logger("real_distance", real_distance)
				transV3 = vector3()
			end
		end
	end

	Driver.move(transV3, rotateV3)

	-- send drive to children
	for _, robotR in pairs(vns.childrenRT) do
		if robotR.trajectory ~= nil then
			-- TODO trajectory
			child_transV3 = vector3()
			child_rotateV3 = vector3()
			child_positionV3 = vector3()
			child_orientationQ = quaternion()
		else 
			child_positionV3 = robotR.goal.positionV3
			child_orientationQ = robotR.goal.orientationQ
			child_transV3 = robotR.goal.transV3
			child_rotateV3 = robotR.goal.rotateV3
		end

		vns.Msg.send(robotR.idS, "drive",
		{
			transV3 = vns.api.virtualFrame.V3_VtoR(child_transV3),
			rotateV3 = vns.api.virtualFrame.V3_VtoR(child_rotateV3),
			positionV3 = vns.api.virtualFrame.V3_VtoR(child_positionV3),
			orientationQ = vns.api.virtualFrame.Q_VtoR(child_orientationQ),
		})
	end
end

function Driver.create_driver_node(vns)
	return function()
		Driver.step(vns)
		return false, true
	end
end

function Driver.create_driver_node_wait(vns)
	return function()
		Driver.step(vns, true)
		return false, true
	end
end

function Driver.move(transV3, rotateV3)
	print("VNS.Driver.move needs to be implemented")
end

return Driver
