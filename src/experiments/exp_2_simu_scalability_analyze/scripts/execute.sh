currentDir=`pwd`
run_threads_dir=threads
done_threads_dir=threads_finish

run () {
	i=$1
	mkdir -p $run_threads_dir/run$i
	cd $run_threads_dir/run$i
	echo $i > evaluate_output
	#python3 ~/code/mns2.0/build/experiments/exp_2_simu_scalability_analyze/run.py -r $i -v false >> output
	lua ~/code/mns2.0/build/experiments/exp_2_simu_scalability_analyze/scripts/evaluator.lua $i >> evaluate_output
}


mkdir -p $run_threads_dir
mkdir -p $done_threads_dir

for i in {1..25}
do
	echo running $i
	cd $currentDir
	run $i
	cd $currentDir
	mv $run_threads_dir/run$i $done_threads_dir
	echo run$i finish
done
