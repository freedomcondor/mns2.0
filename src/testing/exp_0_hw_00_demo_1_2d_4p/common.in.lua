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
	if vns.idS == robot.params.stabilizer_preference_brain then 
		vns.idN = 1 
		api.parameters.droneDefaultStartHeight = 1.6
	end
	if vns.robotTypeS == "pipuck" then 
		vns.idN = 0 
	end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, gene)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		create_led_node(vns),
		create_start_node(vns),
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

-- drone avoider led node ---------------------
function create_led_node(vns)
	return function()
		-- signal led
		--[[
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
		--]]

		--[[
		if vns.parentR ~= nil then
			local color = "0,255,255,0"
			vns.api.debug.drawArrow(color,
		                        vns.api.virtualFrame.V3_VtoR(vector3(0,0,0.03)),
		                        vns.api.virtualFrame.V3_VtoR(vector3(vns.goal.positionV3 + vector3(0,0,0.03))),
								true
		                       )
			vns.api.debug.drawRing(color, api.virtualFrame.V3_VtoR(vns.goal.positionV3 + vector3(0,0,0.03)), 0.15, true)
		end


		if vns.robotTypeS == "drone" then
			if vns.parentR == nil then
				robot.leds.set_leds("red")
				vns.api.debug.drawRing("red", vector3(0,0,0), 0.15, true)
			else
				robot.leds.set_leds("black")
			end
		end
		--]]

		return false, true
	end
end

function create_start_node(vns)
	return function()
		if vns.api.stepCount < 75 then
			return false, false
		else
			return false, true 
		end
	end
end