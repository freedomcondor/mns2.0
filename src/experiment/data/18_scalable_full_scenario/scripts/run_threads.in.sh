#!/bin/bash
#$ -N HARRY_TEST
#$ -m beas
#$ -M weixu.zhu@ulb.be
#$ -cwd

USERNAME="wzhu"
TMPDIR=/tmp/$USERNAME/18_scalable_full_scenario
#JOBDIR=$HOME/100drone
#MNSDIR=$HOME/mns2.0/build/experiment/data/18_scalable_full_scenario
#JOBDIR=$HOME/Desktop/cluster
#MNSDIR=$HOME/Desktop/mns2.0/build/experiment/data/18_scalable_full_scenario
JOBDIR="@CMAKE_CURRENT_SOURCE_DIR@/.."
MNSDIR="@CMAKE_CURRENT_BINARY_DIR@/.."


#THREADS_LOG_OUTPUT=$JOBDIR/random/log
THREADS_LOG_OUTPUT=`pwd`/threads_log
#THREADS_LOG_OUTPUT=/dev/stdout

KILL_THREADS=`pwd`/kill_threads.sh

RUN_OUTPUT=run_log  #run_log file in runX folder

#argos will also create a time_log in each runX

THREADS=2
EACH=2
LOG_INDENT="              "

run() {
	run_number=$(($1+1))
	thread_number=$2

	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent run $run_number start" >> $THREADS_LOG_OUTPUT

	mkdir run$run_number
	cd run$run_number
	python3 $MNSDIR/run_demo.py $run_number novisual > $RUN_OUTPUT
	mkdir $JOBDIR/random/run$run_number
	mv * $JOBDIR/random/run$run_number
	echo "$log_indent run $run_number finish" >> $THREADS_LOG_OUTPUT
	cd ..
}

runthread() {
	thread_number=$1

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent thread $thread_number start" >> $THREADS_LOG_OUTPUT

	start=$(($thread_number*$EACH))
	end=$(($start+$EACH))
	for (( i_run=$start; i_run<$end; i_run++ )); 
	do 
		run $i_run $thread_number
	done

	echo "$log_indent thread $thread_number finish" >> $THREADS_LOG_OUTPUT
}

mkdir -p $JOBDIR/random
rm -rf $TMPDIR/random
mkdir -p $TMPDIR/random
cd $TMPDIR/random

# start log
echo "experiment start" > $THREADS_LOG_OUTPUT
echo "execute in $TMPDIR/random, copy back in $JOBDIR/random" >> $THREADS_LOG_OUTPUT

# create kill_threads.sh
echo "echo killing threads" > $KILL_THREADS
echo "killall python" >> $KILL_THREADS
echo "killall argos3" >> $KILL_THREADS

# start threads
for (( i_thread=0; i_thread<$THREADS; i_thread++ )); 
do 
	runthread $i_thread &
	echo "kill $!" >> $KILL_THREADS
done

# wait to finish
wait
echo "experiment finish" >> $THREADS_LOG_OUTPUT
