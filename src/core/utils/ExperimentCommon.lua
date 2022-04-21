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

ExperimentCommon.detectWallFromReceives = function(vns, wall_brick_type)
	--return the nearest wall brick from vns.avoider.obstacles
	local nearest = nil
	local dis = math.huge
	for i, ob in ipairs(vns.collectivesensor.receiveList) do
		if ob.type == wall_brick_type and
		   ob.positionV3:length() < dis then
			dis = ob.positionV3:length()
			nearest = ob
		end
	end
	
	return nearest
end

ExperimentCommon.detectAndReportGates = function(vns, gate_brick_type, max_gate_size, report_all)
	if vns.robotTypeS ~= "drone" then return {}, nil end

	-- add vns.avoider.obstacles and vns.collectivesensor.receiveList together
	local totalGateSideList = {}
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == gate_brick_type then
			totalGateSideList[#totalGateSideList + 1] = ob
		end
	end
	for i, ob in ipairs(vns.collectivesensor.receiveList) do
		if ob.type == gate_brick_type then
			totalGateSideList[#totalGateSideList + 1] = ob
		end
	end

	-- mark the gates from obstacles with gateV3
	--for i, ob in ipairs(vns.avoider.obstacles) do
	for i, ob in ipairs(totalGateSideList) do
		ob.gateDetection = {
			gateV3 = vector3(max_gate_size,0,0):rotate(ob.orientationQ)
		}
	end

	-- for each gate find the nearest opposite gate
	--for i, ob in ipairs(vns.avoider.obstacles) do if ob.gateV3 ~= nil and ob.paired == nil then
	for i, ob in ipairs(totalGateSideList) do if ob.gateDetection.paired == nil then
		-- find the nearest gate_brick towards my direction
		-- and then check if that gate_brick is towards me 
		--     because sometimes there may be conditions like 
		--                -> (missing one <-)   ->  <-
		local pair = nil
		--local dis = ob.gateV3:length()
		local dis = max_gate_size
		--for i, ob2 in ipairs(vns.avoider.obstacles) do if ob2.gateV3 ~= nil then
		for i, ob2 in ipairs(totalGateSideList) do if ob2.gateDetection.paired == nil then
			-- if it is in my direction
			if ob.gateDetection.gateV3:dot(ob2.positionV3 - ob.positionV3) > 0 then
				-- if nearer
				if (ob2.positionV3 - ob.positionV3):length() < dis then
					pair = ob2
					dis = (ob2.positionV3 - ob.positionV3):length()
				end
			end
		end end
		-- if the nearest is opposite towards me, then we find an effect gate
		if pair ~= nil and 
		   pair.gateDetection.gateV3:dot(ob.gateDetection.gateV3) < 0 then
			ob.gateDetection.gateV3 = ob.gateDetection.gateV3:normalize() * dis
			pair.gateDetection.gateV3 = pair.gateDetection.gateV3:normalize() * dis
			pair.gateDetection.paired = true

			-- if report_all flag is set, report this gate brick anyway
			if report_all == true then
				vns.CollectiveSensor.addToSendList(vns, ob)
			end
		else
			-- unpaired wall side, I report it
			vns.CollectiveSensor.addToSendList(vns, ob)
			ob.gateDetection.single = true
		end
	end end

	-- generate a list of gates
	local gates = {}
	-- add gates from obstacles
	--for i, ob in ipairs(vns.avoider.obstacles) do if ob.gateV3 ~= nil and ob.paired == nil then
	for i, ob in ipairs(totalGateSideList) do if ob.gateDetection.single == nil and ob.gateDetection.paired == nil then
		local positionV3 = ob.positionV3 + ob.gateDetection.gateV3 * 0.5
		local orientationQ = ob.orientationQ * quaternion(math.pi/2, vector3(0,0,1))
		if vector3(1,0,0):rotate(orientationQ):dot(positionV3) < 0 then
			orientationQ = orientationQ * quaternion(math.pi, vector3(0,0,1))
		end
		local length = ob.gateDetection.gateV3:length()

		-- check if this gate already exists in receiveList
		local flag = true
		for i, existingGate in ipairs(vns.collectivesensor.receiveList) do if existingGate.type == "gate" then
			if (existingGate.positionV3 - positionV3):length() < (existingGate.length + length) / 2 then
				flag = false
				break
			end
		end end
		-- check if this gate already exists in gates
		for i, existingGate in ipairs(gates) do
			if (existingGate.positionV3 - positionV3):length() < (existingGate.length + length) / 2 then
				flag = false
				break
			end
		end

		if flag == true then
			gates[#gates+1] = {
				positionV3 = positionV3,
				orientationQ = orientationQ,
				length = length,
				type = "gate",
			}
		end
	end end

	-- find the largest gate
	local largest = nil
	local largest_length = 0
	for i, gate in ipairs(gates) do
		if gate.length > largest_length then
			largest = gate
			largest_length = gate.length
		end
	end

	for i, gate in ipairs(gates) do
		vns.api.debug.drawArrow("red", 
			vns.api.virtualFrame.V3_VtoR(vector3()),
			vns.api.virtualFrame.V3_VtoR(vector3(gate.positionV3))
		)
		vns.api.debug.drawArrow("red", 
			vns.api.virtualFrame.V3_VtoR(vector3(gate.positionV3)),
			vns.api.virtualFrame.V3_VtoR(vector3(gate.positionV3 + vector3(0.1,0,0):rotate(gate.orientationQ)))
		)
	end

	-- calculate gateNumber

	-- send gate list
	local gateNumber = #gates
	for i, gate in ipairs(gates) do
		vns.CollectiveSensor.addToSendList(vns, gate)
	end
	for i, ob in ipairs(vns.collectivesensor.receiveList) do if ob.type == "gate" then
		vns.CollectiveSensor.addToSendList(vns, ob)
	end end
	-- get and report gate number
	for idS, robotR in pairs(vns.childrenRT) do
		for _, msgM in ipairs(vns.Msg.getAM(idS, "gateReport")) do
			gateNumber = gateNumber + msgM.dataT.gateNumber
		end
	end
	if vns.parentR ~= nil then
		vns.Msg.send(vns.parentR.idS, "gateReport", {gateNumber = gateNumber})
	end

	return gates, largest, gateNumber
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
			if ob.type == wall_brick_type then
				vns.CollectiveSensor.addToSendList(vns, ob)
				break
			end
		end
	end
end

return ExperimentCommon