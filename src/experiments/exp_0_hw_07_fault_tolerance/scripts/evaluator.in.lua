package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
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
local structure2Step = stage2Step
local stage3Step = 500
if stage2Step > 500 then
	stage3Step = stage2Step
	stage2Step = 500
end

local stage4Step = logReader.checkIDFirstAppearStep(robotsData, structure3.idN, stage3Step)
local stage5Step = logReader.checkIDLastDisAppearStep(robotsData, structure1.idN)

print("stage2 start at", stage2Step)
print("stage3 start at", stage3Step)
print("stage4 start at", stage4Step)
print("stage5 start at", stage5Step)

logReader.calcSegmentData(robotsData, geneIndex, 1, stage2Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step, stage4Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage4Step, stage5Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage5Step, nil)

lowerBoundParameters = {
	time_period = 0.2,
	default_speed = 0.1,
	slowdown_dis = 0.1,
	stop_dis = 0.01,
}

logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, 1, structure2Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, structure2Step, stage4Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage4Step, stage5Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage5Step, nil)

logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex)

logReader.saveMNSNumber(robotsData, "result_MNSNumber_data.txt")

logReader.saveData(robotsData, "result_data.txt")
logReader.saveDataAveragedBySwarmSize(robotsData, "result_data_averaged_by_focal_size.txt")
logReader.saveEachRobotData(robotsData, "result_each_robot_error", "error", "3.0")
logReader.saveEachRobotDataAveragedBySwarmSize(robotsData, "result_each_robot_error_averaged_by_focal_size")

logReader.saveData(robotsData, "result_lowerbound_data.txt", "lowerBoundError")
logReader.saveData(robotsData, "result_lowerbound_inc_data.txt", "lowerBoundInc")