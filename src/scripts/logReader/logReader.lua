--require("lfs")
vector3 = require('Vector3')
quaternion = require('Quaternion')

logReader = {}
function logReader.getCSVList(dir)
	-- ls dir > fileList.txt and read fileList.txt
	-- so that we don't have to depend on lfs to get files in a dir
	os.execute("ls " .. dir .. " > fileList.txt")
	local f = io.open("fileList.txt", "r")
	local robotNameList = {}
	for file in f:lines() do 
		name, ext = string.match(file, "([^.]+).([^.]+)")
		if ext == "csv" then table.insert(robotNameList, name) end
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
		stepCount = tonumber(strList[1]),
		positionV3 = vector3(tonumber(strList[2]),
		                     tonumber(strList[3]),
		                     tonumber(strList[4])
		                    ),
		-- order of euler angles are z, y, x
		orientationQ = (quaternion(1,0,0, tonumber(strList[7]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[6]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[5]) * math.pi / 180)
		               ) *
		               (quaternion(1,0,0, tonumber(strList[10]) * math.pi / 180) *
		                quaternion(0,1,0, tonumber(strList[9]) * math.pi / 180) *
		                quaternion(0,0,1, tonumber(strList[8]) * math.pi / 180)
		               ),
		targetID = tonumber(strList[11]),
		brainID = strList[12],
	}
	return stepData
end

function logReader.loadData(dir)
	-- read all .csvs, and returns a table
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
	local robotNameList = logReader.getCSVList(dir)
	-- for each robot
	local robotsData = {}
	for i, robotName in ipairs(robotNameList) do
		-- open file
		local filename = dir .. "/" .. robotName .. ".csv"
		print("loading " .. filename)
		local f = io.open(filename, "r")
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
	print("load data finish")
	return robotsData
end

function logReader.calcSegmentData(robotsData, geneIndex, startStep, endStep)
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
			local brainName = robotData[endStep].brainID
			local brainData = robotsData[brainName]

			-- the predator, targetID == nil, consider its error is always 0
			local targetRelativePositionV3 = geneIndex[robotData[endStep].targetID or 1].globalPositionV3
			local targetGlobalPositionV3 = brainData[step].positionV3 + 
			                               brainData[step].orientationQ:toRotate(targetRelativePositionV3)
			local disV3 = targetGlobalPositionV3 - robotData[step].positionV3
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
end

function logReader.calcMorphID(gene)
	local globalContainer = {id = 0}
	local geneIndex = {}
	gene.globalPositionV3 = vector3()
	gene.globalOrientationQ = quaternion()
	logReader.calcMorphChildrenID(gene, globalContainer, geneIndex)

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

return logReader