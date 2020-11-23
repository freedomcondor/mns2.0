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

# 02_allocate
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/pipuck.lua)

configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/morphology.lua
               COPYONLY)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/morphology_classic.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/morphology_classic.lua
               COPYONLY)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/morphology_classic_variation.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/morphology_classic_variation.lua
               COPYONLY)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/02_allocate/morphology_5_children.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/02_allocate/morphology_5_children.lua
               COPYONLY)

# 03_avoide
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/03_avoid/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/testing/03_avoid/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/03_avoid/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/03_avoid/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/03_avoid/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/03_avoid/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/03_avoid/block.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/03_avoid/block.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/testing/03_avoid/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/testing/03_avoid/morphology.lua
               COPYONLY)

# data 01_displace_mns
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/PipuckOnlyConnector.lua
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/PipuckOnlyConnector.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/DroneObserver.lua
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/DroneObserver.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/01_displace_mns/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/data/01_displace_mns/morphology.lua)

# data 02_displace_mns_drone
add_library(vns_loop_functions_02_displace_drone MODULE
   experiment/data/02_displace_mns_drone/vns_loop_functions.h
   experiment/data/02_displace_mns_drone/vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_02_displace_drone
   ${SROCS_ENTITIES_LIBRARY})

configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/vns_template.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/vns_template.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/PipuckMarker.lua
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/PipuckMarker.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/DroneOnlyConnector.lua
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/DroneOnlyConnector.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/02_displace_mns_drone/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/data/02_displace_mns_drone/morphology.lua)

# data 03_cross_displace

# Compile loop functions
add_library(vns_loop_functions_03_cross_displace MODULE
   experiment/data/03_cross_displace/vns_loop_functions.h
   experiment/data/03_cross_displace/vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_03_cross_displace
   ${SROCS_ENTITIES_LIBRARY})

configure_file(${CMAKE_SOURCE_DIR}/experiment/data/03_cross_displace/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/03_cross_displace/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/03_cross_displace/vns_template.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/03_cross_displace/vns_template.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/03_cross_displace/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/data/03_cross_displace/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/03_cross_displace/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/data/03_cross_displace/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/03_cross_displace/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/data/03_cross_displace/morphology.lua)

# data 04_cross_displace_drone

# Compile loop functions
add_library(vns_loop_functions_04_cross_displace_drone MODULE
   experiment/data/04_cross_displace_drone/vns_loop_functions.h
   experiment/data/04_cross_displace_drone/vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_04_cross_displace_drone
   ${SROCS_ENTITIES_LIBRARY})

configure_file(${CMAKE_SOURCE_DIR}/experiment/data/04_cross_displace_drone/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/04_cross_displace_drone/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/04_cross_displace_drone/vns_template.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/04_cross_displace_drone/vns_template.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/04_cross_displace_drone/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/data/04_cross_displace_drone/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/04_cross_displace_drone/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/data/04_cross_displace_drone/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/04_cross_displace_drone/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/data/04_cross_displace_drone/morphology.lua)

# data 05_displace_mns_drone_45
add_library(vns_loop_functions_05_displace_drone_45 MODULE
   experiment/data/05_displace_mns_drone_45/vns_loop_functions.h
   experiment/data/05_displace_mns_drone_45/vns_loop_functions.cpp)
target_link_libraries(vns_loop_functions_05_displace_drone_45
   ${SROCS_ENTITIES_LIBRARY})

configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/vns.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/vns.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/vns_template.argos.in
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/vns_template.argos)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/drone.lua
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/drone.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/pipuck.lua
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/pipuck.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/PipuckMarker.lua
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/PipuckMarker.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/DroneOnlyConnector.lua
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/DroneOnlyConnector.lua)
configure_file(${CMAKE_SOURCE_DIR}/experiment/data/05_displace_mns_drone_45/morphology.lua
               ${CMAKE_BINARY_DIR}/experiment/data/05_displace_mns_drone_45/morphology.lua)