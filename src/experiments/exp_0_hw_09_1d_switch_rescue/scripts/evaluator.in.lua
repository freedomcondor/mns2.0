package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
local structure4 = require("morphology4")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
		structure3,
		structure4,
	}
}

local geneIndex = logReader.calcMorphID(gene)

--local robotsData = logReader.loadData("./logs")  -- for simulation
local robotsData = logReader.loadData("./logs_pkl")  -- for hardware

local stage2Step = logReader.checkIDFirstAppearStep(robotsData, structure2.idN, nil)
local stage3Step = logReader.checkIDFirstAppearStep(robotsData, structure3.idN, nil)
local stage4Step = logReader.checkIDFirstAppearStep(robotsData, structure4.idN, nil)
local stage5Step = logReader.checkIDFirstAppearStep(robotsData, structure1.idN, stage4Step)

print("stage2 start at", stage2Step)
print("stage3 start at", stage3Step)
print("stage4 start at", stage4Step)
print("stage5 start at", stage5Step)

logReader.calcSegmentData(robotsData, geneIndex, 1, stage2Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step, stage4Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage4Step, stage5Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage5Step, nil)

------------------------------------------------------------------------
lowerBoundParameters = {
	time_period = 0.2,
	default_speed = 0.1,
	slowdown_dis = 0.1,
	stop_dis = 0.01,
}

logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, 1, stage2Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage2Step, stage3Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage3Step, stage4Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage4Step, stage5Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage5Step, nil)

logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")
logReader.saveData(robotsData, "result_lowerbound_data.txt", "lowerBoundError")
logReader.saveData(robotsData, "result_lowerbound_inc_data.txt", "lowerBoundInc")
logReader.saveEachRobotData(robotsData, "result_each_robot_lowerbound_inc_data", "lowerBoundInc")
logReader.saveEachRobotData(robotsData, "result_each_robot_error")