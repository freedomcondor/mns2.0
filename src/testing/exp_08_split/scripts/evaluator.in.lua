package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local gene = require("morphology")
local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs")

logReader.calcSegmentData(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")