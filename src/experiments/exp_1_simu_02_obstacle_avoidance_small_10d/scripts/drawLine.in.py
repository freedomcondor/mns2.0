drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import statistics
import math

#dataFolder = "/Users/harry/Desktop/exp_1_simu_02_obstacle_avoidance_small_10d/data_hw/data"
dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_1_simu_02_obstacle_avoidance_small_10d/data_simu/data"


'''
#-------------------------------------------------------------------------
# draw data plain
for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	data = readDataFrom(subfolder + "result_data.txt")
	if data[1375] > 1.3 :
		print("wrong case", subfolder)
	drawData(data)
'''

# two subfigures
fig, axs = plt.subplots(1, 2, gridspec_kw={'width_ratios': [5, 1]})


#-------------------------------------------------------------------------
# read one case and shade fill each robot data
robotsData = []
#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
for subFolder in getSubfolders(dataFolder) :
	#drawData(readDataFrom(subfolder + "result_data.txt"))
	#drawData(readDataFrom(subfolder + "result_lowerbound_data.txt"))
	# choose a folder
	#if subFolder != dataFolder + "/test_20220621_8_success_3/" :
	#	continue
	drawDataInSubplot(readDataFrom(subFolder + "result_lowerbound_data.txt"), axs[0])
	for subFile in getSubfiles(subFolder + "result_each_robot_error") :
		robotsData.append(readDataFrom(subFile))
		#drawData(readDataFrom(subfile))
	break

#drawData(readDataFrom("result_data.txt"))

boxdata, positions = transferTimeDataToBoxData(robotsData, None, 1)

mean = []
upper = []
lower = []
mini = []
maxi = []
for stepData in boxdata :
	meanvalue = statistics.mean(stepData)
	stdev = statistics.stdev(stepData)
	minvalue = min(stepData)
	maxvalue = max(stepData)
	mean.append(meanvalue)
	count = len(stepData)
	interval =1.96 * stdev / math.sqrt(count)
	upper.append(meanvalue + interval)
	lower.append(meanvalue - interval)
	mini.append(minvalue)
	maxi.append(maxvalue)

drawDataInSubplot(mean, axs[0])
axs[0].fill_between(
    positions, mini, maxi, color='b', alpha=.10)
axs[0].fill_between(
    positions, lower, upper, color='b', alpha=.30)

#-------------------------------------------------------------------------
# read all each robot data and make it a total box plot

boxdata = []
for subFolder in getSubfolders(dataFolder) :
	for subFile in getSubfiles(subFolder + "result_each_robot_error") :
		boxdata = boxdata + readDataFrom(subFile)

flierprops = dict(
	marker='.',
	markersize=2,
	linestyle='none'
)

axs[1].boxplot(boxdata, widths=5, flierprops=flierprops)

plt.show()