cmake_minimum_required(VERSION 3.5)

add_subdirectory(CVector 
                 ${CMAKE_CURRENT_BINARY_DIR}/simuGL
)

add_definitions(
	${simu_definitions}
)

add_executable(main_data_12_obstacle_avoidance_small
	${simu_cpps}
	main.cpp
)

include_directories( 
	${simu_include_dirs}
)

target_link_libraries(main_data_12_obstacle_avoidance_small
	${simu_link_libraries}
)

set_target_properties(main_data_12_obstacle_avoidance_small
        PROPERTIES OUTPUT_NAME main)
