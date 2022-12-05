#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/run_threads.sh

#DATADIR=@CMAKE_CURRENT_SOURCE_DIR@/../data
DATADIR=@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_1_simu_03_obstacle_avoidance_large_10d/data_simu/data

TMPDIR=threads
#run 2 3 "python3 @CMAKE_CURRENT_BINARY_DIR@/../run.py -l 50" $DATADIR
#run_single_thread 2 4 4 "python3 @CMAKE_CURRENT_BINARY_DIR@/../run.py -l 60" $DATADIR

#start number, runs per thread, threads
#append "-l 30" to python3 to overwrite experiment length

if [ "$RUN_FLAG" != "false" ]; then
	run_threads 1 2 4 \
	            "python3 @CMAKE_CURRENT_BINARY_DIR@/../run.py" \
	            $DATADIR \
	            $TMPDIR
else
	echo "skip run threads"
fi

if [ "$EVA_FLAG" != "false" ]; then
	echo "Evaluating"
	evaluate $DATADIR \
	         "lua @CMAKE_CURRENT_BINARY_DIR@/evaluator.lua"
	#         "rm result_data.txt"
else
	echo "skip evaluating"
fi