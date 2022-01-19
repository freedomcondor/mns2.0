createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
drone_locations = []
matrix = [2, 2]
start = [0, 0]
step  = [1.2, 1.2]
for i in range(0, matrix[0]) :
	for j in range(0, matrix[1]) :
		drone_locations.append([start[0] + step[0] * i, 
		                        start[1] + step[1] * j])

pipuck_locations = []
matrix = [5, 2]
start = [0, 0.4]
step  = [0.3, 0.3]
for i in range(0, matrix[0]) :
	for j in range(0, matrix[1]) :
		pipuck_locations.append([start[0] + step[0] * i, 
		                         start[1] + step[1] * j])

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
	[
		["RANDOMSEED",        Inputseed],
		["TOTALLENGTH",       str(1000)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
        ''')],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="drone"
              safezone_drone_drone="1.3"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos")