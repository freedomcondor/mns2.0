configure_file( vns_template.in.argos
                vns_template.argos)

configure_file( common.in.lua    common.lua)

file(COPY        ${CMAKE_CURRENT_SOURCE_DIR}/morphologies
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

configure_file( run.in.py
                run.py)

add_subdirectory(scripts)