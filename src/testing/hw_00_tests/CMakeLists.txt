file(COPY        ${CMAKE_CURRENT_SOURCE_DIR}/drones
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)

file(COPY        ${CMAKE_CURRENT_SOURCE_DIR}/pipucks
     DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)

configure_file( 02_wifi.argos            02_wifi.argos)
configure_file( 02_wifi.lua              02_wifi.lua)
configure_file( 03_led_simu.in.argos     03_led_simu.argos)

configure_file( configuration.xml        configuration.xml)
