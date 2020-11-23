-- Avoider -----------------------------------------
------------------------------------------------------
local Avoider = {}

function Avoider.create(vns)
	vns.avoider = {}
	vns.avoider.obstacles = {}
	Avoider.reset(vns)
end

function Avoider.reset(vns)
	vns.avoider = {}
end

function Avoider.preStep(vns)
	vns.avoider.obstacles = {}
end


function Avoider.step(vns)
	local drone_distance = 0.50
	local pipuck_distance = 0.30
	local block_distance = 0.30
	local predator_distance = 0.50

	local avoid_speed = {positionV3 = vector3(), orientationV3 = vector3()}
	-- avoid seen robots
	for idS, robotR in pairs(vns.connector.seenRobots) do
		-- avoid drone
		if robotR.robotTypeS == vns.robotTypeS and
		   robotR.robotTypeS == "drone" then
			avoid_speed.positionV3 =
				Avoider.add(vector3(), robotR.positionV3,
				            avoid_speed.positionV3,
							drone_distance,
				            true)
		end
		-- avoid pipuck
		if robotR.robotTypeS == vns.robotTypeS and
		   robotR.robotTypeS == "pipuck" then
			avoid_speed.positionV3 =
				Avoider.add(vector3(), robotR.positionV3,
				            avoid_speed.positionV3,
				            pipuck_distance,
				            true)
		end
	end
	-- avoid obstacles
	if vns.robotTypeS ~= "drone" then
		for i, obstacle in ipairs(vns.avoider.obstacles) do
			avoid_speed.positionV3 = 
				Avoider.add(vector3(), obstacle.positionV3,
				            avoid_speed.positionV3,
				            block_distance)
		end
	end

	-- avoid predators
	for i, obstacle in ipairs(vns.avoider.obstacles) do
		if obstacle.type == 3 and vns.robotTypeS == "drone" then
			local runawayV3 = vector3()
			--runawayV3 = Avoider.add(vector3(), obstacle.positionV3, runawayV3, predator_distance)
			runawayV3 = vector3() - obstacle.positionV3
			runawayV3.z = 0
			runawayV3:normalize()
			runawayV3 = runawayV3 * 0.03
			vns.Spreader.emergency(vns, runawayV3, vector3(), "green") -- TODO: run away from predator
		end
	end

	vns.goal.transV3 = avoid_speed.positionV3
	vns.goal.rotateV3 = avoid_speed.orientationV3
end

function Avoider.add(myLocV3, obLocV3, accumulatorV3, threshold, vortex)
	local dV3 = myLocV3 - obLocV3
	local d = dV3:length()
	if d == 0 then return accumulatorV3 end
	local ans = accumulatorV3
	if d < threshold then
		dV3:normalize()
		local transV3 = - 0.3 * math.log(d/threshold) * dV3:normalize()
		if vortex == true then
			ans = ans + transV3:rotate(quaternion(math.pi/4, vector3(0,0,1)))
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
