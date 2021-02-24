configure_file( vns_template.argos.in     
                vns_template.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( block.lua        block.lua)

configure_file( morphology1_template.lua  morphology1_template.lua  COPYONLY)
configure_file( morphology2_template.lua  morphology2_template.lua  COPYONLY)
configure_file( morphology3_template.lua  morphology3_template.lua  COPYONLY)

configure_file( run_demo.in.py
                run_demo.py)

add_subdirectory(evaluator)
add_subdirectory(scripts)