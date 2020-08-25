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
	vns.Allocator.setMorphology(vns, nil)
end

function Allocator.deleteParent(vns)
	vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.setGene(vns, morph)
	if morph.robotTypeS ~= vns.robotTypeS then morph = nil return end
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

		-- TODO transfer branch location
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
		end
		Allocator.multi_branch_allocate(vns, "pipuck", branches)
		Allocator.multi_branch_allocate(vns, "drone", branches)
	end end

	Allocator.allocate(vns, "pipuck")
	Allocator.allocate(vns, "drone")
	-- check inter types assign
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.match ~= nil then
			local assignToidS = robotR.match.match
			vns.Assigner.assign(vns, idS, assignToidS)	
			--robotR.match = nil
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
	local i = 0
	local targetList = {}
	for _, branchR in ipairs(branches) do
		if branchR.scale[allocating_type] ~= nil and branchR.scale[allocating_type] ~= 0 then
			i = i + 1
			targetList[i] = {
				number = branchR.scale[allocating_type],
				index = branchR
			}
		end
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
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost)

	logger("multi_branch_sourceList")
	logger(sourceList)
	logger("multi_branch_targetList")
	logger(targetList)

	-- hand up all children that is not with the myself
	local myTarget = nil
	if vns.robotTypeS == allocating_type and
	   #(sourceList[1].to) ~= 0 then
		myTarget = sourceList[1].to[1].target
	end
	for i = 1, #sourceList do
		for j = 1, #(sourceList[i].to) do
			if sourceList[i].to[j].target ~= myTarget and
			   sourceList[i].index.robotTypeS == allocating_type then
				vns.Assigner.assign(vns, sourceList[i].index.idS, vns.parentR.idS)
				sourceList[i].index.goal.positionV3 = vns.parentR.positionV3
				sourceList[i].index.allocated_in_multi_branch = true
				break
			end
		end
	end
	-- set myself as the allcated branch
	if myTarget ~= nil then
		Allocator.setMorphology(vns, targetList[myTarget].index)
		vns.goal.positionV3 = targetList[myTarget].index.positionV3
		vns.goal.orientationQ = targetList[myTarget].index.orientationQ
	end
end

function Allocator.allocate(vns, allocating_type)
	-- create sources from children
	local sourceList = {}
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.scale[allocating_type] ~= nil and 
		   robotR.scale[allocating_type] ~= 0 and 
		   robotR.allocated_in_multi_branch == nil then
			sourceList[#sourceList + 1] = {
				number = robotR.scale[allocating_type],
				index = robotR,
			}
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branch
	local i = 0
	local targetList = {}
	local targetSum = 0
	if vns.allocator.target ~= nil and vns.allocator.target.children ~= nil then
		for _, branchR in ipairs(vns.allocator.target.children) do
			if branchR.scale[allocating_type] ~= nil and branchR.scale[allocating_type] ~= 0 then
				i = i + 1
				targetList[i] = {
					number = branchR.scale[allocating_type],
					index = branchR
				}
			end
		end
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
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost)

	---[[
	logger("sourceList")
	logger(sourceList)
	logger("targetList")
	logger(targetList)
	--]]
	-- one to one case
	--[[
	for i = 1, #sourceList do
		if #(sourceList[i].to) == 1 and 
		   #(targetList[sourceList[i].to[1].target].from) == 1 and
		   sourceList[i].index.robotTypeS == targetList[sourceList[i].to[1].target].index.robotTypeS then
			vns.Msg.send(sourceList[i].index.idS, "branch", 
				{branch = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(targetList[sourceList[i].to[1].target].index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(targetList[sourceList[i].to[1].target].index.orientationQ),
					children = targetList[sourceList[i].to[1].target].index.children
				}}	
			)
		end
	end
	--]]

	-- multiple (including one) sources to one target
	for j = 1, #targetList do
		-- find the farthest source to target j
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

		if farthestI ~= nil and targetList[j].index.robotTypeS == allocating_type then
			-- there is a same type robot matches this branch
			-- mark the farthest match from source to target
			targetList[j].index.match = sourceList[farthestI].index.idS

			-- assign all other source to the farthest one
			for _, fromTable in ipairs(targetList[j].from) do
				if #(sourceList[fromTable.source].to) == 1 and
				   fromTable.source ~= farthestI then
					vns.Assigner.assign(vns, 
					    sourceList[fromTable.source].index.idS,
						sourceList[farthestI].index.idS
					)
					sourceList[fromTable.source].index.goal.positionV3 = targetList[j].index.positionV3
				end
			end

			-- send branch to the farthest source
			vns.Msg.send(sourceList[farthestI].index.idS, "branch", 
				{branch = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(targetList[j].index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(targetList[j].index.orientationQ),
					children = targetList[j].index.children,
					scale = targetList[j].index.scale,
					robotTypeS = targetList[j].index.robotTypeS,
				}}	
			)
		else
			-- there is no same type robot matches this branch
			-- assign all other source to the farthest one
			for _, fromTable in ipairs(targetList[j].from) do
				if #(sourceList[fromTable.source].to) == 1 and
				   sourceList[fromTable.source].index.robotTypeS == allocating_type then
					sourceList[fromTable.source].index.match = targetList[j].index
					sourceList[fromTable.source].index.goal.positionV3 = targetList[j].index.positionV3
				end
			end
		end
	end

	-- one source to multiple targets case
	for i = 1, #sourceList do
		if #(sourceList[i].to) > 1 and
		   sourceList[i].index.robotTypeS == allocating_type then
			local branches = {}
			for j = 1, #(sourceList[i].to) do
				local branch = targetList[sourceList[i].to[j].target].index
				branches[#branches + 1] = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(branch.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(branch.orientationQ),
					children = branch.children,
					scale = targetList[j].index.scale,
					robotTypeS = targetList[j].index.robotTypeS,
				}
			end
			vns.Msg.send(sourceList[i].index.idS, "multiple-branch", {branches = branches})
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
	local sum = vns.ScaleManager.Scale:new()
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			sum = sum + Allocator.calcMorphChildrenScale(vns, branch)
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
	end
end

return Allocator
