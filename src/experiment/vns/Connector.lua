-- connector -----------------------------------------
------------------------------------------------------
local Connector = {}

--[[
	related data:
	vns.connector.waitingRobots = {}
	vns.connector.seenRobots
--]]

function Connector.create(vns)
	vns.connector = {}
	Connector.reset(vns)
end

function Connector.reset(vns)
	vns.connector.waitingRobots = {}
	vns.connector.waitingParents = {}
	vns.connector.seenRobots = {}
	vns.connector.locker_count = 3
	vns.connector.lastid = {}
end

function Connector.preStep(vns)
	vns.connector.seenRobots = {}
end

function Connector.recruit(vns, robotR)
	vns.Msg.send(robotR.idS, "recruit", {	
		positionV3 = vns.api.virtualFrame.V3_VtoR(robotR.positionV3),
		orientationQ = vns.api.virtualFrame.Q_VtoR(robotR.orientationQ),
		fromTypeS = vns.robotTypeS,
		idS = vns.idS,
		idN = vns.idN,
	}) 

	vns.connector.waitingRobots[robotR.idS] = {
		idS = robotR.idS,
		positionV3 = robotR.positionV3,
		orientationQ = robotR.orientationQ,
		robotTypeS = robotR.robotTypeS,
	}

	vns.connector.waitingRobots[robotR.idS].waiting_count = 3
end

function Connector.newVnsID(vns, idN, lastidPeriod)
	local _idS = vns.Msg.myIDS()
	local _idN = idN or robot.random.uniform()
	Connector.updateVnsID(vns, _idS, _idN, lastidPeriod)
end

function Connector.updateVnsID(vns, _idS, _idN, lastidPeriod)
	--vns.connector.lastid[vns.idS] = lastidPeriod or (vns.scale:totalNumber() + 2)
	vns.connector.lastid[vns.idS] = lastidPeriod or (vns.depth + 2)
	vns.connector.locker_count = vns.depth + 2

	vns.idS = _idS
	vns.idN = _idN
	local childrenScale = vns.ScaleManager.Scale:new()
	for idS, childR in pairs(vns.childrenRT) do
		childrenScale = childrenScale + childR.scale
		vns.Msg.send(idS, "updateVnsID", {idS = _idS, idN = _idN, lastidPeriod = lastidPeriod})
	end
	for idS, childR in pairs(vns.connector.waitingRobots) do
		childrenScale = childrenScale + childR.scale
		vns.Msg.send(idS, "updateVnsID", {idS = _idS, idN = _idN, lastidPeriod = lastidPeriod})
	end
end

function Connector.addChild(vns, robotR)
	vns.childrenRT[robotR.idS] = robotR
	vns.childrenRT[robotR.idS].unseen_count = 3
	vns.childrenRT[robotR.idS].heartbeat_count = 3
end

function Connector.addParent(vns, robotR)
	vns.parentR = robotR
	vns.parentR.unseen_count = 3
	vns.parentR.heartbeat_count = 5
end

function Connector.deleteChild(vns, idS)
	vns.connector.waitingRobots[idS] = nil
	vns.childrenRT[idS] = nil
end

function Connector.deleteParent(vns)
	if vns.parentR == nil then return end
	vns.parentR = nil
end

function Connector.update(vns)
	-- updated count
	for idS, robotR in pairs(vns.childrenRT) do
		robotR.unseen_count = robotR.unseen_count - 1
		robotR.heartbeat_count = robotR.heartbeat_count - 1
	end
	if vns.parentR ~= nil then
		vns.parentR.unseen_count = vns.parentR.unseen_count - 1
		vns.parentR.heartbeat_count = vns.parentR.heartbeat_count - 1
	end
	
	-- update waiting list
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if vns.connector.waitingRobots[idS] ~= nil then
			vns.connector.waitingRobots[idS].positionV3 = robotR.positionV3
			vns.connector.waitingRobots[idS].orientationQ = robotR.orientationQ
		end
	end

	-- update vns childrenRT list
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if vns.childrenRT[idS] ~= nil then
			vns.childrenRT[idS].positionV3 = robotR.positionV3
			vns.childrenRT[idS].orientationQ = robotR.orientationQ
			vns.childrenRT[idS].unseen_count = 3
		end
	end

	-- update parent
	if vns.parentR ~= nil and vns.connector.seenRobots[vns.parentR.idS] ~= nil then
		vns.parentR.positionV3 = vns.connector.seenRobots[vns.parentR.idS].positionV3
		vns.parentR.orientationQ = vns.connector.seenRobots[vns.parentR.idS].orientationQ
		vns.parentR.unseen_count = 3
	end

	-- check heartbeat
	for idS, robotR in pairs(vns.childrenRT) do
		for _, msgM in ipairs(vns.Msg.getAM(idS, "heartbeat")) do
			robotR.heartbeat_count = 3
		end
	end
	if vns.parentR ~= nil then
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "heartbeat")) do
			vns.parentR.heartbeat_count = 3
		end
	end

	-- check updated
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.unseen_count == 0 or robotR.heartbeat_count == 0 then
			vns.Msg.send(idS, "dismiss")
			vns.deleteChild(vns, idS)
		end
	end
	if vns.parentR ~= nil and (vns.parentR.unseen_count == 0 or vns.parentR.heartbeat_count == 0) then
		vns.Msg.send(vns.parentR.idS, "dismiss")
		Connector.newVnsID(vns)
		vns.deleteParent(vns)
		vns.resetMorphology(vns)
	end

	-- check locker
	if vns.connector.locker_count > 0 then
		vns.connector.locker_count = vns.connector.locker_count - 1
	end

	-- check last id
	for idS, lastid in pairs(vns.connector.lastid) do
		if vns.connector.lastid[idS] > 0 then
			vns.connector.lastid[idS] = vns.connector.lastid[idS] - 1
		elseif vns.connector.lastid[idS] == 0 then
			vns.connector.lastid[idS] = nil
		end
	end
end

function Connector.waitingCount(vns)
	for idS, robotR in pairs(vns.connector.waitingRobots) do
		robotR.waiting_count = robotR.waiting_count - 1
		if robotR.waiting_count == 0 then
			vns.connector.waitingRobots[idS] = nil
		end
	end
	for idS, robotR in pairs(vns.connector.waitingParents) do
		robotR.waiting_count = robotR.waiting_count - 1
		if robotR.waiting_count == 0 then
			vns.connector.waitingParents[idS] = nil
		end
	end
end

function Connector.step(vns)
	Connector.update(vns)
	Connector.waitingCount(vns)

	-- check ack
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "ack")) do
		if vns.connector.waitingRobots[msgM.fromS] ~= nil then
			vns.connector.waitingRobots[msgM.fromS].waiting_count = nil
			vns.addChild(vns, vns.connector.waitingRobots[msgM.fromS])
			vns.connector.waitingRobots[msgM.fromS] = nil
		end
	end

	-- check split
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "split")) do
		if vns.parentR ~= nil and msgM.fromS == vns.parentR.idS then
			Connector.newVnsID(vns, msgM.dataT.newID, msgM.dataT.waitTick or 100)
			vns.deleteParent(vns)
			if type(msgM.dataT.morphology) == "number" then
				vns.setMorphology(vns, vns.allocator.gene_index[msgM.dataT.morphology])
			elseif type(msgM.dataT.morphology) == "table" then
				vns.setGene(vns, msgM.dataT.morphology)
				-- TODO: its children don't know this gene
			end
		end
	end

	-- check dismiss
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "dismiss")) do
		if vns.parentR ~= nil and msgM.fromS == vns.parentR.idS then
			Connector.newVnsID(vns, msgM.dataT and msgM.dataT.newID)  -- if dataT is nil then nil
			vns.deleteParent(vns)
			vns.resetMorphology(vns)
		end
		if vns.childrenRT[msgM.fromS] ~= nil then
			vns.deleteChild(vns, msgM.fromS)
		end
	end

	-- check updateVnsID
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "updateVnsID")) do
		if vns.parentR ~= nil and msgM.fromS == vns.parentR.idS then
			Connector.updateVnsID(vns, msgM.dataT.idS, msgM.dataT.idN, msgM.dataT.lastidPeriod)
		end
	end

	-- send heartbeat
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "heartbeat")
	end
	if vns.parentR ~= nil then
		vns.Msg.send(vns.parentR.idS, "heartbeat")
	end
end

function Connector.recruitAll(vns)
	-- recruit new
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if vns.childrenRT[idS] == nil and 
		   vns.connector.waitingRobots[idS] == nil and 
		   (vns.parentR == nil or vns.parentR.idS ~= idS) then
			local safezone
			if vns.robotTypeS == "drone" and robotR.robotTypeS == "drone" then
				safezone = vns.Parameters.safezone_drone_drone
			elseif vns.robotTypeS == "drone" and robotR.robotTypeS == "pipuck" then
				safezone = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and robotR.robotTypeS == "drone" then
				safezone = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and robotR.robotTypeS == "pipuck" then
				safezone = vns.Parameters.safezone_pipuck_pipuck
			end
			local position2D = vector3(robotR.positionV3)
			position2D.z = 0
			if position2D:length() < safezone then
				Connector.recruit(vns, robotR)
			end
		end
	end
end

function Connector.recruitNear(vns)
	-- create a available robot list
	local list = {}
	for idS, robotR in pairs(vns.connector.seenRobots) do
		-- if a foreign robot (not parent, not children, note:waiting robots counts in)
		if vns.childrenRT[idS] == nil and 
		   --vns.connector.waitingRobots[idS] == nil and 
		   (vns.parentR == nil or vns.parentR.idS ~= idS) then
			-- choose safezone according to robot type
			local safezone
			if vns.robotTypeS == "drone" and robotR.robotTypeS == "drone" then
				safezone = vns.Parameters.safezone_drone_drone
			elseif vns.robotTypeS == "drone" and robotR.robotTypeS == "pipuck" then
				safezone = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and robotR.robotTypeS == "drone" then
				safezone = vns.Parameters.safezone_drone_pipuck
			elseif vns.robotTypeS == "pipuck" and robotR.robotTypeS == "pipuck" then
				safezone = vns.Parameters.safezone_pipuck_pipuck
			end
			-- calculate 2D length
			local position2D = vector3(robotR.positionV3)
			position2D.z = 0
			if position2D:length() < safezone then
				list[#list + 1] = {
					idS = idS,
					position2D = position2D,
					robotTypeS = robotR.robotTypeS,
				}
			end
		end
	end
	-- check list, recruit all that doesn't have a nearer one
	for i, robotR in ipairs(list) do
		local flag = true
		for j, blocker in ipairs(list) do
			if i ~= j and 
			   blocker.position2D:length() < robotR.position2D:length() and
			   (blocker.position2D-robotR.position2D):length() < robotR.position2D:length() then
			   --blocker.position2D:dot(robotR.position2D) > 0 then
				flag = false
				break
			end
		end
		if flag == true and 
		   vns.connector.waitingRobots[robotR.idS] == nil then
			Connector.recruit(vns, vns.connector.seenRobots[robotR.idS])
		end
	end
end

function Connector.ackAll(vns, option)
	-- check acks, ack the nearest valid recruit
	for _, msgM in pairs(vns.Msg.getAM("ALLMSG", "recruit")) do
		-- check
		-- if id == my vns id then pass unconditionally
		-- else, if it is from changing id, then ack
		-- if not, then check if idN > my idN and my locker
		if (msgM.dataT.idS ~= vns.idS and
		    msgM.dataT.idN > vns.idN and
		    vns.connector.locker_count == 0 and
		    vns.connector.lastid[msgM.dataT.idS] == nil
		    and (option == nil or option.no_parent_ack ~= true or vns.parentR == nil)
		   )
		   or
		   msgM.fromS == vns.connector.greenLight
		   --(vns.parentR == nil or
			--vns.connector.lastid[msgM.dataT.idS] == nil
		   --) 
		   then
			if vns.connector.waitingParents[msgM.fromS] ~= nil then
				if vns.connector.waitingParents[msgM.fromS].nearest == true then
					-- send ack
					vns.Msg.send(msgM.fromS, "ack")
					-- create robotR
					local robotR = {
						idS = msgM.fromS,
						positionV3 = 
						vns.api.virtualFrame.V3_RtoV(
							vector3(-msgM.dataT.positionV3):rotate(msgM.dataT.orientationQ:inverse())
						),
						orientationQ = 
							vns.api.virtualFrame.Q_RtoV(
								msgM.dataT.orientationQ:inverse()
							),
						robotTypeS = msgM.dataT.fromTypeS,
					}
					-- goodbye to old parent
					if vns.parentR ~= nil and vns.parentR ~= msgM.fromS then
						vns.Msg.send(vns.parentR.idS, "dismiss")
						vns.deleteParent(vns)
					end
					-- update vns id
					--vns.idS = msgM.dataT.idS
					--vns.idN = msgM.dataT.idN
					Connector.updateVnsID(vns, msgM.dataT.idS, msgM.dataT.idN)
					vns.addParent(vns, robotR)
				else
					vns.connector.waitingParents[msgM.fromS].waiting_count = 5
				end
			else
				local positionV2 = msgM.dataT.positionV3
				positionV2.z = 0
				vns.connector.waitingParents[msgM.fromS] = {
					waiting_count = 5,
					distance = positionV2:length(),
					idS = msgM.fromS,
				}
			end
		else
			if vns.connector.waitingParents[msgM.fromS] ~= nil then
				vns.connector.waitingParents[msgM.fromS] = nil
			end
		end
	end

	local MinDis = math.huge
	local MinId = nil
	-- mark the nearest waiting parents
	for idS, parent in pairs(vns.connector.waitingParents) do
		if parent.distance < MinDis then
			MinDis = parent.distance
			MinId = idS
		end
	end
	-- old grand parent has priority
	if vns.parentR == nil and
	   vns.brainkeeper.grandParentID ~= nil and
	   vns.connector.waitingParents[vns.brainkeeper.grandParentID] ~= nil then
		MinId = vns.brainkeeper.grandParentID
	end
	for idS, parent in pairs(vns.connector.waitingParents) do
		if idS == MinId then
			parent.nearest = true
		else
			parent.nearest = nil
		end
	end
end

------ behaviour tree ---------------------------------------
function Connector.create_connector_node_no_parent_ack(vns)
	return function()
		Connector.step(vns)
		Connector.ackAll(vns, {no_parent_ack = true})
		Connector.recruitAll(vns)
		--Connector.recruitNear(vns)
		return false, true
	end
end

function Connector.create_connector_node(vns)
	return function()
		Connector.step(vns)
		Connector.ackAll(vns)
		Connector.recruitAll(vns)
		--Connector.recruitNear(vns)
		return false, true
	end
end

function Connector.create_connector_node_no_recruit(vns)
	return function()
		Connector.step(vns)
		Connector.ackAll(vns)
		--Connector.recruitAll(vns)
		return false, true
	end
end

return Connector
