import matplotlib.pyplot as plt
import numpy as np

def readDataFrom(fileName) :
	file = open(fileName,"r")
	data = []
	for line in file :
		data.append(float(line))
	file.close()
	return data

def drawData(data) :
	plt.plot(data)