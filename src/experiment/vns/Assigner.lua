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

function Assigner.deleteParent(vns)
	vns.assigner.targetS = nil
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
	-- check assignTo is valid
	if vns.parentR ~= nil and vns.assigner.targetS == vns.parentR.idS then
		vns.assigner.targetS = nil
	end
	for idS, childR in pairs(vns.childrenRT) do
		if childR.assignTargetS ~= nil then
			if vns.childrenRT[childR.assignTargetS] == nil and
			   (vns.parentR == nil or vns.parentR.idS ~= childR.assignTargetS) then
				Assigner.assign(vns, idS, nil)
			end
		end
	end

	-- listen to recruit from assigner.targetS
	for _, msgM in ipairs(vns.Msg.getAM(vns.assigner.targetS, "recruit")) do
		vns.Msg.send(msgM.fromS, "ack")
		if vns.parentR ~= nil and vns.parentR.idS ~= vns.assigner.targetS then
			vns.Msg.send(vns.parentR.idS, "assign_dismiss")
			vns.parentR = nil
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
		if vns.childrenRT[msgM.dataT.assignToS] == nil then
			vns.assigner.targetS = msgM.dataT.assignToS
		end
	end end

	-- listen to assign_dismiss
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "assign_dismiss")) do
		if vns.childrenRT[msgM.fromS] ~= nil then
			local assignTargetS = vns.childrenRT[msgM.fromS].assignTargetS
			if vns.childrenRT[assignTargetS] ~= nil then
				vns.childrenRT[assignTargetS].scale_assign_offset = vns.ScaleManager.Scale:new()
				vns.childrenRT[assignTargetS].scale_assign_offset[vns.childrenRT[msgM.fromS].robotTypeS] = 1	
			elseif vns.parentR ~= nil and vns.parentR.idS == assignTargetS then
				vns.parentR.scale_assign_offset = vns.ScaleManager.Scale:new()
				vns.parentR.scale_assign_offset[vns.childrenRT[msgM.fromS].robotTypeS] = 1	
			end
			vns.deleteChild(vns, msgM.fromS)
		end
	end

	-- listen to assign_dismiss
	--[[
	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "assign_ack")) do
		if vns.childrenRT[msgM.fromS] ~= nil then
			local assignFrom = msgM.dataT.assignFrom
			if vns.childrenRT[assignFrom] ~= nil then
				vns.childrenRT[assignFrom].scale_assign_offset = vns.ScaleManager.Scale:new()
				vns.childrenRT[assignFrom].scale_assign_offset[vns.childrenRT[msgM.fromS].robotTypeS] = -1
			elseif vns.parentR ~= nil and vns.parentR.idS == assignFrom then
				vns.parentR.scale_assign_offset = vns.ScaleManager.Scale:new()
				vns.parentR.scale_assign_offset[vns.childrenRT[msgM.fromS].robotTypeS] = -1	
			end
		end
	end
	--]]
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
	end
end

return Assigner
