import matplotlib.pyplot as plt
from pyquaternion import Quaternion 
import numpy as np
import math

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
	 
		return roll_x, pitch_y, yaw_z # in radians

#-------------------------------------------------------------------
def getTupleListByFirstElement(tupleList, index):
	for tuple in tupleList:
		if tuple[0] == index:
			return tuple[1]

#-------------------------------------------------------------------
def generateRobotsDictionary():
	robots = {}
	for robot_name in pipucks.keys() :
		robots[robot_name] = {
			'id' : robot_name,
			'robot' : pipucks[robot_name],
			'optitrack_count' : 0,
			'message_count' : 0
		}
	'''
	for robot_name in drones.keys() :
		robots[robot_name] = {
			'id' : robot_name,
			'robot' : drones[robot_name],
			'optitrack_count' : 0,
			'message_count' : 0
		}
	'''
	return robots

def generateRobotsColors(robots):
	cmap = get_cmap(len(robots) + 1)
	id = 0
	for _, robot_idx in robots.items():
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
	return message_data[step]

