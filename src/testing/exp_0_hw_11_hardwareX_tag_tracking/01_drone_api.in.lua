logger = require("Logger")
api = require("droneAPI")
logger.enable()
logger.disable("droneAPI")

local target = vector3()
local lostCount = 0

function init()
	api.init()
end

function reset()
end

local reference_block_id = 101
local reference_block = nil

function step()
	logger("-- " .. robot.id .. " " .. tostring(api.stepCount) .. " ------------------------------------")
	api.preStep() 

	-- add obstacles into seenObstacles 
	local seenObstacles = {}
	api.droneAddObstacles(
		api.droneDetectTags(),
		seenObstacles
	)

	-- print and check
	logger("seenObstacles")
	logger(seenObstacles)

	-- update reference block
	local seen_reference_block = false
	for id, ob in ipairs(seenObstacles) do
		if ob.type == reference_block_id then
			reference_block = ob
			seen_reference_block = true
			break
		end
	end

	-- print and check
	logger("reference")
	logger(reference_block)

	if reference_block ~= nil then
		robot.leds.set_leds("blue")
		if seen_reference_block == true then
			target = reference_block.positionV3
		else
			target = vector3(1.0, 0, 0):rotate(reference_block.orientationQ)
		end

		-- check arrive target
		local target2D = target
		target2D.z = 0
		if target2D:length() < 0.25 then
			reference_block_id = reference_block_id + 1
			if reference_block_id == 107 then reference_block_id = 101 end
		end

		-- fly towards the target
		local speed = target
		speed.z = 0
		local speed = speed:normalize() * 0.05
		api.droneSetSpeed(speed.x, speed.y, 0, 0)
		--api.move(vector3(0.1, 0, 0), vector3())

		--api.droneMaintainHeight(1.8)
	end

	api.postStep()
end

function destroy()
	api.destroy()
end