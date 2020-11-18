-- Assigner -----------------------------------------
------------------------------------------------------
local Assigner = {}

--[[
--	related data
--	vns.assigner.targetS
--	vns.childrenRT.xxid.assignTargetS
--]]

function Assigner.create(vns)
	vns.assigner = {}
end

function Assigner.reset(vns)
	vns.assigner.targetS = nil
end

function Assigner.addParent(vns, robotR)
	robotR.scale_assign_offset = vns.ScaleManager.Scale:new()
	if vns.assigner.targetS == robotR.idS then
		vns.assigner.targetS = nil
	end
end

function Assigner.addChild(vns, robotR)
	robotR.scale_assign_offset = vns.ScaleManager.Scale:new()
	if vns.assigner.targetS == robotR.idS then
		vns.assigner.targetS = nil
	end
end

function Assigner.deleteParent(vns)
	vns.assigner.targetS = nil
	for idS, childR in pairs(vns.childrenRT) do
		if childR.assignTargetS == vns.parentR.idS then
			Assigner.assign(vns, idS, nil)
		end
	end
end

function Assigner.deleteChild(vns, deleting_idS)
	for idS, childR in pairs(vns.childrenRT) do
		if childR.assignTargetS == deleting_idS then
			Assigner.assign(vns, idS, nil)
		end
	end
end

function Assigner.preStep(vns)
	for idS, childR in pairs(vns.childrenRT) do
		childR.scale_assign_offset = vns.ScaleManager.Scale:new()
	end
	if vns.parentR ~= nil then
		vns.parentR.scale_assign_offset = vns.ScaleManager.Scale:new()
	end
end

function Assigner.assign(vns, childIdS, assignToIdS)
	local childR = vns.childrenRT[childIdS]
	if childR == nil then return end

	vns.Msg.send(childIdS, "assign", {assignToS = assignToIdS})
	childR.assignTargetS = assignToIdS

	--update rally point immediately
	--[[ goal point is not related to assign anymore
	if vns.childrenRT[assignToIdS] ~= nil then
		childR.goalPoint = {
			positionV3 = vns.childrenRT[assignToIdS].positionV3,
			orientationQ = quaternion()
		}
	elseif vns.parentR ~= nil and vns.parentR.idS == assignToIdS then
		childR.goalPoint = {
			positionV3 = vns.parentR.positionV3,
			orientationQ = quaternion()
		}
	end
	--]]
end

function Assigner.step(vns)
	-- listen to recruit from assigner.targetS
	for _, msgM in ipairs(vns.Msg.getAM(vns.assigner.targetS, "recruit")) do
		vns.Msg.send(msgM.fromS, "ack")

		-- sum up child scale
		local sumScale = vns.ScaleManager.Scale:new()
		-- add myself
		sumScale:inc(vns.robotTypeS)
		-- add children
		for idS, robotR in pairs(vns.childrenRT) do 
			sumScale = sumScale + robotR.scale
		end

		vns.Msg.send(msgM.fromS, "assign_ack", {oldParent = vns.parentR.idS, scale = sumScale})
		if vns.parentR ~= nil and vns.parentR.idS ~= vns.assigner.targetS then
			vns.Msg.send(vns.parentR.idS, "assign_dismiss", {newParent = msgM.fromS, scale = sumScale})
			vns.deleteParent(vns)
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
			vns.addParent(vns, robotR)
			vns.assigner.targetS = nil
		end
		break
	end

	-- listen to assign
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "assign")) do
		if vns.childrenRT[msgM.dataT.assignToS] == nil and
		   vns.parentR.idS ~= msgM.dataT.assignToS then
			vns.assigner.targetS = msgM.dataT.assignToS
		end
	end end

	-- listen to assign_dismiss
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "assign_dismiss")) do
		if vns.childrenRT[msgM.fromS] ~= nil then
			local assignTargetS = vns.childrenRT[msgM.fromS].assignTargetS
			local assignTargetS = msgM.dataT.newParent
			if vns.childrenRT[assignTargetS] ~= nil then
				--vns.childrenRT[assignTargetS].scale_assign_offset:inc(vns.childrenRT[msgM.fromS].robotTypeS)
				vns.childrenRT[assignTargetS].scale_assign_offset = 
					vns.childrenRT[assignTargetS].scale_assign_offset + msgM.dataT.scale
				vns.childrenRT[assignTargetS].lastSendScale = nil
			elseif vns.parentR ~= nil and vns.parentR.idS == assignTargetS then
				--vns.parentR.scale_assign_offset:inc(vns.childrenRT[msgM.fromS].robotTypeS)
				vns.parentR.scale_assign_offset = 
					vns.parentR.scale_assign_offset + msgM.dataT.scale
				vns.parentR.lastSendScale = nil
			end
			vns.deleteChild(vns, msgM.fromS)
		end
	end

	-- listen to assign_dismiss
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "assign_ack")) do
		if vns.childrenRT[msgM.fromS] ~= nil then
			local assignFrom = msgM.dataT.oldParent
			if vns.childrenRT[assignFrom] ~= nil then
				--vns.childrenRT[assignFrom].scale_assign_offset:dec(vns.childrenRT[msgM.fromS].robotTypeS)
				vns.childrenRT[assignFrom].scale_assign_offset = 
					vns.childrenRT[assignFrom].scale_assign_offset - msgM.dataT.scale
				vns.childrenRT[assignFrom].lastSendScale = nil
			elseif vns.parentR ~= nil and vns.parentR.idS == assignFrom then
				--vns.parentR.scale_assign_offset:dec(vns.childrenRT[msgM.fromS].robotTypeS)
				vns.parentR.scale_assign_offset = 
					vns.parentR.scale_assign_offset - msgM.dataT.scale
				vns.parentR.lastSendScale = nil
			end
		end
	end
	-- update assigning goalPoint
	--[[ goal is not related anymore
	for idS, childR in pairs(vns.childrenRT) do
		if childR.assignTargetS ~= nil then
			if vns.childrenRT[childR.assignTargetS] ~= nil then
				childR.goalPoint = {
					positionV3 = vns.childrenRT[childR.assignTargetS].positionV3,
					orientationQ = quaternion()
				}
			elseif vns.parentR ~= nil and vns.parentR.idS == childR.assignTargetS then
				childR.goalPoint = {
					positionV3 = vns.parentR.positionV3,
					orientationQ = quaternion()
				}
			end

		end
	end
	--]]
end

------ behaviour tree ---------------------------------------
function Assigner.create_assigner_node(vns)
	return function()
		Assigner.step(vns)
		return false, true
	end
end

return Assigner
