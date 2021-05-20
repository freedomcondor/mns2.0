import matplotlib.pyplot as plt
import numpy as np
import sys
import os

mnsfolder = '/Users/harry/Desktop/mns2.0/'
casefolder = 'experiment/data/06_full_scenario1'
testfolder_build = mnsfolder + 'build/' + casefolder
testfolder_src = mnsfolder + 'src/' + casefolder

data_set = sys.argv[1]

total_timestep = 5500

i = 0
for folder in os.walk(testfolder_src + "/" + data_set + "/") :
	#jump over the first one
	if folder[1] != [] : 
		continue

	i = i + 1

	os.system(testfolder_build + "/evaluator/main " + str(total_timestep) + " " + folder[0] + "/")
	os.system("mv result.txt " + folder[0] + "/result.txt")
