import matplotlib.pyplot as plt
import numpy as np
import sys
import os

mnsfolder = '/Users/harry/Desktop/mns2.0/'
casefolder = 'experiment/data/02_displace_mns_drone'
testfolder_build = mnsfolder + 'build/' + casefolder
testfolder_src = mnsfolder + 'src/' + casefolder

data_set = sys.argv[1]

jump_timestep = 400
total_timestep = 1200

data = []
for i in range(total_timestep):
	data.append([])

i = 0
for folder in os.walk(testfolder_src + "/" + data_set + "/") :
	#jump over the first one
	if folder[1] != [] : 
		continue

	i = i + 1
	
	#file = open(testfolder_src + "/" + data_set + "/run" + str(i) + "/result2.txt","r")
	file = open(folder[0] + "/result2.txt","r")
	j = 0
	for line in file:
		data[j].append(float(line))
		j = j + 1
		if j == total_timestep and float(line) > 0.1 :
			print("error case")
			print(i)
	file.close()

	file = open(folder[0] + "/result1.txt","r")

	j = 0
	for line in file:
		data[j][i-1] = float(line)
		j = j + 1
		if j == jump_timestep :
			break

	file.close()

divide = 30
showdata = []
showindex = []
for i in range(int(divide * (jump_timestep - 300) / total_timestep) , divide + 1):
	showindex.append(int(i * total_timestep / divide))
	showdata.append(data[int(total_timestep / divide * i) - 1])

flierprops = dict(marker='.', markersize=2,
			                  linestyle='none')
plt.boxplot(showdata, flierprops = flierprops)
plt.show()
