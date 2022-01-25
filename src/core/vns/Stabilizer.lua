-- stabilizer -----------------------------------------
------------------------------------------------------
logger.register("Stabilizer")
local Transform = require("Transform")

local Stabilizer = {}

function Stabilizer.create(vns)
end

function Stabilizer.reset(vns)
end

function Stabilizer.preStep(vns)
end

function Stabilizer.addParent(vns)
	for i, ob in ipairs(vns.avoider.obstacles) do
		ob.stabilizer = nil
	end
end
function Stabilizer.addParent(vns)
	for i, ob in ipairs(vns.avoider.obstacles) do
		ob.stabilizer = nil
	end
end

function Stabilizer.postStep(vns)
	-- estimate location of the new step 
	-- based on spreader.spreading_speed
	-- assuming this happens before avoider and after reaction_node
	local input_transV3 = vns.goal.transV3
	local input_rotateV3 = vns.goal.rotateV3
	--local input_transV3 = vns.spreader.spreading_speed.positionV3
	--local input_rotateV3 = vns.spreader.spreading_speed.orientationV3
	local newGoal = {}
	newGoal.positionV3 = input_transV3 * vns.api.time.period

	local axis = vector3(input_rotateV3):normalize()
	if input_rotateV3:length() == 0 then axis = vector3(0,0,1) end
	newGoal.orientationQ = 
		quaternion(input_rotateV3:length() * vns.api.time.period, axis)

	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil then
			-- I should be at newGoal, I see ob.stabilizer, I should see ob as X, newGoal x X = ob.stabilizer
			Transform.AxCisB(newGoal, ob.stabilizer, ob.stabilizer)
		end
	end
end

function Stabilizer.setGoal(vns, positionV3, orientationQ)
	local newGoal = {positionV3 = positionV3, orientationQ = orientationQ}
	for i, ob in ipairs(vns.avoider.obstacles) do
		-- I should be at newGoal, I see ob, this ob should be at my X, newGoal x X = ob
		ob.stabilizer = {}
		Transform.AxCisB(newGoal, ob, ob.stabilizer)
	end
end

function Stabilizer.step(vns)
	-- If I'm not the brain, don't do anything
	if vns.parentR ~= nil then return end
	-- If I'm a drone and I haven't take off, don't do anything
	if vns.robotTypeS == "drone" and vns.api.actuator.flight_preparation.state ~= "navigation" then return end

	-- I'm the brain run stabilizer, and set vns.goal
	-- for each obstacle with a stabilizer, average its offset as a new goal
	local offsetAcc = Transform.createAccumulator()

	local flag = false
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil and ob.unseen_count == vns.api.parameters.obstacle_unseen_count then
			flag = true
			-- add offset (choose the nearest)
			local offset = {positionV3 = vector3(), orientationQ = quaternion()}
			-- I see ob, I should see ob at ob.stabilizer, I should be at X, X x ob.stablizer = ob
			Transform.CxBisA(ob, ob.stabilizer, offset)
			-- add offset into offsetAcc
			Transform.addAccumulator(offsetAcc, offset)
			ob.stabilizer.offset = offset
		end
	end

	-- filter wrong case (sometimes obstacles are too close, they may be messed up with each other)
	-- check with average and subtrack from acc
	flag = false
	local averageOffset = Transform.averageAccumulator(offsetAcc)
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer ~= nil and ob.unseen_count == vns.api.parameters.obstacle_unseen_count then
			if (ob.stabilizer.offset.positionV3 - averageOffset.positionV3):length() > vns.api.parameters.obstacle_match_distance / 2 then
				Transform.subAccumulator(offsetAcc, ob.stabilizer.offset)
				ob.stabilizer = nil
			else
				flag = true
			end
			ob.offset = nil
		end
	end

	local offset = {positionV3 = vector3(), orientationQ = quaternion()}
	if flag == true then
		-- average offsetAcc into offset
		Transform.averageAccumulator(offsetAcc, offset)
		vns.goal.positionV3 = offset.positionV3
		vns.goal.orientationQ = offset.orientationQ
		vns.allocator.keepBrainGoal = true
	else
		-- offset = current goal
		offset.positionV3 = vns.goal.positionV3 
		offset.orientationQ = vns.goal.orientationQ 
	end

	-- for each new obstacle without a stabilizer, set a stabilizer
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.stabilizer == nil then
			-- I should be at offset, I see ob, this ob should be at my X, offset x X = ob
			ob.stabilizer = {}
			Transform.AxCisB(offset, ob, ob.stabilizer)
		end
	end

	---[[
	local color = "255,0,255,0"
	vns.api.debug.drawArrow(color, 
	                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
	                        vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 + vector3(0.1,0,0):rotate(vns.goal.orientationQ))
	                       )
	vns.api.debug.drawRing(color, 
	                       vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
	                       0.1
	                      )
	--]]
end

------ behaviour tree ---------------------------------------
function Stabilizer.create_stabilizer_node(vns)
	return function()
		Stabilizer.step(vns)
		return false, true
	end
end

return Stabilizer
