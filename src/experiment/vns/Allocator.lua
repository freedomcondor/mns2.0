-- Allocator -----------------------------------------
------------------------------------------------------
--local Arrangement = require("Arrangement")
local MinCostFlowNetwork = require("MinCostFlowNetwork")
local DeepCopy = require("DeepCopy")
local BaseNumber = require("BaseNumber")

local Allocator = {}

--[[
--	related data
--	vns.allocator.target
--	vns.allocator.gene
--]]

function Allocator.create(vns)
	vns.allocator = {}
end

function Allocator.reset(vns)
	vns.allocator = {}
end

function Allocator.addChild(vns)
end

function Allocator.deleteChild(vns)
end

function Allocator.addParent(vns)
end

function Allocator.deleteParent(vns)
	--vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.setGene(vns, morph)
	vns.allocator.morphIdCount = 0
	vns.allocator.gene_index = {}
	Allocator.calcMorphScale(vns, morph)
	vns.allocator.gene = morph
	vns.Allocator.setMorphology(vns, morph)
end

function Allocator.setMorphology(vns, morph)
	if morph ~= nil and morph.robotTypeS ~= vns.robotTypeS then morph = nil end
	vns.allocator.target = morph
end

function Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.preStep(vns)
	for idS, childR in pairs(vns.childrenRT) do
		childR.allocated_in_multi_branch = nil
		childR.match = nil
	end
	if vns.allocator.target ~= nil and vns.allocator.target.children ~= nil then
		for _, branch in pairs(vns.allocator.target.children) do
			branch.match = nil
		end
	end
end

function Allocator.step(vns)
	--local safezone = false
	-- check if I just assigned children to my parent
	if vns.parentR ~= nil and vns.parentR.scale_assign_offset:totalNumber() ~= 0 then
		return
	end
	-- receive branch
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branch")) do
		if msgM.dataT.branch.idN > 0 then
			msgM.dataT.branch.children = DeepCopy(vns.allocator.gene_index[msgM.dataT.branch.idN].children)
		end
		Allocator.setMorphology(vns, msgM.dataT.branch)

		-- don't go too faraway from the parent
		--[[
		if safezone == true then
			local safezone_half_pipuck = 0.9
			local safezone_half_drone = 1.35
			local safezone_half = safezone_half_pipuck
			if vns.robotTypeS == "drone" and vns.parentR.robotTypes == "drone" then
				local safezone_half = safezone_half_drone
			end
			if msgM.dataT.branch.positionV3.x < -safezone_half then
				msgM.dataT.branch.positionV3.x = -safezone_half
			elseif msgM.dataT.branch.positionV3.x > safezone_half then
				msgM.dataT.branch.positionV3.x = safezone_half
			end
			if msgM.dataT.branch.positionV3.y < -safezone_half then
				msgM.dataT.branch.positionV3.y = -safezone_half
			elseif msgM.dataT.branch.positionV3.y > safezone_half then
				msgM.dataT.branch.positionV3.y = safezone_half
			end
		end
		--]]

		local targetPositionV3 = vns.parentR.positionV3 +
			vector3(msgM.dataT.branch.positionV3):rotate(vns.parentR.orientationQ)
		local targetOrientationQ = vns.parentR.orientationQ * msgM.dataT.branch.orientationQ 
	
		vns.goal.positionV3 = targetPositionV3
		vns.goal.orientationQ = targetOrientationQ

		if vns.allocator.target.children ~= nil then
			for _, branchR in ipairs(vns.allocator.target.children) do
				branchR.positionV3_backup = vector3(branchR.positionV3)
				branchR.orientationQ_backup = quaternion(branchR.orientationQ)
				branchR.positionV3 = vector3(branchR.positionV3):rotate(vns.goal.orientationQ) + vns.goal.positionV3
				branchR.orientationQ = vns.goal.orientationQ * branchR.orientationQ 
				---[[
				if vns.robotTypeS == "drone" and branchR.robotTypeS == "pipuck" and 
				   branchR.positionV3:length() > 1.0 then
					branchR.positionV3 = branchR.positionV3_backup
					branchR.orientationQ = branchR.orientationQ_backup
				end
				--]]
			end
		end

		-- check hand up children
		-- if a children is in a better position than me, hand it up.
		local n_vector = targetPositionV3 - vns.parentR.positionV3
		n_vector.z = 0
		for idS, childR in pairs(vns.childrenRT) do
			if childR.robotTypeS == vns.robotTypeS and
			   (childR.positionV3 - vns.parentR.positionV3):dot(n_vector) <
			   (vector3() - vns.parentR.positionV3):dot(n_vector) then
				childR.match = {idN = -3}
				vns.Msg.send(idS, "branch", 
					{branch = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(targetPositionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(targetOrientationQ),
						--children = targetList[j].index.children,
						scale = msgM.dataT.branch.scale, 
						idN = msgM.dataT.branch.idN,
						robotTypeS = msgM.dataT.branch.robotTypeS,
					}}	
				)	
			end
		end
	end end

	-- receive branches
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "multiple-branch")) do
		local branches = msgM.dataT.branches
		for i, branch in ipairs(branches) do
			if branch.idN > 0 then
				branch.children = DeepCopy(vns.allocator.gene_index[branch.idN].children)
			end

			-- don't go too faraway from the parent
			--[[
			if safezone == true then
				local safezone_half_pipuck = 0.9
				local safezone_half_drone = 1.35
				local safezone_half = safezone_half_pipuck
				if vns.robotTypeS == "drone" and vns.parentR.robotTypes == "drone" then
					local safezone_half = safezone_half_drone
				end
				if branch.positionV3.x < -safezone_half then
					branch.positionV3.x = -safezone_half
				elseif branch.positionV3.x > safezone_half then
					branch.positionV3.x = safezone_half
				end
				if branch.positionV3.y < -safezone_half then
					branch.positionV3.y = -safezone_half
				elseif branch.positionV3.y > safezone_half then
					branch.positionV3.y = safezone_half
				end
			end
			--]]

			local targetPositionV3 = vns.parentR.positionV3 +
				vector3(branch.positionV3):rotate(vns.parentR.orientationQ)
			local targetOrientationQ = vns.parentR.orientationQ * branch.orientationQ

			branch.positionV3 = targetPositionV3
			branch.orientationQ = targetOrientationQ

			if branch.children ~= nil then
				for _, branch_childR in ipairs(branch.children) do
					branch_childR.positionV3_backup = vector3(branch_childR.positionV3)
					branch_childR.orientationQ_backup = quaternion(branch_childR.orientationQ)
					branch_childR.positionV3 = vector3(branch_childR.positionV3):rotate(branch.orientationQ) + branch.positionV3
					branch_childR.orientationQ = branch.orientationQ * branch_childR.orientationQ 

					---[[
					if vns.robotTypeS == "drone" and branch_childR.robotTypeS == "pipuck" and 
					branch_childR.positionV3:length() > 1.0 then
						branch_childR.positionV3 = branch_childR.positionV3_backup
						branch_childR.orientationQ = branch_childR.orientationQ_backup
					end
					--]]
				end
			end
		end
		Allocator.multi_branch_allocate(vns, branches)
	end end

	-- by now, I should have received a branch (or multi-branch decided I should be reporting up), either from branch or chosen from multiple-branch
	-- from multiple branches, 
	-- if I get my branch from multiple branches, all of my children should have a match
	--    if match.idN = -1 then this child should be hand up to my parent
	--    if match.idN doesn't matches my branch then this child should be hand up to my parent
	--    if match.idN matches my branch then keep it for later allocation
	-- all handed up children is marked with allocated_in_multi_branch
	local mybranchidN = nil
	if vns.allocator.target ~= nil then
		mybranchidN = vns.allocator.target.idN
	end
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.match ~= nil and robotR.match.idN ~= mybranchidN then
			-- this is a hand up child
			robotR.allocated_in_multi_branch = true
			vns.Assigner.assign(vns, idS, vns.parentR.idS)	
			--robotR.goal.positionV3 = robotR.match.positionV3
			--robotR.goal.orientationQ = robotR.match.orientationQ
			robotR.goal.positionV3 = vns.parentR.positionV3
			robotR.goal.orientationQ = vns.parentR.orientationQ
		end
	end

	-- allocate the rest children
	Allocator.allocate(vns)

	-- everyone expect for allocated_in_multi_branch (handing up) should have a match
	-- check inter types assign
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.match ~= nil and robotR.allocated_in_multi_branch ~= true then
			local assignToidS = robotR.match.match

			-- check child cross
			--[[
			local cross_flag = false
			if vns.parentR ~= nil and vns.goal.positionV3 ~= nil and robotR.robotTypeS == vns.robotTypeS then
				local distance_now = (robotR.match.positionV3 - robotR.positionV3):length()
				if vns.goal.positionV3:length() > distance_now then 
					distance_now = vns.goal.positionV3:length()
				end
				local distance_reverse = (vns.goal.positionV3 - robotR.positionV3):length()
				if robotR.match.positionV3:length() > distance_reverse then
					 distance_reverse = robotR.match.positionV3:length()
				end
				local parent_to_target_normalize = 
					((vns.goal.positionV3 or vector3()) - vns.parentR.positionV3):normalize()
				local parent_to_me = - vns.parentR.positionV3
				local parent_to_child = robotR.positionV3 - vns.parentR.positionV3
				if distance_now > distance_reverse then
					robotR.goal.positionV3 = vns.parentR.positionV3
					robotR.goal.orientationQ = vns.parentR.orientationQ
					cross_flag = true
					if parent_to_me:dot(parent_to_target_normalize) > 
					   parent_to_child:dot(parent_to_target_normalize) then
						assignToidS = vns.parentR.idS
					end
				end
			end
			--]]

			if assignToidS ~= idS and 
			   ((vns.parentR ~= nil and vns.parentR.idS == assignToidS) or
			    (vns.childrenRT[assignToidS] ~= nil)
			   ) then
				vns.Assigner.assign(vns, idS, assignToidS)	
			end
			robotR.goal.positionV3 = robotR.match.positionV3
			robotR.goal.orientationQ = robotR.match.orientationQ
		end
	end
end

function Allocator.multi_branch_allocate(vns, branches)
	local sourceList = {}
	-- create sources from myself
	local tempScale = vns.ScaleManager.Scale:new()
	tempScale:inc(vns.robotTypeS)
	sourceList[#sourceList + 1] = {
		number = tempScale,
		index = {
			positionV3 = vector3(),
			robotTypeS = vns.robotTypeS,
		},
	}

	-- create sources from children
	for idS, robotR in pairs(vns.childrenRT) do
		sourceList[#sourceList + 1] = {
			number = robotR.scale,
			index = robotR,
		}
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	for _, branchR in ipairs(branches) do
		targetList[#targetList + 1] = {
			--number = branchR.scale[allocating_type],
			number = vns.ScaleManager.Scale:new(branchR.number),
			index = branchR
		}
	end

	-- create a cost matrix
	local originCost = {}
	for i = 1, #sourceList do originCost[i] = {} end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			local targetPosition = vector3(targetList[j].index.positionV3)
			local relativeVector = sourceList[i].index.positionV3 - targetPosition
			relativeVector.z = 0
			originCost[i][j] = relativeVector:length()
			--[[
			if sourceList[i].index.robotTypeS ~= targetList[j].index.robotTypeS then
				originCost[i][j] = originCost[i][j] + 00000
			end
			--]]
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")

	--[[
--if robot.id == "drone24" or robot.id == "pipuck2" then
	logger("multi-sourceList")
	for i, source in ipairs(sourceList) do
		logger(i)
		logger(source, 1, "index")
		logger("\tid = ", source.index.idS or source.index.idN)
		logger("\tposition = ", source.index.positionV3)
	end
	logger("multi-targetList")
	for i, target in ipairs(targetList) do
		logger(i)
		logger(target, 1, "index")
		logger("\tid = ", target.index.idS or target.index.idN)
		logger("\tposition = ", target.index.positionV3)
	end
	logger("cost")
	logger(originCost)
--end
	--]]

	-- mark children
	for i = 1, #sourceList do
		-- zero target case, I keep this child, don't mark it
		-- one target case 
		if #(sourceList[i].to) == 1 then
			sourceList[i].index.match = targetList[sourceList[i].to[1].target].index
		-- more target case
		elseif  #(sourceList[i].to) > 1 then
			sourceList[i].index.match = {
				idN = -1,
				positionV3 = vns.parentR.positionV3,
				orientationQ = vns.parentR.orientationQ,
			}
		end
	end

	-- set myself branch if I'm the right type
	if sourceList[1].to[1] ~= nil then
		Allocator.setMorphology(vns, targetList[sourceList[1].to[1].target].index)
		vns.goal.positionV3 = targetList[sourceList[1].to[1].target].index.positionV3
		vns.goal.orientationQ = targetList[sourceList[1].to[1].target].index.orientationQ
	end
end

function Allocator.allocate(vns)
	-- create sources from children
	local sourceList = {}
	local sourceSum = vns.ScaleManager.Scale:new()
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.allocated_in_multi_branch == nil then
			sourceList[#sourceList + 1] = {
				number = robotR.scale,
				index = robotR,
			}
			sourceSum = sourceSum + robotR.scale
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branch
	local targetList = {}
	local targetSum = vns.ScaleManager.Scale:new()
	if vns.allocator.target ~= nil and vns.allocator.target.children ~= nil then
		for _, branchR in ipairs(vns.allocator.target.children) do
			targetList[#targetList + 1] = {
				number = branchR.scale,
				index = branchR,
			}
			targetSum = targetSum + branchR.scale
		end
	end

	-- add parent as a target
	local diffSum = sourceSum - targetSum
	for i, v in pairs(diffSum) do
		if diffSum[i] ~= nil and diffSum[i] < 0 then
			diffSum[i] = 0
		end
	end
	if diffSum:totalNumber() > 0 and vns.parentR ~= nil then
		targetList[#targetList + 1] = {
			number = diffSum,
			index = {
				idN = -1,
				positionV3 = vns.parentR.positionV3,
				orientationQ = vns.parentR.orientationQ,
				scale = parentScale,
			}
		}
	elseif diffSum:totalNumber() > 0 and vns.parentR == nil then
		targetList[#targetList + 1] = {
			number = diffSum,
			index = {
				idN = -2,
				positionV3 = vector3(),
				orientationQ = quaternion(),
				scale = parentScale,
			}
		}
	end

	-- create a cost matrix
	local originCost = {}
	for i = 1, #sourceList do originCost[i] = {} end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			local targetPosition = vector3(targetList[j].index.positionV3)
			local relativeVector = sourceList[i].index.positionV3 - targetPosition
			relativeVector.z = 0
			originCost[i][j] = relativeVector:length()
			--[[
			if sourceList[i].index.robotTypeS ~= targetList[j].index.robotTypeS then
				originCost[i][j] = originCost[i][j] + 00000
			end
			--]]
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")

	--[[
--if robot.id == "drone2" then
	logger("sourceList")
	for i, source in ipairs(sourceList) do
		logger(i)
		logger(source, 1, "index")
		logger("\tid = ", source.index.idS or source.index.idN)
		logger("\tposition = ", source.index.positionV3)
	end
	logger("targetList")
	for i, target in ipairs(targetList) do
		logger(i)
		logger(target, 1, "index")
		logger("\tid = ", target.index.idS or target.index.idN)
		logger("\tposition = ", target.index.positionV3)
	end
--end
	--]]

	-- multiple (including one) sources to one target
	for j = 1, #targetList do
		-- mark match all single target child with the branch (match = branch)
		for _, fromTable in ipairs(targetList[j].from) do
			if #(sourceList[fromTable.source].to) == 1 then
				sourceList[fromTable.source].index.match = targetList[j].index
			end
		end

		-- mark match all target with the source (or a virtual parent/self robot)
		if targetList[j].index.idN == -1 then targetList[j].index.match = vns.parentR.idS end
		if targetList[j].index.idN == -2 then targetList[j].index.match = {
			idS = vns.idS,
			positionV3 = vector3(),
			orientationQ = quaternion(),
		} end
		-- find the farthest same type source to target j
		local farthestDis = -math.huge
		local farthestI = nil
		for _, fromTable in ipairs(targetList[j].from) do
			if #(sourceList[fromTable.source].to) == 1 and
			   sourceList[fromTable.source].index.robotTypeS == targetList[j].index.robotTypeS then
				local me_to_robot = vector3(sourceList[fromTable.source].index.positionV3)
				local me_to_target = vector3(targetList[j].index.positionV3)
				me_to_robot.z = 0
				me_to_target.z = 0
				local dis = -me_to_robot:dot(me_to_target:normalize())
				--local dis = (sourceList[fromTable.source].index.positionV3 - 
				--			 targetList[j].index.positionV3):length()
				if dis > farthestDis then
					farthestDis = dis
					farthestI = fromTable.source
				end
				vns.Msg.send(sourceList[fromTable.source].index.idS, "branch", 
					{branch = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(targetList[j].index.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(targetList[j].index.orientationQ),
						--children = targetList[j].index.children,
						scale = targetList[j].index.scale, 
						idN = targetList[j].index.idN,
						robotTypeS = targetList[j].index.robotTypeS,
					}}	
				)
			end
		end
		-- if I find one
		if farthestI ~= nil then
			-- mark the farthest match from source to target
			targetList[j].index.match = sourceList[farthestI].index.idS
			-- send branch to the farthest source
			vns.Assigner.assign(vns, sourceList[farthestI].index.idS, nil)
			--[[
			vns.Msg.send(sourceList[farthestI].index.idS, "branch", 
				{branch = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(targetList[j].index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(targetList[j].index.orientationQ),
					--children = targetList[j].index.children,
					scale = targetList[j].index.scale, 
					idN = targetList[j].index.idN,
					robotTypeS = targetList[j].index.robotTypeS,
				}}	
			)
			--]]
		end
	end

	-- one source to multiple targets case
	for i = 1, #sourceList do
		if #(sourceList[i].to) > 1 then
		   --sourceList[i].index.robotTypeS == allocating_type then
			local branches = {}
			for j = 1, #(sourceList[i].to) do
				local branch = targetList[sourceList[i].to[j].target].index
				branches[#branches + 1] = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(branch.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(branch.orientationQ),
					--children = branch.children,
					scale = branch.scale,
					idN = branch.idN,
					number = sourceList[i].to[j].number,
					robotTypeS = branch.robotTypeS,
				}
			end
			vns.Assigner.assign(vns, sourceList[i].index.idS, nil)
			vns.Msg.send(sourceList[i].index.idS, "multiple-branch", {branches = branches, robotTypeS = allocating_type})
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.GraphMatch(sourceList, targetList, originCost, type)
	-- create a enhanced cost matrix
	-- and orderlist, to sort everything in originCost
	local orderList = {}
	local count = 0
	for i = 1, #sourceList do
		for j = 1, #targetList do
			count = count + 1
			orderList[count] = originCost[i][j]
		end
	end

	-- sort orderlist
	for i = 1, #orderList - 1 do
		for j = i + 1, #orderList do
			if orderList[i] > orderList[j] then
				local temp = orderList[i]
				orderList[i] = orderList[j]
				orderList[j] = temp
			end
		end
	end

	-- calculate sum for sourceList
	local sourceSum = 0
	for i = 1, #sourceList do
		sourceSum = sourceSum + (sourceList[i].number[type] or 0)
	end
	-- create a reverse index
	local reverseIndex = {}
	for i = 1, #orderList do reverseIndex[orderList[i]] = i end
	-- create an enhanced cost matrix
	local cost = {}
	for i = 1, #sourceList do
		cost[i] = {}
		for j = 1, #targetList do
			--cost[i][j] = (sourceSum + 1) ^ reverseIndex[originCost[i][j]]
			if (sourceSum + 1) ^ (#orderList + 1) > 2 ^ 31 then
				cost[i][j] = BaseNumber:createWithInc(sourceSum + 1, reverseIndex[originCost[i][j]])
			else
				cost[i][j] = (sourceSum + 1) ^ reverseIndex[originCost[i][j]]
			end
			---[[
			if sourceList[i].index.robotTypeS ~= targetList[j].index.robotTypeS or
			   sourceList[i].index.robotTypeS ~= type then
				if (sourceSum + 1) ^ (#orderList + 1) > 2 ^ 31 then
					cost[i][j] = cost[i][j] + BaseNumber:createWithInc(sourceSum + 1, #orderList + 1)
				else
					cost[i][j] = cost[i][j] + (sourceSum + 1) ^ (#orderList + 1)
				end
			end
			--]]
		end
	end

	-- create a flow network
	local C = {}
	local n = 1 + #sourceList + #targetList + 1
	for i = 1, n do C[i] = {} end
	-- 1, start
	-- 2 to #sourceList+1  source
	-- #sourceList+2 to #sourceList + #targetList + 1  target
	-- #sourceList + #target + 2   end
	local sumSource = 0
	for i = 1, #sourceList do
		C[1][1 + i] = sourceList[i].number[type] or 0
		sumSource = sumSource + C[1][1 + i]
		if C[1][1 + i] == 0 then C[1][1 + i] = nil end
	end
	if sumSource == 0 then
		return
	end

	for i = 1, #targetList do
		C[#sourceList+1 + i][n] = targetList[i].number[type]
		if C[#sourceList+1 + i][n] == 0 then C[#sourceList+1 + i][n] = nil end
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			C[1 + i][#sourceList+1 + j] = math.huge
		end
	end
	
	local W = {}
	local n = 1 + #sourceList + #targetList + 1
	for i = 1, n do W[i] = {} end

	for i = 1, #sourceList do
		W[1][1 + i] = 0
	end
	for i = 1, #targetList do
		W[#sourceList+1 + i][n] = 0
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			W[1 + i][#sourceList+1 + j] = cost[i][j]
		end
	end

	local F = MinCostFlowNetwork(C, W)

--[[
if robot.id == "pipuck2" then
	logger("C")
	logger(C)
	logger("W")
	logger(W)
	logger("F")
	logger(F)
end
]]

	for i = 1, #sourceList do
		if sourceList[i].to == nil then
			sourceList[i].to = {}
		end
	end
	for j = 1, #targetList do
		if targetList[j].from == nil then
			targetList[j].from = {}
		end
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			if F[1 + i][#sourceList+1 + j] ~= nil and
			   F[1 + i][#sourceList+1 + j] ~= 0 then
				-- set sourceTo
				local exist = false
				-- see whether this target has already exist
				for k, sourceTo in ipairs(sourceList[i].to) do
					if sourceTo.target == j then
						sourceTo.number[type] = F[1 + i][#sourceList+1 + j]
						exist = true
						break
					end
				end
				if exist == false then
					local newNumber = vns.ScaleManager.Scale:new()
					newNumber[type] = F[1 + i][#sourceList+1 + j]
					sourceList[i].to[#(sourceList[i].to) + 1] = 
						{
							number = newNumber,
							target = j,
						}
				end
				-- set targetFrom
				exist = false
				-- see whether this source has already exist
				for k, targetFrom in ipairs(targetList[j].from) do
					if targetFrom.source == i then
						targetFrom.number[type] = F[1 + i][#sourceList+1 + j]
						exist = true
						break
					end
				end
				if exist == false then
					local newNumber = vns.ScaleManager.Scale:new()
					newNumber[type] = F[1 + i][#sourceList+1 + j]
					targetList[j].from[#(targetList[j].from) + 1] = 
						{
							number = newNumber,
							source = i,
						}
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.calcMorphScale(vns, morph)
	Allocator.calcMorphChildrenScale(vns, morph)
	Allocator.calcMorphParentScale(vns, morph)
end

function Allocator.calcMorphChildrenScale(vns, morph)
	vns.allocator.morphIdCount = vns.allocator.morphIdCount + 1
	morph.idN = vns.allocator.morphIdCount 
	vns.allocator.gene_index[morph.idN] = morph

	local sum = vns.ScaleManager.Scale:new()
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			sum = sum + Allocator.calcMorphChildrenScale(vns, branch, number)
		end
	end
	if sum[morph.robotTypeS] == nil then
		sum[morph.robotTypeS] = 1
	else
		sum[morph.robotTypeS] = sum[morph.robotTypeS] + 1
	end
	morph.scale = sum
	return sum
end

function Allocator.calcMorphParentScale(vns, morph)
	if morph.parentScale == nil then
		morph.parentScale = vns.ScaleManager.Scale:new()
	end
	local sum = morph.parentScale + morph.scale
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			branch.parentScale = sum - branch.scale
		end
		for i, branch in ipairs(morph.children) do
			Allocator.calcMorphParentScale(vns, branch)
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.create_allocator_node(vns)
	return function()
		Allocator.step(vns)
		return false, true
	end
end

return Allocator
