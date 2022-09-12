createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            -3.3, -0.5,             # origin location
                                            -3.5, -2.5,         # random x range
                                            -2, 2,              # random y range
                                            1.2, 1.7)             # near limit and far limit

pipuck_locations = generate_slave_locations_with_origin(
                                            6,
                                            drone_locations,
                                            -3.2, 0,
                                            -3.5, -2.0,           # random x range
                                            -1.5, 1.5,          # random y range
                                            0.4, 0.7)           # near limit and far limit

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# wall
wall_xml, largest_loc = generate_wall(2,                        # number of gates
                                      1,                      # x location of the wall
                                      -2.25, 2.25,                # y range of the wall
                                      0.5, 1.3, 1.5,            # size range, and max of the gate
                                      0.25,                     # block distance to fill the wall
                                      33, 34)                 # gate_brick_type, and wall_brick_type

# obstacles
obstacle_locations = generate_random_locations(8,               # total number
                                               None, None,      # origin location
                                               -1.5, -0.5,      # x range
                                               -1.9, 1.9,       # y range
                                               0.7, 3.0)        # near and far limit
obstacle_xml = generate_obstacles(obstacle_locations, 100, 32) # start id and payload

# target
target_xml = generate_target_xml(3.5, largest_loc, 0,           # x, y, th
                                 27, 27,                      # payload
                                 0.3, 0.3, 0.2)                 # radius and edge and tag distance

params = '''
              dangerzone_block="0.40"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              drone_tag_detection_rate="1"
              drone_default_height="1.5"
              drone_default_start_height="1.5"
              dangerzone_drone="1.3"
              obstacle_unseen_count="0"

    pipuck_label_from="1"
    pipuck_label_to="20"
    block_label_from="25"
    block_label_to="35"
'''

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],
		["TOTALLENGTH",       str((Experiment_length or 2000)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["WALL",              wall_xml], 
		["OBSTACLES",         obstacle_xml], 
		["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              driver_default_speed="0.07"
              my_type="pipuck"
        ''' + params)],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
        ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)