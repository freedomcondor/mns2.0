#!/bin/bash
EXP_DIR=@CMAKE_BINARY_DIR@/experiments
SCRIPT_PATH=scripts/drawLine.py

EXPERIMENT_LIST=( \
exp_0_hw_01_formation_1_2d_10p \
exp_0_hw_02_obstacle_avoidance_small \
exp_0_hw_03_obstacle_avoidance_large \
exp_0_hw_04_switch_line \
exp_0_hw_05_gate_switch \
exp_1_simu_01_formation_10d \
)

for exp_name in ${EXPERIMENT_LIST[@]}
do
	drawLinePyScript=$EXP_DIR/$exp_name/$SCRIPT_PATH
	echo "running" $drawLinePyScript
	python3 $drawLinePyScript
done