## simulation
configure_file( vns_template.in.argos
                vns_template.argos)

configure_file( run.in.py
                run.py)

configure_file( 01_drone_api.in.lua      hw/01_drone_api.lua)
configure_file( 01_drone_api.in.lua      simu/01_drone_api.lua)
configure_file( dummy_pipuck.lua         hw/dummy_pipuck.lua)
configure_file( dummy_pipuck.lua         simu/dummy_pipuck.lua)
## scripts
add_subdirectory(scripts)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/simu)