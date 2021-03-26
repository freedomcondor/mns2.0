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

local centralize_flag = false
if robot.params.centralize_flag == "true" then centralize_flag = true end

local Cgenerator = require("MorphologyCGenerator")

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
		vns.create_vns_core_node(vns),
		vns.Driver.create_driver_node_wait(vns),
	}}

    if centralize_flag == true and robot.id ~= "drone1" then
		bt = BT.create
		{ type = "sequence", children = {
			vns.create_preconnector_node(vns),
			vns.create_vns_core_node_no_recruit(vns),
			vns.Driver.create_driver_node_wait(vns),
		}}
	end
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
	api.droneMaintainHeight(3.5)
	api.postStep()


	if api.stepCount < 20 then
		vns.allocator.mode_switch = "stationary"
	else
		vns.allocator.mode_switch = "allocate"
	--[[
	elseif api.stepCount < 22 then
		vns.allocator.mode_switch = "allocate"
	elseif robot.id == "drone1" then
		vns.allocator.mode_switch = "keep"
	--]]
	end

	-- debug
	api.debug.showChildren(vns)
end

--- destroy
function destroy()
end
