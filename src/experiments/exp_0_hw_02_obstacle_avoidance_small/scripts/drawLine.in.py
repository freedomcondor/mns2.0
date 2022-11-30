drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
#	drawData(readDataFrom(subfolder + "result_data.txt"))

#drawData(readDataFrom("result_data.txt"))

fig, axs = plt.subplots(1, 2, gridspec_kw={'width_ratios': [5, 1]})

#legend = []
#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
dataFolder = "/Volumes/Samsung USB/mns2.0-data-backup/src/experiments/exp_0_hw_02_obstacle_avoidance_small/data_hw/data"

'''
for subfolder in getSubfolders(dataFolder) :
#	legend.append(subfolder)
	drawDataInSubplot(readDataFrom(subfolder + "result_data.txt"), axs[0])
	break
'''
drawDataInSubplot(readDataFrom(subfolder + "result_data.txt"), axs[0])
#plt.legend(legend)

boxdata = []
for subfolder in getSubfolders(dataFolder) :
	boxdata = boxdata + readDataFrom(subfolder + "result_data.txt")

flierprops = dict(
	marker='.',
	markersize=2,
	linestyle='none'
)

axs[1].boxplot(boxdata, widths=5, flierprops=flierprops)

plt.show()