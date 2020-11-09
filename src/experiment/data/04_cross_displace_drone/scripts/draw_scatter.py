import matplotlib.pyplot as plt
import numpy as np
import sys

testfolder_build = 'experiment/data/04_cross_displace_drone'
testfolder_src = '../src/' + testfolder_build

test_number = int(sys.argv[1])

jump_timestep = 600
total_timestep = 1200

recover_judge = 0.01

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

			if j - jump_timestep < 100 :
				print("less than 100", i)

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