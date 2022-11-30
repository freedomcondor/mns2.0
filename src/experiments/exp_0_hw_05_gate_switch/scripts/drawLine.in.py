drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

'''
for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	data = readDataFrom(subfolder + "result_data.txt")
	if data[1375] > 1.3 :
		print("wrong case", subfolder)
	drawData(data)

robotsData = []
for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	#drawData(readDataFrom(subfolder + "result_data.txt"))
	#drawData(readDataFrom(subfolder + "result_lowerbound_data.txt"))
	for subfile in getSubfiles(subfolder + "result_each_robot_error") :
		robotsData.append(readDataFrom(subfile))
		#drawData(readDataFrom(subfile))

#drawData(readDataFrom("result_data.txt"))

boxdata, positions = transferTimeDataToBoxData(robotsData, None, 20)

flierprops = dict(marker='.', 
                  markersize=2,
                  linestyle='none'
                 )

plt.boxplot(boxdata, positions=positions, widths=10, flierprops=flierprops)
#plt.boxplot(boxdata, positions=positions, widths=10)
'''

fig, axs = plt.subplots(1, 2, gridspec_kw={'width_ratios': [5, 1]})

dataFolder = "/Volumes/Samsung USB/mns2.0-data-backup/src/experiments/exp_0_hw_05_gate_switch/data_hw/data"

for subfolder in getSubfolders(dataFolder) :
	drawDataInSubplot(readDataFrom(subfolder + "result_data.txt"), axs[0])
	break

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