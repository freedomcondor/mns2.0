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
	        |------------+------------------------
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
}