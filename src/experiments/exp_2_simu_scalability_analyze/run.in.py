createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math

# abuse Experiment_length as drone number
n_drone = Experiment_length

print("n_drone", n_drone)

n_pipuck = n_drone * 4
arena_size = n_drone * 3 + 2

# drone and pipuck
drone_locations = generate_random_locations(n_drone,                        # total number
                                            n_drone * 0.25, 0,              # origin location
                                            -n_drone * 0.25-1, n_drone * 0.25+1,              # random x range
                                            -3, 3,              # random y range
                                            1.3, 1.5)                       # near limit and far limit
pipuck_locations = generate_slave_locations_with_origin(n_pipuck,
                                            drone_locations,
                                            n_drone * 0.25, 0,              # origin location
                                            -n_drone * 0.25-1, n_drone * 0.25+1,              # random x range
                                            -3, 3,              # random y range
                                            0.5, 0.9)                       # near limit and far limit

drone_xml = generate_drones(drone_locations, 1)                 # from label 1 generate drone xml tags
pipuck_xml = generate_pipucks(pipuck_locations, 1)              # from label 1 generate pipuck xml tags


params = '''
              n_drone="{}"
              stabilizer_preference_robot="pipuck1"
              stabilizer_preference_brain="drone1"
              drone_tag_detection_rate="1"
              drone_default_height="1.8"
              drone_default_start_height="1.8"
              dangerzone_drone="1.3"
              dangerzone_reference_pipuck_scalar="1.3"
              deadzone_reference_pipuck_scalar="2"
              morphologiesGenerator="morphologiesGenerator"

              avoid_block_vortex="nil"
              deadzone_block="0.2"
'''.format(n_drone)

# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                    "vns.argos",
	[
		["RANDOMSEED",        str(Inputseed)],
		["TOTALLENGTH",       str((2000)/5)],
		["DRONES",            drone_xml], 
		["PIPUCKS",           pipuck_xml], 
		#["WALL",              wall_xml], 
		["ARENA_SIZE",        str(arena_size)], 
		#["OBSTACLES",         obstacle_xml], 
		#["TARGET",            target_xml], 
		["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="pipuck"
              avoid_speed_scalar="1.0"
        ''' + params)],
		["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/common.lua"
              my_type="drone"
        ''' + params)],
		["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
	]
)

os.system("argos3 -c vns.argos" + VisualizationArgosFlag)
