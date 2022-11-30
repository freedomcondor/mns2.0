package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

structure1 = require("morphology1")
structure2 = require("morphology2")
structure3 = require("morphology3")

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
local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs")

local stage2Step = logReader.checkIDFirstAppearStep(robotsData, structure2.idN)
local stage3Step = logReader.checkIDFirstAppearStep(robotsData, structure3.idN)

lowerBoundParameters = {
	time_period = 0.2,
	default_speed = 0.1,
	slowdown_dis = 0.1,
	stop_dis = 0.01,
}

for i = 1, stage2Step - 1 do
	logReader.calcSegmentData(robotsData, geneIndex, i, i)
	logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, i, i)
end

logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage2Step, stage3Step - 1)

logReader.calcSegmentData(robotsData, geneIndex, stage3Step, nil)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage3Step, nil)
--[[
logReader.calcSegmentLowerBound(robotsData, geneIndex, 
	{
		time_period = 0.2;
		default_speed = 0.03;
		slowdown_dis = 0.35;
		stop_dis = 0.01;
	}
)
--]]

logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")
logReader.saveData(robotsData, "result_lowerbound_data.txt", "lowerBoundError")
logReader.saveData(robotsData, "result_lowerbound_inc_data.txt", "lowerBoundInc")
logReader.saveEachRobotData(robotsData, "result_each_robot_error")
logReader.saveEachRobotData(robotsData, "result_each_robot_lowerbound", "lowerBoundError")
logReader.saveEachRobotData(robotsData, "result_each_robot_lowerbound_inc_data", "lowerBoundInc")