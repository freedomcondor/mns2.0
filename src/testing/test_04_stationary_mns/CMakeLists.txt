configure_file( vns.in.argos     vns.argos)
configure_file( common.in.lua    common.lua)
configure_file( morphology.lua   morphology.lua)

configure_file( 01_pipuck_formation_hw.argos          files/01_pipuck_formation_hw.argos)
configure_file( common.in.lua                         files/common.lua)
configure_file( morphology.lua                        files/morphology.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)