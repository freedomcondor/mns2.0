import os
import sys

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

data_set = 'random'
if len(sys.argv) >= 2 :
	data_set = sys.argv[1]

test_start = 1
test_end = 100

if not all([sys.argv[2], sys.argv[3]]) :
	print("incomplete parameters, set start and end as 1 to 100")
else :
	test_start = int(sys.argv[2])
	test_end = int(sys.argv[3])

total_length = 5 * 2600

for i in range(test_start, test_end + 1):
	print("evaluating test" + str(i))
	os.system(testfolder_build + "/evaluator/main " + str(total_length) + " " + testfolder_src + "/" + data_set + "/run" + str(i) + "/")
	#os.system("mv result.txt " + testfolder_src + "/" + data_set + "/run" + str(i) + "/result.txt")
	#os.system("mv result_lowerbound.txt " + testfolder_src + "/" + data_set + "/run" + str(i) + "/result_lowerbound.txt")
	os.system("mv result.txt " + testfolder_src + "/" + data_set + "/run" + str(i) + "/result_stretched.txt")
	os.system("mv result_lowerbound.txt " + testfolder_src + "/" + data_set + "/run" + str(i) + "/result_lowerbound_stretched.txt")