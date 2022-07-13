package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local structure1 = require("morphologies/morphology1")
local structure2 = require("morphologies/morphology2")
local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		structure1, 
		structure2, 
	}
}
local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs")

logReader.calcSegmentData(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")