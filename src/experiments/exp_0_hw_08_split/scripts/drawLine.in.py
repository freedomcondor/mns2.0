drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	data = readDataFrom(subfolder + "result_data.txt")
	drawData(data)
	if data[550] < 0.5:
		print("wrong", subfolder)
#drawData(readDataFrom("result_data.txt"))

plt.show()