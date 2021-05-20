# Set minimum required version
cmake_minimum_required(VERSION 3.1)

project(MNS2.0 CXX)

# Set the path additional cmake files must be searched for
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)

# Set build options, set flags, check libraries
include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildOptions.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildFlags.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/ARGoSBuildChecks.cmake)

# Set up ARGoS compilation information
include_directories(BEFORE ${CMAKE_SOURCE_DIR})

# Compile loop functions
add_library(vns_loop_functions MODULE
   loop_functions/vns_loop_functions.h
   loop_functions/vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions
   ${SROCS_ENTITIES_LIBRARY})

# make a logs folder to store .csv files
add_custom_target(make_log_folder ALL COMMAND ${CMAKE_COMMAND} -E make_directory logs)

# Compile qtopengl user functions
if(ARGOS_QTOPENGL_FOUND)
   add_library(builderbot_qtopengl_user_functions MODULE
      qtopengl_user_functions/builderbot_qtopengl_user_functions.h
      qtopengl_user_functions/builderbot_qtopengl_user_functions_widget.h
      qtopengl_user_functions/builderbot_qtopengl_user_functions.cpp
      qtopengl_user_functions/builderbot_qtopengl_user_functions_widget.cpp)
   target_link_libraries(builderbot_qtopengl_user_functions
      ${ARGOS_QTOPENGL_LIBRARIES}
      ${SROCS_ENTITIES_LIBRARY}
      ${SROCS_BUILDERBOT_LIBRARY})
endif(ARGOS_QTOPENGL_FOUND)

# Copy lua files
file(COPY        ${CMAKE_SOURCE_DIR}/core/api
     DESTINATION ${CMAKE_BINARY_DIR}/core)
file(COPY        ${CMAKE_SOURCE_DIR}/core/utils
     DESTINATION ${CMAKE_BINARY_DIR}/core)
file(COPY        ${CMAKE_SOURCE_DIR}/core/vns
     DESTINATION ${CMAKE_BINARY_DIR}/core)

# Configure examples
add_subdirectory(testing)