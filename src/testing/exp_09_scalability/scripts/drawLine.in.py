drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

legend = []
for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	#legend.append(subfolder)
	data = readDataFrom(subfolder + "result_data.txt")
	if data[2430] > 5:
		print("wrong case: ", subfolder)
	drawData(data)
#plt.legend(legend)

#drawData(readDataFrom("result_data.txt"))

plt.show()