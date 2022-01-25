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
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

#pipuck_xml = generate_pipuck_xml(1, -3, 0) + \                 # an extra pipuck and pipuck1
#             generate_pipucks(pipuck_locations, 2)             # from label 2 generate pipuck xml tags

pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# wall
wall_xml, largest_loc = generate_wall(1,                        # number of gates
                                      0,                        # x location of the wall
                                      -2.9, 2.9,                # y range of the wall
                                      0.5, 1.5,                 # size range of the gate
                                      0.25,                     # block distance to fill the wall
                                      253, 254)                 # gate_brick_type, and wall_brick_type

# obstacles
obstacle_locations = generate_random_locations(10,               # total number
                                               None, None,      # origin location
                                               -2.5, -0.5,      # x range
                                               -2.0, 2.0,       # y range
                                               0.5, 3.0)        # near and far limit
mark_locations = generate_line_locations(2, 1, largest_loc, 2.5, largest_loc)
obstacle_locations += mark_locations
obstacle_xml = generate_obstacles(obstacle_locations, 100, 255) # start id and payload

# target
target_xml = generate_target_xml(3.5, largest_loc, 0,           # x, y, th
                                 252,                           # payload
                                 0.3, 0.3)                      # radius and edge

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],
		["TOTALLENGTH",       str((Experiment_length or 1000)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["WALL",              wall_xml], 
		["OBSTACLES",         obstacle_xml], 
		["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/pipuck.lua"
              dangerzone_block="0.30"
              safezone_drone_drone="1.0"
        ''')],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/drone.lua"
              dangerzone_block="0.30"
              block_label_from="252"
              block_label_to="255"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)