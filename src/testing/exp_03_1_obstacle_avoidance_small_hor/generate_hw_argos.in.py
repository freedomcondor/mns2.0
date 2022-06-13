createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

params = '''
    script="common.lua"
    stabilizer_preference_robot="pipuck1"
    stabilizer_preference_brain="drone1"

    connector_waiting_count="5"
    connector_waiting_parent_count="8"
    connector_unseen_count="20"
    connector_heartbeat_count="10"

    pipuck_label_from="1"
    pipuck_label_to="20"
    block_label_from="30"
    block_label_to="35"
'''

# generate argos file
generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/drone_hw.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/hw/01_drone.argos",
	[
		["PARAMS",       params],  
	]
)

generate_argos_file("@CMAKE_SOURCE_DIR@/scripts/argos_templates/pipuck_hw.argos", 
                    "@CMAKE_CURRENT_BINARY_DIR@/hw/01_pipuck.argos",
	[
		["PARAMS",       params],  
	]
)