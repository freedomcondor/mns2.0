import matplotlib.pyplot as plt
import numpy as np
import sys
import os

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."


data_set = 'random'
if len(sys.argv) >= 2 :
	data_set = sys.argv[1]

jump_timestep = 250
total_timestep = 1000

recover_judge = 0.010

time = []
distance = []

i = 0
for folder in os.walk(testfolder_src + "/" + data_set + "/") :
	#jump over the first one
	if folder[1] != [] : 
		continue

	i = i + 1
	#file = open(testfolder_src + "/" + data_set + "/run" + str(i) + "/result2.txt","r")
	file = open(folder[0] + "/result.txt","r")
	j = 0
	flag = 0
	for line in file:
		j = j + 1
		if j > jump_timestep and float(line) < recover_judge :
			time.append(j - jump_timestep)

			if j - jump_timestep < 10 :
				print("< 10", folder[0])

			flag = 1
			break


	if flag == 0 :
		print("didn't recover", folder[0])
		time.append(total_timestep)
	file.close()

	#file = open(testfolder_src + "/" + data_set + "/run" + str(i) + "/distance.csv","r")
	file = open(folder[0] + "/distance.csv","r")
	dis = 0
	for line in file:
		dis = float(line)
	distance.append(dis)
	file.close()

#plt.subplot(122)
plt.scatter(distance, time)
plt.ylim(-100, 1100)
plt.show()