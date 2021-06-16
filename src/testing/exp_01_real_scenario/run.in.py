createArgosFileName = "@CMAKE_SOURCE_DIR@/scripts/createArgosScenario.py"
#execfile(createArgosFileName)
exec(compile(open(createArgosFileName, "rb").read(), createArgosFileName, 'exec'))

import os

create_argos_file("@CMAKE_CURRENT_BINARY_DIR@/vns_template.argos", 
                  "@CMAKE_CURRENT_BINARY_DIR@/vns.argos",
	[
		["RANDOMSEED", str(1)],
		["TOTALLENGTH", str(1000)],
		["REAL_SCENARIO", create_real_scenario_object()],
	]
)

os.system("argos3 -c @CMAKE_CURRENT_BINARY_DIR@/vns.argos")