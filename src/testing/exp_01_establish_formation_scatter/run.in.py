createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
drone_locations = generate_random_locations(4,                  # total number
                                            0, 0,               # origin location
                                            -3, 3,              # random x range
                                            -2, 2,              # random y range
                                            1.0, 1.3)           # near limit and far limit
pipuck_locations = generate_slave_locations(10,
                                            drone_locations,
                                            -4, 4,              # random x range
                                            -2.5, 2.5,          # random y range
                                            0.5, 1.0)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags
#pipuck_xml = generate_pipuck_xml(1, -3, 0) + \                 # an extra pipuck and pipuck1
#             generate_pipucks(pipuck_locations, 2)             # from label 2 generate pipuck xml tags

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