local myType = robot.params.my_type

package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/api/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/utils/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/src/core/vns/?.lua"
package.path = package.path .. ";C:/Users/rosha/OneDrive/Desktop/Weixu/mns2.0/build/testing/exp_0_hw_07_fault_tolerance/?.lua"

pairs = require("AlphaPairs")
local Transform = require("Transform")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.enableErrorStreamLog()
logger.disable("Stabilizer")
--logger.disable("droneAPI")

-- datas ----------------
local bt
--local vns
local structure1 = require("morphology1")

-- VNS option
-- VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval -- default is oval

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

if myType == "drone" then
VNS.Connector.newVnsID = 
function(vns, idN, lastidPeriod)
	local _idS = vns.Msg.myIDS()
	local _idN = idN or robot.random.uniform() + 1

	VNS.Connector.updateVnsID(vns, _idS, _idN, lastidPeriod)
end
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
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 2 end
	if vns.idS == "drone2" then vns.idN = 0 end
	vns.setGene(vns, structure1)
	vns.setMorphology(vns, structure1)

	bt = BT.create
	{ type = "sequence", children = {
		create_failure_node(vns),
		vns.create_preconnector_node(vns),
		create_led_node(vns),
		vns.create_vns_core_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

--- step
function step()
	-- prestep
	logger(robot.id, api.stepCount, robot.system.time, "-----------------------")
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
	if vns.robotTypeS == "drone" then
		api.debug.showObstacles(vns)
	end

	vns.debug.logInfo(vns, {
		idN = true,
		idS = true,
		goal = true,
		connector = true,
		target = false,
		assigner = false,
		allocator = false,
	})

end

--- destroy
function destroy()
	api.destroy()
end

-- drone avoider led node ---------------------
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
				robot.leds.set_leds("black")
			end
		end
		return false, true
	end
end

-- fail node
function create_failure_node(vns)
	local fail_return = true
return function()
	if vns.api.stepCount == 300 then 
		--if (vns.robotTypeS ~= "drone" and robot.random.uniform() < 0.8) then
		if (robot.id == "drone4") then
			fail_return = false
			if vns.robotTypeS == "drone" then
				robot.flight_system.set_offboard_mode(false)
			end
		end
	end
	if fail_return == false then
		logger(robot.id, "I fail")
		if vns.robotTypeS == "pipuck" then
			vns.api.move(vector3(), vector3())

			if vns.api.stepCount % 6 < 3 then
				vns.api.pipuckShowAllLEDs()
			else
				for count = 1, 8 do
					robot.leds.set_ring_led_index(count, false)
				end
			end
		elseif vns.robotTypeS == "drone" then
			vns.api.parameters.droneDefaultHeight = -0.2
			vns.api.move(vector3(0,0,-0.02), vector3())

			if vns.api.stepCount % 6 < 3 then
				robot.leds.set_leds("red")
			else
				robot.leds.set_leds("black")
			end
		end
	end
	return false, fail_return
end
end
