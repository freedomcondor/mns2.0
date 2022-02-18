logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns

function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()
end

function reset()
	vns.reset(vns)
	if robot.id == "pipuck1" then vns.idN = 1 end

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_reaction_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount + 1) .. " ------------------------------------")
	api.preStep() 
	vns.preStep(vns)

	bt()

	vns.postStep(vns)
	api.postStep()

--[[
	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		connector = true,
		goal = true,
		positionV3 = true,
	})
--]]
	vns.logLoopFunctionInfo(vns)
end

function destroy()
	api.destroy()
end

function create_reaction_node(vns)
return function()
	if vns.api.stepCount == 50 then
		local d = 0.5
		local x = d
		local y = d
		if robot.id == "pipuck3" then y = -y end
		vns.setGoal(vns, vector3(x, y, 0), quaternion())
	end
	return false, true
end
end