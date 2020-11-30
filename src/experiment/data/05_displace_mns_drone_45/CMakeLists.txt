# experiment/testing/00_environment

# data 05_displace_mns_drone_45
add_library(vns_loop_functions_05_displace_drone_45 MODULE
   vns_loop_functions.h
   vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_05_displace_drone_45
   ${SROCS_ENTITIES_LIBRARY})

configure_file( vns.argos.in     vns.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( morphology.lua   morphology.lua)
configure_file( PipuckMarker.lua       
                PipuckMarker.lua)
configure_file( DroneOnlyConnector.lua       
                DroneOnlyConnector.lua)

configure_file( vns_template.argos.in
                vns_template.argos)

add_subdirectory(evaluator)