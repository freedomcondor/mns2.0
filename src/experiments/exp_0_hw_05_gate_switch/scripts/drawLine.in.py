drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	data = readDataFrom(subfolder + "result_data.txt")
	if data[1375] > 1.3 :
		print("wrong case", subfolder)
	drawData(data)


#drawData(readDataFrom("result_data.txt"))

plt.show()