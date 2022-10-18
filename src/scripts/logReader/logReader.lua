--require("lfs")
vector3 = require('Vector3')
quaternion = require('Quaternion')

logReader = {}
function logReader.getCSVList(dir, typelist)
	-- create a typelist index
	-- from {"drone", "pipuck"} to {drone = true, pipuck = true}
	if typelist == nil then typelist = {"drone", "pipuck"} end
	local typelistIndex = {}
	for i, v in ipairs(typelist) do
		typelistIndex[v] = true
	end
	-- ls dir > fileList.txt and read fileList.txt
	-- so that we don't have to depend on lfs to get files in a dir
	os.execute("ls " .. dir .. " > fileList.txt")
	local f = io.open("fileList.txt", "r")
	local robotNameList = {}
	for file in f:lines() do 
		-- drone11.log for example
		local name, ext = string.match(file, "([^.]+).([^.]+)")
		-- name = drone11, ext = log
		local robot, number = string.match(name, "(%a+)(%d+)")
		-- robot = drone, number = 11
		if ext == "log" and typelistIndex[robot] == true then table.insert(robotNameList, name) end
	end
	io.close(f)
	os.execute("rm fileList.txt")
	return robotNameList
	--[[
	local robotNameList = {}
	for file in lfs.dir(dir) do
		name, ext = string.match(file, "([^.]+).([^.]+)")
		if ext == "csv" then table.insert(robotNameList, name) end
	end
	return robotNameList
	--]]
end

function logReader.readLine(str)
	-- read line and return a structure table
	local strList = {};
	string.gsub(str, '[^,]+', function(w) table.insert(strList, w) end);
	local stepData = {
		--stepCount = tonumber(strList[1]),
		positionV3 = vector3(tonumber(strList[1]),
		                     tonumber(strList[2]),
		                     tonumber(strList[3])
		                    ),
		-- order of euler angles are z, y, x
		orientationQ = (quaternion(1,0,0, tonumber(strList[6]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[5]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[4]) * math.pi / 180)
		               ) *
		               (quaternion(1,0,0, tonumber(strList[9]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[8]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[7]) * math.pi / 180)
		               ),
		goalPositionV3 = vector3(tonumber(strList[10]),
		                         tonumber(strList[11]),
		                         tonumber(strList[12])
		                        ),
		goalOrientationQ = (quaternion(1,0,0, (tonumber(strList[15]) or 0) * math.pi / 180) *
		                    quaternion(0,1,0, (tonumber(strList[14]) or 0) * math.pi / 180) *
		                    quaternion(0,0,1, (tonumber(strList[13]) or 0) * math.pi / 180)
		                   ),
		targetID = tonumber(strList[16]),
		brainID = strList[17],
	}
	stepData.goalPositionV3 = stepData.positionV3 + stepData.orientationQ:toRotate(stepData.goalPositionV3)
	stepData.goalOrientationQ = stepData.orientationQ * stepData.goalOrientationQ
	return stepData
end

function logReader.loadData(dir, typelist)
	-- read typelist example: {"drone", "pipuck"}
	-- read all drone*.log and pipuck*.log files, and return a table
	-- {
	--      drone1 = {
	--                  1 = {stepCount, positionV3 ...}
	--                  2 = {stepCount, positionV3 ...}
	--               }
	--      drone2 = { 
	--                  1 = {stepCount, positionV3 ...}
	--                  2 = {stepCount, positionV3 ...}
	--               }
	-- } 
	--
	local robotNameList = logReader.getCSVList(dir, typelist)
	-- for each robot
	local robotsData = {}
	for i, robotName in ipairs(robotNameList) do
		-- open file
		local filename = dir .. "/" .. robotName .. ".log"
		--print("loading " .. filename)
		local f = io.open(filename, "r")
		if f == nil then print("load file " .. filename .. " error") return end
		-- for each line
		robotData = {}
		--count = 0
		for l in f:lines() do 
			--count = count + 1
			--print("reading line", count)
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
	print("load data finish")
	return robotsData
end

function logReader.getEndStep(robotsData)
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	return length
end

function logReader.smoothRobotData(stepTable, window)
	--stepTable = {
	--      1 = {positionV3, orientationQ, goalPositionV3, goalOrientationQ}
	--      2 = {positionV3, orientationQ, goalPositionV3, goalOrientationQ}
	--}
	local smoothedData = {}
	local posAcc = vector3(0,0,0)
	local posAcc_n = 0
	local goalAcc = vector3(0,0,0)
	local goalAcc_n = 0
	for i, stepData in ipairs(stepTable) do
		smoothedData[i] = {
			orientationQ     = quaternion(stepTable[i].orientationQ),
			goalOrientationQ = quaternion(stepTable[i].goalOrientationQ),
			targetID = stepTable[i].targetID,
			brainID  = stepTable[i].brainID,
		}

		posAcc  = posAcc  + stepTable[i].positionV3
		goalAcc = goalAcc + stepTable[i].goalPositionV3
		posAcc_n  = posAcc_n  + 1
		goalAcc_n = goalAcc_n + 1

		if i - window > 0 then
			posAcc  = posAcc  - stepTable[i - window].positionV3
			goalAcc = goalAcc - stepTable[i - window].goalPositionV3
			posAcc_n  = posAcc_n  - 1
			goalAcc_n = goalAcc_n - 1
		end

		smoothedData[i].positionV3     = posAcc  * (1.0 / posAcc_n)
		smoothedData[i].goalPositionV3 = goalAcc * (1.0 / goalAcc_n)
	end
	return smoothedData
end

function logReader.smoothData(robotsData, window)
	for robotName, stepTable in pairs(robotsData) do
		robotsData[robotName] = logReader.smoothRobotData(stepTable, window)
		logger(robotName)
		logger(robotsData[robotName][1])
	end
end

function logReader.calcSegmentData(robotsData, geneIndex, startStep, endStep)
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		endStep = logReader.getEndStep(robotsData)
	end

	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			local brainName = robotData[endStep].brainID
			local brainData = robotsData[brainName]

			-- the predator, targetID == nil, consider its error is always 0
			local targetRelativePositionV3 = geneIndex[robotData[endStep].targetID or 1].globalPositionV3
			--local targetGlobalPositionV3 = brainData[step].positionV3 +
			--                               brainData[step].orientationQ:toRotate(targetRelativePositionV3)
			local targetGlobalPositionV3 = brainData[step].goalPositionV3 +
			                               brainData[step].goalOrientationQ:toRotate(targetRelativePositionV3)
			local disV3 = targetGlobalPositionV3 - robotData[step].positionV3
			--local disV3 = targetGlobalPositionV3 - robotData[step].goalPositionV3
			disV3.z = 0
			robotData[step].error = disV3:len()
			--[[
			if step == endStep then
				print("robotName = ", robotName)
				print("brainPosition = ", brainData[step].positionV3)
				print("brainOrientationQ = X", brainData[step].orientationQ:toRotate(vector3(1,0,0)))
				print("                    Y", brainData[step].orientationQ:toRotate(vector3(0,1,0)))
				print("                    Z", brainData[step].orientationQ:toRotate(vector3(0,0,1)))
				print("targetRelativePositionV3 = ", targetRelativePositionV3)
				print("targetGlobalPositionV3 = ", targetGlobalPositionV3)
				print("myPosition = ", robotData[step].positionV3)
				print("disV3 = ", disV3)
				print("dis = ", disV3:len())
			end
			--]]
		end
	end
	print("calcSegmentData finish")
end

function logReader.calcSegmentLowerBound(robotsData, geneIndex, parameters, startStep, endStep)
	local time_period = parameters.time_period;
	local default_speed = parameters.default_speed;
	local slowdown_dis = parameters.slowdown_dis;
	local stop_dis = parameters.stop_dis;
	-- fill start and end if not provided
	if startStep == nil then startStep = 1 end
	if endStep == nil then 
		local length
		for robotName, stepTable in pairs(robotsData) do
			length = #stepTable
			break
		end
		endStep = length
	end

	for step = startStep, endStep do
		for robotName, robotData in pairs(robotsData) do
			if step == startStep then
				robotData[step].lowerBoundError = robotData[step].error
			else
				local lowerBoundDis = robotData[step-1].lowerBoundError
				local speed = default_speed;
				if lowerBoundDis < stop_dis then
					speed = 0;
				elseif lowerBoundDis < slowdown_dis then
					speed = default_speed * lowerBoundDis / slowdown_dis;
				end

				if lowerBoundDis > 0 then
					lowerBoundDis = lowerBoundDis - time_period * speed;
				end
				robotData[step].lowerBoundError = lowerBoundDis
			end
		end
	end
end

function logReader.saveData(robotsData, saveFile, attribute)
	if attribute == nil then attribute = 'error' end
	-- fill start and end if not provided
	local startStep = 1
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end
	local endStep = length

	local f = io.open(saveFile, "w")
	for step = startStep, endStep do
		local error = 0
		local n = 0
		for robotName, robotData in pairs(robotsData) do
			error = error + robotData[step][attribute]
			n = n + 1
		end
		error = error / n
		f:write(tostring(error).."\n")
	end
	io.close(f)
	print("save data finish")
end

------------------------------------------------------------------------
-- to fill each node in the gene with an id and its global position
--   input:  gene =   drone         output:  gene = drone id=1, globalPosition=xx
--                    /   \                         /   \
--                   /     \                       /     \
--               pipuck   drone                pipuck 2  drone 3
--
--   geneIndex = [1, 2, 3] pointing to matching branch
function logReader.calcMorphID(gene)
	local globalContainer = {id = 0}
	local geneIndex = {}
	gene.globalPositionV3 = vector3()
	gene.globalOrientationQ = quaternion()
	logReader.calcMorphChildrenID(gene, globalContainer, geneIndex)

	-- sometimes a robot may have -1 as target
	geneIndex[-1] = {
		globalPositionV3 = vector3(),
		globalOrientationQ = quaternion(),
	}

	return geneIndex
end

function logReader.calcMorphChildrenID(morph, globalContainer, geneIndex)
	globalContainer.id = globalContainer.id + 1
	morph.idN = globalContainer.id
	geneIndex[morph.idN] = morph

	if morph.children ~= nil then
		for i, child in ipairs(morph.children) do
			child.globalPositionV3 = morph.globalPositionV3 + morph.globalOrientationQ:toRotate(child.positionV3)
			child.globalOrientationQ = morph.globalOrientationQ * child.orientationQ
			logReader.calcMorphChildrenID(child, globalContainer, geneIndex)
		end
	end
end

function logReader.checkIDFirstAppearStep(robotsData, ID, startStep, specificRobotName)
	-- get end step
	local length
	for robotName, stepTable in pairs(robotsData) do
		length = #stepTable
		break
	end

	if startStep == nil then startStep = 1 end
	for i = startStep, length do
		for robotName, robotData in pairs(robotsData) do
			if robotData[i].targetID == ID then
				if specificRobotName == nil or specificRobotName == robotName then
					return i, robotName
				end
			end
		end
	end

	return length
end
------------------------------------------------------------------------

return logReader