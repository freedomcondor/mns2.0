createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = generate_random_locations(3,                  # total number
                                            -4, -0,             # origin location
                                            -4.5, -3.5,         # random x range
                                            -2, 2,              # random y range
                                            1.2, 1.7)             # near limit and far limit

pipuck_locations = generate_slave_locations_with_origin(
                                            8,
                                            drone_locations,
                                            -3.3, 0.7,
                                            -4.8, -3,           # random x range
                                            -1.5, 1.5,          # random y range
                                            0.5, 0.7)           # near limit and far limit

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

obstacle_locations = generate_line_locations(10,               # number of obstacles
                                              -3.0, 2.8,        # begin x and y
                                              0.0, 1.0)         # end x and y
obstacle_locations2 = generate_line_locations(10,               # number of obstacles
                                              -3.0, -2.8,       # begin x and y
                                              0.0, -1.0)        # end x and y

obstacle_locations += obstacle_locations2

obstacle_xml = generate_obstacles(obstacle_locations, 100, 100) # start id and payload
obstacle_xml += generate_obstacle_box_xml(121, 4.5, 0, 0, 101)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 0)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["OBSTACLES",         obstacle_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
        ''')],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="drone"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              drone_default_height="1.8"
              block_label_from="100"
              block_label_to="101"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)