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
logger.disable()

-- time measurement
local time_start_data_file = "time_start_" .. robot.id .. ".csv"
local time_end_data_file = "time_end_" .. robot.id .. ".csv"

local centralize_flag = false
if robot.params.centralize_flag == "true" then centralize_flag = true end

local Cgenerator = require("MorphologyCGenerator")

function VNS.Allocator.calcBaseValue(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	base_target_V3.z = 0
	base_current_V3.z = 0
	local dot = base_current_V3:dot(base_target_V3:normalize())
	if dot < 0 then 
		return dot 
	else
		local x = dot
		local x2 = dot ^ 2
		local l = base_current_V3:length()
		local y2 = l ^ 2 - x2
		elliptic_distance2 = x2 + (1/4) * y2
		return elliptic_distance2
	end
end

-- datas ----------------
local bt
--local vns
gene = require("morphology")

local function CentralizeGenerator(branch, base_positionV3, base_orientationQ, centralize_gene)
	local first_node_flag = false
	if centralize_gene == nil then 
		centralize_gene = {} 
		first_node_flag = true 
	end
	if base_orientationQ == nil then base_orientationQ = quaternion() end
	if base_positionV3 == nil then base_positionV3 = vector3() end
	
	local current_positionV3 = base_positionV3 + vector3(branch.positionV3):rotate(base_orientationQ)
	local current_orientationQ = base_orientationQ * branch.orientationQ

	local origin_gene
	if first_node_flag == true then
		centralize_gene = {
			robotTypeS = "drone",
			positionV3 = current_positionV3,
			orientationQ = current_orientationQ,
			children = {},
		}
		origin_gene = centralize_gene
		centralize_gene = centralize_gene.children
	else
		table.insert(centralize_gene, {
			robotTypeS = "drone",
			positionV3 = current_positionV3,
			orientationQ = current_orientationQ,
		})
	end

	if branch.children ~= nil then
		for i, child in ipairs(branch.children) do
			CentralizeGenerator(child, current_positionV3, current_orientationQ, centralize_gene)
		end
	end

	return origin_gene
end

centralize_gene = CentralizeGenerator(gene)

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()

	-- generate C code for formation
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
end

--- reset
function reset()
	vns.reset(vns)

	-- initialize vns.id to specify the order
	if vns.idS == "drone1" then vns.idN = 1 
	--elseif vns.idS == "drone3" then vns.idN = 0.9 
	else vns.idN = 0.5 
	end

	-- set safezone
    if centralize_flag == true then vns.Parameters.safezone_drone_drone = 100
	                           else vns.Parameters.safezone_drone_drone = 2.5 * math.sqrt(2) end

	-- set Gene
    if centralize_flag == true then
		gene = centralize_gene
	end
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end

	vns.allocator.mode_switch = "stationary"
	-- set BT 
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, {connector_no_parent_ack = true}),
		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}

    if centralize_flag == true and robot.id ~= "drone1" then
		bt = BT.create
		{ type = "sequence", children = {
			vns.create_preconnector_node(vns),
			vns.create_vns_core_node(vns, {connector_no_recruit = true}),
			vns.Driver.create_driver_node(vns, {waiting = true}),
		}}
	end
end

--- step
function step()
	---[[
	if api.stepCount == 0 then
		result = os.execute("@DATECOMMAND@ +%s.%N > " .. time_start_data_file)
	else
		result = os.execute("@DATECOMMAND@ +%s.%N >> " .. time_start_data_file)
	end
	--]]

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
	api.droneMaintainHeight(4.0)
	api.postStep()


	if centralize_flag ~= true then
		if api.stepCount < 20 then
			vns.allocator.mode_switch = "stationary"
		else
			vns.allocator.mode_switch = "allocate"
		end
	else
		if api.stepCount < 20 then
			vns.allocator.mode_switch = "stationary"
		elseif api.stepCount < 22 then
			vns.allocator.mode_switch = "allocate"
		elseif robot.id == "drone1" then
			vns.allocator.mode_switch = "keep"
		end
	end

	-- debug
	api.debug.showChildren(vns)

	--[[
	logger("my assign", vns.assigner.targetS)
	logger("my parent")
	if vns.parentR ~= nil then
		logger(vns.parentR.idS)
	end
	logger("children")
	for idS, robotR in pairs(vns.childrenRT) do
		logger("\t", idS)
		logger("\tscale")
		logger(robotR.scalemanager.scale)
		logger("\t", robotR.assignTargetS)
	end
	--]]
	--[[
	for idS, robotR in pairs(vns.connector.seenRobots) do
		if robotR.robotTypeS == "pipuck" then
			api.debug.drawArrow("red", vector3(), 
				robotR.positionV3)
		end
	end
	--]]

	-- stepCount is +1 in preStep
	---[[
	if api.stepCount == 1 then
		result = os.execute("@DATECOMMAND@ +%s.%N > " .. time_end_data_file)
	else
		result = os.execute("@DATECOMMAND@ +%s.%N >> " .. time_end_data_file)
	end
	--]]
end

--- destroy
function destroy()
end
