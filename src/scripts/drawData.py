import matplotlib.pyplot as plt
import numpy as np
import os

def readDataFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		data.append(float(line))
	file.close()
	return data

def drawData(data, color = None) :
	if color == None:
		return plt.plot(data)
	else:
		return plt.plot(data, color=color)

def drawDataInSubplot(data, subplot, color = None) :
	return subplot.plot(data, color=color)

def drawDataWithXInSubplot(X, data, subplot, color = None) :
	return subplot.plot(X, data, color=color)

def getSubfolders(data_dir) :
	# get the self folder item of os.walk
	walk_dir_item=[]
	for folder in os.walk(data_dir) :
		if folder[0] == data_dir :
			walk_dir_item=folder
			break

	# iterate subdir
	subfolders=[]
	for subfolder in walk_dir_item[1] :
		rundir = walk_dir_item[0] + "/" + subfolder + "/"
		subfolders.append(rundir)
	
	return subfolders

def getSubfiles(data_dir) :
	# get the self folder item of os.walk
	walk_dir_item=[]
	for folder in os.walk(data_dir) :
		if folder[0] == data_dir :
			walk_dir_item=folder
			break

	# iterate subdir
	subfiles =[]
	for subfile in walk_dir_item[2] :
		rundir = walk_dir_item[0] + "/" + subfile
		subfiles.append(rundir)
	
	return subfiles

def sparceDataEveryXSteps(data, step_length) :
	X = []
	return_data = []
	for i in range(0, len(data)) :
		if i % step_length == 0 :
			X.append(i)
			return_data.append(data[i])
	return X, return_data

def transferTimeDataToBoxData(robotsData, step_number = 50, step_length = 50, interval_steps = False) :
	boxdata = []
	positions = []
	robot_count = 0
	# for each robot
	for robotData in robotsData :
		# for each step of this robot
		box_count = 0
		for i in range(0, len(robotData)) :
			# if a right step
			if i % step_length == 0 :
				#if robot_count == 0 :
				if len(boxdata) <= box_count:
					boxdata.append([])
					positions.append(i)
				boxdata[box_count].append(robotData[i])
				box_count = box_count + 1
			# if count interval steps
			if interval_steps == True:
				boxdata[box_count-1].append(robotData[i])


		robot_count = robot_count + 1

	return boxdata, positions