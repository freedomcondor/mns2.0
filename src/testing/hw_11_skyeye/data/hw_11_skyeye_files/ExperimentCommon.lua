ExperimentCommon = {}

ExperimentCommon.detectWall = function(vns, wall_brick_type)
	--return the nearest wall brick from vns.avoider.obstacles
	local nearest = nil
	local dis = math.huge
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == wall_brick_type and
		   ob.positionV3:length() < dis then
			dis = ob.positionV3:length()
			nearest = ob
		end
	end

	return nearest
end

ExperimentCommon.detectGates = function(vns, gate_brick_type, max_gate_size)
	-- mark the gates from obstacles with gateV3
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == gate_brick_type then
			ob.gateV3 = vector3(max_gate_size,0,0):rotate(ob.orientationQ)
		end
	end

	-- for each gate find the nearest opposite gate
	for i, ob in ipairs(vns.avoider.obstacles) do if ob.gateV3 ~= nil and ob.paired == nil then
		-- find the nearest opposite gate_brick

		local pair = nil
		local dis = ob.gateV3:length()
		for i, ob2 in ipairs(vns.avoider.obstacles) do if ob2.gateV3 ~= nil then
			-- if opposite
			if ob.gateV3:dot(ob2.gateV3) < 0 then
				-- if nearer
				if (ob2.positionV3 - ob.positionV3):length() < dis then
					pair = ob2
					dis = (ob2.positionV3 - ob.positionV3):length()
				end
			end
		end end
		ob.gateV3 = ob.gateV3:normalize() * dis
		if pair ~= nil then
			pair.gateV3 = pair.gateV3:normalize() * dis
			pair.paired = true
		end
	end end

	-- generate a list of gates
	local gates = {}
	local largest = nil
	local largest_length = 0
	for i, ob in ipairs(vns.avoider.obstacles) do if ob.gateV3 ~= nil and ob.paired == nil then
		local positionV3 = ob.positionV3 + ob.gateV3 * 0.5
		local orientationQ = ob.orientationQ * quaternion(math.pi/2, vector3(0,0,1))
		if vector3(1,0,0):rotate(orientationQ):dot(positionV3) < 0 then
			orientationQ = orientationQ * quaternion(math.pi, vector3(0,0,1))
		end
		local length = ob.gateV3:length()
		gates[#gates+1] = {
			positionV3 = positionV3,
			orientationQ = orientationQ,
			length = length,
		}

		if length > largest_length then
			largest = gates[#gates]
			largest_length = length
		end
	end end

	for i, gate in ipairs(gates) do
		vns.api.debug.drawArrow("red", 
			vns.api.virtualFrame.V3_VtoR(vector3(gate.positionV3)),
			vns.api.virtualFrame.V3_VtoR(vector3(gate.positionV3 + vector3(0.1,0,0):rotate(gate.orientationQ)))
		)
	end

	return gates, largest
end

ExperimentCommon.detectTarget = function(vns, target_type)
	--return the nearest target vns.avoider.obstacles
	local nearest = nil
	local dis = math.huge
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == target_type and
		   ob.positionV3:length() < dis then
			dis = ob.positionV3:length()
			nearest = ob
		end
	end

	return nearest
end

--     from vns.collectivesensor.receiveList, or what I see to vns.collectivesensor.sendList
ExperimentCommon.reportWall = function(vns, wall_brick_type)
	local wall_brick 
	if vns.robotTypeS == "drone" then
		wall_brick = ExperimentCommon.detectWall(vns, wall_brick_type)
	end
	if wall_brick ~= nil then
		-- I see a wall, I report it
		vns.CollectiveSensor.addToSendList(vns, wall_brick)
	else
		-- I see nothing, I report one of what I received
		for i, ob in pairs(vns.collectivesensor.receiveList) do
			vns.CollectiveSensor.addToSendList(vns, ob)
			break
		end
	end
end

return ExperimentCommon