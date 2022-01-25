#----------------------------------------------------------------------------------------------
# usage message 
usage=\
"[usage] example: bash xxx.sh -r false -e false"
echo $usage

RUN_FLAG="true"
EVA_FLAG="true"

#----------------------------------------------------------------------------------------------
# check flags
while getopts "r:e:h" arg; do
	case $arg in
		r)
			echo "run flag provided: $OPTARG"
			RUN_FLAG=$OPTARG
			;;
		e)
			echo "evalutate flag provided: $OPTARG"
			EVA_FLAG=$OPTARG
			;;
		h)
			exit
	esac
done

#-- run threads functions ---------------------------------------------------------------------
LOG_INDENT="                |"
  LOG_LINE="-----------------"
THREADS_LOG_OUTPUT=/dev/stdout
RUN_OUTPUT=output.log
KILL_THREADS=kill_threads.sh

run() {
	# `run 2 3` means run No.2 on thread No.3 (thread No is for indents)
	run_number=$1
	thread_number=$2
	cmd=$3
	DATADIR=$4

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	# check if datadir case exists and it is already finished in tmpdir
	if [ -d "$DATADIR/run$run_number" ] && [ ! -d "run$run_number" ]; then
		echo "$log_indent skip run$run_number" >> $THREADS_LOG_OUTPUT
		return
	fi

	# create a runX folder in TMPDIR and run cmd
	echo "$log_indent run $run_number start" >> $THREADS_LOG_OUTPUT

	rm -rf run$run_number
	mkdir run$run_number
	cd run$run_number
	mkdir logs

	$cmd -r $run_number -v false > $RUN_OUTPUT

	rm -rf $DATADIR/run$run_number
	mkdir -p $DATADIR/run$run_number
	mv -f * $DATADIR/run$run_number

	echo "$log_indent run $run_number finish" >> $THREADS_LOG_OUTPUT
	cd ..
	rm -rf run$run_number
}

run_single_thread() {
	start=$1
	end=$2
	thread_number=$3
	cmd=$4
	DATADIR=$5

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent thread $thread_number start" >> $THREADS_LOG_OUTPUT

	for (( i_run=$start; i_run<$end; i_run++ )); 
	do 
		run $i_run $thread_number "$cmd" $DATADIR
	done

	echo "$log_indent thread $thread_number finish" >> $THREADS_LOG_OUTPUT
}

run_threads() {
	start=$1
	runs_per_thread=$2
	threads=$3
	cmd=$4
	DATADIR=$5
	TMPDIR=$6

	# create kill_threads.sh
	echo "ps" > $KILL_THREADS
	echo "echo ---------------" >> $KILL_THREADS
	echo "echo killing threads" >> $KILL_THREADS

	echo "Execute in $TMPDIR, copy back in $DATADIR" > $THREADS_LOG_OUTPUT
	# create temp dir
	CURRENTDIR=`pwd`
	if [ -d $TMPDIR ]; then
		echo "[warning] $TMPDIR already exists" >> $THREADS_LOG_OUTPUT
	else
		mkdir -p $TMPDIR
	fi
	cd $TMPDIR

	# line length
	log_line=""
	for (( indent=0; indent<$threads; indent++ )); do log_line="$log_line$LOG_LINE"; done

	# start log
	echo "Experiment start" >> $THREADS_LOG_OUTPUT
	echo "$log_line" >> $THREADS_LOG_OUTPUT

	# start threads
	for (( i_thread=0; i_thread<$threads; i_thread++ )); 
	do 
		let thread_start=$start+$runs_per_thread*$i_thread
		let thread_end=$thread_start+$runs_per_thread
		run_single_thread $thread_start $thread_end $i_thread "$cmd" $DATADIR &
		echo "kill $!" >> $CURRENTDIR/$KILL_THREADS
	done

	#echo "killall python" >> $CURRENTDIR/$KILL_THREADS
	echo "killall argos3" >> $CURRENTDIR/$KILL_THREADS
	echo "killall python" >> $CURRENTDIR/$KILL_THREADS
	echo "echo ---------------" >> $CURRENTDIR/$KILL_THREADS
	echo "ps" >> $CURRENTDIR/$KILL_THREADS

	# wait to finish
	wait
	echo "$log_line" >> $THREADS_LOG_OUTPUT
	echo "Experiment finish" >> $THREADS_LOG_OUTPUT

	# clean
	cd $CURRENTDIR
	rm $KILL_THREADS
	rm -rf $TMPDIR
}

evaluate_single_case() {
	RUNDIR=$1
	cmd=$2
	CURRENTDIR=`pwd`
	cd $RUNDIR
	$cmd >> $THREADS_LOG_OUTPUT
	cd $CURRENTDIR
}

evaluate() {
	DATADIR=$1
	cmd=$2
	check_result_file=$3

	for rundir in $DATADIR/*; do
		echo $rundir >> $THREADS_LOG_OUTPUT
		if [ -f "$rundir/$check_result_file" ]; then
			echo "skip" >> $THREADS_LOG_OUTPUT
		else
			evaluate_single_case $rundir "$cmd"
		fi
	done
}