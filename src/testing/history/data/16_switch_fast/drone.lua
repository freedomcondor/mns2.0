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
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
		structure3,
	}
}

local Cgenerator = require("MorphologyCGenerator")

-- overwrite resetMorphology
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

function create_head_navigate_node(vns)
local state = 2
return function()
	-- only run for brain
	if vns.parentR ~= nil then return false, true end

	-- append collective sensor to obstacles
	for i, v in ipairs(vns.collectivesensor.receiveList) do
		table.insert(vns.avoider.obstacles, v)
	end

	-- detect width
	local left = 5
	local right = -5
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.positionV3.y > 0 and 
		   ob.positionV3.y < left then
			left = ob.positionV3.y
		end
		if ob.positionV3.y < 0 and 
		   ob.positionV3.y > right then
			right = ob.positionV3.y
		end
	end
	local width = left - right

	-- State
	if state == 1 then
		if width < 3.5 then
			state = 2
			vns.setMorphology(vns, structure2)
		end
	elseif state == 2 then
		if width > 3.5 then
			state = 1
			vns.setMorphology(vns, structure1)
		end
	end

	-- move
	local speed = 0.02
	vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
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
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 else vns.idN = 0.5 end
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
	-- set Morphology to structure1
	vns.setMorphology(vns, structure2)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = true}),
	}}
end

--- step
function step()
	-- prestep
	--logger(robot.id, "-----------------------")
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
	--if robot.id == "drone1" then
	--	api.debug.showObstacles(vns)
	--end
end

--- destroy
function destroy()
end
