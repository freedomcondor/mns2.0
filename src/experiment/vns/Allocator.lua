-- Allocator -----------------------------------------
------------------------------------------------------
--local Arrangement = require("Arrangement")
local MinCostFlowNetwork = require("MinCostFlowNetwork")

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
	vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.setGene(vns, morph)
	if morph.robotTypeS ~= vns.robotTypeS then morph = nil return end
	vns.allocator.morphIdCount = 0
	Allocator.calcMorphScale(vns, morph)
	vns.allocator.gene = morph
	vns.Allocator.setMorphology(vns, morph)
end

function Allocator.setMorphology(vns, morph)
	vns.allocator.target = morph
end

function Allocator.preStep(vns)
	for idS, childR in pairs(vns.childrenRT) do
		childR.allocated_in_multi_branch = nil
		childR.match = nil
		childR.pre_match = nil
		childR.divided = nil
	end
	if vns.allocator.target ~= nil and vns.allocator.target.children ~= nil then
		for _, branch in pairs(vns.allocator.target.children) do
			branch.match = nil
		end
	end
end

function Allocator.step(vns)
	-- receive branch
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branch")) do
		Allocator.setMorphology(vns, msgM.dataT.branch)
		local targetPositionV3 = vns.api.virtualFrame.V3_RtoV(
			vector3(msgM.dataT.branch.positionV3):rotate(
				vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ)
			) + 
			vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3)
		)
		local targetOrientationQ = vns.api.virtualFrame.Q_RtoV(
			msgM.dataT.branch.orientationQ * vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ)
		)
		vns.goal.positionV3 = targetPositionV3
		vns.goal.orientationQ = targetOrientationQ

		if vns.allocator.target.children ~= nil then
			for _, branchR in ipairs(vns.allocator.target.children) do
				branchR.positionV3_backup = vector3(branchR.positionV3)
				branchR.orientationQ_backup = quaternion(branchR.orientationQ)
				branchR.positionV3 = vector3(branchR.positionV3):rotate(vns.goal.orientationQ) + vns.goal.positionV3
				branchR.orientationQ = branchR.orientationQ * vns.goal.orientationQ
			end
		end
	end end

	-- receive branches
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "multiple-branch")) do
		local branches = msgM.dataT.branches
		for i, branch in ipairs(branches) do
			local targetPositionV3 = vns.api.virtualFrame.V3_RtoV(
				vector3(branch.positionV3):rotate(
					vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ)
				) + 
				vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3)
			)
			local targetOrientationQ = vns.api.virtualFrame.Q_RtoV(
				branch.orientationQ * vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ)
			)
			branch.positionV3 = targetPositionV3
			branch.orientationQ = targetOrientationQ

			if branch.children ~= nil then
				for _, branch_childR in ipairs(branch.children) do
					branch_childR.positionV3_backup = vector3(branch_childR.positionV3)
					branch_childR.orientationQ_backup = quaternion(branch_childR.orientationQ)
					branch_childR.positionV3 = vector3(branch_childR.positionV3):rotate(branch.orientationQ) + branch.positionV3
					branch_childR.orientationQ = branch_childR.orientationQ * branch.orientationQ
				end
			end
		end
		Allocator.multi_branch_allocate(vns, msgM.dataT.robotTypeS, branches)
	end end

	-- by now, I should have received a branch, either from branch or chosen from multiple-branch
	-- from multiple branches, some of my children should be hand up to my parent
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
	Allocator.allocate(vns, "pipuck")
	Allocator.allocate(vns, "drone")
	-- check inter types assign
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.match ~= nil and robotR.allocated_in_multi_branch ~= true then
			local assignToidS = robotR.match.match
			if assignToidS ~= idS and 
			   ((vns.parentR ~= nil and vns.parentR.idS == assignToidS) or
			    (vns.childrenRT[assignToidS] ~= nil and vns.childrenRT[assignToidS].divided == nil)
			   ) then
				vns.Assigner.assign(vns, idS, assignToidS)	
			end
			robotR.goal.positionV3 = robotR.match.positionV3
			robotR.goal.orientationQ = robotR.match.orientationQ
		end
	end
end

function Allocator.multi_branch_allocate(vns, allocating_type, branches)
	local sourceList = {}
	-- create sources from myself
	if vns.robotTypeS == allocating_type then
		sourceList[#sourceList + 1] = {
			number = 1,
			index = {
				positionV3 = vector3(),
			},
		}
	end
	-- create sources from children
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.scale[allocating_type] ~= nil and robotR.scale[allocating_type] ~= 0 then
			sourceList[#sourceList + 1] = {
				number = robotR.scale[allocating_type],
				index = robotR,
			}
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	for _, branchR in ipairs(branches) do
		if branchR.scale[allocating_type] ~= nil and branchR.scale[allocating_type] ~= 0 then
			targetList[#targetList + 1] = {
				--number = branchR.scale[allocating_type],
				number = branchR.number,
				index = branchR
			}
		end
	end

	-- sum number of source and target should be the same

	-- create a cost matrix
	local originCost = {}
	for i = 1, #sourceList do originCost[i] = {} end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			local targetPosition = vector3(targetList[j].index.positionV3)
			local relativeVector = sourceList[i].index.positionV3 - targetPosition
			relativeVector.z = 0
			originCost[i][j] = relativeVector:length()
			if sourceList[i].index.robotTypeS ~= allocating_type then
				originCost[i][j] = originCost[i][j] + 100000
			end
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost)

	--[[
	logger("multi-sourceList")
	logger(sourceList)
	logger("multi-targetList")
	logger(targetList)
	--]]

	-- mark children
	for i = 1, #sourceList do
		-- one target case
		if sourceList[i].index.robotTypeS == allocating_type then
			if #(sourceList[i].to) == 1 then
				sourceList[i].index.match = targetList[sourceList[i].to[1].target].index
			else
				sourceList[i].index.match = {
					idN = -1,
					positionV3 = vns.parentR.positionV3,
					orientationQ = vns.parentR.orientationQ,
				}
			end
		end
	end

	-- set myself branch if I'm the right type
	if vns.robotTypeS == allocating_type and sourceList[1].to[1] ~= nil then
		Allocator.setMorphology(vns, targetList[sourceList[1].to[1].target].index)
		vns.goal.positionV3 = targetList[sourceList[1].to[1].target].index.positionV3
		vns.goal.orientationQ = targetList[sourceList[1].to[1].target].index.orientationQ
	end
end

function Allocator.allocate(vns, allocating_type)
	-- create sources from children
	local sourceList = {}
	local sourceSum = 0
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.scale[allocating_type] ~= nil and 
		   robotR.scale[allocating_type] ~= 0 and 
		   robotR.allocated_in_multi_branch == nil then
			sourceList[#sourceList + 1] = {
				number = robotR.scale[allocating_type],
				index = robotR,
			}
			sourceSum = sourceSum + robotR.scale[allocating_type]
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branch
	local targetList = {}
	local targetSum = 0
	if vns.allocator.target ~= nil and vns.allocator.target.children ~= nil then
		for _, branchR in ipairs(vns.allocator.target.children) do
			if branchR.scale[allocating_type] ~= nil and branchR.scale[allocating_type] ~= 0 then
				targetList[#targetList + 1] = {
					number = branchR.scale[allocating_type],
					index = branchR
				}
				targetSum = targetSum + branchR.scale[allocating_type]
			end
		end
	end

	-- add parent as a target
	if sourceSum > targetSum and vns.parentR ~= nil then
		local parentScale = vns.ScaleManager.Scale:new()
		parentScale[allocating_type] = sourceSum - targetSum
		targetList[#targetList + 1] = {
			number = sourceSum - targetSum,
			index = {
				idN = -1,
				positionV3 = vns.parentR.positionV3,
				orientationQ = vns.parentR.orientationQ,
				scale = parentScale,
			}
		}
	elseif sourceSum > targetSum and vns.parentR == nil then
		local parentScale = vns.ScaleManager.Scale:new()
		parentScale[allocating_type] = sourceSum - targetSum
		targetList[#targetList + 1] = {
			number = sourceSum - targetSum,
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
			if sourceList[i].index.robotTypeS ~= allocating_type then
				originCost[i][j] = originCost[i][j] + 100000
			end
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost)

	--[[
	logger("sourceList")
	logger(sourceList)
	logger("targetList")
	logger(targetList)
	--]]

	-- multiple (including one) sources to one target
	for j = 1, #targetList do
		-- mark all allocating type, single target child to the branch
		for _, fromTable in ipairs(targetList[j].from) do
			if #(sourceList[fromTable.source].to) == 1 then
				if sourceList[fromTable.source].index.robotTypeS == allocating_type then
					sourceList[fromTable.source].index.match = targetList[j].index
					if sourceList[fromTable.source].index.pre_match ~= nil and 
					   sourceList[fromTable.source].index.pre_match ~= targetList[j].index then
						sourceList[fromTable.source].index.divided = true
					end
				else
					sourceList[fromTable.source].index.pre_match = targetList[j].index
					if sourceList[fromTable.source].index.match ~= nil and 
					   sourceList[fromTable.source].index.match ~= targetList[j].index then
						sourceList[fromTable.source].index.divided = true
					end
				end
			end
		end

		if targetList[j].index.idN == -1 then targetList[j].index.match = vns.parentR.idS end
		if targetList[j].index.idN == -2 then targetList[j].index.match = {
			idS = vns.idS,
			positionV3 = vector3(),
			orientationQ = quaternion(),
		} end
		if targetList[j].index.robotTypeS == allocating_type then
			-- find the farthest allocating type source to target j
			local farthestDis = 0
			local farthestI = nil
			for _, fromTable in ipairs(targetList[j].from) do
				if #(sourceList[fromTable.source].to) == 1 and
				   sourceList[fromTable.source].index.robotTypeS == allocating_type then
					local dis = (sourceList[fromTable.source].index.positionV3 - 
								 targetList[j].index.positionV3):length()
					if dis > farthestDis then
						farthestDis = dis
						farthestI = fromTable.source
					end
				end
			end
			-- if there is a same type robot matches this branch
			if farthestI ~= nil and targetList[j].index.robotTypeS == allocating_type then
				-- mark the farthest match from source to target
				targetList[j].index.match = sourceList[farthestI].index.idS
				-- send branch to the farthest source
				vns.Msg.send(sourceList[farthestI].index.idS, "branch", 
					{branch = {
						positionV3 = vns.api.virtualFrame.V3_VtoR(targetList[j].index.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(targetList[j].index.orientationQ),
						children = targetList[j].index.children,
						scale = targetList[j].index.scale, 
						idN = targetList[j].index.idN,
						robotTypeS = targetList[j].index.robotTypeS,
					}}	
				)
			end
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
					children = branch.children,
					scale = branch.scale,
					idN = branch.idN,
					number = sourceList[i].to[j].number,
					robotTypeS = branch.robotTypeS,
				}
			end
			vns.Msg.send(sourceList[i].index.idS, "multiple-branch", {branches = branches, robotTypeS = allocating_type})
			sourceList[i].index.divided = true
		end
	end
end

-------------------------------------------------------------------------------
function Allocator.GraphMatch(sourceList, targetList, originCost)
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
		sourceSum = sourceSum + sourceList[i].number
	end
	-- create a reverse index
	local reverseIndex = {}
	for i = 1, #orderList do reverseIndex[orderList[i]] = i end
	-- create an enhanced cost matrix
	local cost = {}
	for i = 1, #sourceList do
		cost[i] = {}
		for j = 1, #targetList do
			--cost[i][j] = (#orderList) ^ reverseIndex[originCost[i][j]]
			cost[i][j] = (sourceSum + 1) ^ reverseIndex[originCost[i][j]]
		end
	end

	--DMSG("cost")
	--DMSG(cost)

	-- create a flow network
	local C = {}
	local n = 1 + #sourceList + #targetList + 1
	for i = 1, n do C[i] = {} end
	-- 1, start
	-- 2 to #sourceList+1  source
	-- #sourceList+2 to #sourceList + #targetList + 1  target
	-- #sourceList + #target + 2   end
	for i = 1, #sourceList do
		C[1][1 + i] = sourceList[i].number
	end
	for i = 1, #targetList do
		C[#sourceList+1 + i][n] = targetList[i].number
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

	for i = 1, #sourceList do
		sourceList[i].to = {}
	end
	for j = 1, #targetList do
		targetList[j].from = {}
	end
	for i = 1, #sourceList do
		for j = 1, #targetList do
			if F[1 + i][#sourceList+1 + j] ~= nil and
			   F[1 + i][#sourceList+1 + j] ~= 0 then
				sourceList[i].to[#(sourceList[i].to) + 1] = 
					{
						number = F[1 + i][#sourceList+1 + j],
						target = j,
					}
				targetList[j].from[#(targetList[j].from) + 1] = 
					{
						number = F[1 + i][#sourceList+1 + j],
						source = i,
					}
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
