from matplotlib import cm
#from scipy.interpolate import make_interp_spline

logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-2, 2])
	ax.set_ylim([-2, 2])
	ax.set_zlim([-1.0, 3.0])
	ax.set_zticks([0, 3])
	ax.view_init(30, -60)
	ax.grid(visible=None)

fig = plt.figure()
ax = fig.add_subplot(projection='3d')

#plt.ion()
#setAxParameters(ax)
#plt.show()

pipuckLogNames, pipuckNames = findRobotLogs(input_file, "pipuck")
pipuckLogs = openRobotLogs(pipuckLogNames)

droneLogNames, droneNames = findRobotLogs(input_file, "drone")
droneLogs = openRobotLogs(droneLogNames)

targetLogNames, targetNames = findRobotLogs(input_file, "target")
targetLogs = openRobotLogs(targetLogNames)

obstacleLogNames, obstacleNames = findRobotLogs(input_file, "obstacle")
obstacleLogs = openRobotLogs(obstacleLogNames)

count = 0
stepLength = 1

# colors and key frames
n_colors = len(pipuckLogs + droneLogs)
#n_colors = 3
colours = cm.rainbow(np.linspace(0, 1, n_colors))

key_frame = []

# for each robot, draw line
robot_count = 0
RobotNames = pipuckNames + droneNames
# key frame record
key_frame_robots = []
for pipuckLog in pipuckLogs + droneLogs:
	robotName = RobotNames[robot_count]
	robot_count = robot_count + 1

	# read data for this robot
	X = []
	Y = []
	Z = []
	T = []
	P = []
	B = []
	step_count = 0
	while True:
		step = None
		for i in range(0, stepLength):
			step = readNextLine(pipuckLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
			if step == None :
				break
		if step == None :
			break
		
		X.append(step['position'][0])
		Y.append(step['position'][1])
		Z.append(step['position'][2])
		T.append(step_count)
		P.append(step['parent'])
		B.append(step['brain'])

		step_count = step_count + stepLength
	#end while True
	total_step = step_count
	key_frame.append(total_step + 1)

	# smooth
	def moving_average(interval, windowsize) :
		window = np.ones(int(windowsize)) / float(windowsize)
		re = np.convolve(interval, window, 'same')
		return re

	window = 20
	T_smooth = T
	X_smooth = moving_average(X, window)
	Y_smooth = moving_average(Y, window)
	Z_smooth = moving_average(Z, window)

	# draw
	i = window
	interval = 1
	key_frame_i = 0
	while i < len(T_smooth)-window : 
		if i != 0 :
				drawVector3(ax, 
				            [X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval]], 
				            [X_smooth[i],          Y_smooth[i],          Z_smooth[i]], 
				            colours[robot_count-1],
				            0.7
				)
		
		# record key_frame
		if i * stepLength > key_frame[key_frame_i] :
			if robot_count == 1:
				key_frame_robots.append({})
			key_frame_robots[key_frame_i][robotName] = {
				"position" : [X_smooth[i], Y_smooth[i], Z_smooth[i]],
				"parent" : P[i],
				"brain" : B[i]
			}
			key_frame_i = key_frame_i + 1
		'''
		if i > key_frame[key_frame_i] :
			ax.plot3D(X_smooth[i], Y_smooth[i], Z_smooth[i], color = 'black', marker = key_frame_style[key_frame_i], linewidth='5')
			key_frame_i = key_frame_i + 1
		'''

		i = i + interval
	#end while i < total_step

	# record last step into key frame 

	if robot_count == 1:
		key_frame_robots.append({})
	key_frame_robots[key_frame_i][robotName] = {
		"position" : [X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval]],
		"parent" : P[i-interval],
		"brain" : B[i-interval]
	}
	#ax.plot3D(X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval], color = 'black', marker = 'o')

#print(key_frame_robots)

# draw obstacles
color = 'red'
for obstacleLog in obstacleLogs:
	step = readNextLine(obstacleLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
	# draw dot
	ax.plot3D([step["position"][0]], 
	          [step["position"][1]],
	          [step["position"][2]],
	          color = color, linewidth='0.5', markersize='3.5', marker = 's')

for obstacleLog in targetLogs:
	step = readNextLine(obstacleLog, True)    # True means asking readNextLine to return none if pipuckLog ends, otherwise it returns exit()
	# draw dot
	ax.plot3D([step["position"][0]], 
	          [step["position"][1]],
	          [step["position"][2]],
	          color = color, linewidth='0.5', markersize='3.5', marker = 'v')

# draw key frame
usualcolor = 'black'
braincolor = 'blue'
for key_frame in key_frame_robots :
	for robotID, robotData in key_frame.items() : 
		robotType = robotID.rstrip(string.digits)
		marker = 'o'
		markersize = '3.5'
		if robotType == "drone" :
			marker = '*'
			markersize = '7'
		if robotData["brain"] == robotID :
			color = braincolor
		else :
			color = usualcolor
		# draw dot
		ax.plot3D([robotData["position"][0]], 
		          [robotData["position"][1]],
		          [robotData["position"][2]],
		          color = color, 
		          marker = marker,
		          markersize=markersize
		         )
		# draw parent line
		if robotData["parent"] != "nil" :
			parentData = key_frame[robotData["parent"]]
			ax.plot3D([robotData["position"][0], parentData["position"][0]], 
			          [robotData["position"][1], parentData["position"][1]],
			          [robotData["position"][2], parentData["position"][2]],
			          linewidth="1.2",
			          color = color)



# save images

setAxParameters(ax)
plt.draw()
plt.savefig("3D_track_replay.png")
plt.show()
