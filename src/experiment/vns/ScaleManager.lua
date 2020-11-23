-- ScaleManager --------------------------------------
------------------------------------------------------

local ScaleManager = {}

--[[
--	related data
--	vns.scale
--	vns.parentR.scale
--	vns.parentR.lastSendScale
--	vns.childrenRT[xxx].scale
--	vns.childrenRT[xxx].lastSendScale
--]]

ScaleManager.Scale = require("Scale")

function ScaleManager.create(vns)
	ScaleManager.reset(vns)
end

function ScaleManager.reset(vns)
	vns.scale = ScaleManager.Scale:new()
	vns.scale[vns.robotTypeS] = 1
end

function ScaleManager.addChild(vns, robotR)
	robotR.scale = ScaleManager.Scale:new()
	robotR.scale[robotR.robotTypeS] = 1
end

function ScaleManager.deleteChild(vns, idS)
end

function ScaleManager.preStep(vns)
end

function ScaleManager.step(vns)
	-- receive scale from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "scale")) do
		vns.parentR.scale = ScaleManager.Scale:new(msgM.dataT.scale)
	end end
	-- receive scale from children
	for idS, robotR in pairs(vns.childrenRT) do 
		for _, msgM in ipairs(vns.Msg.getAM(idS, "scale")) do
			robotR.scale = ScaleManager.Scale:new(msgM.dataT.scale)
		end 
	end

	-- add assign_offset
	-- and check assign_offset minus
	for idS, robotR in pairs(vns.childrenRT) do 
		if robotR.scale_assign_offset ~= nil then
			robotR.scale = robotR.scale + robotR.scale_assign_offset
		end
		for typeS, number in pairs(robotR.scale) do
			if number < 0 then robotR.scale[typeS] = 0 end
		end
		if robotR.scale[robotR.robotTypeS] == nil or 
		   robotR.scale[robotR.robotTypeS] < 1 then
			robotR.scale[robotR.robotTypeS] = 1
		end
	end
	if vns.parentR ~= nil and vns.parentR.scale_assign_offset ~= nil then
		vns.parentR.scale = vns.parentR.scale + vns.parentR.scale_assign_offset
		for typeS, number in pairs(vns.parentR.scale) do
			if number < 0 then vns.parentR.scale[typeS] = 0 end
		end
		if vns.parentR.scale[vns.parentR.robotTypeS] == nil or
		   vns.parentR.scale[vns.parentR.robotTypeS] < 1 then
			vns.parentR.scale[vns.parentR.robotTypeS] = 1
		end
	end

	-- sum up scale
	local sumScale = ScaleManager.Scale:new()
	-- add myself
	sumScale:inc(vns.robotTypeS)
	-- add parent
	if vns.parentR ~= nil then sumScale = sumScale + vns.parentR.scale end
	-- add children
	for idS, robotR in pairs(vns.childrenRT) do 
		sumScale = sumScale + robotR.scale
	end
	vns.scale = sumScale

	-- report scale
	local toReport
	if vns.parentR ~= nil then 
		toReport = sumScale - vns.parentR.scale 
		if toReport ~= vns.parentR.lastSendScale then
			vns.Msg.send(vns.parentR.idS, "scale", {scale = toReport})
			vns.parentR.lastSendScale = toReport
		end
	end
	for idS, robotR in pairs(vns.childrenRT) do 
		toReport = sumScale - robotR.scale 
		if toReport ~= robotR.lastSendScale then
			vns.Msg.send(idS, "scale", {scale = toReport})
			robotR.lastSendScale = toReport
		end
	end
end

function ScaleManager.create_scalemanager_node(vns)
	return function()
		ScaleManager.step(vns)
		return false, true
	end
end

return ScaleManager
