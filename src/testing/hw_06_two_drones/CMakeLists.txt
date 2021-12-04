make_directory(files)

configure_file( 01_drone_two_simu.in.argos      01_drone_two_simu.argos)
configure_file( 01_drone_two_hw.argos           files/01_drone_two_hw.argos)
configure_file( 01_drone_two.lua                files/01_drone_two.lua)
configure_file( 01_pipuck_two_hw.argos          files/01_pipuck_two_hw.argos)
configure_file( 01_pipuck_two.lua               files/01_pipuck_two.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)