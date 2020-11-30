cmake_minimum_required(VERSION 3.5)

add_subdirectory(CVector 
                 ${CMAKE_CURRENT_BINARY_DIR}/simuGL
)

add_definitions(
	${simu_definitions}
)

add_executable(main_03_cross_displace
	${simu_cpps}
	main.cpp
)

include_directories( 
	${simu_include_dirs}
)

target_link_libraries(main_03_cross_displace 	
	${simu_link_libraries}
)
