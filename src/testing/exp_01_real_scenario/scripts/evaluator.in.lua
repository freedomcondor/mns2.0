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

logReader.calcSegmentData(robotsData, geneIndex)
logReader.calcSegmentLowerBound(robotsData, geneIndex, 
	{
		time_period = 0.2;
		default_speed = 0.03;
		slowdown_dis = 0.35;
		stop_dis = 0.01;
	}
)


---[[
for robotName, robotData in pairs(robotsData) do
	print(robotName)
	for i, stepData in ipairs(robotData) do
		print("\t", stepData.lowerBoundError)
	end
end
--]]