package.path = package.path .. ";@CMAKE_SOURCE_DIR@/scripts/logReader/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/../simu/?.lua"

logger = require("Logger")
logReader = require("logReader")

require("morphologiesGenerator")

logger.enable()

------- formation evaluation -----------------------------------------------------------------------
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

logReader.calcSegmentData(robotsData, geneIndex)

--local stage2Step = logReader.checkIDFirstAppearStep(robotsData, structure2.idN)
--local stage3Step = logReader.checkIDFirstAppearStep(robotsData, structure3.idN)
--logReader.calcSegmentData(robotsData, geneIndex, 1, stage2Step - 1)
--logReader.calcSegmentData(robotsData, geneIndex, stage2Step, stage3Step - 1)
--logReader.calcSegmentData(robotsData, geneIndex, stage3Step, nil)
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

------- error and converge speed measure  -------------------------------------------------------------------
-- average error from the last 50 steps
function readDataInFile(file)
	local f = io.open(file, "r")
	local data = {}
	local length = 0
	for line in f:lines() do 
		table.insert(data, tonumber(line))
		length = length + 1
	end
	io.close(f)
	return data, length
end

function sumDataFromSteps(data, from, to)
	local sum = 0
	local count = 0
	for i = from, to do
		sum = sum + data[i]
		count = count + 1
	end
	return sum, count
end

function findDataStepBelowValue(data, fromStep, value)
	local i = fromStep
	while data[i] > value do
		i = i + 1
	end
	return i
end

local result_data, data_length = readDataInFile("result_data.txt")
local sum, count = sumDataFromSteps(result_data, data_length - 50, data_length)
local average_error = sum * 1.0 / count
local converge_step = findDataStepBelowValue(result_data, 100, average_error)
os.execute("echo " .. tostring(average_error) .. " " .. tostring(converge_step) .. " > result_formation_data.txt")

------- time and comm measure  ------------------------------------------------------------------------------
function getDataFileList(dir, data_ext)
	-- ls dir > fileList.txt and read fileList.txt
	-- so that we don't have to depend on lfs to get files in a dir
	os.execute("ls " .. dir .. " > fileList.txt")
	local f = io.open("fileList.txt", "r")
	local robotNameList = {}
	local robotNumber = 0
	for file in f:lines() do 
		-- drone11.log for example
		local name, ext = string.match(file, "([^.]+).([^.]+)")
		-- name = drone11, ext = log
		if ext == data_ext then 
			table.insert(robotNameList, file)
			robotNumber = robotNumber + 1
		end
	end
	io.close(f)
	os.execute("rm fileList.txt")
	return robotNameList, robotNumber
end

function sumDataInFile(fileName)
	local f = io.open(fileName, "r")
	local sum = 0
	local count = 0
	for line in f:lines() do
		local number = tonumber(line)
		sum = sum + number
		count = count + 1
	end
	io.close(f)
	return sum, count
end

function sumDataInFiles(folder, fileNameList)
	local total_sum = 0
	local total_count = 0
	for i, fileName in ipairs(fileNameList) do
		local sum, count = sumDataInFile(folder .. "/" .. fileName)
		total_sum = total_sum + sum
		total_count = total_count + count
	end
	return total_sum, total_count
end

----- time -----------
local time_file_list, robotNumber = getDataFileList("./logs", "time_dat")
local sum, count = sumDataInFiles("./logs", time_file_list)
local average = sum * 1.0 / count
os.execute("echo " .. tostring(robotNumber) .. " " .. tostring(average) .. " > result_time_data.txt")

----- comm -----------
local comm_file_list, robotNumber = getDataFileList("./logs", "comm_dat")
local sum, count = sumDataInFiles("./logs", comm_file_list)
local average = sum * 1.0 / count
os.execute("echo " .. tostring(robotNumber) .. " " .. tostring(average) .. " > result_comm_data.txt")