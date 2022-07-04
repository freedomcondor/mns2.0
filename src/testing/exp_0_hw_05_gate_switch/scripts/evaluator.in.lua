package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

structure1 = require("morphologies/morphology1")
structure2 = require("morphologies/morphology2")
structure3 = require("morphologies/morphology3")

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

for i = 1, stage2Step - 1 do
	logReader.calcSegmentData(robotsData, geneIndex, i, i)
end

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