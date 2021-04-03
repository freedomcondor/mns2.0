import os
import sys

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

test_start = 1
test_end = 100
if not all([sys.argv[1], sys.argv[2]]) :
	print("incomplete parameters, set start and end as 1 to 100")
else :
	test_start = int(sys.argv[1])
	test_end = int(sys.argv[2])

total_length = 1000

for i in range(test_start, test_end + 1):
	print("running test" + str(i))
	os.system("python " + testfolder_build + "/run_demo.py " + str(i) + " novisual")

	os.system("mkdir " + testfolder_src + "/random/run" + str(i))

	os.system(testfolder_build + "/evaluator/main " + str(total_length) + " ./")
	os.system("mv result.txt " + testfolder_src + "/random/run" + str(i) + "/result.txt")

	os.system("mv *.csv " + testfolder_src + "/random/run" + str(i))
	os.system("mv vns.argos " + testfolder_src + "/random/run" + str(i))