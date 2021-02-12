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

def add_obstacle_xml(tagstr, i, x, y):
	tag = "<block id=\"obstacle" + str(i) + "\" init_led_color=\"magenta\">\n"
	tag = tag + "  <body position=\"" + str(x) + "," + str(y) + ", 0\" orientation=\"0,0,0\" />\n" 
	tag = tag + "  <controller config=\"block\"/>\n</block>\n"
	return tagstr + tag

def generate_obstacle_xmls(locations):
	xml_tag = ""
	i = 0
	for loc in locations :
		offset = 0.055 / 2
		xml_tag = add_obstacle_xml(xml_tag, i+1, loc[0]-offset, loc[1]-offset)
		xml_tag = add_obstacle_xml(xml_tag, i+2, loc[0]-offset, loc[1]+offset)
		xml_tag = add_obstacle_xml(xml_tag, i+3, loc[0]+offset, loc[1]-offset)
		xml_tag = add_obstacle_xml(xml_tag, i+4, loc[0]+offset, loc[1]+offset)
		i = i + 4

	return xml_tag

TotalLength = 2500 / 5
if Visual :
	TotalLength = 0 
RandomSeed = Inputseed or 2

random.seed(RandomSeed)
ObstacleXml = generate_obstacle_xmls(generate_obstacle_locations(80, -3.3, 3.3, -2.0, 2.0, 0.4))
generate_argos_file(TotalLength, RandomSeed, ObstacleXml)

os.system("argos3 -c vns.argos")


