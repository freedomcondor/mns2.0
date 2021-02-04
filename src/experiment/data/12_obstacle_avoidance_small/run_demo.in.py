import os
import sys
import random

testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

def generate_argos_file(TotalLength, RandomSeed, ObstacleXml):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('OBSTACLES', ObstacleXml)
	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))

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

#TotalLength = 1500 / 5
TotalLength = 0
RandomSeed = 2
random.seed(RandomSeed)
ObstacleXml = generate_obstacle_xmls(generate_obstacle_locations(100, -3.5, 3.5, -2.0, 2.0, 0.3))
generate_argos_file(TotalLength, RandomSeed, ObstacleXml)

