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

def generate_obstacle_locations(number, x_left, y_left, x_right, y_right):
	a = []
	x = x_left
	y = y_left
	x_inc = (x_right - x_left) / (number-1)
	y_inc = (y_right - y_left) / (number-1)
	for i in range(1,number + 1):
		a.append([x,y])
		x = x + x_inc
		y = y + y_inc

	return a

def add_obstacle_xml(tagstr, i, x, y):
	tag = "<block id=\"obstacle" + str(i) + "\" init_led_color=\"magenta\">\n"
	tag = tag + "  <body position=\"" + str(x) + "," + str(y) + ", 0\" orientation=\"0,0,0\" />\n" 
	tag = tag + "  <controller config=\"block\"/>\n</block>\n"
	return tagstr + tag

def generate_obstacle_xmls(locations1, locations2):
	xml_tag = ""
	i = 0
	for loc in locations1 :
		xml_tag = add_obstacle_xml(xml_tag, i+1, loc[0], loc[1])
		i = i + 1
	for loc in locations2 :
		xml_tag = add_obstacle_xml(xml_tag, i+1, loc[0], loc[1])
		i = i + 1

	return xml_tag

TotalLength = 0 / 5
RandomSeed = 2
random.seed(RandomSeed)
location1 = generate_obstacle_locations(10, -3.5, 2.5, 1.0, 1.0)
location2 = generate_obstacle_locations(10, -3.5, -2.5, 1.0, -1.0)
ObstacleXml = generate_obstacle_xmls(location1, location2)
generate_argos_file(TotalLength, RandomSeed, ObstacleXml)

