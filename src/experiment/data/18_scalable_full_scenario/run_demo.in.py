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
	largest_length = 0
	largest_loc = 0
	for i in range(1, gate_number+1) :
		valid_position = False
		while valid_position == False:
			loc = left_end + random.random() * (right_end - left_end)
			size = small_limit + random.random() * (large_limit - small_limit)
			if i == 1 :
				size = large_limit
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
				# push into list
				a.append([left,right])
				# check largest
				if right - left > largest_length :
					largest_length = right - left
					largest_loc = (left + right) / 2

	#sort
	for i in range(0, gate_number-1) :
		for j in range(i+1, gate_number) :
			if a[i][0] > a[j][0] :
				temp = a[i]
				a[i] = a[j]
				a[j] = temp
	return a, largest_loc

def generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step) :
	block_locations = []
	gate_locations, largest_loc = generate_gate_locations(gate_number, left_end, right_end, small_limit, large_limit)
	left_end = left_end - 1.0
	right_end = right_end + 1.0
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
		
	return block_locations, largest_loc

def add_obstacle_xml(tagstr, i, x, y, type):
	tag =       "<block id=\"obstacle" + str(i) + "\" init_led_color=\"" + type + "\">"
	tag = tag + "<body position=\"" + str(x) + "," + str(y) + ", 0\" orientation=\"0,0,0\" />" 
	tag = tag + "<controller config=\"block\"/></block>\n"
	return tagstr + tag

def generate_obstacle(gate_number, wall_x, left_end, right_end, small_limit, large_limit, step) :
	tagstr = ""
	block_locations, largest_loc = generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step) 
	i = 0
	for loc in block_locations :
		i = i + 1
		tagstr = add_obstacle_xml(tagstr, i, wall_x, loc[0], loc[1])

	return tagstr, largest_loc


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

def generate_drone_pipuck_xml(drone_n, pipuck_n,
                              origin_x,    origin_y, 
                              x_min_limit, x_max_limit,
                              y_min_limit, y_max_limit, 
                              drone_near_limit, drone_far_limit,
                              pipuck_near_limit, pipuck_far_limit) :
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

	pipuck_locations = generate_pipuck_locations(pipuck_n, drone_locations,
                                                 x_min_limit, x_max_limit,
                                                 y_min_limit, y_max_limit, 
                                                 pipuck_near_limit, pipuck_far_limit) 

	i = 0
	for loc in pipuck_locations :
		i = i + 1
		tagstr = add_pipuck_xml(tagstr, i, loc[0], loc[1])

	return tagstr	

#- target ------------------------------------------------------------------
def generate_target_xml(radius, x, y, tag_edge_distance):
	tagstr = '''
	<prototype id="target" movable="true" friction="2">
      <body position="{},{},0" orientation="0,0,0" />
      <links ref="base">
        <link id="base" geometry="cylinder" radius="{}" height="0.1" mass="0.01"
          position="0,0,0" orientation="0,0,0" />
      </links>
      <devices>
        <tags medium="tags">
          <tag anchor="base" observable_angle="75" side_length="0.02"
               position="{},0.000,0.11" orientation="0,0,0" />
        </tags>
      </devices>
    </prototype>'''
	return tagstr.format(x, y, radius, tag_edge_distance-radius)

#- argos file ------------------------------------------------------------------
def generate_argos_file(TotalLength, RandomSeed, drone_pipuck_xml, obstacle_xml, target_xml):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))
	filedata = filedata.replace('DRONES_PIPUCKS', str(drone_pipuck_xml))
	filedata = filedata.replace('OBSTACLES', str(obstacle_xml))
	filedata = filedata.replace('TARGET', str(target_xml))
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

Scale = 10
N = Scale * 2 + 1

obstacle_xml, largest_loc = generate_obstacle(int(Scale / 2) + 1,                # number of gates
                                              0,                # x location of the wall
                                              -(Scale)*1, 
                                              (Scale)*1,    
                                                                # y range of the wall
                                              0.5, 1.5,         # size range of the wall
                                              0.3)              # block distance to fill the wall

drone_pipuck_xml = generate_drone_pipuck_xml(N, N*2+2,          # number of drone and pipuck 
                                             -Scale-2,0,        # location of drone1
                                             -Scale*2-2,-2,     # x range
                                             -Scale,Scale,      # y range
                                             1.0, 1.2,          # drone near and far limit
                                             0.2, 1.0)          # pipuck near limit and pipuck-drone far limit

target_xml = generate_target_xml((N)/math.pi/2,               # radius
                                 Scale +2 + (N)/math.pi/2, largest_loc,            
                                                                # x, y location
                                 0.3)                           # distance from edge to tag

generate_argos_file(TotalLength, RandomSeed, drone_pipuck_xml, obstacle_xml, target_xml)

generate_structure("morphology1", Scale-1, "line", 0)
generate_structure("morphology2", N-2, "line", 0)
generate_structure("morphology3", Scale-1, "curve", math.pi/(2+Scale))

os.system("argos3 -c vns.argos")

