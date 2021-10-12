package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("RandomPairs")

-- includes -------------
logger = require("Logger")
local api = require("droneAPI")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")

-- datas ----------------
local bt
--local vns  -- global vns to make vns appear in lua_editor
local structure = require("morphology_cube")
--local structure = require("morphology_octahedron")
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval

-- argos functions ------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create("drone")
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, structure)
	bt = BT.create(VNS.create_vns_node(vns))

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		create_reaction_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = true}),
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
	if api.stepCount < 10 then
		if robot.id == "drone1" then
			api.droneMaintainHeight(3.5)
		end

		if robot.id == "drone2" then
			api.droneMaintainHeight(0.5)
		end
	end
	api.postStep()

	-- debug
	api.debug.showChildren(vns)
	--api.debug.showParent(vns)

	--[[
	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		goal = true,
		target = true,
		assigner = true,
		allocator = true,
	})
	--]]
end

--- destroy
function destroy()
end

-- Strategy -----------------------------------------------
function create_reaction_node(vns)
	local state = "waiting"
	local stateCount = 0
return function()
	---------------------------------------
	-- waiting for taking off and form a formation
	if state == "waiting" then
		stateCount = stateCount + 1
		if stateCount == 700 then 
			state = "roll" 
			stateCount = 0
		end
	elseif state == "roll" and vns.parentR == nil then
		stateCount = stateCount + 1
		if stateCount == 1 then
			local dis = 0.6
			local th = 10
			vns.allocator.keepBrainGoal = true
			--vns.goal.positionV3 = vector3(dis/2*math.sqrt(2) - dis/2,0,-dis/2)
			vns.goal.positionV3 = vector3(dis * math.cos((90-th) * math.pi / 180) / math.sqrt(2),
			                              dis * math.cos((90-th) * math.pi / 180) / math.sqrt(2),
			                              dis * math.sin((90-th) * math.pi / 180)
			                             ) - 
			                      vector3(0,
			                              0,
			                              dis * math.sin((90) * math.pi / 180)
										 )
			vns.goal.orientationQ = quaternion(th * math.pi/180, vector3(-1,1,0))
		elseif stateCount == 100 then
			stateCount = 0
		end
	end
end
end