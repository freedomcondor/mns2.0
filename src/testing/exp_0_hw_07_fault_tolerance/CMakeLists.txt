configure_file( vns_template.in.argos
                vns_template.argos)

configure_file( common.in.lua    common.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/morphologies/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

configure_file( run.in.py
                run.py)

add_subdirectory(scripts)

configure_file( generate_hw_argos.in.py
                generate_hw_argos.py)
configure_file( common.in.lua      hw/common.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/morphologies/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/hw)