configure_file( simulation.in.argos      simulation.argos)
configure_file( drone_calibration.argos  drone_calibration.argos)
configure_file( drone_calibration.lua    drone_calibration.lua)

file(COPY        ${CMAKE_CURRENT_SOURCE_DIR}/scripts
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR})