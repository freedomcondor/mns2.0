import getopt
import sys
import xml.etree.ElementTree as ET

#----------------------------------------------------------------------------------------------
# usage message 
usage="[usage] example: python3 create_drone_calibration_file.py -i lua_calibration.xml -t drone_camera_calibration_arm0.xml -a arm0"
print(usage)

#----------------------------------------------------------------------------------------------
# parse opts
try:
	optlist, args = getopt.getopt(sys.argv[1:], "i:t:a:h")
except:
	print("[error] unexpected opts")
	print(usage)
	sys.exit(0)

input_file = ""
output_file = ""
arm = ""

for opt, value in optlist:
	if opt == "-i":
		input_file = value
		print("input_file provided:", input_file)
	elif opt == "-t":
		output_file = value
		print("output_file provided:", output_file)
	elif opt == "-a":
		arm = value
		print("arm specified:", arm)
	elif opt == "-h":
		print(usage)
		exit()

#----------------------------------------------------------------------------------------------
# default value
if input_file == "":
	input_file = "lua_calibration.xml"
	print("input_file not provided, use default:", input_file)

if output_file == "":
	output_file = "drone_camera_calibration_arm0.xml"
	print("output_file not provided, use default:", output_file)

if arm == "":
	arm = "arm0"
	print("arm not provided, use default:", arm)

#----------------------------------------------------------------------------------------------
# read arm position and orientation from input_file
position_text = None; orientation_text = None
root = ET.parse(input_file).getroot()
# get camera_matrix tag
for arm_tag in root.findall("arm"):
	#if arm_tag.attrib[id]
	if arm_tag.attrib["id"] == arm :
		position_text = arm_tag.attrib["position"]
		orientation_text = arm_tag.attrib["orientation"]

print("Read " + arm + " extrinsic parameters")
if position_text == None:
	print(arm + " is not detected in " + input_file)
	exit()
print("position = " + position_text)
print("orientation = " + orientation_text)

#----------------------------------------------------------------------------------------------
# read output file and attributes to it
xml_file = ET.parse(output_file)
root = xml_file.getroot()
attrib = ""
for camera_tag in root.findall("drone_camera"):
	camera_tag.attrib["position"] = position_text
	camera_tag.attrib["orientation"] = orientation_text 
	attrib = camera_tag.attrib

#xml_file.write(output_file, encoding="utf8")

# write output file
str='''<?xml version="1.0" ?>
<calibration>
   <drone_camera focal_length="{}"
                 principal_point="{}"
                 distortion_k="{}"
                 distortion_p="{}"
                 position="{}"
                 orientation="{}"/>
</calibration>
'''.format(attrib["focal_length"],
           attrib["principal_point"],
           attrib["distortion_k"],
           attrib["distortion_p"],
           attrib["position"],
           attrib["orientation"])

f = open(output_file, "w")
f.write(str)
f.close()
print("File \"" + output_file + "\" updated!")