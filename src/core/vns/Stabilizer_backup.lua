-- stabilizer -----------------------------------------
------------------------------------------------------
logger.register("Stabilizer")
local Stabilizer = {}

function Stabilizer.create(vns)
	vns.stabilizer = {
		allocator_signal = nil, -- for allocator
		-- how much should I move in this step
		step_offset = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		-- location of the goal based on the reference object
		reference_offset = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		reference = nil,
	}
end

function Stabilizer.reset(vns)
	vns.stabilizer = {
		allocator_signal = nil,
		step_offset = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		reference_offset = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		reference = nil,
	}
end

function Stabilizer.preStep(vns)
end

function Stabilizer.postStep(vns)
	-- estimate location of the new step 
	-- based on spreader.spreading_speed
	-- assuming this happens before avoider and after reaction_node
	local input_transV3 = vns.goal.transV3
	local input_rotateV3 = vns.goal.rotateV3
	--local input_transV3 = vns.spreader.spreading_speed.positionV3
	--local input_rotateV3 = vns.spreader.spreading_speed.orientationV3
	vns.stabilizer.step_offset.positionV3 = input_transV3 * vns.api.time.period
	local axis = vector3(input_rotateV3):normalize()
	if input_rotateV3:length() == 0 then axis = vector3(0,0,1) end
	vns.stabilizer.step_offset.orientationV3 = 
		quaternion(input_rotateV3:length() * vns.api.time.period, axis)

	--[[
	if vns.robotTypeS == "pipuck" and vns.parentR ~= nil then
		for _, msgM in pairs(vns.Msg.getAM(vns.parentR.idS, "you_are_a_reference")) do
			vns.Msg.send(vns.parentR.idS, "reference_estimated_location_report", 
			{
				positionV3 = vns.api.virtualFrame.V3_VtoR(vns.api.estimateLocation.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(vns.api.estimateLocation.orientationQ),
			})
		end
	end
	--]]
end

function Stabilizer.setGoal(vns, positionV3, orientationQ)
	if vns.stabilizer.reference ~= nil then
		vns.stabilizer.reference_offset.positionV3 = 
			(positionV3 - vns.stabilizer.reference.positionV3):rotate(
				vns.stabilizer.reference.orientationQ:inverse()
			)
		vns.stabilizer.reference_offset.orientationQ = vns.stabilizer.reference.orientationQ:inverse() *
													   orientationQ
	end
end

function Stabilizer.step(vns)
	if vns.parentR ~= nil then
		-- I'm not the brain
		vns.stabilizer.allocator_signal = nil
	else
		-- I'm the brain run stabilizer, and set vns.goal

		-- reverse calculation
		-- A.positionV3, A.orientationQ
		-- in A's eye, I'm at
		--   position:     (-A.positionV3):rotate(A.orientationQ:inverse())
		--   orientation:  A.orientationQ:inverse()

		--[[
			A.positionV3, A.orientationQ
			myVec in A's eye
				(myVec-A.positionV3):rotate(A.orientationQ:inverse())
			myQua in A's eye
				A.orientationQ:inverse() * myQua
		--]]
	

		-- find a reference
		local current_reference = Stabilizer.getNearestReference(vns)
		if current_reference == nil then 
			vns.stabilizer.allocator_signal = nil
			return 
		end
		-- if it is not the same one
		--     reset reference and reference_offset
		if vns.stabilizer.reference == nil or
		   (current_reference.positionV3 - vns.stabilizer.reference.positionV3):length() > 0.1 then --TODO set a parameter
			vns.stabilizer.reference_offset = {
				positionV3 = vector3(-current_reference.positionV3):rotate(current_reference.orientationQ:inverse()),
				orientationQ = current_reference.orientationQ:inverse(),
			}
		end
		vns.stabilizer.reference = current_reference

		-- if it is not stable
		--      ask and receive estimated location from it
		--      add it to reference_offset
		--[[
		if vns.stabilizer.reference.robotTypeS == "pipuck" then
			vns.Msg.send(vns.stabilizer.reference.idS, "you_are_a_reference")
			for _, msgM in pairs(vns.Msg.getAM(vns.stabilizer.reference.idS, "reference_estimated_location_report")) do
				--reference_offset in estimated location's eye
				vns.stabilizer.reference_offset.positionV3 = 
					vector3(vns.stabilizer.reference_offset.positionV3 - msgM.dataT.positionV3):rotate(
						msgM.dataT.orientationQ:inverse()
					)
				vns.stabilizer.reference_offset.orientationQ = 
					msgM.dataT.orientationQ:inverse() *
					vns.stabilizer.reference_offset.orientationQ
			end
		end
		--]]
		
		-- add goal into reference
		--[[
		vns.stabilizer.reference_offset.positionV3 = 
			vns.stabilizer.reference_offset.positionV3 + 
			vector3(vns.goal.positionV3):rotate(vns.stabilizer.reference_offset.orientationQ)
		vns.stabilizer.reference_offset.orientationQ = vns.stabilizer.reference_offset.orientationQ * 
		                                               vns.goal.orientationQ
		--]]

		--draw reference
		vns.api.debug.drawArrow("255,255,0,0", 
		    vns.api.virtualFrame.V3_VtoR(vns.stabilizer.reference.positionV3), 
		    vns.api.virtualFrame.V3_VtoR(
				vns.stabilizer.reference.positionV3 + vector3(vns.stabilizer.reference_offset.positionV3):rotate(
					vns.stabilizer.reference.orientationQ
				)
			)
		)

		vns.api.debug.drawArrow("255,255,0,0", 
		    vns.api.virtualFrame.V3_VtoR(
				vns.stabilizer.reference.positionV3 + vector3(vns.stabilizer.reference_offset.positionV3):rotate(
					vns.stabilizer.reference.orientationQ
				)
			),

		    vns.api.virtualFrame.V3_VtoR(
				vns.stabilizer.reference.positionV3 + vector3(vns.stabilizer.reference_offset.positionV3):rotate(
					vns.stabilizer.reference.orientationQ
				) 
				+ 
				vector3(0.2, 0, 0):rotate(vns.stabilizer.reference.orientationQ * vns.stabilizer.reference_offset.orientationQ)
			)
		)

		--[[
		-- estimate location of the new step 
		-- based on spreader.spreading_speed
		-- assuming this happens before avoider and after reaction_node
		vns.stabilizer.step_offset.positionV3 = vns.spreader.spreading_speed.positionV3 * vns.api.time.period
		local axis = vector3(vns.spreader.spreading_speed.orientationV3):normalize()
		if vns.spreader.spreading_speed.orientationV3:length() == 0 then axis = vector3(0,0,1) end
		vns.stabilizer.step_offset.orientationV3 = 
			quaternion(vns.spreader.spreading_speed.orientationV3:length() * vns.api.time.period, axis)
		--]]

		-- accumulate step_offset to reference_offset
		-- offset in reference obstacle's eye
		vns.stabilizer.reference_offset.positionV3 = 
			vns.stabilizer.reference_offset.positionV3 + 
			vector3(vns.stabilizer.step_offset.positionV3):rotate(vns.stabilizer.reference_offset.orientationQ)
		vns.stabilizer.reference_offset.orientationQ = vns.stabilizer.reference_offset.orientationQ * 
		                                               vns.stabilizer.step_offset.orientationQ

		-- accumulate reference_offset to goal
		vns.goal.positionV3 = vns.stabilizer.reference.positionV3 + 
		                      vector3(vns.stabilizer.reference_offset.positionV3):rotate(vns.stabilizer.reference.orientationQ)
		vns.goal.orientationQ = vns.stabilizer.reference.orientationQ * vns.stabilizer.reference_offset.orientationQ

		logger("stablizer reference: ")
		logger(vns.stabilizer.reference)
		logger("stablizer step: end step")
		logger("vns.goal.positionV3 = ", vns.goal.positionV3)
		logger("vns.goal.orientationQ X = ", vector3(1,0,0):rotate(vns.goal.orientationQ))
		logger("                      Y = ", vector3(0,1,0):rotate(vns.goal.orientationQ))
		logger("                      Z = ", vector3(0,0,1):rotate(vns.goal.orientationQ))
		-- tell allocator to use vns.goal for the brain
		vns.stabilizer.allocator_signal = true
	end
end

function Stabilizer.getNearestReference(vns)
	-- get nearest obstacle first
	-- if no obstacle in sight, get nearest pipuck
	local distance = math.huge
	local nearest = nil
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.positionV3:length() < distance then
			distance = obstacle.positionV3:length()
			nearest = obstacle
		end
	end
	--[[
	if nearest == nil then
		local distance = math.huge
		for idS, robotR in pairs(vns.connector.seenRobots) do
			if robotR.robotTypeS == "pipuck" and
			   robotR.positionV3:length() < distance then
				distance = robotR.positionV3:length()
				nearest = robotR 
			end
		end
	end
	--]]
	return nearest
end

------ behaviour tree ---------------------------------------
function Stabilizer.create_stabilizer_node(vns)
	return function()
		Stabilizer.step(vns)
		return false, true
	end
end

return Stabilizer
