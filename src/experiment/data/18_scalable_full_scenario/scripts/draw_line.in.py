import matplotlib.pyplot as plt
import numpy as np
import sys
import os

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

data_sets = ['random']
if len(sys.argv) >= 2 :
	data_sets = []
	for i in range(1, len(sys.argv)) :
		data_sets.append(sys.argv[i])

data = []
data_lowerbound = []
data_error = []
#     [0, 1, ... , data_set_number-1] x [0, 1, ... , step_number-1] x [0, ..., run_number-1]

set_average_data = []
set_average_lowerbound = []
set_average_error = []
#     [0, 1, ... , data_set_number-1] x [0, 1, ... , step_number-1]

run_total_error = []
#     [0, 1, ... , data_set_number-1] x [0, ..., run_number - 1]

data_set_i = -1
for data_set in data_sets :
	data_set_i = data_set_i + 1
	data.append([])              #data[data_set_i] = []
	data_lowerbound.append([])   #data_lowerbound[data_set_i] = []
	data_error.append([])        #data_error[data_set_i] = []

	set_average_data.append([])       #[set_average_data[data_set_i] = []
	set_average_lowerbound.append([]) #[set_average_lowerbound[data_set_i] = []
	set_average_error.append([])      #set_average_error[data_set_i] = []

	run_total_error.append([])   # run_total_error[data_set_i] = []

	run_i = -1
	for folder in os.walk(testfolder_src + "/" + data_set + "/") :
		#jump over the first one
		if folder[1] != [] : 
			continue
		run_i = run_i + 1
	
		# read from result.txt
		file = open(folder[0] + "/result.txt","r")
		#file = open(folder[0] + "/result_stretched.txt","r")
		step_i = -1
		for line in file:
			step_i = step_i + 1

			if run_i == 0 :
				data[data_set_i].append([])         #data[data_set_i][step_i] = []
				data_error[data_set_i].append([])   #data_error[data_set_i][step_i] = []
				total_timestep = step_i + 1

				set_average_data[data_set_i].append(0)   #set_average_data[data_set_i][step_i] = 0
				set_average_error[data_set_i].append(0)  #set_average_error[data_set_i][step_i] = 0

			data[data_set_i][step_i].append(float(line))       #data[data_set_i][step_i][run_i] = float(line)
			data_error[data_set_i][step_i].append(float(line)) #data_error[data_set_i][step_i][run_i] = float(line)

			set_average_data[data_set_i][step_i] = set_average_data[data_set_i][step_i] + float(line)
			set_average_error[data_set_i][step_i] = set_average_error[data_set_i][step_i] + float(line)
		file.close()

		# read from result_lowerbound.txt
		file = open(folder[0] + "/result_lowerbound.txt","r")
		#file = open(folder[0] + "/result_lowerbound_stretched.txt","r")
		step_i = -1
		for line in file:
			step_i = step_i + 1
			if run_i == 0 :
				data_lowerbound[data_set_i].append([])          #data_lowerbound[data_set_i][step_i] = []
				set_average_lowerbound[data_set_i].append(0)    #set_average_lowerbound[data_set_i][step_i] = 0

			data_lowerbound[data_set_i][step_i].append(float(line)) #data_lowerbound[data_set_i][step_i][run_i] = float(line)
			data_error[data_set_i][step_i][run_i] = data_error[data_set_i][step_i][run_i] - float(line)

			set_average_lowerbound[data_set_i][step_i] = set_average_lowerbound[data_set_i][step_i] + float(line)
			set_average_error[data_set_i][step_i] = set_average_error[data_set_i][step_i] - float(line)
		file.close()

		# end of for step
		# now we have data, data_lowerbound, data_error of this run (run_i) ready [data_set_i][:][run_i]

		# calculate total_error for this run (run_i), i.e, sum up [data_set_i][:][run_i] for all the steps
		run_total_error[data_set_i].append(0)  # run_total_error[data_set_i][run_i] = 0
		for step_i in range(0, total_timestep) :
			run_total_error[data_set_i][run_i] = run_total_error[data_set_i][run_i] + data_error[data_set_i][step_i][run_i]
		run_total_error[data_set_i][run_i] = run_total_error[data_set_i][run_i] / total_timestep 

	# end of for run
	# now we have data, data_lowerbound, data_error of this this data_set(data_set_i) ready [data_set_i][:][:]
	plt.plot(data[data_set_i])
	#plt.plot(data_lowerbound[data_set_i])
	#plt.plot(data_error[data_set_i])

	# we have run_total_error of this data_set(data_set_i) ready [data_set_i][:]
	#plt.boxplot(run_total_error[data_set_i], positions=[data_set_i/len(data_sets)])
	
	# calculate average of all the runs for each step, produce set_average_data/lowerbound/error [data_set_i][all time step]
	for step_i in range(0, total_timestep) :
		set_average_data[data_set_i][step_i] = set_average_data[data_set_i][step_i] / (run_i+1)
		set_average_lowerbound[data_set_i][step_i] = set_average_lowerbound[data_set_i][step_i] / (run_i+1)
		set_average_error[data_set_i][step_i] = set_average_error[data_set_i][step_i] / (run_i+1)

	#plt.plot(set_average_data[data_set_i], color = 'blue')
	#plt.plot(set_average_lowerbound[data_set_i], color='red')
	#plt.plot(set_average_error[data_set_i])

'''
# calculate average lowerbound
average_lowerbound = []
# [0, step-1]
for step_i in range(0, total_timestep) :
	average_lowerbound.append(0)
	for data_set_i in range(0, len(data_sets)) :
		average_lowerbound[step_i] = average_lowerbound[step_i] + set_average_lowerbound[data_set_i][step_i]
	average_lowerbound[step_i] = average_lowerbound[step_i] / len(data_sets) 
	#plt.plot(average_lowerbound)

# calculate average lowerbound + error based value
lb_error_value = []
# [0, dataset_number-1][0, step - 1]
for data_set_i in range(0, len(data_sets)) :
	lb_error_value.append([])
	for step_i in range(0, total_timestep) :
		lb_error_value[data_set_i].append(average_lowerbound[step_i] + set_average_error[data_set_i][step_i])
	#plt.plot(lb_error_value[data_set_i])
'''

plt.show()
