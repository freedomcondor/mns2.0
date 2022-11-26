drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

'''
legend = []
for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	legend.append(subfolder)
	drawData(readDataFrom(subfolder + "result_data.txt"))
plt.legend(legend)
'''

drawData(readDataFrom("result_data.txt"))
drawData(readDataFrom("result_lowerbound_data.txt"))
drawData(readDataFrom("result_lowerbound_inc_data.txt"))

robotsData = []
for subfile in getSubfiles("result_each_robot_lowerbound_inc_data") :
	robotsData.append(readDataFrom(subfile))
	drawData(readDataFrom(subfile))

#data = [[0,1], [1,2], [2,3]]
boxdata, positions = transferTimeDataToBoxData(robotsData, None, 20)

flierprops = dict(marker='.', 
                  markersize=2,
                  linestyle='none'
                 )

#plt.boxplot(boxdata, positions=positions, widths=10, flierprops=flierprops)
plt.boxplot(boxdata, positions=positions, widths=10)

plt.show()
