import os
import sys

test_number = 100
testfolder_build = 'experiment/data/02_displace_mns_drone' 
testfolder_src = '../src/' + testfolder_build

jump = 400
total_length = 1200

def generate_argos_file(i):
	#read in the file
	with open(testfolder_build + '/vns_template.argos', 'r') as file :
		filedata = file.read()

	# Replace the target string
	filedata = filedata.replace('TOTALLENGTH', str(total_length/5))
	filedata = filedata.replace('RANDOMSEED', str(i))

	# Write the file out again
	with open(testfolder_build + '/vns_test.argos', 'w') as file:
		file.write(filedata)

for i in range(1, test_number + 1):
	print("running test" + str(i))
	generate_argos_file(i)
	os.system("argos3 -c " + testfolder_build + "/vns_test.argos")

	os.system("mkdir " + testfolder_src + "/random/run" + str(i))

	os.system(testfolder_src + "/evaluator/main " + str(jump) + " ./")
	os.system("mv result.txt " + testfolder_src + "/random/run" + str(i) + "/result1.txt")
	os.system(testfolder_src + "/evaluator/main " + str(total_length) + " ./")
	os.system("mv result.txt " + testfolder_src + "/random/run" + str(i) + "/result2.txt")

	os.system("mv *.csv " + testfolder_src + "/random/run" + str(i))
	os.system("mv " + testfolder_build + "/vns_test.argos " + testfolder_src + "/random/run" + str(i))