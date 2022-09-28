createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os
import math 

drone_xml = generate_drone_xml(1, -2, 0, 0)
obstacle_xml  = generate_obstacle_box_xml(101, -1.5,  0,    70,  101)
obstacle_xml += generate_obstacle_box_xml(102, -0.6,  1,    10,  102)
obstacle_xml += generate_obstacle_box_xml(103,  0.6,  1,   -10,  103)
obstacle_xml += generate_obstacle_box_xml(104,  1.5,  0,   -110, 104)
obstacle_xml += generate_obstacle_box_xml(105,  0.6,  -1,   190,  105)
obstacle_xml += generate_obstacle_box_xml(106, -0.6,  -1,   170,  106)

params = '''
    block_label_from="101"
    block_label_to="110"
'''
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
#                    "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
                    "vns.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["REAL_SCENARIO",     generate_real_scenario_object()],
        ["DRONES",            drone_xml], 
		["OBSTACLES",         obstacle_xml], 
        ["PIPUCK_CONTROLLER", generate_pipuck_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/dummy_pipuck.lua"
              my_type="pipuck"
        ''' + params)],
        ["DRONE_CONTROLLER", generate_drone_controller('''
              script="@CMAKE_CURRENT_BINARY_DIR@/simu/01_drone_api.lua"
              my_type="drone"
        ''' + params)],
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@")],
    ]
)
              #drone_default_height="1.8"

#os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos" + VisualizationArgosFlag)
os.system("argos3 -c vns.argos" + VisualizationArgosFlag)