configure_file( vns_template.argos.in     
                vns_template.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( block.lua        block.lua)

configure_file( morphology.lua  morphology.lua  COPYONLY)

configure_file( run_demo.in.py
                run_demo.py)

add_subdirectory(evaluator)