drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import statistics
import math 

#dataFolder = "/Users/harry/Desktop/exp_0_hw_07_fault_tolerance/data_hw/data"
dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_07_fault_tolerance/data_hw/data"

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
fig, axs = plt.subplots(2, 2, gridspec_kw={'width_ratios': [5, 1], 'height_ratios': [5, 1]})
axs[1, 1].axis('off')
axs[1, 0].set_yticks([1,8])

#-------------------------------------------------------------------------
# read one case and shade fill each robot data
failure_step = 500

robotsData = []
#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
for subFolder in getSubfolders(dataFolder) :
	#if subFolder != dataFolder + "/test_20220712_2_success_1/" :
	#if subFolder != dataFolder + "/test_20220712_3_success_2/" :
	#if subFolder != dataFolder + "/test_20220712_4_success_3/" :
	#if subFolder != dataFolder + "/test_20220712_5_success_4/" :
	#if subFolder != dataFolder + "/test_20220712_6_success_5/" :
	if subFolder != dataFolder + "/test_20220712_7_success_6/" :
		continue
	# check failure step
	if os.path.isfile(subFolder + "failure_step.txt") :
		failure_step = readDataFrom(subFolder + "failure_step.txt")[0]
	if os.path.isfile(subFolder + "saveStartStep.txt") :
		failure_step = failure_step - readDataFrom(subFolder + "saveStartStep.txt")[0] + 1
	#drawData(readDataFrom(subfolder + "result_data.txt"))
	# choose a folder
	drawDataInSubplot(readDataFrom(subFolder + "result_lowerbound_data.txt"), axs[0, 0])
	drawDataInSubplot(readDataFrom(subFolder + "result_MNSNumber_data.txt"), axs[1, 0])
	for subFile in getSubfiles(subFolder + "result_each_robot_error") :
		robotsData.append(readDataFrom(subFile))
		#drawDataInSubplot(readDataFrom(subFile), axs[0, 0])
	break

axs[0,0].axvline(x = failure_step, color="red", linestyle=":")
axs[1,0].axvline(x = failure_step, color="red", linestyle=":")

#drawData(readDataFrom("result_data.txt"))

boxdata, positions = transferTimeDataToBoxData(robotsData, None, 5)

mean = []
upper = []
lower = []
mini = []
maxi = []
failurePlaceHolder = 0
for stepData in boxdata :
	while failurePlaceHolder in stepData :
		stepData.remove(failurePlaceHolder)
	minvalue = min(stepData)
	maxvalue = max(stepData)
	meanvalue = statistics.mean(stepData)
	stdev = statistics.stdev(stepData)
	count = len(stepData)
	mean.append(meanvalue)
	interval = 1.96 * stdev / math.sqrt(count)
	upper.append(meanvalue + interval)
	lower.append(meanvalue - interval)
	mini.append(minvalue)
	maxi.append(maxvalue)

drawDataWithXInSubplot(positions, mean, axs[0, 0])
axs[0, 0].fill_between(
    positions, mini, maxi, color='b', alpha=.10)
axs[0, 0].fill_between(
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

axs[0, 1].boxplot(boxdata, widths=5, flierprops=flierprops)

plt.show()