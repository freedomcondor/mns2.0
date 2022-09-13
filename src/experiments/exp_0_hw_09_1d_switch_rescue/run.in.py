createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = generate_random_locations(1,                  # total number
                                            -1.5, 0,         # origin location
                                            -2.5, -1.5,         # random x range
                                            -1.0, 1.0,              # random y range
                                            1.2, 1.5)             # near limit and far limit

pipuck_locations = generate_slave_locations(
                                            3,
                                            drone_locations,
                                            -2.5, -1.5,           # random x range
                                            -1.0, 1.0,          # random y range
                                            0.4, 0.7)           # near limit and far limit

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags

pipuck_xml = generate_pipuck_xml(1, 1.0, 0, 0) + \
             generate_pipucks(pipuck_locations, 2)
                          # from label 2 generate pipuck xml tags

obstacle_xml =  generate_obstacle_box_xml(1, 1.0, 0.3, 0, 101)
obstacle_xml += generate_obstacle_box_xml(2, 1.0, -0.3, 0, 101)
obstacle_xml += generate_obstacle_box_xml(3, 1.3, 0, 0, 101)

target_xml = generate_target_xml(0.5, 0, 90,           # x, y, th
                                     100, 0,                       # payload
                                     0.3, 0.3, 0.3)                      # radius and edge

target_xml_backup = '''
	<prototype id="target" movable="true" friction="2">
		<body position="{},{},0" orientation="{},0,0" />
		<links ref="base">
			<link id="base" geometry="box" size="{}, {}, 0.1" mass="0.10"
			      position="0,0,0" orientation="45,0,0" />
		</links>
		<devices>
			<tags medium="tags">
                <tag anchor="base" observable_angle="75" side_length="0.1078" payload="{}"
                position="0,0,0.11" orientation="-45,0,0" />
			</tags>
		</devices>
    </prototype>
'''.format(0, -1.0, -90, 0.7, 0.7, 100)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 1600)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["OBSTACLES",         obstacle_xml], 
		["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
              stabilizer_preference_brain="drone1"
              dangerzone_pipuck="0.25"
              safezone_pipuck_pipuck="1.5"
              driver_default_speed="0.05"
        ''')],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
              stabilizer_preference_brain="drone1"
              drone_default_height="2.0"
              driver_default_speed="0.05"
              pipuck_label_from="2"
              block_label_from="100"
              block_label_to="101"
              safezone_pipuck_pipuck="1.5"
        ''')],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

'''
              stabilizer_preference_robot="pipuck1"
'''

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)