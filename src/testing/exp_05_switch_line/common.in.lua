local myType = robot.params.my_type

package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()

-- datas ----------------
local bt
--local vns
local structure1 = require("morphologies/morphology1")
local structure2 = require("morphologies/morphology2")
local structure3 = require("morphologies/morphology3")
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

-- VNS option
-- VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval -- default is oval

-- argos functions -----------------------------------------------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create(myType)
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	--if vns.idS == "pipuck1" then vns.idN = 1 end
	if vns.idS == "drone1" then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
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

	-- poststep
	vns.postStep(vns)
	api.postStep()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)
	--api.debug.showObstacles(vns)

	--ExperimentCommon.detectGates(vns, 253, 1.5) -- gate brick id and longest possible gate size
end

--- destroy
function destroy()
	api.destroy()
end

----------------------------------------------------------------------------------
function create_head_navigate_node(vns)
local state = 1
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
		if ob.positionV3.y > 0 and ob.type == 100 and
		   ob.positionV3.y < left then
			left = ob.positionV3.y
		end
		if ob.positionV3.y < 0 and ob.type == 100 and
		   ob.positionV3.y > right then
			right = ob.positionV3.y
		end
	end
	local width = left - right

	-- State
	if state == 1 then
		if width < 4.0 then
			state = 2
			vns.setMorphology(vns, structure2)
			logger("state2")
		end
	elseif state == 2 then
		if width < 3.0 then
			state = 3
			vns.setMorphology(vns, structure3)
			logger("state3")
		end
	end

	-- move
	local speed = 0.03
	vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
	return false, true
end end