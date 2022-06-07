createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math

exp_scale = 3

n_drone = exp_scale * 2 * 3 + 1
n_pipuck = n_drone * 2

arena_size = exp_scale * 10 + 8 + (n_drone)/math.pi

'''
# drone and pipuck
drone_locations = generate_random_locations(n_drone,                        # total number
                                            -exp_scale - 2, 0,              # origin location
                                            -exp_scale*2-2, -1,             # random x range
                                            -exp_scale*2,exp_scale*2,       # random y range
                                            1.3, 1.7)                       # near limit and far limit
pipuck_locations = generate_slave_locations_with_origin(n_pipuck,
                                            drone_locations,
                                            -exp_scale-2+0.8, 0.4,          # origin
                                            -exp_scale*2-2, -1,             # random x range
                                            -exp_scale*2,exp_scale*2,       # random y range
                                            0.5, 1.0)                       # near limit and far limit
'''
'''
x = -2
drone_locations = []
pipuck_locations = []
drone_locations.append([x, 0])
pipuck_locations.append([x - 0.5, +0.5])
pipuck_locations.append([x + 0.5, +0.5])
pipuck_locations.append([x - 0.5, -0.5])
pipuck_locations.append([x + 0.5, -0.5])

for i in range(1, exp_scale + 1):
    drone_locations.append([x, 1.5 * i])
    drone_locations.append([x, -1.5 * i])
    pipuck_locations.append([x + 0.5, 1.5 * i+0.5])
    pipuck_locations.append([x + 0.5, -1.5 *i-0.5])
    pipuck_locations.append([x - 0.5, 1.5 * i+0.5])
    pipuck_locations.append([x - 0.5, -1.5 *i-0.5])
'''

# wall
wall_xml, largest_loc = generate_wall(1,                        # number of gates
                                      -3,                        # x location of the wall
                                      -exp_scale*1.5-2, 
                                      exp_scale*1.5+2,          # y range of the wall
                                      0.8, 3.8, 4.0,                 # size range and max of the gate
                                      0.25,                     # block distance to fill the wall
                                      253, 254)                 # gate_brick_type, and wall_brick_type

x = 0 
drone_locations = []
pipuck_locations = []
drone_locations.append([x, largest_loc])
pipuck_locations.append([x + 0.5, largest_loc+0.5])
pipuck_locations.append([x - 0.5, largest_loc+0.5])

for i in range(1, exp_scale * 2 + 1):
    drone_locations.append([x - 1.5 * i,        largest_loc])
    pipuck_locations.append([x - 1.5 * i + 0.5, largest_loc + 0.5])
    pipuck_locations.append([x - 1.5 * i - 0.5, largest_loc - 0.5])

    drone_locations.append([x - 1.5 * i + 1.5,         largest_loc + 1.5])
    pipuck_locations.append([x - 1.5 * i + 1.5, largest_loc + 1.5 + 0.3])
    pipuck_locations.append([x - 1.5 * i + 0.5, largest_loc + 1.5 - 0.5])

    '''
    drone_locations.append([x - 1.5 * i + 1.5,         largest_loc - 1.5])
    pipuck_locations.append([x - 1.5 * i + 1.5, largest_loc - 1.5 + 0.5])
    pipuck_locations.append([x - 1.5 * i + 0.5, largest_loc - 1.5 - 0.5])
    '''

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags

# obstacles
'''
obstacle_locations = generate_random_locations(10,               # total number
                                               None, None,      # origin location
                                               -1.5, -0.5,      # x range
                                               -2.0, 2.0,       # y range
                                               0.5, 3.0)        # near and far limit
obstacle_xml = generate_obstacles(obstacle_locations, 100, 255) # start id and payload
'''

# target
droneDis = 1.5
n = exp_scale * 2 + 2
alpha = math.pi * 2 / n
th = (math.pi - alpha) / 2
radius = droneDis / 2 / math.cos(th) - 1.0

target_xml = generate_target_xml(1, largest_loc, 0,           # x, y, th
                                 252, 255,                           # payload
                                 radius, 0.1, 0.2)                      # radius and edge

params = '''
              exp_scale="{}"
              n_drone="{}"
              dangerzone_block="0.30"
              block_label_from="252"
              block_label_to="255"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              drone_tag_detection_rate="1"
              drone_default_height="1.8"
              drone_default_start_height="1.8"
              dangerzone_drone="1.3"
              obstacle_unseen_count="0"
              morphologiesGenerator="morphologiesGenerator_forward_again"
              start_state="forward_again"
'''.format(exp_scale, n_drone)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],
		["TOTALLENGTH",       str((Experiment_length or 6000)/5)],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		["WALL",              wall_xml], 
		["ARENA_SIZE",        str(arena_size)], 
		#["OBSTACLES",         obstacle_xml], 
		["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="pipuck"
              avoid_speed_scalar="0.7"
        ''' + params)],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/common.lua"
              my_type="drone"
        ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)