# loop function
add_library(vns_loop_functions_data_21_displace MODULE
   vns_loop_functions.h
   vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_data_21_displace
   ${SROCS_ENTITIES_LIBRARY})
   
configure_file( vns_template.argos.in     
                vns_template.argos)

IF (CMAKE_SYSTEM_NAME MATCHES "Linux")
    set(DATECOMMAND "date")
ELSEIF (CMAKE_SYSTEM_NAME MATCHES "Darwin")
    set(DATECOMMAND "gdate")
ENDIF()

configure_file( drone.lua        drone.lua)
configure_file( pipuck.lua       pipuck.lua)
configure_file( block.lua        block.lua)

configure_file( morphology_chain_template.lua  morphology_chain_template.lua  COPYONLY)
configure_file( morphology_square_template.lua  morphology_square_template.lua  COPYONLY)

configure_file( run_demo.in.py
                run_demo.py)

add_subdirectory(evaluator)
add_subdirectory(scripts)