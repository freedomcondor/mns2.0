-- Allocator -----------------------------------------
------------------------------------------------------
--local Arrangement = require("Arrangement")
local MinCostFlowNetwork = require("MinCostFlowNetwork")
local DeepCopy = require("DeepCopy")
local BaseNumber = require("BaseNumber")

local Allocator = {}

--[[
--	related data
--	vns.allocator.target = {positionV3, orientationQ, robotTypeS, children}
--	vns.allocator.gene
--	vns.allocator.gene_index
--]]

function Allocator.create(vns)
	vns.allocator = {
		target = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
		},
		parentGoal = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		mode_switch = "allocate",
	}
end

function Allocator.reset(vns)
	vns.allocator = {
		target = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
		},
		parentGoal = {
			positionV3 = vector3(),
			orientationQ = quaternion(),
		},
		mode_switch = "allocate",
	}
end

function Allocator.addChild(vns)
end

function Allocator.deleteChild(vns)
end

function Allocator.addParent(vns)
	vns.mode_switch = "allocate"
end

function Allocator.deleteParent(vns)
	vns.allocator.parentGoal = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
	}
	--vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.setGene(vns, morph)
	vns.allocator.morphIdCount = 0
	vns.allocator.gene_index = {}
	vns.allocator.gene_index[-1] = {
		positionV3 = vector3(),
		orientationQ = quaternion(),
		idN = -1,
		robotTypeS = vns.robotTypeS,
	}
	Allocator.calcMorphScale(vns, morph)
	vns.allocator.gene = morph
	vns.Allocator.setMorphology(vns, morph)
end

function Allocator.setMorphology(vns, morph)
	-- issue a temporary morph if the morph is not valid
	if morph == nil then
		morph = {
			idN = -1,
			positionV3 = vector3(),
			orientationQ = quaternion(),
			robotTypeS = vns.robotTypeS,
		} 
	elseif morph.robotTypeS ~= vns.robotTypeS then 
		morph = {
			idN = -1,
			positionV3 = morph.positionV3,
			orientationQ = morph.orientationQ,
			robotTypeS = vns.robotTypeS,
		} 
	end
	vns.allocator.target = morph
end

function Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, vns.allocator.gene)
end

function Allocator.preStep(vns)
	for idS, childR in pairs(vns.childrenRT) do
		childR.match = nil
	end
end

function Allocator.sendStationary(vns)
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "allocator_stationary")
	end
end

function Allocator.sendKeep(vns)
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "allocator_keep")
		vns.Msg.send(idS, "parentGoal", {
			positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
			orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
		})
	end
end

function Allocator.step(vns)
	vns.api.debug.drawRing(vns.lastcolor or "black", vector3(0,0,0.3), 0.1)
	-- update parentGoal
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "parentGoal")) do
		vns.allocator.parentGoal.positionV3 = vns.parentR.positionV3 +
			vector3(msgM.dataT.positionV3):rotate(vns.parentR.orientationQ)
		vns.allocator.parentGoal.orientationQ = vns.parentR.orientationQ * msgM.dataT.orientationQ 
	end end

	-- stationary mode
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "allocator_stationary")) do
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
		Allocator.sendStationary(vns)
		return 
	end end
	if vns.allocator.mode_switch == "stationary" then
		-- vns.goal.positionV3 and orientationQ remain nil
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
		Allocator.sendStationary(vns)
		return 
	end

	-- keep mode
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "allocator_keep")) do
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3 +
			vector3(vns.allocator.target.positionV3):rotate(vns.allocator.parentGoal.orientationQ)
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ * vns.allocator.target.orientationQ
		Allocator.sendKeep(vns)
		return 
	end end
	if vns.allocator.mode_switch == "keep" then
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3 +
			vector3(vns.allocator.target.positionV3):rotate(vns.allocator.parentGoal.orientationQ)
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ * vns.allocator.target.orientationQ
		Allocator.sendKeep(vns)
		return 
	end

	-- if I just handovered a child to parent, then I will receive an outdated allocate command, ignore this cmd
	if vns.parentR ~= nil and vns.parentR.scale_assign_offset:totalNumber() ~= 0 then
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branches")) do
			msgM.ignore = true
		end
	end

	-- allocate mode
		-- update my target based on parent's cmd
	local flag
	local second_level
	local self_align
	local temporary_goal
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "branches")) do 
	if msgM.ignore ~= true then
		flag = true
		second_level = msgM.dataT.branches.second_level
		self_align = msgM.dataT.branches.self_align

		logger("receive branches")
		logger(msgM.dataT.branches)

		if #msgM.dataT.branches == 1 then
			local color = "green"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(), 0.2)
		elseif #msgM.dataT.branches > 1 then
			local color = "blue"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(), 0.2)
		end
		if second_level == true then
			local color = "red"
			vns.lastcolor = color
			vns.api.debug.drawRing(color, vector3(0,0,0.01), 0.19)
		end
		for i, received_branch in ipairs(msgM.dataT.branches) do
			-- branches = 
			--	{  1 = {
			--              idN, may be -1
			--              number(the scale)
			--              positionV3 and orientationV3
			--         }
			--     2 = {...}
			--     second_level = nil or true
			--         -- indicates if I'm under a split node
			--     goal = {positionV3, orientationQ} 
			--         -- a goal indicates the location of grand parent
			--         -- happens in the first level split
			--     self_align - nil or true
			--         -- indicates whether this child should ignore second_level parent chase
			--	}
			received_branch.positionV3 = vns.parentR.positionV3 +
				vector3(received_branch.positionV3):rotate(vns.parentR.orientationQ)
			received_branch.orientationQ = vns.parentR.orientationQ * received_branch.orientationQ
			received_branch.robotTypeS = vns.allocator.gene_index[received_branch.idN].robotTypeS -- TODO: consider
		end
		if msgM.dataT.branches.goal ~= nil then
			msgM.dataT.branches.goal.positionV3 = vns.parentR.positionV3 +
				vector3(msgM.dataT.branches.goal.positionV3):rotate(vns.parentR.orientationQ)
			msgM.dataT.branches.goal.orientationQ = vns.parentR.orientationQ * msgM.dataT.branches.goal.orientationQ
			temporary_goal = msgM.dataT.branches.goal
		end
		Allocator.multi_branch_allocate(vns, msgM.dataT.branches)
	end end end
	if flag ~= true and vns.parentR ~= nil then
		local color = "yellow"
		vns.lastcolor = color
		vns.api.debug.drawRing(color, vector3(), 0.2)

		-- if I don't receive branches cmd, update my goal according to parentGoal
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3 + 
			vector3(vns.allocator.target.positionV3):rotate(vns.allocator.parentGoal.orientationQ)
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ * vns.allocator.target.orientationQ

		-- send my new goal and don't send command for my children, everyone keep still
		-- send my new goal to children
		for idS, robotR in pairs(vns.childrenRT) do
			vns.Assigner.assign(vns, idS, nil)	
			vns.Msg.send(idS, "parentGoal", {
				positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
				orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
			})
		end
		return
	end
	--if I'm brain, stay still
	if vns.parentR == nil then
		vns.goal.positionV3 = vector3()
		vns.goal.orientationQ = quaternion()
	end

	-- I should have a target (either updated or not), 
	-- a goal for this step
	-- a group of children with match = nil

	-- if my target is -1, I'm in the process of handing up to grandparent, stop children assign
	-- TODO: what if I'm already in the brain and I have more children 
	-- somethings when topology changing, there will be -1 perturbation shortly, ignore this -1
	---[[
	if vns.allocator.target.idN == -1 and (vns.allocator.extraCount or 0) < 5 then
		second_level = true
	end
	if vns.allocator.target.idN == -1 then
		vns.allocator.extraCount = (vns.allocator.extraCount or 0) + 1
	else
		vns.allocator.extraCount = nil
	end
	--]]

	-- assign better child
	if vns.parentR ~= nil then
		local myValue = Allocator.calcBaseValue(vns.allocator.parentGoal.positionV3, vector3(), vns.goal.positionV3)
		--local myValue = Allocator.calcBaseValue(vns.parentR.positionV3, vector3(), vns.goal.positionV3)
		for idS, robotR in pairs(vns.childrenRT) do
			if robotR.match == nil then
				local value = Allocator.calcBaseValue(vns.allocator.parentGoal.positionV3, robotR.positionV3, vns.goal.positionV3)
				--local value = Allocator.calcBaseValue(vns.parentR.positionV3, robotR.positionV3, vns.goal.positionV3)
				if robotR.robotTypeS == vns.robotTypeS and value < myValue then
					local send_branches = {}
					send_branches[1] = {
						idN = vns.allocator.target.idN,
						number = vns.allocator.target.scale,
						positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3),
						orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ),
					}
					send_branches.second_level = second_level
					vns.Msg.send(idS, "branches", {branches = send_branches})
					if second_level ~= true then
						vns.Assigner.assign(vns, idS, vns.parentR.idS)	
					end
					robotR.match = true
				end
			end
		end
	end

	-- create branches from target children, with goal drifted position
	local branches = {second_level = second_level}
	if vns.allocator.target.children ~= nil then
		for _, branch in ipairs(vns.allocator.target.children) do
			branches[#branches + 1] = {
				idN = branch.idN,
				number = branch.scale,
				-- for brain, vns.goal.positionV3 = nil
				positionV3 = (vns.goal.positionV3) +
					vector3(branch.positionV3):rotate(vns.goal.orientationQ),
				orientationQ = vns.goal.orientationQ * branch.orientationQ, 
				robotTypeS = branch.robotTypeS,
			 }
			-- do not drift if self align switch is on
			if vns.allocator.self_align == true and
			   vns.robotTypeS == "drone" and
			   branch.robotTypeS == "pipuck" then
				branches[#branches].positionV3 = branch.positionV3
				branches[#branches].orientationQ = branch.orientationQ
				branches[#branches].self_align = true
			end
		end
	end
	Allocator.allocate(vns, branches)

	if second_level == true and self_align ~= true and vns.parentR ~= nil then -- parent may be deleted by intersection
		vns.goal.positionV3 = vns.parentR.positionV3
		vns.goal.orientationQ = vns.parentR.orientationQ
	end
	if temporary_goal ~= nil then
		vns.goal.positionV3 = temporary_goal.positionV3
		vns.goal.orientationQ = temporary_goal.orientationQ
	end

	-- send my new goal to children
	for idS, robotR in pairs(vns.childrenRT) do
		vns.Msg.send(idS, "parentGoal", {
			positionV3 = vns.api.virtualFrame.V3_VtoR(vns.goal.positionV3 or vector3()),
			orientationQ = vns.api.virtualFrame.Q_VtoR(vns.goal.orientationQ or quaternion()),
		})
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
			number = vns.ScaleManager.Scale:new(robotR.scale),
			index = robotR,
		}
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	for _, branchR in ipairs(branches) do
		targetList[#targetList + 1] = {
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
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")

	---[[
	logger("multi-branch sourceList")
	for i, source in ipairs(sourceList) do
		logger(i)
		logger(source, 1)
		logger("\tid = ", source.index.idS or source.index.idN)
		logger("\tposition = ", source.index.positionV3)
	end
	logger("multi-branch targetList")
	for i, target in ipairs(targetList) do
		logger(i)
		logger(target, 1) 
		logger("\tid = ", target.index.idS or target.index.idN)
		logger("\tposition = ", target.index.positionV3)
	end
	--]]

	-- set myself  
	local myTarget = nil
	if #(sourceList[1].to) == 1 then
		myTarget = targetList[sourceList[1].to[1].target]
		local branchID = myTarget.index.idN
		Allocator.setMorphology(vns, vns.allocator.gene_index[branchID])
		vns.goal.positionV3 = myTarget.index.positionV3
		vns.goal.orientationQ = myTarget.index.orientationQ
		---[[ sometimes when topology changes, these maybe a -1 misjudge shortly, ignore this -1
		if branchID == -1 and (vns.allocator.extraCount or 0) < 5 then
			branches.second_level = true
		end
		--]]
	elseif #(sourceList[1].to) == 0 then
		Allocator.setMorphology(vns, vns.allocator.gene_index[-1])
		vns.goal.positionV3 = vns.allocator.parentGoal.positionV3
		vns.goal.orientationQ = vns.allocator.parentGoal.orientationQ
	elseif #(sourceList[1].to) > 1 then
		logger("Impossible! Myself is split in multi_branch_allocation")
	end

	-- handle split children
	-- this means I've already got a multi-branch cmd, I send a second_level multi-branch cmd
	-- if my cmd is first level multi-branch, I handover this child to my parent
	for i = 2, #sourceList do
		if #(sourceList[i].to) > 1 then
			local sourceChild = sourceList[i].index
			local send_branches = {}
			for _, targetItem in ipairs(sourceList[i].to) do
				local target_branch = targetList[targetItem.target]
				send_branches[#send_branches+1] = {
					idN = target_branch.index.idN,
					number = targetItem.number,
					positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.index.orientationQ),
				}
			end
			send_branches.second_level = true
			-- send temporary goal based on my temporary goal
			-- if I'm a first level split node, send a temporary goal for grand parent location
			if branches.second_level ~= true then
				send_branches.goal = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ),
				}
			end

			vns.Msg.send(sourceChild.idS, "branches", {branches = send_branches})
			if branches.second_level ~= true then
				vns.Assigner.assign(vns, sourceChild.idS, vns.parentR.idS)	
			else
				vns.Assigner.assign(vns, sourceChild.idS, nil)	
			end
			sourceChild.match = true
		end
	end

	-- handle not my children
	-- for each target that is not my assignment
	for j = 1, #targetList do if targetList[j] ~= myTarget then
		local farthest_id = nil
		local farthest_value = math.huge
		-- for each child that is assigned to the current target
		for i = 2, #sourceList do 
		if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			-- create send branch
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				idN = target_branch.idN,
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
			}
			-- if I'm a first level split node, send a temporary goal for grand parent location
			if branches.second_level ~= true then
				send_branches.goal = {
					positionV3 = vns.api.virtualFrame.V3_VtoR(vns.parentR.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(vns.parentR.orientationQ),
				}
			end
			--send_branches.second_level = branches.second_level
			send_branches.second_level = true
			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})

			-- calculate farthest value
			local value = Allocator.calcBaseValue(vns.allocator.parentGoal.positionV3, source_child.positionV3, target_branch.positionV3)
			--local value = Allocator.calcBaseValue(vns.parentR.positionV3, source_child.positionV3, target_branch.positionV3)
			if source_child.robotTypeS == vns.allocator.gene_index[target_branch.idN].robotTypeS and 
			   value < farthest_value then
				farthest_id = i
				farthest_value = value
			end

			-- mark
			source_child.match = true
		end end

		-- assign
		-- for each child that is assigned to the current target
		for i = 2, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child_id = sourceList[i].index.idS
			if i == farthest_id then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			elseif farthest_id ~= nil then
				if branches.second_level ~= true then
					--vns.Assigner.assign(vns, source_child_id, sourceList[farthest_id].index.idS)	-- can't hand up and hand among siblings at the same time
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			elseif farthest_id == nil then -- the children are all different type, no farthest one is chosen
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, vns.parentR.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			end
		end end
	end end
end

function Allocator.allocate(vns, branches)
	-- create sources from children
	local sourceList = {}
	local sourceSum = vns.ScaleManager.Scale:new()
	for idS, robotR in pairs(vns.childrenRT) do
		if robotR.match == nil then
			sourceList[#sourceList + 1] = {
				number = vns.ScaleManager.Scale:new(robotR.scale),
				index = robotR,
			}
			sourceSum = sourceSum + robotR.scale
		end
	end

	if #sourceList == 0 then return end

	-- create targets from branches
	local targetList = {}
	local targetSum = vns.ScaleManager.Scale:new()
	for _, branchR in ipairs(branches) do
		targetList[#targetList + 1] = {
			number = vns.ScaleManager.Scale:new(branchR.number),
			index = branchR
		}
		targetSum = targetSum + branchR.number
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
			}
		}
	elseif diffSum:totalNumber() > 0 and vns.parentR == nil then
		targetList[#targetList + 1] = {
			number = diffSum,
			index = {
				idN = -1,
				positionV3 = vector3(),
				orientationQ = quaternion(),
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
		end
	end

	Allocator.GraphMatch(sourceList, targetList, originCost, "pipuck")
	Allocator.GraphMatch(sourceList, targetList, originCost, "drone")

	---[[
	logger("sourceList")
	for i, source in ipairs(sourceList) do
		logger(i)
		logger(source, 1)
		logger("\tid = ", source.index.idS or source.index.idN)
		logger("\tposition = ", source.index.positionV3)
	end
	logger("targetList")
	for i, target in ipairs(targetList) do
		logger(i)
		logger(target, 1)
		logger("\tid = ", target.index.idS or target.index.idN)
		logger("\tposition = ", target.index.positionV3)
	end
	--]]

	-- handle split children  -- TODO if one of the split branches is -1
	for i = 1, #sourceList do
		if #(sourceList[i].to) > 1 then
			local sourceChild = sourceList[i].index
			local send_branches = {}
			for _, targetItem in ipairs(sourceList[i].to) do
				local target_branch = targetList[targetItem.target]
				send_branches[#send_branches+1] = {
					idN = target_branch.index.idN,
					number = targetItem.number,
					positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.index.positionV3),
					orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.index.orientationQ),
				}
			end
			send_branches.second_level = branches.second_level

			vns.Msg.send(sourceChild.idS, "branches", {branches = send_branches})
			vns.Assigner.assign(vns, sourceChild.idS, nil)	
			sourceChild.match = true
		end
	end

	-- handle rest of the children
	-- for each target that is not the parent
	for j = 1, #targetList do if targetList[j].index.idN ~= -1 then
		local farthest_id = nil
		local farthest_value = math.huge
		-- for each child that is assigned to the current target
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			-- create send branch
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				idN = target_branch.idN,
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
			}
			send_branches.second_level = branches.second_level
			send_branches.self_align = target_branch.self_align
			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})

			-- calculate farthest value
			local value = Allocator.calcBaseValue(vns.goal.positionV3, source_child.positionV3, target_branch.positionV3)
			--local value = Allocator.calcBaseValue(vector3(), source_child.positionV3, target_branch.positionV3)

			if source_child.robotTypeS == vns.allocator.gene_index[target_branch.idN].robotTypeS and 
			   value < farthest_value then
				farthest_id = i
				farthest_value = value
			end

			-- mark
			source_child.match = true
		end end

		-- assign
		-- for each child that is assigned to the current target
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child_id = sourceList[i].index.idS
			if i == farthest_id then
				vns.Assigner.assign(vns, source_child_id, nil)	
			elseif farthest_id ~= nil then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child_id, sourceList[farthest_id].index.idS)	
				else
					vns.Assigner.assign(vns, source_child_id, nil)	
				end
			end
		end end
	end end

	-- handle extra children     -- TODO: may set second level
	-- for each target that is the parent
	for j = 1, #targetList do if targetList[j].index.idN == -1 then
		for i = 1, #sourceList do if #(sourceList[i].to) == 1 and sourceList[i].to[1].target == j then
			local source_child = sourceList[i].index
			local target_branch = targetList[j].index
			local send_branches = {}
			send_branches[1] = {
				--idN = vns.allocator.target.idN,
				idN = target_branch.idN, --(-1)
				number = sourceList[i].to[1].number,
				positionV3 = vns.api.virtualFrame.V3_VtoR(target_branch.positionV3),
				orientationQ = vns.api.virtualFrame.Q_VtoR(target_branch.orientationQ),
			}
			send_branches.second_level = branches.second_level
			-- stop children handing over for extre children
			--send_branches.second_level = true 

			vns.Msg.send(source_child.idS, "branches", {branches = send_branches})
			if vns.parentR ~= nil then
				if branches.second_level ~= true then
					vns.Assigner.assign(vns, source_child.idS, vns.parentR.idS)	
				end
			else
				vns.Assigner.assign(vns, source_child.idS, nil)	
			end
		end end
	end end
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
function Allocator.calcBaseValue(base, current, target)
	local base_target_V3 = target - base
	local base_current_V3 = current - base
	base_target_V3.z = 0
	base_current_V3.z = 0
	return base_current_V3:dot(base_target_V3:normalize())
end

-------------------------------------------------------------------------------
function Allocator.calcMorphScale(vns, morph)
	Allocator.calcMorphChildrenScale(vns, morph)
	Allocator.calcMorphParentScale(vns, morph)
end

function Allocator.calcMorphChildrenScale(vns, morph, level)
	vns.allocator.morphIdCount = vns.allocator.morphIdCount + 1
	morph.idN = vns.allocator.morphIdCount 
	level = level or 1
	morph.level = level
	vns.allocator.gene_index[morph.idN] = morph

	local sum = vns.ScaleManager.Scale:new()
	if morph.children ~= nil then
		for i, branch in ipairs(morph.children) do
			sum = sum + Allocator.calcMorphChildrenScale(vns, branch, level + 1)
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
