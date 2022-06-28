local myType = robot.params.my_type

package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/api/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/utils/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/vns/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/build/testing/exp_01_4_establish_formation_3d_8p/?.lua"

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")
logger.disable("Stabilizer")
logger.disable("droneAPI")

-- datas ----------------
local bt
--local vns
local gene = require("morphology")

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
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, gene)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		create_led_node(vns),
		vns.create_vns_core_node(vns, {drone_pipuck_avoidance = true}),
		vns.Driver.create_driver_node(vns, {waiting = "spring"}),
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
end

--- destroy
function destroy()
	api.destroy()
end

function create_led_node(vns)
	return function()
		-- signal led
		if vns.robotTypeS == "drone" then
			local flag = false
			for idS, robotR in pairs(vns.connector.seenRobots) do
				if robotR.robotTypeS == "drone" then
					flag = true
				end
			end
			if flag == true then
				robot.leds.set_leds("green")
			else
				robot.leds.set_leds("red")
			end
		end
		return false, true
	end
end
