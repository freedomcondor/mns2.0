createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os
import math

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            -4, -0.7,           # origin location
                                            -4.5, -3.5,         # random x range
                                            -0.7, 2,            # random y range
                                            1.2, 2)             # near limit and far limit
pipuck_locations = generate_slave_locations(6,
                                            drone_locations,
                                            -4.8, -3,           # random x range
                                            -1.5, 1.5,          # random y range
                                            0.5, 0.7)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# obstacles
large_obstacle_locations = generate_random_locations(80,               # total number
                                                     None, None,      # origin location
                                                     -3, 3,      # x range
                                                     -2.5, 2.5,       # y range
                                                     1.0, 3.0)        # near and far limit
obstacle_locations = []
#d = 0.10 * math.sqrt(2)
d = 0.10
d_sqrt3_2 = d / math.sqrt(3)
for loc in large_obstacle_locations :
    obstacle_locations.append([loc[0], loc[1] + d_sqrt3_2 * 2])
    obstacle_locations.append([loc[0] + d, loc[1] - d_sqrt3_2])
    obstacle_locations.append([loc[0] - d, loc[1] - d_sqrt3_2])
    '''
    obstacle_locations.append([loc[0]-d, loc[1]-d])
    obstacle_locations.append([loc[0]+d, loc[1]-d])
    obstacle_locations.append([loc[0]+d, loc[1]+d])
    obstacle_locations.append([loc[0]-d, loc[1]+d])
    obstacle_locations.append([loc[0]-d, loc[1]])
    obstacle_locations.append([loc[0], loc[1]-d])
    obstacle_locations.append([loc[0]+d, loc[1]])
    obstacle_locations.append([loc[0], loc[1]+d])
    '''

obstacle_xml = generate_obstacles(obstacle_locations, 100, 0) # start id and payload

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 3700)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["OBSTACLES",         obstacle_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
              connector_unseen_count="30"
        ''')],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="drone"
              drone_tag_detection_rate="1.0"
              connector_unseen_count="30"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)