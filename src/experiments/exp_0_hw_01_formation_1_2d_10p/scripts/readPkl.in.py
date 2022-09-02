parseJournalFileName = "@CMAKE_SOURCE_DIR@/scripts/pklReader/parse_journal.py"
exec(compile(open(parseJournalFileName, "rb").read(), parseJournalFileName, 'exec'))

logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/pklReader/logGenerator.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))


def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-5, 5])
	ax.set_ylim([-3, 3])
	ax.set_zlim([-1.0, 2.0])

	ax.view_init(90, 00)

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
	drawRobot(ax, [0,0,0], Quaternion(data[1]['orientation'][3],
	                                  data[1]['orientation'][0],
	                                  data[1]['orientation'][1],
	                                  data[1]['orientation'][2]
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
		time = time + 500

		#drawVector3(ax, [0,0,0], step['position'], "blue")
		drawRobot(ax, step['position'], Quaternion(step['orientation'][3],
	                                               step['orientation'][0],
	                                               step['orientation'][1],
	                                               step['orientation'][2]
	                                              )
		         )

		print(step['timestamp'])
		#plt.pause((step['timestamp'] - lastTimestamp) / 1000000)
		#lastTimestamp = step['timestamp']
		plt.pause(0.01)
		ax.clear()
		setAxParameters(ax)
		plt.draw()

#draw_optitrack_data("pipuck2")
#draw_optitrack_data("pipuck3")

robots_idx = generateRobotsIndex(drones, pipucks)
#robots_idx.pop('drone1')
generateRobotsColors(robots_idx)
createRobotsLogFiles(robots_idx)

timestamp = 0
stepTime = 200
while True:
	for id, robot_idx in robots_idx.items():
		optitrack_step_data = getNextRobotOptitrackStep(robot_idx, timestamp)
		message_step_data = getNextRobotLogInfoMessageStep(robot_idx, timestamp)
		if optitrack_step_data == None:
			closeRobotsLogFiles(robots_idx)
			exit()
		if message_step_data == None:
			closeRobotsLogFiles(robots_idx)
			exit()
		
		logStepLine(robot_idx['log_file'], optitrack_step_data, message_step_data)

		drawRobot(ax, optitrack_step_data['position'], Quaternion(optitrack_step_data['orientation'][3],
		                                                          optitrack_step_data['orientation'][0],
		                                                          optitrack_step_data['orientation'][1],
		                                                          optitrack_step_data['orientation'][2]
		                                                         ),
		          robot_idx['color']
		         )
		
		virtualFrameQTuple = getTupleListByFirstElement(message_step_data, 'virtualFrameQ')

		drawRobot(ax, 
		          optitrack_step_data['position'], 
		          Quaternion(optitrack_step_data['orientation'][3],
		                     optitrack_step_data['orientation'][0],
		                     optitrack_step_data['orientation'][1],
		                     optitrack_step_data['orientation'][2]
		                    ) *
		          Quaternion(virtualFrameQTuple[0],
		                     virtualFrameQTuple[1],
		                     virtualFrameQTuple[2],
		                     virtualFrameQTuple[3],
		                    ),
		          'blue',
		          0.1
		         )

	plt.pause(0.01)
	ax.clear()
	setAxParameters(ax)
	plt.draw()

	timestamp = timestamp + stepTime

closeRobotsLogFiles(robots_idx)