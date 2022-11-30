drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

fig, axs = plt.subplots(1, 2, gridspec_kw={'width_ratios': [5, 1]})

#legend = []
#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
dataFolder = "/Users/harry/Desktop/exp_0_hw_01_formation_1_2d_10p/data_hw/data"

for subfolder in getSubfolders(dataFolder) :
#	legend.append(subfolder)
	drawDataInSubplot(readDataFrom(subfolder + "result_data.txt"), axs[0])
	break
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

'''
drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_lowerbound_data.txt"))
drawData(readDataFrom("result_lowerbound_inc_data.txt"))
'''

'''
robotsData = []
for subfolder in getSubfolders("/Users/harry/Desktop/exp_0_hw_01_formation_1_2d_10p/data_hw/data") :
	drawData(readDataFrom(subfolder + "result_data.txt"))
	drawData(readDataFrom(subfolder + "result_lowerbound_data.txt"))
	for subfile in getSubfiles(subfolder + "result_each_robot_lowerbound_inc_data") :
		robotsData.append(readDataFrom(subfile))
		drawData(readDataFrom(subfile))

boxdata, positions = transferTimeDataToBoxData(robotsData, None, 20)

flierprops = dict(marker='.', 
                  markersize=2,
                  linestyle='none'
                 )

plt.boxplot(boxdata, positions=positions, widths=10, flierprops=flierprops)
#plt.boxplot(boxdata, positions=positions, widths=10)
'''

plt.show()
