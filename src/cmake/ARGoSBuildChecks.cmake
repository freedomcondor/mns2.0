#
# Check ARGoS
#
find_package(ARGoS REQUIRED)
include_directories(${ARGOS_INCLUDE_DIRS})
link_directories(${ARGOS_LIBRARY_DIR})
link_libraries(${ARGOS_LDFLAGS})
#
# Check if ARGoS-SRoCS is installed
#
find_package(SRoCS)

if(NOT SROCS_FOUND)
  message(FATAL_ERROR "The SRoCS plugins for ARGoS can not be found.")
endif(NOT SROCS_FOUND)
