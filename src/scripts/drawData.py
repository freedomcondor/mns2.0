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

def drawData(data) :
	plt.plot(data)

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