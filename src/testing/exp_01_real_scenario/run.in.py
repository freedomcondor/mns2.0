createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
drone_locations = generate_random_locations(3,                  # total number
                                            -3, 0,              # origin location
                                            -5, -3,             # random x range
                                            -2, 2,              # random y range
											0.5, 1.0)           # near limit and far limit
pipuck_locations = generate_slave_locations(8,
                                            drone_locations,
                                            -5, -3,             # random x range
                                            -2, 2,              # random y range
											0.5, 1.0)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from lable 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from lable 1 generate pipuck xml tags

# wall
wall_xml, largest_loc = generate_wall(1,                        # number of gates
                                      0,                        # x location of the wall
                                      -2.9, 2.9,                # y range of the wall
                                      0.5, 1.5,                 # size range of the gate
                                      0.15)                     # block distance to fill the wall

# obstacles
obstacle_locations = generate_random_locations(5,               # total number
                                               None, None,      # origin location
                                               -2.5, -0.5,      # x range
                                               -1.0, 1.0,       # y range
                                               0.0, 3.0)          # near and far limit

obstacle_xml = generate_obstacles(obstacle_locations, 100, "black")

# target
target_xml = generate_target_xml(3.5, largest_loc, 0.3, 0.3)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
	[
		["RANDOMSEED",    str(1)],
		["TOTALLENGTH",   str(1000)],
		["REAL_SCENARIO", generate_real_scenario_object()],
		["DRONES",        drone_xml], 
		["PIPUCKS",       pipuck_xml], 
		["WALL",          wall_xml], 
		["OBSTACLES",     obstacle_xml], 
		["TARGET",        target_xml], 
	]
)

os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos")