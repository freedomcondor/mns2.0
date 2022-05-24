logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-5, 5])
	ax.set_ylim([-3, 3])
	ax.set_zlim([-1.0, 2.0])
	ax.view_init(30, 60)

fig = plt.figure()
ax = fig.add_subplot(projection='3d')

#plt.ion()
setAxParameters(ax)
#plt.show()

RobotLogNames = findRobotLogs("logs")
print(RobotLogNames)
RobotLogs = openRobotLogs(RobotLogNames)

while True:
	for robotLog in RobotLogs :
		step = readNextLine(robotLog)
		drawRobot(ax, step['position'], step['virtual_orientation'])
		#drawRobot(ax, step['position'], step['orientation'])

	plt.pause(0.01)
	ax.clear()
	setAxParameters(ax)
	plt.draw()

	temp = input()
