import os
import sys
import random

testfolder_build = '@CMAKE_CURRENT_BINARY_DIR@'
testfolder_src = '@CMAKE_CURRENT_SOURCE_DIR@'

def generate_argos_file(TotalLength, RandomSeed):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	filedata = filedata.replace('RANDOMSEED', str(RandomSeed))
	filedata = filedata.replace('TOTALLENGTH', str(TotalLength))

	# Write the file out again
	with open('vns.argos', 'w') as file:
		file.write(filedata)

TotalLength = 0 / 5
RandomSeed = 2
random.seed(RandomSeed)
generate_argos_file(TotalLength, RandomSeed)

os.system("argos3 -c vns.argos")

