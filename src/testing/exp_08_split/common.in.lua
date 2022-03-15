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
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
	}
}

-- VNS option
--VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_vertical -- default is oval

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

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

	if vns.parentR == nil then
		api.debug.showObstacles(vns)
	end
end

--- destroy
function destroy()
	api.destroy()
end

----------------------------------------------------------------------------------
function create_head_navigate_node(vns)
local state = "form"
local count = 0
local speed = 0.05
return function()
	-- only run after navigation
	if vns.api.stepCount < 150 then return false, true end

	-- State
	if state == "form" and 
	   vns.allocator.target.split == true then
		count = count + 1
		if count == 200 then
			-- rebellion
			if vns.parentR ~= nil then
				vns.Msg.send(vns.parentR.idS, "dismiss")
				vns.deleteParent(vns)
			end
			vns.setMorphology(vns, structure2)
			vns.Connector.newVnsID(vns, nil, 200)

			state = "split"
			logger("split")
			count = 0
		end
	elseif state == "split" and 
	       vns.allocator.target.ranger == true then
		vns.Spreader.emergency_after_core(vns, vector3(-speed,0,0), vector3())
		count = count + 1
		if count == 200 then
			state = "go_back"
			logger("go_back")
			count = 0
		end
	elseif state == "go_back" and 
	       vns.allocator.target.ranger == true then
		vns.Spreader.emergency_after_core(vns, vector3(speed,0,0), vector3())
		count = count + 1
		if count == 200 then
			state = "end"
			logger("end")
			count = 0
		end
	end

	return false, true
end end