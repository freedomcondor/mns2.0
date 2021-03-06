import os
import sys
import random

testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

Inputseed = False
Visual = True
if len(sys.argv) >= 2 :
	Inputseed = sys.argv[1]
if len(sys.argv) >= 3 and sys.argv[2] == "novisual":
	Visual = False

def generate_argos_file(TotalLength, RandomSeed, ObstacleXml):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('OBSTACLES', ObstacleXml)
	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))
	if Visual == False :
		filedata = filedata.replace('VISUALIZATION_HEAD', '<!--')
		filedata = filedata.replace('VISUALIZATION_TAIL', '-->')

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

def generate_obstacle_locations(a, number, x_left, y_left, x_right, y_right):
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

def generate_obstacle_xmls(locations):
	xml_tag = ""
	i = 0
	for loc in locations :
		xml_tag = add_obstacle_xml(xml_tag, i+1, loc[0], loc[1])
		i = i + 1

	return xml_tag

TotalLength = 2500 / 5
if Visual :
	TotalLength = 0 
RandomSeed = Inputseed or 2

random.seed(RandomSeed)
locations = generate_obstacle_locations(       [], 3, -3.0,  1.5, 3.0,   1.5)
locations = generate_obstacle_locations(locations, 3, -3.0, -1.5, 3.0,  -1.5)
locations = generate_obstacle_locations(locations, 2, -1.5,  2.0, 1.5,   2.0)
locations = generate_obstacle_locations(locations, 2, -1.5, -2.0, 1.5,  -2.0)
ObstacleXml = generate_obstacle_xmls(locations)
generate_argos_file(TotalLength, RandomSeed, ObstacleXml)

os.system("argos3 -c vns.argos")

