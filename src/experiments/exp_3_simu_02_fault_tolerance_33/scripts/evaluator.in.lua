package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")

-- this is a hack of log reader for bugs
-- some good pipuck is marked as failed, they all have 0,0,0,0,0,0, 70, drone1
logReader.markFailedRobot = function(robotsData, endStep)
	for robotName, robotData in pairs(robotsData) do
		if robotData[endStep].targetID ~= 70 and
		   robotData[endStep].originGoalPositionV3:XYequ(robotData[endStep-1].originGoalPositionV3) == true and
		   robotData[endStep-1].originGoalPositionV3:XYequ(robotData[endStep-2].originGoalPositionV3) == true and
		   robotData[endStep-2].originGoalPositionV3:XYequ(robotData[endStep-3].originGoalPositionV3) == true and
		   robotData[endStep].originGoalOrientationQ == robotData[endStep-1].originGoalOrientationQ and
		   robotData[endStep-1].originGoalOrientationQ == robotData[endStep-2].originGoalOrientationQ and
		   robotData[endStep-2].originGoalOrientationQ == robotData[endStep-3].originGoalOrientationQ and
		   ((robotData[endStep].originGoalPositionV3 ~= vector3() 
		     and
		     robotData[endStep].originGoalOrientationQ ~= quaternion()
		    ) 
		    or 
		    robotData[endStep].brainID ~= robotName
		   ) then
			robotData[endStep].failed = true
			print(robotName, "failed at", endStep)
		end
	end
end

logger.enable()

require("morphologiesGenerator")

local droneDis = 1.5
local pipuckDis = 0.7
local height = 1.8
local structure1 = create_left_right_line_morphology(2, droneDis, pipuckDis, height)
local structure2 = create_back_line_morphology(4, droneDis, pipuckDis, height, vector3(), quaternion())
local structure3 = create_left_right_back_line_morphology(2, droneDis, pipuckDis, height)
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
local failureStep = 1000
local stage3Step = failureStep
if stage2Step > failureStep then
	stage3Step = stage2Step
	stage2Step = failureStep
end

local stage4Step = logReader.checkIDFirstAppearStep(robotsData, structure3.idN)

print("stage2 start at", stage2Step)
print("stage3 start at", stage3Step)
print("stage4 start at", stage4Step)

logReader.calcSegmentData(robotsData, geneIndex, 1, stage2Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step, stage4Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage4Step, nil)

lowerBoundParameters = {
	time_period = 0.2,
	default_speed = 0.1,
	slowdown_dis = 0.1,
	stop_dis = 0.01,
}

logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, 1, structure2Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, structure2Step, stage4Step - 1)
logReader.calcSegmentLowerBound(robotsData, geneIndex, lowerBoundParameters, stage4Step, nil)

logReader.calcSegmentLowerBoundErrorInc(robotsData, geneIndex)

logReader.saveMNSNumber(robotsData, "result_MNSNumber_data.txt")

logReader.saveData(robotsData, "result_data.txt")
logReader.saveDataAveragedBySwarmSize(robotsData, "result_data_averaged_by_focal_size.txt")
logReader.saveEachRobotData(robotsData, "result_each_robot_error", "error", "10.0")
logReader.saveEachRobotDataAveragedBySwarmSize(robotsData, "result_each_robot_error_averaged_by_focal_size")

logReader.saveData(robotsData, "result_lowerbound_data.txt", "lowerBoundError")
logReader.saveData(robotsData, "result_lowerbound_inc_data.txt", "lowerBoundInc")