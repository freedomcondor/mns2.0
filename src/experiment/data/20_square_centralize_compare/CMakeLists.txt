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

configure_file( morphology_template.lua  morphology_template.lua  COPYONLY)

configure_file( run_demo.in.py
                run_demo.py)

add_subdirectory(evaluator)
add_subdirectory(scripts)