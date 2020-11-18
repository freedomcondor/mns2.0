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
	vns.connector.seenRobots = {}
	vns.connector.locker_count = 3
	vns.connector.lastid = {}
end

function Connector.prestep(vns)
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

function Connector.newVnsID(vns)
	local _idS = vns.Msg.myIDS()
	local _idN = robot.random.uniform()
	Connector.updateVnsID(vns, _idS, _idN)
end

function Connector.updateVnsID(vns, _idS, _idN)
	vns.connector.lastid[vns.idS] = vns.scale:totalNumber() + 2
	vns.idS = _idS
	vns.idN = _idN
	local childrenScale = vns.ScaleManager.Scale:new()
	for idS, childR in pairs(vns.childrenRT) do
		childrenScale = childrenScale + childR.scale
		vns.Msg.send(idS, "updateVnsID", {idS = _idS, idN = _idN})
	end
	for idS, childR in pairs(vns.connector.waitingRobots) do
		childrenScale = childrenScale + childR.scale
		vns.Msg.send(idS, "updateVnsID", {idS = _idS, idN = _idN})
	end
	vns.connector.locker_count = childrenScale:totalNumber() + 2
end

function Connector.addChild(vns, robotR)
	vns.childrenRT[robotR.idS] = robotR
	vns.childrenRT[robotR.idS].unseen_count = 3
end

function Connector.addParent(vns, robotR)
	vns.parentR = robotR
	vns.parentR.unseen_count = 3
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
	end
	if vns.parentR ~= nil then
		vns.parentR.unseen_count = vns.parentR.unseen_count - 1
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

	-- check updated
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.unseen_count == 0 then
			vns.Msg.send(idS, "dismiss")
			vns.deleteChild(vns, idS)
		end
	end
	if vns.parentR ~= nil and vns.parentR.unseen_count == 0 then
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

	-- check dismiss
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "dismiss")) do
		if vns.parentR ~= nil and msgM.fromS == vns.parentR.idS then
			Connector.newVnsID(vns)
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
			Connector.updateVnsID(vns, msgM.dataT.idS, msgM.dataT.idN)
		end
	end
end

function Connector.recruitAll(vns)
	-- recruit new
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if vns.childrenRT[idS] == nil and 
		   vns.connector.waitingRobots[idS] == nil and 
		   (vns.parentR == nil or vns.parentR.idS ~= idS) then
			Connector.recruit(vns, robotR)
		end
	end
end

function Connector.ackAll(vns)
	-- check acks, ack the nearest valid recruit
	local MinDis = math.huge
	local MinMsg = nil
	for _, msgM in pairs(vns.Msg.getAM("ALLMSG", "recruit")) do
		-- check
		-- if id == my vns id then pass unconditionally
		-- else, if it is from changing id, then ack
		-- if not, then check if idN > my idN and my locker
		if msgM.dataT.idS ~= vns.idS and
		   msgM.dataT.idN > vns.idN and
		   vns.connector.locker_count == 0 and
		   (vns.parentR == nil or
			vns.connector.lastid[msgM.dataT.idS] == nil
		   ) then
			local disVec = 
					vns.api.virtualFrame.V3_RtoV(
						vector3(-msgM.dataT.positionV3):rotate(msgM.dataT.orientationQ:inverse())
					)
			disVec.z = 0
			local dis = disVec:length()
			if dis < MinDis then 
				MinDis = dis
				MinMsg = msgM
			end
		end
	end

	-- ack according to the nearest message
	if MinMsg ~= nil then
		local msgM = MinMsg
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
	end
end

------ behaviour tree ---------------------------------------
function Connector.create_connector_node(vns)
	return function()
		Connector.step(vns)
		Connector.ackAll(vns)
		Connector.recruitAll(vns)
		return false, true
	end
end

return Connector
