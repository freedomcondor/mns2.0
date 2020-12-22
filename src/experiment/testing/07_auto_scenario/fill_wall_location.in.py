import os
import sys
import random

#mnsfolder = '/Users/harry/Desktop/mns2.0/'
#casefolder = 'experiment/testing/07_auto_scenario'
#testfolder_build = mnsfolder + 'build/' + casefolder
#testfolder_src = mnsfolder + 'src/' + casefolder
testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

def generate_argos_file(RandomSeed, wallLocation):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	sideWallLocation = 2.5

	# Replace the target string
	filedata = filedata.replace('WALL_X',                 str(0.5))
	filedata = filedata.replace('WALL_UP_LOCATION_END',   str(sideWallLocation-0.15-0.060))
	filedata = filedata.replace('WALL_UP_LOCATION',       str(sideWallLocation))

	filedata = filedata.replace('WALL_DOWN_LOCATION_END', str(-sideWallLocation+0.15+0.060))
	filedata = filedata.replace('WALL_DOWN_LOCATION',     str(-sideWallLocation))

	filedata = filedata.replace('WALL_LOCATION_END1',     str(wallLocation-0.6-0.060))
	filedata = filedata.replace('WALL_LOCATION_END2',     str(wallLocation+0.6+0.060))
	filedata = filedata.replace('WALL_LOCATION',          str(wallLocation))

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))

	# Write the file out again
	with open(testfolder_build + '/vns.argos', 'w') as file:
		file.write(filedata)

RandomSeed = 1
random.seed(RandomSeed)
wallLocation = (random.random() - 0.5)*2 * 0.8
generate_argos_file(RandomSeed, wallLocation)

