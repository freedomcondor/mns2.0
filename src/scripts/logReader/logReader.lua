require("lfs")
vector3 = require('Vector3')
quaternion = require('Quaternion')

logReader = {}
function logReader.getCSVList(dir)
	local robotNameList = {}
	for file in lfs.dir(dir) do
		name, ext = string.match(file, "([^.]+).([^.]+)")
		if ext == "csv" then table.insert(robotNameList, name) end
	end
	return robotNameList
end

function logReader.readLine(str)
	local strList = {};
	string.gsub(str, '[^,]+', function(w) table.insert(strList, w) end);
	local th = tonumber(strList[8]) * math.pi / 180
	local stepData = {
		stepCount = tonumber(strList[1]),
		positionV3 = vector3(tonumber(strList[2]),
		                     tonumber(strList[3]),
		                     tonumber(strList[4])
		                    ),
		orientationQ = (quaternion(1,0,0, tonumber(strList[5]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[6]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[7]) * math.pi / 180)
		               ) *
		               (quaternion(1,0,0, tonumber(strList[8]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[9]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[10]) * math.pi / 180)
		               ),
		targetID = tonumber(strList[11]),
		brainID = strList[12],
	}
	return stepData
end

function logReader.loadData(dir)
	local robotNameList = logReader.getCSVList(dir)
	-- for each robot
	local robotsData = {}
	for i, robotName in ipairs(robotNameList) do
		-- open file
		local filename = dir .. "/" .. robotName .. ".csv"
		print("loading " .. filename)
		f = io.open(filename, "r")
		if f == nil then print("load file " .. filename .. "error") return end
		-- for each line
		robotData = {}
		for l in f:lines() do 
			table.insert(robotData, logReader.readLine(l)) 
		end
		-- close file
		io.close(f)
		robotsData[robotName] = robotData
		--[[
		for i, v in ipairs(robotData) do
			print("step", i)
			print("\tstepCount", v.stepCount)
			print("\tpositionV3", v.positionV3)
			print("\torientationQ", v.orientationQ)
			print("\ttargetID", v.targetID)
			print("\tbrainID", v.brainID)
		end
		--]]
	end
	return robotsData
end

return logReader