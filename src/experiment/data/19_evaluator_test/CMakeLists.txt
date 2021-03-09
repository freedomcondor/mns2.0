configure_file( vns.argos.in     
                vns.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)

configure_file( morphology.lua  morphology.lua  COPYONLY)

add_subdirectory(evaluator)
add_subdirectory(scripts)