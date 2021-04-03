import matplotlib.pyplot as plt
import numpy as np
import os
import statistics

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

def read_data(data_set, robot_number, centralize_or_not) :
	data = []
	for folder in os.walk(testfolder_src + "/" + data_set + "/") :
		#jump over the first one
		if folder[1] != [] : 
			continue
	
		folder_data = []
		for i in range(1, robot_number+1) :
			robot_name = "drone" + str(i)
			start_name = "time_start_" + robot_name + ".csv"
			end_name = "time_end_" + robot_name + ".csv"

			start_file = open(folder[0] + "/" + start_name,"r")

			start_data = []
			step = 0
			for line in start_file:
				step = step + 1
				value = float(line)
				start_data.append(value)
			total_step = step
			start_file.close()

			end_file = open(folder[0] + "/" + end_name,"r")
			end_data = []
			for line in end_file:
				value = float(line)
				end_data.append(value)
			end_file.close()

			if centralize_or_not == True :
				total_step = 22

			robot_data = []
			for i in range(20, total_step) :
				robot_data.append(end_data[i] - start_data[i])
		
			folder_data.append(robot_data)

		max_folder_data = []
		for step in range(0, len(folder_data[0])) :
			step_time = 0
			for robot in range(0, len(folder_data)) :
				if folder_data[robot][step] > step_time :
					step_time = folder_data[robot][step]
			max_folder_data.append(step_time)
		data.append(max_folder_data)

	return data

def scatter3Dplot(A) :
	X = []
	Y = []
	Z = []
	for i in range(0, len(A)) :
		for j in range(0, len(A[0])) :
			X.append(i)
			Y.append(j)
			Z.append(A[i][j])
	fig = plt.figure()
	ax = plt.axes(projection='3d')
	ax.scatter3D(X, Y, Z, c=Z, cmap='Greens');
	plt.show()

A1 = read_data("random_5x5_mns_time", 25, False)
x = np.matrix(A1)
print(x.mean())

A2 = read_data("random_4x4_mns_time", 16, False)
x = np.matrix(A2)
print(x.mean())

A3 = read_data("random_3x3_mns_time", 9, False)
x = np.matrix(A3)
print(x.mean())

B1 = read_data("random_3x3_ce_time", 9, True)
x = np.matrix(B1)
print(x.mean())

B2 = read_data("random_4x4_ce_time", 16, True)
x = np.matrix(B2)
print(x.mean())

B3 = read_data("random_5x5_ce_time", 25, True)
x = np.matrix(B3)
print(x.mean())