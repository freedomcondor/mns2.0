-- Avoider -----------------------------------------
------------------------------------------------------
local Avoider = {}

function Avoider.create(vns)
	vns.avoider = {}
	vns.avoider.obstacles = {}
end

function Avoider.reset(vns)
	vns.avoider.obstacles = {}
end

function Avoider.preStep(vns)
	vns.avoider.obstacles = {}
end

function Avoider.step(vns)
	local avoid_speed = {positionV3 = vector3(), orientationV3 = vector3()}
	-- avoid seen robots
	-- the brain is not influenced by other robots
	if vns.parentR ~= nil then
		for idS, robotR in pairs(vns.connector.seenRobots) do
			-- avoid drone
			if robotR.robotTypeS == vns.robotTypeS and
			   robotR.robotTypeS == "drone" then
				avoid_speed.positionV3 =
					Avoider.add(vector3(), robotR.positionV3,
					            avoid_speed.positionV3,
					            vns.Parameters.dangerzone_drone,
					            vns.goal.positionV3)
			end
			-- avoid pipuck
			if robotR.robotTypeS == vns.robotTypeS and
			   robotR.robotTypeS == "pipuck" then
				avoid_speed.positionV3 =
					Avoider.add(vector3(), robotR.positionV3,
					            avoid_speed.positionV3,
					            vns.Parameters.dangerzone_pipuck,
					            vns.goal.positionV3)
			end
		end
	end

	-- avoid obstacles
	if vns.robotTypeS ~= "drone" then
		for i, obstacle in ipairs(vns.avoider.obstacles) do
			local vortex = false
			--if obstacle.type == 1 then
			--	vortex = true
			--end
			avoid_speed.positionV3 = 
				Avoider.add(vector3(), obstacle.positionV3,
			            	avoid_speed.positionV3,
					        vns.Parameters.dangerzone_block,
							vns.goal.positionV3)
		end
	end

	-- avoid predators
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.type == 3 and vns.robotTypeS == "drone" then
			local runawayV3 = vector3()
			runawayV3 = vector3() - obstacle.positionV3
			runawayV3.z = 0
			runawayV3:normalize()
			runawayV3 = runawayV3 * vns.Parameters.driver_default_speed
			vns.Spreader.emergency(vns, runawayV3, vector3(), "green") -- TODO: run away from predator
		end
	end

	-- TODO: maybe add surpress or not
	-- add the speed to goal -- the brain can't be influended
	vns.goal.transV3 = vns.goal.transV3 + avoid_speed.positionV3
	vns.goal.rotateV3 = vns.goal.rotateV3 + avoid_speed.orientationV3
end

function Avoider.add(myLocV3, obLocV3, accumulatorV3, threshold, vortex)
	-- calculate the avoid speed from obLoc to myLoc,
	-- add the result into accumulator
	--[[
	        |   |
	        |   |
	speed   |    |  -log(d/dangerzone) * scalar
	        |     |
	        |      \  
	        |       -\
	        |         --\ 
	        |------------+------------------------
	                     |
	                 threshold
	--]]
	-- if vortex is true, rotate the speed to create a vortex
	--[[
	    moveup |     /
	           R   \ Ob \
	                  /
	--]]
	-- if vortex is vector3, it means the goal of the robot is at the vortex, 
	--         add left or right speed accordingly
	--[[
	                 /    
	           R   \ Ob -
	   movedown \    \      * goal(vortex)
	--]]

	local dV3 = myLocV3 - obLocV3
	dV3.z = 0
	local d = dV3:length()
	if d == 0 then return accumulatorV3 end
	local ans = accumulatorV3
	if d < threshold then
		dV3:normalize()
		local transV3 = - vns.Parameters.avoid_speed_scalar 
		                * math.log(d/threshold) 
						* dV3:normalize()
		if type(vortex) == "bool" and vortex == true then
			ans = ans + transV3:rotate(quaternion(math.pi/4, vector3(0,0,1)))
		elseif type(vortex) == "userdata" and getmetatable(vortex) == getmetatable(vector3()) then
			local goalV3 = vortex - myLocV3
			local cos = goalV3:dot(-dV3) / (goalV3:length() * dV3:length())
			if cos > math.cos(60*math.pi/180) then
				local product = (-dV3):cross(goalV3)
				if product.z > 0 then
					ans = ans + transV3:rotate(quaternion(-math.pi/4, vector3(0,0,1)))
				else
					ans = ans + transV3:rotate(quaternion(math.pi/4, vector3(0,0,1)))
				end
			else
				ans = ans + transV3
			end
		else
			ans = ans + transV3
		end
	end
	return ans
end

function Avoider.create_avoider_node(vns)
	return function()
		Avoider.step(vns)
	end
end

return Avoider
