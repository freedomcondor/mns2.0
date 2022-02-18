parseJournalFileName = "@CMAKE_SOURCE_DIR@/scripts/pklReader/parse_journal.py"
exec(compile(open(parseJournalFileName, "rb").read(), parseJournalFileName, 'exec'))

logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/pklReader/logGenerator.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))


def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-0.5, 1.0])
	ax.set_ylim([-0.5, 1.0])
	ax.set_zlim([-0.5, 1.0])

fig = plt.figure()
ax = fig.add_subplot(projection='3d')

#plt.ion()
setAxParameters(ax)
#plt.show()

def draw_optitrack_data(robot_name):
	target_robot = None
	if robot_name in pipucks.keys() :
		target_robot = pipucks[robot_name]
	if robot_name in drones.keys() :
		target_robot = drones[robot_name]
	data = target_robot.optitrack_data


	'''
	drawRobot(ax, data[1]['position'], Quaternion(data[1]['orientation']))
	drawRobot(ax, [0,0,0], Quaternion(data[1]['orientation'][0],
	                                              data[1]['orientation'][1],
	                                              data[1]['orientation'][2],
	                                              data[1]['orientation'][3]
	                                             )
	         )
	plt.show()

	return 
	'''

	lastTimestamp = 0
	time = 0
	for step in data:
		if step['timestamp'] < time :
			continue
		time = time + 1000

		#drawVector3(ax, [0,0,0], step['position'], "blue")
		drawRobot(ax, step['position'], Quaternion(step['orientation']))

		print(step['timestamp'])
		#plt.pause((step['timestamp'] - lastTimestamp) / 1000000)
		#lastTimestamp = step['timestamp']
		plt.pause(0.01)
		ax.clear()
		setAxParameters(ax)
		plt.draw()

draw_optitrack_data("pipuck2")