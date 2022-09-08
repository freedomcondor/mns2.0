local myType = robot.params.my_type

--[[
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/vns/?.lua"
package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/?.lua"
--]]
if robot.params.hardware ~= "true" then
	package.path = package.path .. ";@CMAKE_CURRENT_BINARY_DIR@/simu/?.lua"
end

pairs = require("AlphaPairs")
local Transform = require("Transform")
-- includes -------------
logger = require("Logger")
local api = require(myType .. "API")
local VNS = require("VNS")
local BT = require("BehaviorTree")
logger.enable()
logger.disable("Stabilizer")
logger.disable("droneAPI")

-- datas ----------------
local bt
--local vns
local structure1 = require("morphology1")
local structure2 = require("morphology2")
local structure3 = require("morphology3")
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

-- VNS option
-- VNS.Allocator.calcBaseValue = VNS.Allocator.calcBaseValue_oval -- default is oval

-- called when a child lost its parent
function VNS.Allocator.resetMorphology(vns)
	vns.Allocator.setMorphology(vns, structure1)
end

-- argos functions -----------------------------------------------
--- init
function init()
	api.linkRobotInterface(VNS)
	api.init() 
	vns = VNS.create(myType)
	reset()
end

--- reset
function reset()
	vns.reset(vns)
	--if vns.idS == "pipuck1" then vns.idN = 1 end
	if vns.idS == robot.params.stabilizer_preference_brain then vns.idN = 1 end
	vns.setGene(vns, gene)
	vns.setMorphology(vns, structure1)

	bt = BT.create
	{ type = "sequence", children = {
		vns.create_preconnector_node(vns),
		vns.create_vns_core_node(vns),
		vns.CollectiveSensor.create_collectivesensor_node_reportAll(vns),
		create_head_navigate_node(vns),
		vns.Driver.create_driver_node(vns),
	}}
end

--- step
function step()
	-- prestep
	--logger(robot.id, "-----------------------")
	api.preStep()
	vns.preStep(vns)

	-- step
	bt()

	-- poststep
	vns.postStep(vns)
	api.postStep()

	vns.logLoopFunctionInfo(vns)
	-- debug
	api.debug.showChildren(vns)
	if vns.robotTypeS == "drone" then
		api.debug.showObstacles(vns)
	end
end

--- destroy
function destroy()
	api.destroy()
end

----------------------------------------------------------------------------------
function create_head_navigate_node(vns)
local state = 1
local obstacle_type = 34
local target_type = 33

	local function sendChilrenNewState(vns, newState)
		for idS, childR in pairs(vns.childrenRT) do
			vns.Msg.send(idS, "switch_to_state", {state = newState})
		end
	end

	local function newState(vns, _newState)
		stateCount = 0
		state = _newState
	end

	local function switchAndSendNewState(vns, _newState)
		newState(vns, _newState)
		sendChilrenNewState(vns, _newState)
	end

return function()
	-- for debug
	vns.state = state

	-- if I receive switch state cmd from parent
	if vns.parentR ~= nil then for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "switch_to_state")) do
		switchAndSendNewState(vns, msgM.dataT.state)
	end end

	if vns.parentR == nil then
		-- brain detect width
		local middle = 0.7
		if state == 3 then
			middle = 0.5
		end
		local left = 10
		local right = -10
		for i, ob in ipairs(vns.avoider.obstacles) do
			if ob.positionV3.y > middle and ob.type == obstacle_type and
			   ob.positionV3.y < left then
				left = ob.positionV3.y
			end
			if ob.positionV3.y < middle and ob.type == obstacle_type and
			   ob.positionV3.y > right then
				right = ob.positionV3.y
			end
		end
		for i, ob in ipairs(vns.collectivesensor.receiveList) do
			if ob.positionV3.y > middle and ob.type == obstacle_type and
			   ob.positionV3.y < left then
				left = ob.positionV3.y
			end
			if ob.positionV3.y < middle and ob.type == obstacle_type and
			   ob.positionV3.y > right then
				right = ob.positionV3.y
			end
		end

		local width = left - right

		-- brain run state
		if state == 1 then
			if width < 3.0 then
				state = 2
				vns.setMorphology(vns, structure2)
				logger("state2")
			end
		elseif state == 2 then
			vns.Parameters.stabilizer_preference_robot = nil
			if width < 1.5 then
				state = 3
				vns.setMorphology(vns, structure3)
				logger("state3")
			end
		elseif state == 3 then
			vns.Parameters.stabilizer_preference_robot = nil
			for id, ob in ipairs(vns.avoider.obstacles) do
				if ob.type == target_type then
					state = 4
					vns.setMorphology(vns, structure1)
				end
			end
		elseif state == 4 then
			for id, ob in ipairs(vns.avoider.obstacles) do
				if ob.type == target_type then
					vns.setGoal(vns, ob.positionV3 - vector3(0.5, 0.7, 0), ob.orientationQ)
					--[[
					if vns.goal.positionV3:length() < 0.3 then
						state = 5
					end
					--]]
					return false, true
				end
			end
		elseif state == 5 then
			-- reach do nothing
			return false, true
		end

		-- align with the average direction of the obstacles
		if #vns.avoider.obstacles ~= 0 or #vns.collectivesensor.receiveList ~= 0 then
			local orientationAcc = Transform.createAccumulator()

			-- add vns.avoider.obstacles and vns.collectivesensor.receiveList together
			local totalGateSideList = {}
			for i, ob in ipairs(vns.avoider.obstacles) do
				totalGateSideList[#totalGateSideList + 1] = ob
			end
			for i, ob in ipairs(vns.collectivesensor.receiveList) do
				totalGateSideList[#totalGateSideList + 1] = ob
			end

			for id, ob in ipairs(totalGateSideList) do
				-- check left and right
				if ob.positionV3.y > 0 and ob.type == obstacle_type and
				   ob.positionV3.y < left then
					left = ob.positionV3.y
			 	end
				if ob.positionV3.y < 0 and ob.type == obstacle_type and
				   ob.positionV3.y > right then
					right = ob.positionV3.y
				end

				-- accumulate orientation
				Transform.addAccumulator(orientationAcc, {positionV3 = vector3(), orientationQ = ob.orientationQ})
			end

			local averageOri = Transform.averageAccumulator(orientationAcc).orientationQ

			if vns.stabilizer.referencing_robot ~= nil then
				vns.Msg.send(vns.stabilizer.referencing_robot.idS, "new_heading", 
					{heading = vns.api.virtualFrame.Q_VtoR(averageOri)}
				)
			else
				vns.setGoal(vns, vns.goal.positionV3, averageOri)
			end
		end

		-- brain calc y speed
		local SpeedY = 0
		if left > middle and right < middle and 
		   left < 9 and right > -9 then
			if vns.stabilizer.referencing_robot == nil then
				local newGoalPositionV3 = vns.goal.positionV3
				local Y_offset = 0.7
				if state == 3 then Y_offset = 0.35 end
				SpeedY = (left + right) / 2 - Y_offset
			end
		end

		-- brain move forward
		if vns.api.stepCount < 250 then return false, true end
		local speed = 0.03
		vns.Spreader.emergency_after_core(vns, vector3(speed,SpeedY * speed,0), vector3())
	end

	-- reference lead move
	if vns.stabilizer.referencing_me == true then
		-- receive from brain information about heading and middle
		vns.stabilizer.referencing_me_goal_overwrite = {}
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "new_heading")) do
			vns.stabilizer.referencing_me_goal_overwrite = {orientationQ = vns.parentR.orientationQ * msgM.dataT.heading}
		end

		--[[
		for _, msgM in ipairs(vns.Msg.getAM(vns.parentR.idS, "middleY")) do
			local middleV3 = vns.parentR.positionV3 + (msgM.dataT.positionY * vector3(0,1,0)):rotate(vns.parentR.orientationQ)
			newGoalPosition = vector3(vns.goal.positionV3)
			newGoalPosition.y = middleV3.y
			vns.stabilizer.referencing_me_goal_overwrite = {positionV3 = newGoalPosition}
		end
		--]]
	end

	return false, true
end end