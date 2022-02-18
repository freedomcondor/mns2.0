import matplotlib.pyplot as plt
from pyquaternion import Quaternion 
import numpy as np

def drawVector3(ax, startV3, endV3, color) :
	'''
	ax.quiver(startV3[0], startV3[1], startV3[2],
	          endV3[0],   endV3[1],   endV3[2],
	          color=color
	)
	'''
	ax.plot3D([startV3[0], endV3[0]], [startV3[1], endV3[1]], [startV3[2], endV3[2]], color=color)

def drawRobot(ax, positionV3, orientationQ) :
	size = 0.1
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([size, 0, 0])), "blue")
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([0, size, 0])), "blue")
	drawVector3(ax, positionV3, positionV3 + orientationQ.rotate(np.array([0, 0, size])), "red")
	#print(positionV3)
	#print(orientationQ.rotate(np.array([size, 0, 0])) )
	#print(positionV3 + orientationQ.rotate(np.array([size, 0, 0])) )