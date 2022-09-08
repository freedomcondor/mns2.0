createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))
# createArgosScenario parse the parameters
# python3 run.py -r 12 -l 500 -v false (-r: randomseed, -l: experiment length, -v: run with visualization GUI or not)
# Inputseed, Experiment_length, Visualization = True or False, VisualizationArgosFlag = "" or " -z" in inherited

import os

# drone and pipuck
drone_locations = generate_random_locations(2,                  # total number
                                            -3.0, -0.7,         # origin location
                                            -4.0, -2.8,         # random x range
                                            -1.5, 1.5,          # random y range
                                            1.5, 1.7)           # near limit and far limit
pipuck_locations = generate_slave_locations_with_origin(
                                            6,
                                            drone_locations,
                                            -2.6, 0,
                                            -4.0, -2.3,         # random x range
                                            -1.5, 1.5,          # random y range
                                            0.5, 0.7)           # near limit and far limit
drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# obstacles
large_obstacle_locations = generate_random_locations(10,              # total number
                                               None, None,      # origin location
                                               -2.0, 2.0,       # x range
                                               -2.2, 2.2,       # y range
                                               1.2, 3.0)        # near and far limit

obstacle1_locations = []
obstacle2_locations = []
obstacle3_locations = []
#d = 0.10 * math.sqrt(2)
d = 0.06
for loc in large_obstacle_locations :
    obstacle1_locations.append([loc[0] - d, loc[1]])
for loc in large_obstacle_locations :
    obstacle2_locations.append([loc[0] + d, loc[1] + d])
for loc in large_obstacle_locations :
    obstacle3_locations.append([loc[0] + d, loc[1] - d])
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

obstacle_xml = generate_obstacles(obstacle1_locations, 100, 34) # start id and payload
obstacle_xml = obstacle_xml + generate_obstacles(obstacle2_locations, 180, 32) # start id and payload
obstacle_xml = obstacle_xml + generate_obstacles(obstacle3_locations, 260, 31) # start id and payload

obstacle_xml += generate_obstacle_box_xml(300, 4.0, 0, 0, 33)  # start id, location x, y, th, and payload

# generate argos file
params = '''
      stabilizer_preference_robot="pipuck1"
      stabilizer_preference_brain="drone1"
      pipuck_wheel_speed_limit="0.2"
      drone_default_height="1.7"

      pipuck_label_from="1"
      pipuck_label_to="20"
      block_label_from="30"
      block_label_to="35"

      avoid_block_vortex="nil"
'''

#safezone_drone_pipuck="1.0"

generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
		["TOTALLENGTH",       str((Experiment_length or 2500)/5)],
		["REAL_SCENARIO",     generate_real_scenario_object()],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["OBSTACLES",         obstacle_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
            ''' + params)],
              #pipuck_rotation_scalar="0.03"
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
            ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)