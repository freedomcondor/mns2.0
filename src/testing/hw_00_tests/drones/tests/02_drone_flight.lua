local stepCount = 0
local state = "pre_flight"

function init()
	state = "pre_flight"
	stepCount = 0
end

function reset()
	state = "pre_flight"
	stepCount = 0
end
 
function step()
	print("----------- stepCount = ", stepCount, "----------------")
	if robot.flight_system ~= nil and robot.flight_system.ready() then
		stepCount = stepCount + 1
		-- flight preparation state machine
		if state == "pre_flight" then
			robot.flight_system.set_target_pose(vector3(0,0,1.5), 0)

			if stepCount >= 25 then
				state = "armed"
			end
		elseif state == "armed" then
			robot.flight_system.set_target_pose(vector3(0,0,1.5), 0)

			robot.flight_system.set_armed(true, false)
			robot.flight_system.set_offboard_mode(true)
			state = "take_off"
		elseif api.actuator.flight_preparation.state == "take_off" then
			robot.flight_system.set_target_pose(vector3(0,0,1.5), 0)

			if stepCount >= 75 then
				state = "navigation"
			end
		elseif api.actuator.flight_preparation.state == "navigation" then
			robot.flight_system.set_target_pose(vector3(0,0,1.5), 0)
		end
	end
end
 
 
function destroy()

end