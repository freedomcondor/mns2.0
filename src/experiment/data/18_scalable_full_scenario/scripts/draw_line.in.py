import matplotlib.pyplot as plt
import numpy as np
import sys
import os

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

data_set = 'random'
if len(sys.argv) >= 2 :
	data_set = sys.argv[1]

total_timestep = 1700

data = []
for i in range(total_timestep):
	data.append([])

i = 0
for folder in os.walk(testfolder_src + "/" + data_set + "/") :
	#jump over the first one
	if folder[1] != [] : 
		continue

	i = i + 1
	
	file = open(folder[0] + "/result.txt","r")
	j = 0
	for line in file:
		data[j].append(float(line))
		j = j + 1
		if j == total_timestep and float(line) > 0.1 :
			print("error case")
			print(folder[0])
	file.close()

'''
divide = 30
showdata = []
showindex = []
for i in range(int(divide * 1.0 / total_timestep) , divide + 1):
	showindex.append(int(i * total_timestep / divide))
	showdata.append(data[int(total_timestep / divide * i) - 1])
flierprops = dict(marker='.', markersize=2,
			                  linestyle='none')
plt.boxplot(showdata, flierprops = flierprops)
'''
plt.plot(data)
plt.show()
