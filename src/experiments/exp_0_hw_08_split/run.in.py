createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            1, 0,         # origin location
                                            -2.3, 2.3,         # random x range
                                            -1.3, 1.3,              # random y range
                                            1.2, 1.4)             # near limit and far limit

pipuck_locations = generate_slave_locations_with_origin(
                                            5,
                                            drone_locations,
                                            1, 0.7,
                                            -2.3, 2.3,           # random x range
                                            -1.3, 1.3,          # random y range
                                            0.4, 0.6)           # near limit and far limit

pipuck_locations.remove(pipuck_locations[0])

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

pipuck_xml = generate_pipuck_xml(1, 1, 0.7, 90) + \
             generate_pipucks(pipuck_locations, 2) + \
             generate_pipuck_xml(6, -2, 0, 0) 
                          # from label 2 generate pipuck xml tags

obstacle_xml = generate_obstacle_xml(1, -1, 0.35, 90, 100)

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
		["OBSTACLES",         obstacle_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              single_robot="pipuck6"
              dangerzone_pipuck="0.30"
              safezone_pipuck_pipuck="1.5"
              deadzone_reference_pipuck_scalar="1.5"
        ''')],
              #pipuck_wheel_speed_limit="0.2"
              #pipuck_rotation_scalar="0.03"
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              single_robot="pipuck6"
              drone_default_height="1.5"
              safezone_pipuck_pipuck="1.5"
              block_label_from="100"
              block_label_to="101"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)