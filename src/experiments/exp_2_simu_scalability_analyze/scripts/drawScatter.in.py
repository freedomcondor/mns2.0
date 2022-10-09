drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

def readCommOrTimeData(fileName) :
	file = open(fileName,"r")
	for line in file :
		splits = line.split(' ')
	file.close()
	return float(splits[0]), float(splits[1])

def readFormationData(fileName) :
	file = open(fileName,"r")
	for line in file :
		splits = line.split(' ')
	file.close()
	return float(splits[0]), float(splits[1]), float(splits[2])


folder = "@CMAKE_CURRENT_SOURCE_DIR@/../data"
folder = "/home/harry/code/mns2.0/build/threads"
scales = []
comms = []
for subfolder in getSubfolders(folder) :
	scale, comm = readCommOrTimeData(subfolder + "result_comm_data.txt")
	scales.append(scale)
	comms.append(comm)

plt.scatter(scales, comms)
plt.show()

scales = []
times = []
for subfolder in getSubfolders(folder) :
	scale, time = readCommOrTimeData(subfolder + "result_time_data.txt")
	scales.append(scale)
	times.append(time)

plt.scatter(scales, times)
plt.show()

scales = []
errors = []
converges = []
for subfolder in getSubfolders(folder) :
	scale, error, converge = readFormationData(subfolder + "result_formation_data.txt")
	scales.append(scale)
	errors.append(error)
	converges.append(converge)

plt.scatter(scales, errors)
plt.show()

plt.scatter(scales, converges)
plt.show()
