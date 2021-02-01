import os
import sys

mnsfolder = '/Users/harry/Desktop/mns2.0/'
casefolder = 'experiment/data/09_auto_scenario'
testfolder_build = mnsfolder + 'build/' + casefolder
testfolder_src = mnsfolder + 'src/' + casefolder

test_start = 1
test_end = 100
if not all([sys.argv[1], sys.argv[2]]) :
	print("incomplete parameters, set start and end as 1 to 100")
else :
	test_start = int(sys.argv[1])
	test_end = int(sys.argv[2])

total_length = 2500

def generate_argos_file(i):
	#read in the file
	#with open(testfolder_build + '/vns_template.argos', 'r') as file :
	with open(testfolder_build + '/fill_wall_location_template.py', 'r') as file :
		filedata = file.read()

	# Replace the target string
	filedata = filedata.replace('TOTALLENGTHPY', str(total_length/5))
	filedata = filedata.replace('RANDOMSEEDPY', str(i))

	# Write the file out again
	#with open('vns_test.argos', 'w') as file:
	with open('fill_wall_location.py', 'w') as file:
		file.write(filedata)

for i in range(test_start, test_end + 1):
	print("running test" + str(i))
	generate_argos_file(i)
	os.system("python fill_wall_location.py && argos3 -c vns.argos")

	os.system("mkdir " + testfolder_src + "/random/run" + str(i))

	os.system(testfolder_build + "/evaluator/main " + str(total_length) + " ./")
	os.system("mv result.txt " + testfolder_src + "/random/run" + str(i) + "/result.txt")

	os.system("mv *.csv " + testfolder_src + "/random/run" + str(i))
	os.system("mv vns.argos " + testfolder_src + "/random/run" + str(i))
	os.system("mv fill_wall_location.py " + testfolder_src + "/random/run" + str(i))