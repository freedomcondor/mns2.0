cmake_minimum_required(VERSION 3.5)

add_subdirectory(CVector 
                 ${CMAKE_CURRENT_BINARY_DIR}/simuGL
)

add_definitions(
	${simu_definitions}
)

add_executable(main_02_displace_mns_drone 
	${simu_cpps}
	main.cpp
)

include_directories( 
	${simu_include_dirs}
)

target_link_libraries(main_02_displace_mns_drone
	${simu_link_libraries}
)

set_target_properties(main_02_displace_mns_drone
        PROPERTIES OUTPUT_NAME main)
