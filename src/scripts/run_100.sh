#!/bin/bash
LOG_INDENT="              "
THREADS_LOG_OUTPUT=/dev/stdout
RUN_OUTPUT=output.log

run() {
	# `run_thread 2 3` means run No.2 on thread No.3 (thread No is for indents)
	run_number=$1
	thread_number=$2
	cmd=$3

	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent run $run_number start" >> $THREADS_LOG_OUTPUT

	mkdir run$run_number
	cd run$run_number
	mkdir logs

	$cmd > $RUN_OUTPUT

	mkdir -p $JOBDIR/random/run$run_number
	mv * $JOBDIR/random/run$run_number

	echo "$log_indent run $run_number finish" >> $THREADS_LOG_OUTPUT
	cd ..
	rm -rf run$run_number
}

run_single_thread() {
	start=$1
	end=$2
	thread_number=$3

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent thread $thread_number start" >> $THREADS_LOG_OUTPUT

	for (( i_run=$start; i_run<$end; i_run++ )); 
	do 
		run $i_run $thread_number
	done

	echo "$log_indent thread $thread_number finish" >> $THREADS_LOG_OUTPUT
}

run_threads() {
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
		run_single_thread $i_thread &
		echo "kill $!" >> $KILL_THREADS
	done

	# wait to finish
	wait
	echo "experiment finish" >> $THREADS_LOG_OUTPUT
}