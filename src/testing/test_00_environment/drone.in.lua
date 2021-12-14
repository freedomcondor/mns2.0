package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/api/?.lua"
package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/utils/?.lua"
--package.path = package.path .. ";@CMAKE_SOURCE_DIR@/core/VNS/?.lua"

pairs = require("RandomPairs")
local DeepCopy = require("DeepCopy")

logger = require("Logger")
local api = require("droneAPI")
local BT = require("BehaviorTree")
logger.enable()

local bt

function init()
	logger(robot.id, "-----------------------")
	logger("robot")
	logger(robot)

	api.init()
	bt = BT.create
		{type = "sequence", children = {
			function()
				robot.radios.wifi.send({a = "hi, I'm drone", b = 2})
				logger("I am a btnode")
				return false, true
			end,
		}}

	-- test pairs
	--[[
	local tabletest = {"a", "b" , "c"}
	for i, v in pairs(tabletest) do print(i, v) end
	tabletest.aaa = "aaa"
	for i, v in pairs(tabletest) do print(i, v) end
	--]]

	-- test vector3
	--[[
	logger("vector3")
	logger(getmetatable(vector3()))
	--]]

	-- quaternion test
	--[[
	logger("quaternion test")
	logger(getmetatable(quaternion()))
	vec = vector3(1, 0, 0)
	base = quaternion(math.pi/2, vector3(0,0,1))
	basevec = vector3(vec):rotate(base)
	sub = quaternion(math.pi/4, vector3(0,1,0))
	--sub = base * sub
	sub = sub * base
	subvec = vector3(vec):rotate(sub)
	api.debug.drawArrow("green", vector3(0,0,0.1), subvec+vector3(0,0,0.1))
	--]]

	-- Deepcopy test
	--[[
	local a_deep = {index1 = 1, index2 = vector3(1,1,1)}
	local b_deep = DeepCopy(a_deep)
	b_deep.index2 = vector3(b_deep.index2):rotate(quaternion(math.pi/2, vector3(0,0,1)))
	logger("a_deep")
	logger(a_deep)
	logger("b_deep")
	logger(b_deep)
	--]]
end

function step()
	logger(robot.id, "-----------------------")
	api.preStep()

	api.move(vector3(math.pi/100, 0, 0), vector3(0,0,2*math.pi/100))  -- move along a circle diameter 1m in 100s
	--[[
	if math.fmod(api.stepCount, 10) < 5 then
		api.move(vector3(0.05, 0.05, 0), vector3(0,0,0.01))
	else
		api.move(vector3(-0.05, -0.05, 0), vector3(0,0,0.01))
	end
	--]]

	bt()

	api.droneMaintainHeight(1.8)
	api.postStep()

	-- debug
	for i, tag in ipairs(api.droneDetectTags()) do
		api.debug.drawArrow("blue", vector3(), tag.positionV3)
	end

	-- wifi debug
	robot.radios.wifi.send({a=1, b=2})

	logger(robot.radios.wifi.recv)
end

function reset()
	init()
end

function destroy()
end
