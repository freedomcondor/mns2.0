logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-5, 5])
	ax.set_ylim([-3, 3])
	#ax.set_xlim([-10, 0])
	#ax.set_ylim([0, 5])
	ax.set_zlim([-1.0, 2.0])
	ax.view_init(45, 45)

fig = plt.figure()
ax = fig.add_subplot(projection='3d')

#plt.ion()
setAxParameters(ax)
#plt.show()

pipuckLogNames = findRobotLogs(input_file, "pipuck")
pipuckLogs = openRobotLogs(pipuckLogNames)

droneLogNames = findRobotLogs(input_file, "drone")
droneLogs = openRobotLogs(droneLogNames)

targetLogNames = findRobotLogs(input_file, "target")
targetLogs = openRobotLogs(targetLogNames)

obstacleLogNames = findRobotLogs(input_file, "obstacle")
obstacleLogs = openRobotLogs(obstacleLogNames)

while True:
	plt.pause(0.01)
	ax.clear()
	steps = 1

	for pipuckLog in pipuckLogs :
		for i in range(0, steps):
			step = readNextLine(pipuckLog)
		drawRobot(ax, step['position'], step['virtual_orientation'], "green")
		drawRobot(ax, step['position'], step['orientation'], "blue")
		drawRobot(ax, step['goal_position_global'], step['goal_orientation_global'], "black")
		drawVector3(ax, step['position'], step['goal_position_global'], color='black')

	for droneLog in droneLogs :
		for i in range(0, steps):
			step = readNextLine(droneLog)
		drawRobot(ax, step['position'], step['virtual_orientation'], "green")
		drawRobot(ax, step['position'], step['orientation'], "red")
		drawRobot(ax, step['goal_position_global'], step['goal_orientation_global'], "black")
		drawVector3(ax, step['position'], step['goal_position_global'], color='black')

	for obstacleLog in obstacleLogs :
		for i in range(0, steps):
			step = readNextLine(obstacleLog)
		drawRobot(ax, step['position'], step['orientation'], "black")

	for targetLog in targetLogs:
		for i in range(0, steps):
			step = readNextLine(targetLog)
		drawRobot(ax, step['position'], step['orientation'], "black")

	setAxParameters(ax)
	plt.draw()

	#temp = input()
