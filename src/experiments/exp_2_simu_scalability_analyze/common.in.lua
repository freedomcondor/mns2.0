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

function VNS.create_vns_core_node(vns, option)
	-- option = {
	--      connector_no_recruit = true or false or nil,
	--      connector_no_parent_ack = true or false or nil,
	--      specific_name = "drone1"
	--      specific_time = 150
	--          -- If I am stabilizer_preference_robot then ack to only drone1 for 150 steps
	-- }
	if option == nil then option = {} end
	if robot.id == vns.Parameters.stabilizer_preference_robot then
		option.specific_name = vns.Parameters.stabilizer_preference_brain
		option.specific_time = vns.Parameters.stabilizer_preference_brain_time
	end
	return 
	{type = "sequence", children = {
		--vns.create_preconnector_node(vns),
		function()           timeCoreStart = getCurrentTime() return false, true end,	
		vns.Connector.create_connector_node(vns, 
			{	no_recruit = option.connector_no_recruit,
				no_parent_ack = option.connector_no_parent_ack,
				specific_name = option.specific_name,
				specific_time = option.specific_time,
			}),
		function()  timeCoreAfterConnector = getCurrentTime() return false, true end,	
		vns.Assigner.create_assigner_node(vns),
		function()  timeCoreAfterAssigner  = getCurrentTime() return false, true end,	
		vns.ScaleManager.create_scalemanager_node(vns),
		function()  timeCoreAfterScalemanager  = getCurrentTime() return false, true end,	
		vns.Stabilizer.create_stabilizer_node(vns),
		function()  timeCoreAfterStabilizer = getCurrentTime() return false, true end,	
		vns.Allocator.create_allocator_node(vns),
		function()  timeCoreAfterAllocator = getCurrentTime() return false, true end,	
		vns.IntersectionDetector.create_intersectiondetector_node(vns),
		function()  timeCoreAfterIntersectiondetector = getCurrentTime() return false, true end,	
		vns.Avoider.create_avoider_node(vns, {
			drone_pipuck_avoidance = option.drone_pipuck_avoidance
		}),
		function()  timeCoreAfterAvoider = getCurrentTime() return false, true end,	
		vns.Spreader.create_spreader_node(vns),
		function()  timeCoreAfterSpreader = getCurrentTime() return false, true end,	
		vns.BrainKeeper.create_brainkeeper_node(vns),
		function()  timeCoreAfterBrainkeeper = getCurrentTime() return false, true end,	
		--vns.CollectiveSensor.create_collectivesensor_node(vns),
		--vns.Driver.create_driver_node(vns),
	}}
end

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
		function() timeAfterPre = getCurrentTime() return false, true end,
		vns.create_vns_core_node(vns, option),
		vns.CollectiveSensor.create_collectivesensor_node(vns),
		vns.Driver.create_driver_node(vns, {waiting = "spring"}),
	}}
end

--- step
function step()
	local timeStepStart = getCurrentTime()
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

	local timeAfterBT = getCurrentTime()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	local timeAfterPost = getCurrentTime()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)

	local timeStepEnd = getCurrentTime()

	local timeMeasurePre = timeAfterPre - timeStepStart
	local timeMeasureBT = timeAfterBT - timeAfterPre 
	local timeMeasurePost = timeAfterPost - timeAfterBT
	local timeMeasureEnd = timeStepEnd - timeAfterPost

	local timeMeasureCoreConnector = timeCoreAfterConnector - timeCoreStart
	local timeMeasureCoreAssigner = timeCoreAfterAssigner - timeCoreAfterConnector
	local timeMeasureCoreScalemanager = timeCoreAfterScalemanager - timeCoreAfterAssigner
	local timeMeasureCoreStabilizer = timeCoreAfterStabilizer - timeCoreAfterScalemanager
	local timeMeasureCoreAllocator = timeCoreAfterAllocator - timeCoreAfterStabilizer
	local timeMeasureCoreIntersectiondetector = timeCoreAfterIntersectiondetector - timeCoreAfterAllocator
	local timeMeasureCoreAvoider = timeCoreAfterAvoider - timeCoreAfterIntersectiondetector
	local timeMeasureCoreSpreader = timeCoreAfterSpreader - timeCoreAfterAvoider
	local timeMeasureCoreBrainkeeper = timeCoreAfterBrainkeeper- timeCoreAfterSpreader

	os.execute('echo ' .. tostring(timeMeasurePre)  .. ' ' ..
	                      tostring(timeMeasureBT)   .. ' ' ..
	                      tostring(timeMeasurePost) .. ' ' ..
	                      tostring(timeMeasureEnd)  .. ' ' ..

	                      tostring(timeMeasureCoreConnector)  .. ' ' ..
	                      tostring(timeMeasureCoreAssigner)  .. ' ' ..
	                      tostring(timeMeasureCoreScalemanager)  .. ' ' ..
	                      tostring(timeMeasureCoreStabilizer)  .. ' ' ..
	                      tostring(timeMeasureCoreAllocator)  .. ' ' ..
	                      tostring(timeMeasureCoreIntersectiondetector)  .. ' ' ..
	                      tostring(timeMeasureCoreAvoider)  .. ' ' ..
	                      tostring(timeMeasureCoreSpreader)  .. ' ' ..
	                      tostring(timeMeasureCoreBrainkeeper)  .. ' ' ..
	           ' >> ' .. timeMeasureDataFile
	          )
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