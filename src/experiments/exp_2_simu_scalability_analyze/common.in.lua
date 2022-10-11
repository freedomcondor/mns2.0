local myType = robot.params.my_type

--[[
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"
--]]
if robot.params.hardware ~= "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu/?.lua"
end

-- get scalability scale
local n_drone = tonumber(robot.params.n_drone or 1)
local morphologiesGenerator = robot.params.morphologiesGenerator

pairs = require("AlphaPairs")
ExperimentCommon = require("ExperimentCommon")
require(morphologiesGenerator)
local Transform = require("Transform")

-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Allocator")
logger.disable("Stabilizer")
logger.disable("droneAPI")

--logger.enableFileLog()

-- datas ----------------
local bt
--local vns
local droneDis = 1.5
local pipuckDis = 0.7
local height = api.parameters.droneDefaultHeight
local gene = create_back_line_morphology_with_drone_number(n_drone, droneDis, pipuckDis, height)

Message = VNS.Msg

-- VNS option
VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_vertical

local timeMeasureDataFile = "logs/" .. robot.id .. ".time_dat"
local commMeasureDataFile = "logs/" .. robot.id .. ".comm_dat"

-- argos functions -----------------------------------------------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create(myType)
	reset()
	os.execute("rm -f " .. timeMeasureDataFile)
end

--- reset
function reset()
	vns.reset(vns)
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	if vns.robotTypeS == "pipuck" then vns.idN = 0 end
	vns.setGene(vns, gene)

	vns.setMorphology(vns, gene)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns, option),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = "spring"}),
	}}
end

--- step
function step()
	local startTime = getCurrentTime()
	-- prestep
	-- log step
	if robot.id == "drone1" then
		if api.stepCount % 100 == 0 then
			logger("---- step ", api.stepCount, "-------------")
		end
	end

	--logger(robot.id, api.stepCount, "-----------------------")
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

	local endTime = getCurrentTime()
	local timeMeasure = endTime - startTime
	os.execute('echo ' .. tostring(timeMeasure) .. ' >> ' .. timeMeasureDataFile)
	local commMeasure = countMessage(vns.Msg.waitToSend)
	os.execute('echo ' .. tostring(commMeasure) .. ' >> ' .. commMeasureDataFile)
end

--- destroy
function destroy()
	api.destroy()
end

-- Analyze function -----
function getCurrentTime()
	local tmpfile = robot.id .. '_time_tmp.dat'

	os.execute('date +\"%s.%N\" > ' .. tmpfile)
	--os.execute('gdate +\"%s.%N\" > ' .. tmpfile) -- use gdate in mac

	local time
	local f = io.open(tmpfile)
	for line in f:lines() do
		time = tonumber(line)
	end
	f:close()
	return time
end

function countMessage(waitToSend)
	local count = 0
	for index, value in pairs(waitToSend) do
		if type(value) == "number" then
			count = count + 1
		elseif type(value) == "string" then
			count = count + 1
		elseif type(value) == "userdata" then
			count = count + 3
		elseif type(value) == "table" then
			count = count + countMessage(value)
		end
	end
	return count
end