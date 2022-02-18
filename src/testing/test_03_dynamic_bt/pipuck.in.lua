package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("pipuckAPI")
local VNS = require("VNS")
local BT = require("DynamicBehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns     -- global vns to make vns appear in lua_editor
local structure = require("morphology")

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("pipuck")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	vns.setGene(vns, structure)
	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_learn_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

--- step
function step()
	-- prestep
	logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
end

--- destroy
function destroy()
end

---------------------------------------------------------
local string = [[
return function()
	print("I'm crazy!") 
	vns.api.debug.drawRing("red", vector3(0,0,0), 0.2)
	return false, true
end
]]
---------------------------------------------------------

function create_learn_node(vns)
	local flag = false
	local children = {
		function(BT_children)
			if robot.id == "pipuck1" then
				vns.Msg.send("ALLMSG", "learn", {string = string, idS = vns.idS})
			end

			for _, msgM in pairs(vns.Msg.getAM("ALLMSG", "learn")) do
				if msgM.dataT.idS == vns.idS and flag == false then
					flag = true
					table.insert(BT_children, load(msgM.dataT.string)())
				end
			end
		end,
	}
	if robot.id == "pipuck1" then 
		table.insert(children, load(string)()) 
	end

	return {type = "sequence", dynamic = true, children = children}
end
