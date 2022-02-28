package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../files/?.lua"

logger = require("Logger")
logReader = require("logReader")
logger.enable()

local gene = require("01_morphology")
local geneIndex = logReader.calcMorphID(gene)

local robotsData = logReader.loadData("./logs_pkl", {"pipuck"})
--local robotsData = logReader.loadData("./logs", {"pipuck"})

logReader.calcSegmentData(robotsData, geneIndex)

logReader.saveData(robotsData, "result_data.txt")