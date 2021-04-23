return {
	-- safe zone and danger zone-----------------------------------
	-- recruit happens only if robots in the safezone
	-- robots wait if neighbours outside the safezone
	safezone_drone_drone = tonumber(robot.params.safezone_drone_drone or 1.35),
	safezone_drone_pipuck = tonumber(robot.params.safezone_drone_pipuck or 0.9),
	safezone_pipuck_pipuck = tonumber(robot.params.safezone_pipuck_pipuck or 0.9),

	-- robots avoid each other within dangerzone
	dangerzone_drone = tonumber(robot.params.dangerzone_drone or 1.00),
	dangerzone_pipuck = tonumber(robot.params.dangerzone_pipuck or 0.15),
	dangerzone_block = tonumber(robot.params.dangerzone_block or 0.15),
	dangerzone_predator = tonumber(robot.params.dangerzone_predator or 0.50),

	-- avoid speed
	--[[
	        |   |
	        |   |
	speed   |    |  -log(d/dangerzone) * scalar
	        |     |
	        |      \  
	        |       -\
	        |         --\ 
	        |            ---\ 
	        |---------------+------------------------ d
	                        |
	                    dangerzone
	--]]
	avoid_speed_scalar = tonumber(robot.params.avoid_speed_scalar or 0.3),

	-- driver --------------------------------------------------------
	--[[
	        |          slowdown            
	        |              /----------- default_speed
	speed   |             /
	        |            /
	        |       stop/ 
	        |-----------------------------------
	                      distance
	--]]
	driver_default_speed = tonumber(robot.params.driver_default_speed or 0.03),
	driver_slowdown_zone = tonumber(robot.params.driver_slowdown_zone or 0.35),
	driver_stop_zone = tonumber(robot.params.driver_stop_zone or 0.01),
	driver_default_rotate_scalar = tonumber(robot.params.driver_default_rotate_scalar or 0.3),

	-- time out
	connector_locker_count_reset = tonumber(robot.params.connector_locker_count_reset or 3),
		-- usually locker count is set to vns.depth + 2 everytime vns id got updated.
		-- locker_count_reset is only used to set a init number when experiment starts
	connector_waiting_count = tonumber(robot.params.connector_waiting_count or 3),
		-- robots wait this waiting_count steps for ack after recruiting a robot
	connector_waiting_parent_count = tonumber(robot.params.connector_waiting_parent_count or 5),
		-- robots wait this waiting_parent_count steps for a parent recuit again
	connector_unseen_count = tonumber(robot.params.connector_unseen_count or 3),
		-- robots disconnect after this steps after losing visual of a robot
	connector_heartbeat_count = tonumber(robot.params.connector_heartbeat_count or 3),
		-- robots disconnect after this steps after stop receiving hearbeat from a neighbour (parent + children)

	brainkeeper_time = tonumber(robot.params.brainkeeper_time or 100), 
}