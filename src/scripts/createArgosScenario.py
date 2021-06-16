def create_real_scenario_object() :
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


def create_argos_file(template_name, argos_name, replacements) :
	with open(template_name, 'r') as file :
		filedata = file.read()

	for i in replacements :
		filedata = filedata.replace(i[0], i[1])

	with open(argos_name, 'w') as file:
		file.write(filedata)
