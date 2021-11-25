make_directory(files)

configure_file( dummy_pipuck.lua                dummy_pipuck.lua)

configure_file( 01_drone_api_simu.in.argos      01_drone_api_simu.argos)
configure_file( 01_drone_api_hw.argos           files/01_drone_api_hw.argos)
configure_file( 01_drone_api.lua                files/01_drone_api.lua)

configure_file( 02_drone_driver_simu.in.argos      02_drone_driver_simu.argos)
configure_file( 02_drone_driver_hw.argos           files/02_drone_driver_hw.argos)
configure_file( 02_drone_driver.lua                files/02_drone_driver.lua)

file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/api/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/utils/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
file(GLOB MY_PUBLIC_HEADERS ${CMAKE_SOURCE_DIR}/core/vns/*)
file(COPY ${MY_PUBLIC_HEADERS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)