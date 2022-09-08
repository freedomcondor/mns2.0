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


logReader.saveData(robotsData, "result_data.txt")