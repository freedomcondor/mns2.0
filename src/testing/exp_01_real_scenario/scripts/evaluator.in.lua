package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../?.lua"

logger = require("Logger")

logReader = require("logReader")
logger = require("logger")

logger.enable()

local gene = {
	robotTypeS = "drone",
	positionV3 = vector3(),
	orientationQ = quaternion(),
	children = {
		require("morphology1"),
		require("morphology2"),
		require("morphology3"),
	}
}

local robotsData = logReader.loadData("./logs")
local geneIndex = logReader.calcMorphID(gene)

logReader.calcDataSegment(robotsData, geneIndex)


---[[
for robotName, robotData in pairs(robotsData) do
	print(robotName)
	for i, stepData in ipairs(robotData) do
		print("\t", stepData.error)
	end
end
--]]