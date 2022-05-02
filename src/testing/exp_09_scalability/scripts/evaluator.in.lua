package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"

logger = require("Logger")
logReader = require("logReader")

require("morphologiesGenerator")

logger.enable()

local expScale = 4
local droneDis = 1.5
local pipuckDis = 0.7
local height = 1.8

local structure1 = create_left_right_line_morphology(expScale, droneDis, pipuckDis, height)
local structure2 = create_back_line_morphology(expScale * 2, droneDis, pipuckDis, height, vector3(), quaternion())
local structure3 = create_left_right_back_line_morphology(expScale, droneDis, pipuckDis, height)

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
logReader.calcSegmentData(robotsData, geneIndex, 1, stage2Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
logReader.calcSegmentData(robotsData, geneIndex, stage3Step, nil)
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

logReader.saveData(robotsData, "result_data.txt")
--logReader.saveData(robotsData, "result_lowerbound.txt", "lowerBoundError")