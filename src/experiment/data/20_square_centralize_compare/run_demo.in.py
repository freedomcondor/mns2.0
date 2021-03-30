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
def generate_line_children_text(n, offset_str):
	node = '''
	{{	robotTypeS = "drone",
		positionV3 = vector3({x}, 0),
		orientationQ = quaternion(),
	'''.format(x = offset_str)

	if n != 1 :
		node = node + "children = {\n"
		node = node + generate_line_children_text(n-1, offset_str)
		node = node + "}\n"

	node = node + "},\n"
	return node

def generate_square_children_text(n):
	text = '''
	{	robotTypeS = "drone",
		positionV3 = vector3(dis, dis, 0),
		orientationQ = quaternion(),
	'''
	if n != 1 :
		text = text + "children = {\n"
		text = text + generate_line_children_text(n-1, "dis, 0")
		text = text + generate_line_children_text(n-1, "0, dis")
		text = text + generate_square_children_text(n-1)
		text = text + "}"

	text = text + "}\n"
	return text

def generate_square_text(n):
	text = '''
	{	robotTypeS = "drone",
		positionV3 = vector3(0, 0, 0),
		orientationQ = quaternion(),
	'''
	if n != 1 :
		text = text + "children = {\n"
		text = text + generate_line_children_text(n-1, "dis, 0")
		text = text + generate_line_children_text(n-1, "0, dis")
		text = text + generate_square_children_text(n-1)
		text = text + "}"

	text = text + "}\n"
	return text

def generate_structure(structure_id, n):
	with open(testfolder_build + '/' + structure_id + '_template.lua', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('SQUARE_STRUCTURE', generate_square_text(n))

	with open(testfolder_build + '/' + structure_id + '.lua', 'w') as file:
		file.write(filedata)

#- drone ------------------------------------------------------------------------
def generate_drone_locations(n, origin_x,    origin_y, 
                                x_min_limit, x_max_limit,
                                y_min_limit, y_max_limit, 
                                near_limit, far_limit) :
	a = []
	a.append([origin_x, origin_y])   # a[0] origin
	for i in range(1, n) : # 1 to n - 1
		valid = False
		while valid == False :
			loc_x = x_min_limit + random.random() * (x_max_limit - x_min_limit)
			loc_y = y_min_limit + random.random() * (y_max_limit - y_min_limit)

			#check near
			valid = True
			for j in range(0, i) :
				if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < near_limit ** 2 :
					valid = False
					break
			if valid == False :
				continue

			#check faraway
			valid = False
			for j in range(0, i) :
				if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < far_limit ** 2 :
					valid = True
					break
			if valid == True :
				a.append([loc_x, loc_y])
	return a

def generate_pipuck_locations(n, drone_locations,
                                 x_min_limit, x_max_limit,
                                 y_min_limit, y_max_limit, 
                                 near_limit, far_limit) :
	a = []
	for i in range(0, n) :
		valid = False
		while valid == False :
			loc_x = x_min_limit + random.random() * (x_max_limit - x_min_limit)
			loc_y = y_min_limit + random.random() * (y_max_limit - y_min_limit)

			# check near
			valid = True
			for j in range(0, i) :
				if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < near_limit ** 2 :
					valid = False
					break
			if valid == False :
				continue

			#check faraway
			valid = False
			for drone_loc in drone_locations :
				if (loc_x - drone_loc[0]) ** 2 + (loc_y - drone_loc[1]) ** 2 < far_limit ** 2 :
					valid = True
					break
			if valid == True :
				a.append([loc_x, loc_y])
	return a

def generate_drone_line_locations(n, origin_x, origin_y) :
	a = []
	a.append([origin_x, origin_y])   # a[0] origin
	for i in range(1, int((n-1)/2) + 1) :
		a.append([origin_x, origin_y + i*1])
	for i in range(1, n-1 - int((n-1)/2) + 1) :
		a.append([origin_x, origin_y - i*1])
	return a

def generate_pipuck_line_locations(n, origin_x, origin_y) :
	a = []
	for i in range(0, int(n/4)) :
		a.append([origin_x - 0.5, origin_y + (i+1)*0.5])
		a.append([origin_x + 0.5, origin_y + (i+1)*0.5])
	for i in range(0, int(n/4)) :
		a.append([origin_x - 0.5, origin_y - (i+1)*0.5])
		a.append([origin_x + 0.5, origin_y - (i+1)*0.5])
	return a

def add_drone_xml(tagstr, i, x, y) :
	tag =       "<drone id=\"drone" + str(i) + "\">"
	tag = tag + "<body position=\"" + str(x) + "," + str(y) + ",0\" orientation=\"0,0,0\"/>"
	tag = tag + "<controller config=\"drone\"/>"
	tag = tag + "</drone>\n"
	return tagstr + tag

def add_pipuck_xml(tagstr, i, x, y) :
	tag =       "<pipuck id=\"pipuck" + str(i) + "\" wifi_medium=\"wifi\" tag_medium=\"tags\">"
	tag = tag + "<body position=\"" + str(x) + "," + str(y) + ",0\" orientation=\"0,0,0\"/>"
	tag = tag + "<controller config=\"pipuck\"/>"
	tag = tag + "</pipuck>\n"
	return tagstr + tag

def generate_drone_pipuck_xml(drone_n, 
                              origin_x,    origin_y, 
                              x_min_limit, x_max_limit,
                              y_min_limit, y_max_limit, 
                              drone_near_limit, drone_far_limit) :
	tagstr = ""
	drone_locations = generate_drone_locations(drone_n, 
	                                           origin_x,    origin_y, 
	                                           x_min_limit, x_max_limit,
	                                           y_min_limit, y_max_limit, 
	                                           drone_near_limit, drone_far_limit) 
	i = 0
	for loc in drone_locations :
		i = i + 1
		tagstr = add_drone_xml(tagstr, i, loc[0], loc[1])

	tagstr = add_pipuck_xml(tagstr, 1, 
	                        (x_min_limit + x_max_limit)/2, 
	                        (y_min_limit + y_max_limit)/2)

	return tagstr	



#- argos file ------------------------------------------------------------------
def generate_argos_file(TotalLength, RandomSeed, drone_pipuck_xml, centralize_flag):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))
	filedata = filedata.replace('DRONES_PIPUCKS', str(drone_pipuck_xml))
	filedata = filedata.replace('CENTRALIZE_FLAG', centralize_flag)
	if Visual == False :
		filedata = filedata.replace('VISUALIZATION_HEAD', '<!--')
		filedata = filedata.replace('VISUALIZATION_TAIL', '-->')

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

#------------------------------------------------------------------------
TotalLength = 700 / 5
if Visual :
	TotalLength = 0
RandomSeed = Inputseed or 1

random.seed(RandomSeed)

Scale = 5
N = Scale ** 2

Centralize_Flag = "false"
#Centralize_Flag = "true"

drone_pipuck_xml = generate_drone_pipuck_xml(N,              # number of drone
                                             -Scale/2,-Scale/2,  # location of drone1
                                             -Scale/2,Scale/2-1,        # x range
                                             -Scale/2,Scale/2-1,        # y range
                                             0.6, 1.2)       # drone near and far limit

generate_argos_file(TotalLength, RandomSeed, drone_pipuck_xml, Centralize_Flag)

generate_structure("morphology", Scale)

os.system("argos3 -c vns.argos")