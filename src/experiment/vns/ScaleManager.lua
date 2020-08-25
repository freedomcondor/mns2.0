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
	vns.scalemanager = {
		buffer = {}, 
		steady_countdown_period = 3,
		steady_countdown = 3,
	}
end

function ScaleManager.reset(vns)
	vns.scale = ScaleManager.Scale:new()
	vns.scale[vns.robotTypeS] = 1
end

function ScaleManager.addChild(vns, robotR)
	robotR.scale = ScaleManager.Scale:new()
	vns.scalemanager.buffer[robotR.idS] = ScaleManager.Scale:new()
	vns.scalemanager.steady_countdown = vns.scalemanager.steady_countdown_period
end

function ScaleManager.deleteChild(vns, idS)
	vns.scalemanager.buffer[idS] = nil
	vns.scalemanager.steady_countdown = vns.scalemanager.steady_countdown_period
end

function ScaleManager.step(vns)
	-- receive scale from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "scale")) do
		vns.parentR.scale = ScaleManager.Scale:new(msgM.dataT.scale)
	end end
	-- receive scale from children
	for idS, robotR in pairs(vns.childrenRT) do 
		for _, msgM in ipairs(vns.Msg.getAM(idS, "scale")) do
			local temp = ScaleManager.Scale:new(msgM.dataT.scale)
			if vns.scalemanager.buffer[idS] ~= temp then
				vns.scalemanager.steady_countdown = vns.scalemanager.steady_countdown_period
			end
			vns.scalemanager.buffer[idS] = temp
			--robotR.scale = ScaleManager.Scale:new(msgM.dataT.scale)
		end 
	end

	-- countdown and try update children
	vns.scalemanager.steady_countdown = vns.scalemanager.steady_countdown - 1
	if vns.scalemanager.steady_countdown <= 0 then
		for idS, robotR in pairs(vns.childrenRT) do
			robotR.scale = vns.scalemanager.buffer[idS] 
		end
	end

	-- add assign_offset
	for idS, robotR in pairs(vns.childrenRT) do 
		if robotR.scale_assign_offset ~= nil then
			robotR.scale = robotR.scale + robotR.scale_assign_offset
			robotR.scale_assign_offset = nil
		end
	end

	-- find the biggest child number and make it count down period
	local biggest_child_number = 0
	for idS, robotR in pairs(vns.childrenRT) do 
		if robotR.scale:totalNumber() > biggest_child_number then
			biggest_child_number = robotR.scale:totalNumber()
		end
	end
	vns.scalemanager.steady_countdown_period = biggest_child_number + 2

	-- sum up scale
	local sumScale = ScaleManager.Scale:new()
	if vns.parentR ~= nil then sumScale = sumScale + vns.parentR.scale end
	for idS, robotR in pairs(vns.childrenRT) do 
		sumScale = sumScale + robotR.scale
	end
	-- add myself
	if sumScale[vns.robotTypeS] == nil then
		sumScale[vns.robotTypeS] = 1
	else
		sumScale[vns.robotTypeS] = sumScale[vns.robotTypeS] + 1
	end
	vns.scale = sumScale

	-- report scale
	local toReport
	if vns.parentR ~= nil then 
		toReport = sumScale - vns.parentR.scale 
		if toReport ~= vns.parentR.lastSendScale then
			vns.Msg.send(vns.parentR.idS, "scale", {scale = toReport})
		end
	end
	for idS, robotR in pairs(vns.childrenRT) do 
		toReport = sumScale - robotR.scale 
		if toReport ~= robotR.lastSendScale then
			vns.Msg.send(idS, "scale", {scale = toReport})
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
