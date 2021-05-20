import os

mnsfolder = '/Users/harry/Desktop/mns2.0/'
casefolder = 'experiment/data/02_displace_mns_drone'
testfolder_build = mnsfolder + 'build/' + casefolder
testfolder_src = mnsfolder + 'src/' + casefolder

threads = 5
each = 20
for i in range(1, threads + 1) :
    os.system("mkdir thread" + str(i))
    command = "python " 
    command = command + testfolder_src + "/scripts/run_single_thread.py " 
    command = command + str((i-1)*each+1) + " " + str((i-1)*each+each) + " "
    if i == 1 :
        os.system("tmux new-session -c thread"+str(i)+" -d -s argosthreads \""+command+"; bash -i\"")
    else : 
        os.system("tmux split-window -h -c thread"+str(i)+" -t argosthreads \""+command+"; bash -i\"")

os.system("tmux select-layout -t argosthreads even-horizontal")
os.system("tmux attach-session -t argosthreads")