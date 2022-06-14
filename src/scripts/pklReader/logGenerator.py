import matplotlib.pyplot as plt
from pyquaternion import Quaternion 
import numpy as np
import math
import os 
import shutil
# shutil is for removing a dir

#-------------------------------------------------------------------
# draw
def drawVector3(ax, startV3, endV3, color='blue'):
	'''
	ax.quiver(startV3[0], startV3[1], startV3[2],
			  endV3[0],   endV3[1],   endV3[2],
			  color=color
	)
	'''
	ax.plot3D([startV3[0], endV3[0]], [startV3[1], endV3[1]], [startV3[2], endV3[2]], color=color)

def drawRobot(ax, positionV3, orientationQ, color='blue', size=0.05):
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([size*3, 0,      0     ])), color)
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([0,      size*2, 0     ])), color)
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([0,      0,      size  ])), color) 

def get_cmap(n, name='hsv'):
    '''Returns a function that maps each index in 0, 1, ..., n-1 to a distinct 
    RGB color; the keyword argument name must be a standard mpl colormap name.'''
    return plt.cm.get_cmap(name, n)
 
#-------------------------------------------------------------------
def euler_from_quaternion(x, y, z, w):
		'''
		Convert a quaternion into euler angles (roll, pitch, yaw)
		roll is rotation around x in radians (counterclockwise)
		pitch is rotation around y in radians (counterclockwise)
		yaw is rotation around z in radians (counterclockwise)
		'''
		t0 = +2.0 * (w * x + y * z)
		t1 = +1.0 - 2.0 * (x * x + y * y)
		roll_x = math.atan2(t0, t1)

		t2 = +2.0 * (w * y - z * x)
		t2 = +1.0 if t2 > +1.0 else t2
		t2 = -1.0 if t2 < -1.0 else t2
		pitch_y = math.asin(t2)
	 
		t3 = +2.0 * (w * z + x * y)
		t4 = +1.0 - 2.0 * (y * y + z * z)
		yaw_z = math.atan2(t3, t4)
	 
		return roll_x*180/math.pi, pitch_y*180/math.pi, yaw_z*180/math.pi # in degree

#-------------------------------------------------------------------
def getTupleListByFirstElement(tupleList, index):
	for tuple in tupleList:
		if tuple[0] == index:
			return tuple[1]

#-------------------------------------------------------------------
def generateRobotsIndex(parse_pkl_drones, parse_pkl_pipucks):
	robots = {}
	for robot_name in parse_pkl_pipucks.keys() :
		robots[robot_name] = {
			'id' : robot_name,
			'robot' : parse_pkl_pipucks[robot_name],
			'optitrack_count' : 0,
			'message_count' : 0
		}
	for robot_name in parse_pkl_drones.keys() :
		robots[robot_name] = {
			'id' : robot_name,
			'robot' : parse_pkl_drones[robot_name],
			'optitrack_count' : 0,
			'message_count' : 0
		}
	return robots

def generateRobotsColors(robots_idx):
	cmap = get_cmap(len(robots_idx) + 1)
	id = 0
	for _, robot_idx in robots_idx.items():
		robot_idx['color'] = cmap(id)
		id = id + 1

def getNextRobotOptitrackStep(robot_idx, timestamp):
	step = robot_idx['optitrack_count']
	optitrack_data = robot_idx['robot'].optitrack_data
	while optitrack_data[step]['timestamp'] < timestamp :
		step = step + 1
		if step >= len(optitrack_data):
			return None
	robot_idx['optitrack_count'] = step
	return optitrack_data[step]

def getNextRobotLogInfoMessageStep(robot_idx, timestamp):
	step = robot_idx['message_count']
	message_data = robot_idx['robot'].messages
	while getTupleListByFirstElement(message_data[step]['data'], 'toS') != "LOGINFO" or message_data[step]['timestamp'] < timestamp :
		step = step + 1
		if step >= len(message_data):
			return None
	robot_idx['message_count'] = step
	return message_data[step]['data']

#----------------------------------------------------------------------------------
def createRobotsLogFiles(robots_idx):
	cache_dir = 'logs_pkl'
	if os.path.exists(cache_dir):
		print("[Warning] " + cache_dir + " exists, overwrite!")
		shutil.rmtree(cache_dir)
		os.mkdir(cache_dir)
	else:
		os.mkdir(cache_dir)
	for _, robot_idx in robots_idx.items():
		robot_idx['log_file'] = open(cache_dir + '/' + robot_idx['id'] + '.log', 'w')

def closeRobotsLogFiles(robots_idx):
	for _, robot_idx in robots_idx.items():
		robot_idx['log_file'].close()

def logStepLine(file, optitrack_step_data, message_step_data):
	# position
	file.write(str(optitrack_step_data['position'][0]) + ',' +
	           str(optitrack_step_data['position'][1]) + ',' +
	           str(optitrack_step_data['position'][2]) + ','   )
	# orientation
	roll_x, pitch_y, yaw_z = euler_from_quaternion(optitrack_step_data['orientation'][0],
	                                               optitrack_step_data['orientation'][1],
	                                               optitrack_step_data['orientation'][2],
	                                               optitrack_step_data['orientation'][3])
	file.write(str(yaw_z)   + ',' +
	           str(pitch_y) + ',' +
	           str(roll_x)  + ','   )
	'''
	file.write(str(roll_x)   + ',' +
	           str(pitch_y) + ',' +
	           str(yaw_z)  + ','   )
	'''
	# virtualOrientation 
	virtualFrameQTuple = getTupleListByFirstElement(message_step_data, 'virtualFrameQ')
	roll_x, pitch_y, yaw_z = euler_from_quaternion(virtualFrameQTuple[1],
	                                               virtualFrameQTuple[2],
	                                               virtualFrameQTuple[3],
	                                               virtualFrameQTuple[0])
	file.write(str(yaw_z)   + ',' +
	           str(pitch_y) + ',' +
	           str(roll_x)  + ','   )
	'''
	file.write(str(roll_x)   + ',' +
	           str(pitch_y) + ',' +
	           str(yaw_z)  + ','   )
	'''
	# goal position 
	goalPositionV3Tuple = getTupleListByFirstElement(message_step_data, 'goalPositionV3')
	file.write(str(goalPositionV3Tuple[0]) + ',' +
	           str(goalPositionV3Tuple[1]) + ',' +
	           str(goalPositionV3Tuple[2]) + ',' )
	# goal orientation 
	goalOrientationQTuple = getTupleListByFirstElement(message_step_data, 'goalOrientationQ')
	roll_x, pitch_y, yaw_z = euler_from_quaternion(goalOrientationQTuple[1],
	                                               goalOrientationQTuple[2],
	                                               goalOrientationQTuple[3],
	                                               goalOrientationQTuple[0])
	file.write(str(yaw_z)   + ',' +
	           str(pitch_y) + ',' +
	           str(roll_x)  + ','   )
	'''
	file.write(str(roll_x)   + ',' +
	           str(pitch_y) + ',' +
	           str(yaw_z)  + ','   )
	'''
	# targetID
	file.write(str(getTupleListByFirstElement(message_step_data, 'targetID')) + ',')
	# vnsID(brainName)
	file.write(getTupleListByFirstElement(message_step_data, 'vnsID') + '\n')

