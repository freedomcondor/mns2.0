package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local gene = require("morphology")
local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs")

local endStep = logReader.getEndStep(robotsData)

logReader.calcSegmentData(robotsData, geneIndex, 1, 200)
for i = 201, 1200 do
	logReader.calcSegmentData(robotsData, geneIndex, i, i)
end
logReader.calcSegmentData(robotsData, geneIndex, 1201, endStep)

------------------------------------------------
lowerBoundParameters = {
	time_period = 0.2,
	default_speed = 0.1,
	slowdown_dis = 0.1,
	stop_dis = 0.01,
}

logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, 1, 200)
for i = 201, 1200 do
	logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, i, i)
end
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, 1201, endStep)

logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")
logReader.saveData(robotsData, "result_lowerbound_data.txt", "lowerBoundError")
logReader.saveData(robotsData, "result_lowerbound_inc_data.txt", "lowerBoundInc")
logReader.saveEachRobotData(robotsData, "result_each_robot_lowerbound_inc_data", "lowerBoundInc")
logReader.saveEachRobotData(robotsData, "result_each_robot_error")