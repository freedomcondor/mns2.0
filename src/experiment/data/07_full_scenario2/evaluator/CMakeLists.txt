cmake_minimum_required(VERSION 3.5)

add_subdirectory(CVector 
                 ${CMAKE_CURRENT_BINARY_DIR}/simuGL
)

add_definitions(
	${simu_definitions}
)

add_executable(main_07_full_scenario2
	${simu_cpps}
	main_new.cpp
)

include_directories( 
	${simu_include_dirs}
)

target_link_libraries(main_07_full_scenario2
	${simu_link_libraries}
)

set_target_properties(main_07_full_scenario2
        PROPERTIES OUTPUT_NAME main)
