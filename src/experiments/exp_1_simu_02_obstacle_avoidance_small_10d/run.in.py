createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

# drone and pipuck
'''
drone_locations = generate_random_locations(10,                  # total number
                                            0, -0.5,             # origin location
                                            -3, 3,              # random x range
                                            -5, 5,              # random y range
                                            1.5, 1.6)           # near limit and far limit
'''
drone_locations = [
    [0, 0],
    [-1, 0],
    [-1, 1.5],
    [-1, -1.5],
    [-2, 0],
    [-2, 1.5],
    [-2, -1.5],
    [-3, 0],
    [-3, 1.5],
    [-3, -1.5],
]

pipuck_locations = generate_slave_locations_with_origin(
                                            40,
                                            drone_locations,
                                            0.7, 0.7,
                                            -3, 3,              # random x range
                                            -5, 5,          # random y range
                                            0.5, 0.8)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

#pipuck_xml = generate_pipuck_xml(1, -3, 0) + \                 # an extra pipuck and pipuck1
#             generate_pipucks(pipuck_locations, 2)             # from label 2 generate pipuck xml tags

# obstacles
obstacle_locations = generate_random_locations(50,              # total number
                                               None, None,      # origin location
                                               3, 8,            # x range
                                               -4, 4,           # y range
                                               1.0, 3.0)        # near and far limit

obstacle_xml = generate_obstacles(obstacle_locations, 100, 100)   # start id and payload
obstacle_xml += generate_obstacle_box_xml(200, 12, 0, 0, 101)  # start id, location x, y, th, and payload

params = '''
    stabilizer_preference_robot="pipuck1"
    stabilizer_preference_brain="drone1"
    pipuck_label_from="1"
    pipuck_label_to="99"
    block_label_from="100"
    block_label_to="101"
'''

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 2500)/5)],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["OBSTACLES",         obstacle_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
              pipuck_wheel_speed_limit="0.2"
        ''' + params)],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
              drone_tag_detection_rate="1"
              drone_default_height="1.8"
              drone_default_start_height="1.8"
              dangerzone_drone="1.3"
        ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)
              #drone_default_height="1.8"

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
