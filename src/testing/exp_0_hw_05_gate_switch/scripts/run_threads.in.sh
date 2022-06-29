#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/run_100.sh
run 1 2 "argos3 -c @CMAKE_CURRENT_BINARY_DIR@/../vns.argos -z"