import matplotlib.pyplot as plt
import numpy as np
import sys

testfolder_build = 'experiment/data/03_cross_displace' 
testfolder_src = '../src/' + testfolder_build

test_number = int(sys.argv[1])

jump_timestep = 800
total_timestep = 1700

recover_judge = 0.03

time = []
distance = []

for i in range(1, test_number + 1):
	file = open(testfolder_src + "/random/run" + str(i) + "/result2.txt","r")
	j = 0
	flag = 0
	for line in file:
		j = j + 1
		if j > jump_timestep and float(line) < recover_judge :
			time.append(j - jump_timestep)
			flag = 1
			break
	if flag == 0 :
		print("didn't recover", i)
		time.append(0)
	file.close()

	file = open(testfolder_src + "/random/run" + str(i) + "/distance.csv","r")
	dis = 0
	for line in file:
		dis = float(line)
	distance.append(dis)
	file.close()

#plt.subplot(122)
plt.scatter(distance, time)
plt.show()