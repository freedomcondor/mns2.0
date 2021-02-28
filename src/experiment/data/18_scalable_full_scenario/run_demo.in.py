import os
import sys
import random
import math

testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

Inputseed = False
Visual = True
if len(sys.argv) >= 2 :
	Inputseed = sys.argv[1]
if len(sys.argv) >= 3 and sys.argv[2] == "novisual":
	Visual = False

#- structure ------------------------------------------------------------------
def generate_cross_knot_children_text(text, i):
	if i == 0:
		return text
	text = text + '''{ 	robotTypeS = "drone",
	positionV3 = vector3(-droneDis, 0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis/4, droneDis, 0),
		orientationQ = quaternion(-math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	{	robotTypeS = "drone",
		positionV3 = vector3(-droneDis/4, -droneDis, 0),
		orientationQ = quaternion(math.pi/2, vector3(0,0,1)),
		children = {
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, -pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
		{	robotTypeS = "pipuck",
			positionV3 = vector3(-pipuckDis, pipuckDis/2, 0),
			orientationQ = quaternion(0, vector3(0,0,1)),
		},
	}},
	'''
	text = generate_cross_knot_children_text(text, i-1)
	text = text + "}},\n"
	return text

def generate_link_children_text(text, i, drift):
	if i == 0:
		return text

	text = text + '''{ 	robotTypeS = "drone",
	positionV3 = vector3(-droneDis, ''' + str(drift) + '''0, 0),
	orientationQ = quaternion(),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},\n--]]\n'''
	text = generate_link_children_text(text, i-1, -drift)
	text = text + "}},\n"
	return text

def generate_curve_link_text(text, i, th):
	if i == 0:
		return text

#
#       -----------
#       |\
#       | \
#       |  \
#       |   \
#       | th \

	text = text + '''{ 	robotTypeS = "drone",
	positionV3 = vector3('''
	text = text + "-droneDis * " + str(math.cos(th)) + ", "
	text = text + "-droneDis * " + str(math.sin(th)) + ", "
	text = text + '''0),
	orientationQ = quaternion(''' 
	text = text + str(th) 
	text = text + ''', vector3(0,0,1)),
	children = {
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(-pipuckDis, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},

	--[[
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, -pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},
	{	robotTypeS = "pipuck",
		positionV3 = vector3(pipuckDis/2, pipuckDis, 0),
		orientationQ = quaternion(0, vector3(0,0,1)),
	},\n--]]\n'''
	text = generate_curve_link_text(text, i-1, th)
	text = text + "}},\n"
	return text

def generate_structure(structure_id, n, structure_type, th):
	with open(testfolder_build + '/' + structure_id + '_template.lua', 'r') as file :
		filedata = file.read()

	if structure_type == "line" :
		filedata = filedata.replace('DRONE_CHILDREN', generate_link_children_text("", n, th))
	if structure_type == "cross" :
		filedata = filedata.replace('DRONE_CHILDREN', generate_cross_knot_children_text("", n))
	if structure_type == "curve" :
		filedata = filedata.replace('DRONE_CHILDREN_LEFT', generate_curve_link_text("", n, -th))
		filedata = filedata.replace('DRONE_CHILDREN_RIGHT', generate_curve_link_text("", n, th))

	with open(testfolder_build + '/' + structure_id + '.lua', 'w') as file:
		file.write(filedata)

#- wall ------------------------------------------------------------------------
def generate_gate_locations(gate_number, left_end, right_end, small_limit, large_limit) :
	a = []
	for i in range(1, gate_number+1) :
		valid_position = False
		while valid_position == False:
			loc = left_end + random.random() * (right_end - left_end)
			size = small_limit + random.random() * (large_limit - small_limit)
			left = loc - size/2 
			right = loc + size/2 

			if left < left_end or right > right_end :
				valid_position = False
				continue

			valid_position = True
			for item in a:
				if (item[0] < left and right < item[1] or
				    left < item[0] and item[0] < right or
				    left < item[1] and item[1] < right
				   ) :
					valid_position = False
					break

			if valid_position == True:
				a.append([left,right])

	#sort
	for i in range(0, gate_number-1) :
		for j in range(i+1, gate_number) :
			if a[i][0] > a[j][0] :
				temp = a[i]
				a[i] = a[j]
				a[j] = temp
	return a

def generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step) :
	block_locations = []
	gate_locations = generate_gate_locations(gate_number, left_end, right_end, small_limit, large_limit)
	for i in range(0, gate_number + 1) :
		# get interval of gates
		left = left_end
		right = right_end
		if i != 0 :
			left = gate_locations[i-1][1]
		if i != gate_number :
			right = gate_locations[i][0]

		#set blocks from left to right
		j = left
		while j < right - 0.055 :
			block_locations.append([j, "blue"])
			j = j + step
		block_locations.append([right, "blue"])
		#set mark blocks
		if i != 0 :
			block_locations.append([left - 0.06, "orange"])
		if i != gate_number :
			block_locations.append([right + 0.06, "orange"])
		
	return block_locations

def add_obstacle_xml(tagstr, i, x, y, type):
	tag = "<block id=\"obstacle" + str(i) + "\" init_led_color=\"" + type + "\">\n"
	tag = tag + "  <body position=\"" + str(x) + "," + str(y) + ", 0\" orientation=\"0,0,0\" />\n" 
	tag = tag + "  <controller config=\"block\"/>\n</block>\n"
	return tagstr + tag

def generate_obstacle(gate_number, wall_x, left_end, right_end, small_limit, large_limit, step) :
	tagstr = ""
	block_locations = generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step) 
	i = 0
	for loc in block_locations :
		i = i + 1
		tagstr = add_obstacle_xml(tagstr, i, wall_x, loc[0], loc[1])

	return tagstr


#- argos file ------------------------------------------------------------------
def generate_argos_file(TotalLength, RandomSeed, obstacle_xml):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))
	filedata = filedata.replace('OBSTACLE', str(obstacle_xml))
	if Visual == False :
		filedata = filedata.replace('VISUALIZATION_HEAD', '<!--')
		filedata = filedata.replace('VISUALIZATION_TAIL', '-->')

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

#------------------------------------------------------------------------
TotalLength = 2500 / 5
if Visual :
	TotalLength = 20000 / 5
RandomSeed = Inputseed or 2

random.seed(RandomSeed)

obstacle_xml = generate_obstacle(5,        # number of gates
                                 3,        # x location of the wall
								 -5, 5,    # y range of the wall
								 0.3, 2,   # size range of the wall
								 0.1)      # block distance to fill the wall

generate_argos_file(TotalLength, RandomSeed, obstacle_xml)

generate_structure("morphology1", 3, "line", 0)
generate_structure("morphology2", 7, "line", 0.2)
generate_structure("morphology3", 3, "curve", math.pi/6)

os.system("argos3 -c vns.argos")

