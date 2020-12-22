local api = {}

---- Time -------------------------------------
api.time = {}
api.time.currentTime = robot.system.time
function api.processTime()
	api.time.period = robot.system.time - api.time.currentTime
	api.time.currentTime = robot.system.time
end

---- step count -------------------------------
api.stepCount = 0

---- Debug Draw -------------------------------
api.debug = {}
function api.debug.drawArrow(color, begin, finish)
	if robot.debug == nil then return end
	robot.debug.draw("arrow(" .. color .. ")(" .. 
		tostring(begin) .. ")(" ..
		tostring(finish) .. ")"
	)
end

function api.debug.showVirtualFrame()
	api.debug.drawArrow(
		"green", 
		vector3(0,0,0.1), 
		vector3(0.2,0,0.1):rotate(api.virtualFrame.orientationQ)
	)
end

--[[ probabaly won't use
function api.debug.showEstimateLocation()
	api.debug.drawArrow(
		"red", 
			-vector3(api.estimateLocation.positionV3):rotate(
			quaternion(api.estimateLocation.orientationQ):inverse()
		), 
		vector3(0,0,0.1)
	)
end
--]]

function api.debug.showParent(vns)
	if vns.parentR ~= nil then
		local robotR = vns.parentR
		api.debug.drawArrow("blue", vector3(), api.virtualFrame.V3_VtoR(vector3(robotR.positionV3)))
		api.debug.drawArrow("blue", 
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
			vector3(0.1, 0, 0):rotate(
				api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
			)
		)
	end
end

function api.debug.showChildren(vns)
	-- draw children location
	for i, robotR in pairs(vns.childrenRT) do
		api.debug.drawArrow("blue", vector3(), api.virtualFrame.V3_VtoR(vector3(robotR.positionV3)))
		api.debug.drawArrow("blue", 
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1),
			api.virtualFrame.V3_VtoR(robotR.positionV3) + vector3(0,0,0.1) +
			vector3(0.1, 0, 0):rotate(
				api.virtualFrame.Q_VtoR(quaternion(robotR.orientationQ))
			)
		)
	end
end

function api.debug.showObstacles(vns)
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		api.debug.drawArrow("red", vector3(), 
		api.virtualFrame.V3_VtoR(vector3(obstacle.positionV3)))
		--obstacle.positionV3)
	end
end

---- Step Function ----------------------------
function api.init()
	api.reset()
end

function api.reset()
	--[[
	api.estimateLocation = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
	}
	--]]
end

function api.preStep()
	api.stepCount = api.stepCount + 1
	api.processTime()
end

function api.postStep()
	api.debug.showVirtualFrame()
end

--[[ probably won't use
---- Location Estimate ------------------------
api.estimateLocation = {
	positionV3 = vector3(),
	orientationQ = quaternion(),
}
--]]

---- Virtual Coordinate Frame -----------------
-- instead of turn the real robot, we turn the virtual coordinate frame, 
-- so that a pipuck can be "omni directional"
api.virtualFrame = {}
api.virtualFrame.orientationQ = quaternion()
function api.virtualFrame.rotateInSpeed(speedV3)
	local axis = vector3(speedV3):normalize()
	if speedV3:length() == 0 then axis = vector3(1,0,0) end
	api.virtualFrame.orientationQ = 
		quaternion(speedV3:length() * api.time.period,
		           axis
		) * api.virtualFrame.orientationQ
end

function api.virtualFrame.V3_RtoV(vec)
	return vector3(vec):rotate(api.virtualFrame.orientationQ:inverse())
end
function api.virtualFrame.V3_VtoR(vec)
	return vector3(vec):rotate(api.virtualFrame.orientationQ)
end
function api.virtualFrame.Q_RtoV(q)
	return api.virtualFrame.orientationQ:inverse() * q
end
function api.virtualFrame.Q_VtoR(q)
	return api.virtualFrame.orientationQ * q
end

---- Speed Control ---------------------------
function api.setSpeed()
	print("api.setSpeed needs to be implemented for specific robot")
end

function api.move(transV3, rotateV3)
	-- transV3 and rotateV3 in virtual frame
	local transRealV3 = api.virtualFrame.V3_VtoR(transV3)
	local rotateRealV3 = api.virtualFrame.V3_VtoR(rotateV3)
	api.setSpeed(transRealV3.x, transRealV3.y, transRealV3.z, 0)
	-- rotate virtual frame
	api.virtualFrame.rotateInSpeed(rotateRealV3)
	--[[ probably won't use
	-- accumulate estimate location
	api.estimateLocation.positionV3 = 
		api.estimateLocation.positionV3 + transRealV3 * api.time.period
	local axis = vector3(rotateRealV3):normalize()
	if rotateRealV3:length() == 0 then axis = vector3(0,0,1) end
	api.estimateLocation.orientationQ = 
		quaternion(rotateRealV3:length() * api.time.period, axis) *
		api.estimateLocation.orientationQ
	--]]
end

------------------------------------------------------
function api.linkRobotInterface(VNS)
	VNS.Msg.sendTable = function(table)
		robot.wifi.tx_data(table)
	end

	VNS.Msg.getTablesAT = function(table)
		return robot.wifi.rx_data
	end

	VNS.Msg.myIDS = function()
		return robot.id
	end

	VNS.Driver.move = api.move
	VNS.api = api
end

return api
