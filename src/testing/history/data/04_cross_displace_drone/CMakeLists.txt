# experiment/testing/03_cross_displace

# Compile loop functions
add_library(vns_loop_functions_04_cross_displace_drone MODULE
   vns_loop_functions.h
   vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_04_cross_displace_drone
   ${SROCS_ENTITIES_LIBRARY})

configure_file( vns.argos.in     vns.argos)
configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( morphology.lua   morphology.lua)

configure_file( vns_template.argos.in
                vns_template.argos)

add_subdirectory(evaluator)