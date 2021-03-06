import os
import sys
import random

#mnsfolder = '/Users/harry/Desktop/mns2.0/'
#casefolder = 'experiment/testing/07_auto_scenario'
#testfolder_build = mnsfolder + 'build/' + casefolder
#testfolder_src = mnsfolder + 'src/' + casefolder
testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

def generate_argos_file(RandomSeed, wallLocation, obstacleXmls):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	sideWallLocation = 2.1

	# Replace the target string
	# Visualization
	filedata = filedata.replace('VISUALIZATION_HEAD', '<!--')
	filedata = filedata.replace('VISUALIZATION_TAIL', '-->')
	# WALL
	filedata = filedata.replace('WALL_X',                 str(0.5))
	filedata = filedata.replace('WALL_UP_LOCATION_END',   str(sideWallLocation-0.15-0.060))
	filedata = filedata.replace('WALL_UP_LOCATION',       str(sideWallLocation))

	filedata = filedata.replace('WALL_DOWN_LOCATION_END', str(-sideWallLocation+0.15+0.060))
	filedata = filedata.replace('WALL_DOWN_LOCATION',     str(-sideWallLocation))

	filedata = filedata.replace('WALL_LOCATION_END1',     str(wallLocation-0.6-0.060))
	filedata = filedata.replace('WALL_LOCATION_END2',     str(wallLocation+0.6+0.060))
	filedata = filedata.replace('WALL_LOCATION',          str(wallLocation))

	# calculate the large gap place
	upgap_length = (sideWallLocation-0.15-0.060) - (wallLocation+0.6+0.060)
	upgap_middle = ((sideWallLocation-0.15-0.060) + (wallLocation+0.6+0.060)) / 2
	downgap_length = (wallLocation-0.6-0.060) - (-sideWallLocation+0.15+0.060)
	downgap_middle = ((-sideWallLocation+0.15+0.060) + (wallLocation-0.6-0.060)) / 2
	middle = upgap_middle
	if upgap_length < downgap_length:
		middle = downgap_middle

	filedata = filedata.replace('TARGET_LOCATION_Y',        str(middle))

	# Obtacles
	filedata = filedata.replace('OBSTACLES',              obstacleXmls)
	'''
	filedata = filedata.replace('OBSTACLE15_X',           str(obstacleLocations[0][0]))
	filedata = filedata.replace('OBSTACLE15_Y',           str(obstacleLocations[0][1]))
	filedata = filedata.replace('OBSTACLE16_X',           str(obstacleLocations[1][0]))
	filedata = filedata.replace('OBSTACLE16_Y',           str(obstacleLocations[1][1]))
	filedata = filedata.replace('OBSTACLE17_X',           str(obstacleLocations[2][0]))
	filedata = filedata.replace('OBSTACLE17_Y',           str(obstacleLocations[2][1]))
	filedata = filedata.replace('OBSTACLE18_X',           str(obstacleLocations[3][0]))
	filedata = filedata.replace('OBSTACLE18_Y',           str(obstacleLocations[3][1]))
	filedata = filedata.replace('OBSTACLE19_X',           str(obstacleLocations[4][0]))
	filedata = filedata.replace('OBSTACLE19_Y',           str(obstacleLocations[4][1]))
	'''

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TOTALLENGTHPY))

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

def generate_obstacle_locations(number, x_min, x_max, y_min, y_max, distance):
	a = []
	for i in range(1,number + 1):
		valid_position = False
		while valid_position == False:
			x = x_min + random.random() * (x_max - x_min)
			y = y_min + random.random() * (y_max - y_min)

			valid_position = True
			for item in a:
				if (item[0]-x)**2 + (item[1]-y)**2 < distance**2:
					valid_position = False
					break

			if valid_position == True:
				a.append([x,y])

	return a

def generate_obstacle_xmls(locations):
	xml_tag = ""
	i = 0
	for loc in locations :
		i = i + 1
		tag = "<block id=\"obstacle" + str(i) + "\" init_led_color=\"magenta\">\n"
		tag = tag + "  <body position=\"" + str(loc[0]) + "," + str(loc[1]) + ", 0\" orientation=\"0,0,0\" />\n" 
		tag = tag + "  <controller config=\"block\"/>\n</block>\n"
		xml_tag = xml_tag + tag
	return xml_tag

RandomSeed = RANDOMSEEDPY
random.seed(RandomSeed)
wallLocation = (random.random() - 0.5)*2 * 0.8
while wallLocation == 0 :
	wallLocation = (random.random() - 0.5)*2 * 0.8
obstacleLocations = generate_obstacle_locations(20, -2.5, -0.5, -1.0, 1.0, 0.2)
obstacleXmls = generate_obstacle_xmls(obstacleLocations
generate_argos_file(RandomSeed, wallLocation, obstacleXmls)

