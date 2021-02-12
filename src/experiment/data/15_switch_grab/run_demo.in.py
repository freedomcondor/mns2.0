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

def generate_argos_file(TotalLength, RandomSeed):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))
	if Visual == False :
		filedata = filedata.replace('VISUALIZATION_HEAD', '<!--')
		filedata = filedata.replace('VISUALIZATION_TAIL', '-->')

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

TotalLength = 2500 / 5
if Visual :
	TotalLength = 0 
RandomSeed = Inputseed or 2

random.seed(RandomSeed)
generate_argos_file(TotalLength, RandomSeed)

os.system("argos3 -c vns.argos")