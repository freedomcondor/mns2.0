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
local state = "2to1"
local count = 0
return function()
	-- only run for brain
	if vns.parentR ~= nil then return false, true end

	for _, msgM in ipairs(vns.Msg.getAM("ALLMSG", "split")) do
		state = "split"
		count = 0
	end

	-- move
	local speed = 0.03
	if state == "2to1" then
		if vns.scale.pipuck == 6 then
			vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
		elseif vns.scale.pipuck == 4 then
			vns.Spreader.emergency_after_core(vns, vector3(-speed,0,0), vector3())
		end

		if vns.scale.drone == 4 then
			state = "1wait"
			count = 0
			vns.setMorphology(vns, structure2)
		end
	elseif state == "1wait" then
		count = count + 1
		if count == 450 then
			state = "1to3"
			-- cut front and back id 15 and 21
			local idS = vns.allocator.gene_index[15].match
			vns.deleteChild(vns, idS)
			vns.Msg.send(idS, "split", {morphology = 15, newID = 0.9, waitTick = 150})
			local idS = vns.allocator.gene_index[21].match
			vns.deleteChild(vns, idS)
			vns.Msg.send(idS, "split", {morphology = 15, newID = 0.9, waitTick = 150})

			count = 0
		end
	elseif state == "1to3" then
		-- wait for cut children to get back and start counting
		if vns.scale.drone == 4 then
			count = count + 1
		end
		if count == 300 then
			state = "1to4"
			-- cut front, right and back id 15, 18 and 21
			local idS = vns.allocator.gene_index[15].match
			vns.deleteChild(vns, idS)
			vns.Msg.send(idS, "split", {morphology = 15, newID = 0.9, waitTick = 150})
			local idS = vns.allocator.gene_index[18].match
			vns.deleteChild(vns, idS)
			vns.Msg.send(idS, "split", {morphology = 15, newID = 0.9, waitTick = 150})
			local idS = vns.allocator.gene_index[21].match
			vns.deleteChild(vns, idS)
			vns.Msg.send(idS, "split", {morphology = 15, newID = 0.9, waitTick = 150})
		end
	elseif state == "split" then
		count = count + 1
		if count < 100 then
			vns.Spreader.emergency_after_core(vns, vector3(-speed,0,0), vector3())
		elseif count > 150 then
			vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
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

	-- initialize vns.id to specify the order
	if vns.idS == "drone1" then vns.idN = 1 
	elseif vns.idS == "drone3" then vns.idN = 0.9 
	else vns.idN = 0.5 
	end

	-- set Gene
	vns.setGene(vns, gene)
	-- generate Ccode gene
	if robot.id == "drone1" then Cgenerator(gene, "Ccode.cpp") end
	-- set Morphology to structure1
	vns.setMorphology(vns, structure1)
	-- set BT 
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
