import matplotlib.pyplot as plt
from pyquaternion import Quaternion 
import numpy as np
import math
import os 
import shutil
# shutil is for removing a dir

import getopt
import sys

import string

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 replay.py -i xx/logs (default logs)"

#----------------------------------------------------------------------------------------------
# parse opts
try:
	optlist, args = getopt.getopt(sys.argv[1:], "i:")
except:
	print("[error] unexpected opts")
	print(usage)
	sys.exit(0)

input_file = ""
output_file = ""

for opt, value in optlist:
	if opt == "-i":
		input_file = value
		print("input_path provided:", input_file)
	elif opt == "-h":
		print(usage)
		exit()

#----------------------------------------------------------------------------------------------
# default value
if input_file == "":
	input_file = "logs"
	print("input_path not provided, use default:", input_file)




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

#-------------------------------------------------------------------
# files

def findRobotLogs(path, robotType) :
	robotLogNames = []
	for folder in os.walk(path) :
		if folder[0] == path :
			for file in folder[2] :
				name = file.split(".",2)[0]
				ext  = file.split(".",2)[1]
				name_head = name.rstrip(string.digits)
				if robotType == "ALL" :
					if name_head == "drone" or name_head == "pipuck" or name_head == "obstacle" or name_head == "target":
						robotLogNames.append(path + "/" + file)
				else :
					if name_head == robotType :
						robotLogNames.append(path + "/" + file)
	
	return robotLogNames

def openRobotLogs(nameList) :
	robotLogs = []
	for file_name in nameList :
		robotLogs.append(open(file_name, "r"))

	return robotLogs

# TODO close files
#def closeRobotLogs(nameList) :
#	for file_name in nameList :

def readNextLine(file) :
	line = file.readline()
	if len(line) == 0 :
		exit()
	lineList = line.split(",")
	step = {
		"position": [float(lineList[0]), 
		             float(lineList[1]),
		             float(lineList[2])
		            ],
		"orientation" : Quaternion(axis=[1, 0, 0], angle=math.pi / 180 * float(lineList[5])) *
		                Quaternion(axis=[0, 1, 0], angle=math.pi / 180 * float(lineList[4])) *
		                Quaternion(axis=[0, 0, 1], angle=math.pi / 180 * float(lineList[3])),
	}

	'''
		"virtual_orientation" : 
		               (Quaternion(axis=[1, 0, 0], angle=math.pi / 180 * float(lineList[5])) *
		                Quaternion(axis=[0, 1, 0], angle=math.pi / 180 * float(lineList[4])) *
		                Quaternion(axis=[0, 0, 1], angle=math.pi / 180 * float(lineList[3]))
		               ) *
		               (Quaternion(axis=[1, 0, 0], angle=math.pi / 180 * float(lineList[8])) *
		                Quaternion(axis=[0, 1, 0], angle=math.pi / 180 * float(lineList[7])) *
		                Quaternion(axis=[0, 0, 1], angle=math.pi / 180 * float(lineList[6]))
		               )
	'''

	return step