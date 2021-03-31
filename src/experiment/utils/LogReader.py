import sys

fileName = "log"

if len(sys.argv) >= 3:
	target_robot = sys.argv[1]
	target_step = int(sys.argv[2])

file = open(fileName, "r")
i = 0
mark = False
for line in file:
	i = i + 1
	User_Inputs = line.split('\t')

	if len(User_Inputs) >= 5 and User_Inputs[4] == "-----------------------\n":
		robot = User_Inputs[2]
		step = int(User_Inputs[3])

		if robot == target_robot and step == target_step :
			mark = True
		else :
			mark = False
		
	if mark == True:
		line = line.rstrip('\n')
		print(line)