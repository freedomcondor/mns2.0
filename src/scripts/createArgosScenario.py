import random
import sys
import getopt

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 xxx.py -r 1 -l 1000 -v true"

#----------------------------------------------------------------------------------------------
# parse opts
try:
	optlist, args = getopt.getopt(sys.argv[1:], "r:l:v:h")
except:
	print("[error] unexpected opts")
	print(usage)
	sys.exit(0)

Inputseed = 0
Experiment_length = None
Visualization = True
VisualizationArgosFlag = ""

for opt, value in optlist:
	if opt == "-r":
		Inputseed = int(value)
		print("Inputseed provided:", Inputseed)
	elif opt == "-l":
		Experiment_length = int(value)
		print("experiment_length provided:", Experiment_length)
	elif opt == "-v":
		if value == "False" or value == "false" :
			Visualization = False
		print("visualization provided:", Visualization)
	elif opt == "-h":
		print(usage)
		exit()

if Visualization == False :
	VisualizationArgosFlag = " -z"

#######################################################################
# random seed
random.seed(Inputseed)

#######################################################################
# Controller
def generate_drone_controller(params) :
	text = '''
    <!-- Drone Controller -->
    <lua_controller id="drone">
      <actuators>
        <debug implementation="default" />
        <drone_flight_system implementation="default" />
        <drone_leds implementation="default" />
        <radios implementation="default" />
      </actuators>
      <sensors>
        <drone_system implementation="default" />
        <drone_cameras_system implementation="default" show_frustum="false" show_tag_rays="false" />
        <drone_flight_system implementation="default" />
        <radios implementation="default" />
      </sensors>
      <params {} />
    </lua_controller>
    '''.format(params)

	return text

def generate_pipuck_controller(params) :
	text = '''
    <!-- Pi-Puck Controller -->
    <lua_controller id="pipuck">
      <actuators>
        <pipuck_differential_drive implementation="default" />
        <pipuck_leds implementation="default" />
        <debug implementation="default" />
        <radios implementation="default" />
      </actuators>
      <sensors>
        <pipuck_system implementation="default" />
        <radios implementation="default" />
      </sensors>
      <params {} />
    </lua_controller>
    '''.format(params)

	return text

def generate_physics_media_loop_visualization(cmake_binary_dir) :
	text = '''
  <!-- ******************* -->
  <!-- * Physics engines * -->
  <!-- ******************* -->
  <physics_engines>
    <pointmass3d id="pm3d" iterations="10" />
    <dynamics3d id="dyn3d" iterations="25">
      <gravity g="9.8" />
      <floor />
    </dynamics3d>
  </physics_engines>

  <!-- ********* -->
  <!-- * Media * -->
  <!-- ********* -->
  <media>
    <directional_led id="directional_leds" index="grid" grid_size="20,20,20"/>
    <tag id="tags" index="grid" grid_size="20,20,20" />
    <radio id="wifi" index="grid" grid_size="20,20,20" />
  </media>

  <!-- ****************** -->
  <!-- * Loop functions * -->
  <!-- ****************** -->
  <loop_functions library="{}/libmy_extensions"
                  label="my_loop_functions" />

  <!-- ****************** -->
  <!-- * Visualization  * -->
  <!-- ****************** -->
  <visualization>
    <qt-opengl lua_editor="true" show_boundary="false">
      <user_functions library="{}/libmy_qtopengl_extensions"
                      label="my_qtopengl_user_functions" />
      <camera>
        <placements>
          <placement index="0" position="0.0122872,0.0534732,25.7009" look_at="0.0122872,0.0534732,24.7009" up="-0.00187965,0.999998,0" lens_focal_length="90" />
          <placement index="1" position="-6.01698,3.45411,1.68985" look_at="-5.13495,3.03202,1.48039" up="0.188941,-0.0904165,0.977817" lens_focal_length="30" />
          <placement index="2" position="6.24865,-4.76935,2.71261" look_at="5.52826,-4.16628,2.37006" up="-0.262661,0.219888,0.939499" lens_focal_length="30" />
          <placement index="3" position="-6.25183,-4.76287,2.69551" look_at="-5.59804,-4.13326,2.27582" up="0.302308,0.291125,0.907665" lens_focal_length="30" />
          <placement index="4" position="-6.2675,4.75161,2.71277" look_at="-5.59966,4.11924,2.32022" up="0.285045,-0.269901,0.91973" lens_focal_length="30" />
          <placement index="5" position="  0, 15, 7.5" look_at="0,0,0.25" lens_focal_length="60" />
          <placement index="6" position="-15, 15, 10"  look_at="0,0,0.25" lens_focal_length="90" />
          <placement index="7" position="-15,  0, 7.5" look_at="0,0,0.25" lens_focal_length="60" />
          <placement index="8" position="-15,-15, 10"  look_at="0,0,0.25" lens_focal_length="90" />
        </placements>
      </camera>
    </qt-opengl>
  </visualization>
    '''.format(cmake_binary_dir, cmake_binary_dir)

	return text

#######################################################################
# real lab scenario
def generate_real_scenario_object() :
	if Visualization == False :
		return ""
	text = '''
	<!-- room -->
	<!--
	<box id="north_room" size="-2.02,14,3.00" movable="false" mass="10">
	  <body position="5.1,0,0"  orientation="0,0,0" />
	</box>
	<box id="south_room" size="-2.02,14,3.00" movable="false" mass="10">
	  <body position="-9.1,0,0"  orientation="0,0,0" />
	</box>
	-->

	<!-- furnitures -->
	<box id="furniture1" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="4, 4.90,0"  orientation="0,0,0" />
	</box>
	<box id="furniture2" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="4,-4.90,0"  orientation="0,0,0" />
	</box>
	<box id="furniture3" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="-1, 4.90,0"  orientation="0,0,0" />
	</box>
	<box id="furniture4" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="-1,-4.90,0"  orientation="0,0,0" />
	</box>
	<box id="furniture5" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="-6, 4.90,0"  orientation="0,0,0" />
	</box>
	<box id="furniture6" size="3.20,1.0,2.00" movable="false" mass="10">
	  <body position="-6,-4.90,0"  orientation="0,0,0" />
	</box>

	<!-- truss -->
	<box id="south_truss" size="0.02,9.50,0.20" movable="false" mass="10">
	  <body position="-6.26,0,2.5"  orientation="0,0,0" />
	</box>
	<box id="north_truss" size="0.02,9.50,0.20" movable="false" mass="10">
	  <body position="6.26,0,2.5"  orientation="0,0,0" />
	</box>
	<box id="west_truss" size="12.5,0.02,0.20" movable="false" mass="10">
	  <body position="0, 4.76, 2.5"  orientation="0,0,0" />
	</box>
	<box id="east_truss" size="12.5,0.02,0.20" movable="false" mass="10">
	  <body position="0, -4.76, 2.5"  orientation="0,0,0" />
	</box>

	<!-- man -->
	<cylinder id="head" radius="0.1" height="0.2" movable="false" mass="10">
	  <body position="-6, 3.5, 1.55"  orientation="0,0,0" />
	</cylinder>
	<box id="body" size="0.3, 0.5, 0.60" movable="false" mass="10">
	  <body position="-6, 3.5, 0.95"  orientation="0,0,0" />
	</box>
	<cylinder id="leg1" radius="0.1" height="0.95" movable="false" mass="10">
	  <body position="-6, 3.35, 0"  orientation="0,0,0" />
	</cylinder>
	<cylinder id="leg2" radius="0.1" height="0.95" movable="false" mass="10">
	  <body position="-6, 3.65, 0"  orientation="0,0,0" />
	</cylinder>
	<cylinder id="arm1" radius="0.05" height="0.90" movable="false" mass="10">
	  <body position="-6, 3.80, 0.65"  orientation="0,0,0" />
	</cylinder>
	<cylinder id="arm2" radius="0.05" height="0.90" movable="false" mass="10">
	  <body position="-6, 3.2, 0.65"  orientation="0,0,0" />
	</cylinder>

	<!-- arena -->
	<box id="south_arena" size="0.02,6.04,0.10" movable="false" mass="10">
	  <body position="-5.01,0,0"  orientation="0,0,0" />
	</box>
	<box id="north_arena" size="0.02,6.04,0.10" movable="false" mass="10">
	  <body position="5.01,0,0"  orientation="0,0,0" />
	</box>
	<box id="west_arena" size="10.00,0.02,0.10" movable="false" mass="10">
	  <body position="0, -3.01,0"  orientation="0,0,0" />
	</box>
	<box id="east_arena" size="10.00,0.02,0.10" movable="false" mass="10">
	  <body position="-, 3.01,0"  orientation="0,0,0" />
	</box>
	'''
	return text

#######################################################################
# add xml of drone, pipuck, obstacle, targets
def generate_obstacle_xml(i, x, y, th, type) :
	tag = '''
	<prototype id="obstacle{}" movable="true" friction="10">
		<body position="{},{},0" orientation="{},0,0" />
		<links ref="base">
			<link id="base" geometry="cylinder" radius="0.10" height="0.1" mass="0.01"
			      position="0,0,0" orientation="0,0,0" />
		</links>
		<devices>
			<tags medium="tags">
				<tag anchor="base" observable_angle="75" side_length="0.1078" payload="{}"
				     position="0,0.000,0.11" orientation="0,0,0" />
			</tags>
		</devices>
	</prototype>
	'''.format(i, x, y, th, type)
	return tag

def generate_block_xml(i, x, y, th, type) :
	tag = '''
	<block id="obstacle{}" init_led_color="{}">
		<body position="{},{},0" orientation="{},0,0" />
		<controller config="block"/>
	</block>
	'''.format(i, type, x, y, th)
	return tag

def generate_drone_xml(i, x, y, th) :
	tag = '''
	<drone id="drone{}" wifi_medium="wifi" >
		<body position="{},{},0" orientation="{},0,0"/>
		<controller config="drone"/>
	</drone>
	'''.format(i, x, y, th)
	return tag

def generate_pipuck_xml(i, x, y, th) :
	tag = '''
	<pipuck_ext id="pipuck{}" wifi_medium="wifi" tag_medium="tags" debug="true">
		<body position="{},{},0" orientation="{},0,0"/>
		<controller config="pipuck"/>
	</pipuck_ext>
	'''.format(i, x, y, th)
	return tag

def generate_target_xml(x, y, th, type, radius, tag_edge_distance):
	tag = '''
	<prototype id="target" movable="true" friction="2">
		<body position="{},{},0" orientation="{},0,0" />
		<links ref="base">
			<link id="base" geometry="cylinder" radius="{}" height="0.1" mass="0.01"
			      position="0,0,0" orientation="0,0,0" />
		</links>
		<devices>
			<tags medium="tags">
				<tag anchor="base" observable_angle="75" side_length="0.02" payload="{}"
				     position="{},0.000,0.11" orientation="0,0,0" />
			</tags>
		</devices>
    </prototype>
	'''.format(x, y, th, radius, type, tag_edge_distance-radius)
	return tag

#######################################################################
# generate random locations

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# return an array of gates in order
#	[
#		[left1, right1],
#		[left2, right2],
#	]
#	and the middle of the largest gate
attempt_count_down_default = 500
def generate_gate_locations(gate_number, left_end, right_end, small_limit, large_limit) :
	a = []
	largest_length = 0
	largest_loc = 0
	for i in range(1, gate_number+1) :
		valid_position = False
		attempt_count_down = attempt_count_down_default
		while valid_position == False :
			# check attempt
			if attempt_count_down == 0 :
				print("[warning] gate locations incomplete")
				break
			else :
				attempt_count_down = attempt_count_down - 1

			# generate a random location
			loc = left_end + random.random() * (right_end - left_end)
			size = small_limit + random.random() * (large_limit - small_limit)
			if i == 1 :
				size = large_limit
			left = loc - size/2 
			right = loc + size/2 

			# valid check
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
		if attempt_count_down == 0 :
			break

	#sort
	for i in range(0, gate_number-1) :
		for j in range(i+1, gate_number) :
			if a[i][0] > a[j][0] :
				temp = a[i]
				a[i] = a[j]
				a[j] = temp
	return a, largest_loc

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# fill the wall with <step>
# return an array of gates in order
#	[
#		[1D-location, type],
#	]
#	and the middle of the largest gate
def generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) :
	return generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, step, 0.055, gate_brick_type, wall_brick_type)

def generate_obstacle_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) :
	return generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, step, 0.10, gate_brick_type, wall_brick_type) # 254 gate, 255 wall brick

def generate_wall_brick_locations(gate_number, left_end, right_end, small_limit, large_limit, step, brick_size, gate_brick_type, wall_brick_type) :
	block_locations = []
	margin = 0.10
	gate_locations, largest_loc = generate_gate_locations(gate_number, left_end + margin, right_end - margin, small_limit, large_limit)
	for i in range(0, gate_number + 1) :
		# get interval of gates
		left = left_end
		right = right_end
		if i != 0 :
			left = gate_locations[i-1][1]
		if i != gate_number :
			right = gate_locations[i][0]

		#set blocks from left to right
		#set left block
		j = left
		block_locations.append([left, -90, gate_brick_type])
		j = j + step
		#set middle block
		while j < right - brick_size:
			block_locations.append([j, 0, wall_brick_type])
			j = j + step
		#set right block
		block_locations.append([right, 90, gate_brick_type])
		
	return block_locations, largest_loc

# from <left_end> to <right_end>, generate <gate_number> gates of different sizes ranging from <small_limit> and <large_limit>
# fill the wall with <step>
# return an array of gates in order
#	[
#		[1D-location, type],
#	]
#	and the middle of the largest gate
def generate_wall(gate_number, wall_x, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) :
	tagstr = ""
	#block_locations, largest_loc = generate_block_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) 
	block_locations, largest_loc = generate_obstacle_locations(gate_number, left_end, right_end, small_limit, large_limit, step, gate_brick_type, wall_brick_type) 
	i = 0
	for loc in block_locations :
		i = i + 1
		tagstr = tagstr + generate_obstacle_xml(i, wall_x, loc[0], loc[1], loc[2]) #loc[0 to 2] means y, th, type

	return tagstr, largest_loc

#- random locations ------------------------------------------------------------------------
def generate_random_locations(n, origin_x,    origin_y, 
                                 x_min_limit, x_max_limit,
                                 y_min_limit, y_max_limit, 
                                 near_limit,  far_limit) :
	a = []

	# if origin is not None then add origin as the first
	start = 0
	if origin_x != None and origin_y != None :
		a.append([origin_x, origin_y])
		start = 1

	# start generating
	for i in range(start, n) : # 0/1 to n - 1
		valid = False
		attempt_count_down = attempt_count_down_default
		while valid == False :
			# check attempt
			if attempt_count_down == 0 :
				print("[warning] random locations incomplete")
				break
			else :
				attempt_count_down = attempt_count_down - 1

			# generate a random location
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
			if i == 0 :
				valid = True
			for j in range(0, i) :
				if (loc_x - a[j][0]) ** 2 + (loc_y - a[j][1]) ** 2 < far_limit ** 2 :
					valid = True
					break
			if valid == True :
				a.append([loc_x, loc_y])
		if attempt_count_down == 0 :
			break
	return a

def generate_slave_locations(n, master_locations,
                                x_min_limit, x_max_limit,
                                y_min_limit, y_max_limit, 
                                near_limit, far_limit) :
	a = []
	for i in range(0, n) :
		valid = False
		attempt_count_down = attempt_count_down_default
		while valid == False :
			# check attempt
			if attempt_count_down == 0 :
				print("[warning] slave locations incomplete")
				break
			else :
				attempt_count_down = attempt_count_down - 1

			# generate a random location
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
			for drone_loc in master_locations :
				if (loc_x - drone_loc[0]) ** 2 + (loc_y - drone_loc[1]) ** 2 < far_limit ** 2 :
					valid = True
					break
			if valid == True :
				a.append([loc_x, loc_y])
		if attempt_count_down == 0 :
			break
	return a

def generate_drones(locations, start_id) :
	tagstr = ""
	i = start_id
	for loc in locations :
		tagstr = tagstr + generate_drone_xml(i, loc[0], loc[1], 0)
		i = i + 1
	return tagstr

def generate_pipucks(locations, start_id) :
	tagstr = ""
	i = start_id
	for loc in locations :
		tagstr = tagstr + generate_pipuck_xml(i, loc[0], loc[1], 0)
		i = i + 1
	return tagstr

def generate_obstacles(locations, start_id, type) :
	tagstr = ""
	i = start_id
	for loc in locations :
		tagstr = tagstr + generate_obstacle_xml(i, loc[0], loc[1], 0, type)
		i = i + 1
	return tagstr
#######################################################################
# create argos file
def generate_argos_file(template_name, argos_name, replacements) :
	'''
	replacements = 
	[
		[RANDOMSEED, str(500)],
		[xxx, yyy],
		[xxx, yyy],
	]
	'''
	with open(template_name, 'r') as file :
		filedata = file.read()

	for i in replacements :
		filedata = filedata.replace(i[0], i[1])

	with open(argos_name, 'w') as file:
		file.write(filedata)
