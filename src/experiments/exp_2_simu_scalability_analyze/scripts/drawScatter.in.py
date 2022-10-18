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

fig, axs = plt.subplots(2, 2)

folder = "@CMAKE_CURRENT_SOURCE_DIR@/../data"
folder = "/home/harry/code/mns2.0/build/threads_finish"
scales = []
comms = []
for subfolder in getSubfolders(folder) :
	scale, comm = readCommOrTimeData(subfolder + "result_comm_data.txt")
	scales.append(scale)
	comms.append(comm)

axs[0, 0].scatter(scales, comms)
axs[0, 0].set_ylim([0, 1000])
axs[0, 0].set_title("communication")
#plt.scatter(scales, comms)
#plt.show()

scales = []
times = []
for subfolder in getSubfolders(folder) :
	scale, time = readCommOrTimeData(subfolder + "result_time_data.txt")
	scales.append(scale)
	times.append(time)

axs[0, 1].scatter(scales, times)
axs[0, 1].set_ylim([0, 0.3])
axs[0, 1].set_title("calculation cost")
#plt.scatter(scales, times)
#plt.show()

scales = []
errors = []
converges = []
for subfolder in getSubfolders(folder) :
	scale, error, converge = readFormationData(subfolder + "result_formation_data.txt")
	scales.append(scale)
	errors.append(error)
	converges.append(converge)

axs[1, 0].scatter(scales, errors)
axs[1, 0].set_title("position errors")
#plt.scatter(scales, errors)
#plt.show()

axs[1, 1].scatter(scales, converges)
axs[1, 1].set_title("converge time")
#plt.scatter(scales, converges)
#plt.show()
plt.show()
