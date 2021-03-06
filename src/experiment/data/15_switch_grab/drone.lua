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
local structure4 = require("morphology4")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
		structure3,
		structure4,
	}
}

local Cgenerator = require("MorphologyCGenerator")

-- overwrite resetMorphology
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

function create_head_navigate_node(vns)
local state = "reach"
local count = 0
return function()
	-- only run for brain
	if vns.parentR ~= nil then return false, true end

	-- append collective sensor to obstacles
	for i, v in ipairs(vns.collectivesensor.receiveList) do
		table.insert(vns.avoider.obstacles, v)
	end

	-- detect target
	local targetV3 = nil
	for i, ob in ipairs(vns.avoider.obstacles) do
		if ob.type == 0 then
			targetV3 = ob.positionV3 - vector3(0.8,0,0)
			targetV3.z = 0
		end
	end

	-- State
	if state == "reach" then
		-- move
		local speed = 0.03
		if targetV3 == nil then
			vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
		else
			vns.Spreader.emergency_after_core(vns, 
				speed * vector3(targetV3):normalize(), 
				vector3()
			)
		end

		if targetV3 ~= nil and targetV3:length() < 0.02 then
			state = "stretch"
			count = 0
			vns.setMorphology(vns, structure2)
		end
	elseif state == "stretch" then
		count = count + 1
		if count == 350 then
			state = "clutch"
			count = 0
			vns.setMorphology(vns, structure3)
		end
	elseif state == "clutch" then
		count = count + 1
		if count == 150 then
			state = "retrieve"
			count = 0
			vns.setMorphology(vns, structure4)
		end
	elseif state == "retrieve" then
		count = count + 1
		if count == 250 then
			state = "end"
			vns.setMorphology(vns, structure1)
		end
	end

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
	vns.setMorphology(vns, structure1)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node_wait(vns),
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
