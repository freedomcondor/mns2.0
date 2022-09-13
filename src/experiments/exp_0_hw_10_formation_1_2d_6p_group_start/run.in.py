createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math 

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            0.5, 0,             # origin location
                                            -3, 3,              # random x range
                                            -2, 2,              # random y range
                                            0.8, 1.0)           # near limit and far limit
pipuck_locations = generate_random_locations(6,                  # total number
                                            None, None,
                                            -0.3, 0.3,          # random x range
                                            -0.3, 0.3,          # random y range
                                            0.2, 0.3)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

pipuck_xml = generate_pipucks(pipuck_locations, 2)             # from label 2 generate pipuck xml tags

#pipuck_xml = generate_pipuck_xml(1, -3, 0) + \                 # an extra pipuck and pipuck1
#             generate_pipucks(pipuck_locations, 2)             # from label 2 generate pipuck xml tags

params = '''
    stabilizer_preference_robot="pipuck1"
    stabilizer_preference_brain="drone1"

    block_label_from="25"
    block_label_to="35"

	dangerzone_pipuck="0.70"
	dangerzone_block="0.70"
    deadzone_block="0.2"
    deadzone_pipuck="0.2"

    obstacle_unseen_count="0"
'''
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 1000)/5)],
        ["REAL_SCENARIO",     generate_real_scenario_object()],
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
        ''' + params)],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
        ''' + params)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
    ]
)
              #drone_default_height="1.8"

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)