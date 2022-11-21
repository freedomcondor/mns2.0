from matplotlib import cm
#from scipy.interpolate import make_interp_spline

logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

def setAxParameters(ax):
	ax.set_xlabel("x")
	ax.set_ylabel("y")
	ax.set_zlabel("z")
	ax.set_xlim([-5, 5])
	ax.set_ylim([-5, 5])
	ax.set_zlim([-5.0, 5.0])
	ax.view_init(90, -90)

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

count = 0
stepLength = 1

# colors and key frames
n_colors = len(pipuckLogs + droneLogs)
#n_colors = 3
colours = cm.rainbow(np.linspace(0, 1, n_colors))

key_frame = [300, 1000]
key_frame_style = ['v', 's']

# for each robot, draw line
robot_count = 0
for pipuckLog in pipuckLogs + droneLogs:
	robot_count = robot_count + 1

	# read data for this robot
	X = []
	Y = []
	Z = []
	T = []
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

		step_count = step_count + 1
	#end while True
	total_step = step_count
	key_frame.append(total_step + 1)

	# smooth
	def moving_average(interval, windowsize) :
		window = np.ones(int(windowsize)) / float(windowsize)
		re = np.convolve(interval, window, 'same')
		return re

	window = 50
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
				            colours[robot_count-1]
				)
		
		if i > key_frame[key_frame_i] :
			ax.plot3D(X_smooth[i], Y_smooth[i], Z_smooth[i], color = 'black', marker = key_frame_style[key_frame_i], linewidth='5')
			key_frame_i = key_frame_i + 1

		i = i + interval
	#end while i < total_step
	ax.plot3D(X_smooth[i-interval], Y_smooth[i-interval], Z_smooth[i-interval], color = 'black', marker = 'o')

# save images
plt.draw()
plt.savefig("3D_track_replay.png")
plt.show()
