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

# Compile qtopengl user functions
if(ARGOS_COMPILE_QTOPENGL)
   add_library(builderbot_qtopengl_user_functions MODULE
      qtopengl_user_functions/builderbot_qtopengl_user_functions.h
      qtopengl_user_functions/builderbot_qtopengl_user_functions_widget.h
      qtopengl_user_functions/builderbot_qtopengl_user_functions.cpp
      qtopengl_user_functions/builderbot_qtopengl_user_functions_widget.cpp)
   target_link_libraries(builderbot_qtopengl_user_functions
      ${ARGOS_QTOPENGL_LIBRARY}
      ${SROCS_ENTITIES_LIBRARY}
      ${SROCS_BUILDERBOT_LIBRARY})
endif(ARGOS_COMPILE_QTOPENGL)

# Copy lua files
file(COPY        ${CMAKE_SOURCE_DIR}/experiment/api
     DESTINATION ${CMAKE_BINARY_DIR}/experiment)
file(COPY        ${CMAKE_SOURCE_DIR}/experiment/utils
     DESTINATION ${CMAKE_BINARY_DIR}/experiment)
file(COPY        ${CMAKE_SOURCE_DIR}/experiment/vns
     DESTINATION ${CMAKE_BINARY_DIR}/experiment)

# Configure examples

# 00_environment_setup
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/00_environment_setup/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/testing/00_environment_setup/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/00_environment_setup/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/00_environment_setup/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/00_environment_setup/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/00_environment_setup/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/00_environment_setup/builderbot.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/00_environment_setup/builderbot.lua)

# 01_recruit_assign_drive
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/01_recruit_assign_drive/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/testing/01_recruit_assign_drive/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/01_recruit_assign_drive/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/01_recruit_assign_drive/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/01_recruit_assign_drive/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/01_recruit_assign_drive/pipuck.lua)

