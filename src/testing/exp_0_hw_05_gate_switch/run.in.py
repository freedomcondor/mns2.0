createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            None, None,             # origin location
                                            -3.5, -2.5,         # random x range
                                            -1.5, 1.5,              # random y range
                                            1.2, 1.7)             # near limit and far limit

pipuck_locations = generate_slave_locations_with_origin(
                                            6,
                                            drone_locations,
                                            -2.5, 0,
                                            -3.5, -2.5,           # random x range
                                            -1.5, 1.5,          # random y range
                                            0.4, 0.7)           # near limit and far limit

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# wall
wall_xml, largest_loc = generate_wall(2,                        # number of gates
                                      0.5,                      # x location of the wall
                                      -2.2, 2.2,                # y range of the wall
                                      0.5, 0.5, 1.0,            # size range, and max of the gate
                                      0.25,                     # block distance to fill the wall
                                      34, 33)                 # gate_brick_type, and wall_brick_type

# target
target_xml = generate_target_xml(3.0, largest_loc, 0,           # x, y, th
                                 32, 32,                      # payload
                                 0.3, 0.3, 0.2)                 # radius and edge and tag distance

# generate argos file
params = '''
    stabilizer_preference_brain="pipuck1"
    avoid_block_vortex="nil"
    drone_default_height="1.5"

    pipuck_label_from="1"
    pipuck_label_to="20"
    block_label_from="30"
    block_label_to="35"

    obstacle_unseen_count="0"
'''

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 2000)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
        ''' + params)],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="drone"
        ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)