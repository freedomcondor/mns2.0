import matplotlib.pyplot as plt
import numpy as np
import sys
import os

mnsfolder = '/Users/harry/Desktop/mns2.0/'
casefolder = 'experiment/data/05_displace_mns_drone_45'
testfolder_build = mnsfolder + 'build/' + casefolder
testfolder_src = mnsfolder + 'src/' + casefolder

data_set = sys.argv[1]

jump_timestep = 330
total_timestep = 1000

recover_judge = 0.015

time = []
distance = []


i = 0
for folder in os.walk(testfolder_src + "/" + data_set + "/") :
	#jump over the first one
	if folder[1] != [] : 
		continue

	i = i + 1
	#file = open(testfolder_src + "/" + data_set + "/run" + str(i) + "/result2.txt","r")
	file = open(folder[0] + "/result2.txt","r")
	j = 0
	flag = 0
	for line in file:
		j = j + 1
		if j > jump_timestep and float(line) < recover_judge :
			time.append(j - jump_timestep)

			if j - jump_timestep > 600 :
				print("greater than 600", folder[0])
			if j - jump_timestep < 100 :
				print("less than 100", j - jump_timestep,folder[0])

			flag = 1
			break


	if flag == 0 :
		print("didn't recover", folder[0])
		time.append(0)
	file.close()

	#file = open(testfolder_src + "/" + data_set + "/run" + str(i) + "/distance.csv","r")
	file = open(folder[0] + "/distance.csv","r")
	dis = 0
	for line in file:
		dis = float(line)
	distance.append(dis)
	file.close()
	if dis > 14 :
		print("greater than 14m", folder[0])

#plt.subplot(122)
plt.scatter(distance, time)
plt.show()