createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = []
matrix = [3, 1]
start = [1.5, 0]
step  = [-1.5, 0]
for i in range(0, matrix[0]) :
	for j in range(0, matrix[1]) :
		drone_locations.append([start[0] + step[0] * i, 
		                        start[1] + step[1] * j])

pipuck_locations = []
matrix = [4, 2]
start = [2.2, 0.7]
step  = [-1.5, -1.4]
for i in range(0, matrix[0]) :
	for j in range(0, matrix[1]) :
		pipuck_locations.append([start[0] + step[0] * i, 
		                         start[1] + step[1] * j])

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

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
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              dangerzone_pipuck="0.30"
              pipuck_wheel_speed_limit="0.2"
              pipuck_rotation_scalar="0.03"
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