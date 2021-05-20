import os

testfolder_build = "@CMAKE_CURRENT_BINARY_DIR@/.."
testfolder_src = "@CMAKE_CURRENT_SOURCE_DIR@/.."

base = 0
threads = 5
each = 2
for i in range(1, threads + 1) :
    os.system("mkdir thread" + str(i))
    command = "python " 
    command = command + testfolder_build + "/scripts/run_single_thread.py " 
    command = command + str(base+(i-1)*each+1) + " " + str(base+(i-1)*each+each) + " "
    if i == 1 :
        os.system("tmux new-session -c thread"+str(i)+" -d -s argosthreads \""+command+"; bash -i\"")
    else : 
        os.system("tmux split-window -h -c thread"+str(i)+" -t argosthreads \""+command+"; bash -i\"")
        os.system("tmux select-layout -t argosthreads even-horizontal")

os.system("tmux select-layout -t argosthreads even-horizontal")
os.system("tmux attach-session -t argosthreads")