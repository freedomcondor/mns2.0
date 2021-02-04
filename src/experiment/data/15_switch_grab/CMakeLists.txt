configure_file( vns_template.argos.in     
                vns_template.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( block.lua        block.lua)

configure_file( morphology1.lua  morphology1.lua  COPYONLY)
configure_file( morphology2.lua  morphology2.lua  COPYONLY)
configure_file( morphology3.lua  morphology3.lua  COPYONLY)
configure_file( morphology4.lua  morphology4.lua  COPYONLY)

configure_file( run_demo.in.py
                run_demo.py)

add_subdirectory(evaluator)