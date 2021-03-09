package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/api/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/utils/?.lua"
package.path = package.path .. ";@CMAKE_BINARY_DIR@/experiment/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns
local gene = require("morphology")
local Cgenerator = require("MorphologyCGenerator")

function create_head_navigate_node(vns)
local count = 0
local state = "start"
return function()
	-- only run for brain
	--if vns.parentR ~= nil then return false, true end

	local speed = 0.02
	if state == "start" then
		count = count + 1
		if count >= 200 then
			state = "before_wall"
		end
	elseif state == "before_wall" then
		-- move forward
		if vns.parentR == nil then
			vns.Spreader.emergency(vns, vector3(speed,0,0), vector3(), nil, true)
		end
	end
	vns.state = state
	vns.state_count = count
	return false, true
end end

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	-- generate C code for formation
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp", "N_ROBOTS") end
end

--- reset
function reset()
	vns.reset(vns)

	-- initialize vns.id to specify the order
	if vns.idS == "drone1" then vns.idN = 1 
	else vns.idN = 0.5 
	end

	-- set Gene
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
	-- set BT 
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node_wait(vns),
	}}
end

--- step
function step()
	-- prestep
	logger(robot.id, api.stepCount + 1, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- loop function message
	if vns.allocator.target == nil then
		robot.debug.loop_functions("-1")
	else
		robot.debug.loop_functions(tostring(vns.allocator.target.idN))
	end

	-- poststep
	vns.postStep(vns)
	api.droneMaintainHeight(1.5)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
end

--- destroy
function destroy()
end
