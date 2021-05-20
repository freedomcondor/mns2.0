#import matplotlib.pyplot as plt
import matplotlib.pyplot as plt
import numpy as np
import os
import statistics

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

def read_data(data_set) :
	threshold = 0.05
	data = []
	for folder in os.walk(testfolder_src + "/" + data_set + "/") :
		#jump over the first one
		if folder[1] != [] : 
			continue
	
		file = open(folder[0] + "/result.txt","r")
		time = 0
		for line in file:
			time = time + 1
			value = float(line)
			if value < threshold :
				data.append(time)
				break
		file.close()

	return data

# Some fake data to plot
#A = [[1, 2, 5,],  [7, 2]]
A1 = read_data("random_3x3_ce_2")
A2 = read_data("random_4x4_ce_2")
A3 = read_data("random_5x5_ce_2")
B1 = read_data("random_3x3_mns_3")
B2 = read_data("random_4x4_mns_3")
B3 = read_data("random_5x5_mns_3")

print(statistics.mean(A1), statistics.mean(B1))
print(statistics.mean(A2), statistics.mean(B2))
print(statistics.mean(A3), statistics.mean(B3))

data_a = [A1, A2, A3]
data_b = [B1, B2, B3]

ticks = ['3x3', '4x4', '5x5']

def set_box_color(bp, color):
    plt.setp(bp['boxes'], color=color)
    plt.setp(bp['whiskers'], color=color)
    plt.setp(bp['caps'], color=color)
    plt.setp(bp['medians'], color=color)

plt.figure()

bpl = plt.boxplot(data_a, positions=np.array(range(len(data_a)))*2.0-0.4, sym='', widths=0.6)
bpr = plt.boxplot(data_b, positions=np.array(range(len(data_b)))*2.0+0.4, sym='', widths=0.6)
set_box_color(bpl, '#D7191C') # colors are from http://colorbrewer2.org/
set_box_color(bpr, '#2C7BB6')

# draw temporary red and blue lines and use them to create a legend
plt.plot([], c='#D7191C', label='centralize')
plt.plot([], c='#2C7BB6', label='mns')
plt.legend()

plt.xticks(range(0, len(ticks) * 2, 2), ticks)
plt.xlim(-2, len(ticks)*2)
plt.ylim(0, 700)
plt.tight_layout()
plt.show()
#plt.savefig('boxcompare.png')