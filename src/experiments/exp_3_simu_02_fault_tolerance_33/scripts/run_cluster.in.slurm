#!/bin/bash

## Resource Request
#SBATCH --job-name=mns_exp3simu02           # name of your job, will be shown when running squeue
#SBATCH --output=mns_exp01_%A_%a.stdout   # name of the output file, %j will be replaced by the Job ID
#SBATCH --error=mns_exp01_%A_%a.stderr    # name of the error file, %j will be replaced by the Job ID
#SBATCH --partition=Epyc7452           # the hardware that you want to run on
#SBATCH --qos=short                    # the queue that you want to run on (short, long)
#SBATCH --ntasks=1                     # the job will launch a single task, set higher for MPI programs
#SBATCH --cpus-per-task=1              # each task will require 1 core on the same machine, set higher for OpenMP programs
#SBATCH --mail-user=weixu.zhu@ulb.be   # your email to receive emails about the state of your job
#SBATCH --mail-type=END,FAIL           # when to send emails, choices are BEGIN, END, FAIL, ARRAY_TASKS

#SBATCH --array=1-50                    # job array

## Module dependencies
#export MODULEPATH=$HOME/Software/modulefiles:$MODULEPATH
module load argos3.mod
module load lua5.3-dev.mod
module load readline-8.1.mod

#srun my_program   # run your program here 
DATADIR=@CMAKE_CURRENT_BINARY_DIR@/../data
TMPDIR=/tmp/wzhu/mns_exp/exp_3_simu_02_fault_tolerance_33

# job id
#JOB_ID=1
JOB_ID=$SLURM_ARRAY_TASK_ID

mkdir -p $DATADIR
rm -rf $TMPDIR/run$JOB_ID

mkdir -p $TMPDIR/run$JOB_ID
rm -rf $TMPDIR/run$JOB_ID/*

cd $TMPDIR/run$JOB_ID
mkdir logs
python3 @CMAKE_CURRENT_BINARY_DIR@/../run.py -r $JOB_ID -v false
lua @CMAKE_CURRENT_BINARY_DIR@/evaluator.lua 

cd ..
mv run$JOB_ID $DATADIR