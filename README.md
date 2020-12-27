## Guidelines
1. This project requires the latest versions of argos3 (https://github.com/ilpincy/argos3) and argos3-srocs (https://github.com/allsey87/argos3-srocs) to be installed.
    "Latest version" is only relative. The version I'm sure to work is:
    * argos3: 
       ```bash
       commit 86f60d26b2ad148c0455a290cd6bd6fa2109172d (HEAD -> master, origin/master, origin/HEAD)
       Author: Michael Allwright <allsey87@gmail.com>
       Date:   Tue Nov 24 09:37:16 2020 +0100
           Update BulletPhysics to version 3.06
       ```
    * argos3-srocs:
       ```bash
       commit 86b0846b4a9c61e200ff79d4758d20111f52fe50 (HEAD -> master, origin/master, origin/HEAD)
       Author: Harry ZHU <freedomcondor@126.com>
       Date:   Mon Dec 14 16:39:05 2020 +0100
           Import fixes by @freedomcondor
           1. Fix bug when getting the wheel velocity for the Pi-Puck and the BuilderBot
           2. Calibrate 3D dynamics model for the Pi-Puck (differential drive only)
           3. Improve aiming due to camera bias in the `aim_block` behavior node
       ```

2. After installing argos3 and argos3-srocs, you are clear to build this repository. Clone the repository and run the following commands. The default folder name is mns2.0, it should be ok to change this name :
   ```bash
   cd mns2.0
   mkdir build
   cd build
   cmake ../src
   make
   argos3 -c experiment/testing/02_allocate/vns.argos
   ```
   If everything is right, you should be able to see a group of drones and pipucks forming formations.
   
## Folder Explanation
1. **ARGoS loop function and user function :** They are located in src/loop_functions and src/qtopengl_user_functions. They provide a general function for most of the testing cases. For example loop function records the location of each robot.

2. **MNS core :**  The core source code of mns is located in src/experiment/api, src/experiment/utils and src/experiment/vns. Codes in these folders make the MNS algorithm come true.

3. **Testing and data :** src/experiment/testing and src/experiment/data is what the users play with. In testing folder, each subfolder is a scenario case to test one or several features of MNS. In data, each subfolder is an experiment in which a scenario got run for 100 times, and data collected and plotted. 
   
   **IMPORTANT NOTES:** The codes inside src/experiment/testing or data are pre-executable. The real codes are generated in cmake and make in build folder.
   
   For example, if you check    
   > src/experiment/testing/00_environment_setup/vns.argos.in 
   > Line 32

   you can see a @CMAKE_CURRENT_BINARY_DIR@ in it. After cmake and make, a 
   > build/experiment/testing/00_environment_setup/vns.argos 
   
   will be generated, and this @CMAKE_CURRENT_BINARY_DIR@ would be replaced by the absolute path of your folder. It is this file you should run. and it doesn't matter which folder are you in because, everything is in absolute paths.
   
   This happens to most of the files, most of the files got a copy or an "improved" copy in build folder during make. So, if you want to change the code, do it in src/, and make again. Any change in build is only temporary and would be overwritten in the next time you make.
   
## Scenario Explanation

I have already created several scenarios to play with. 
1. A simple one is "experiment/testing/02_allocate/" where a group of drones and pipucks form a cross shape.
2. In "experiment/data/06_full_scenario1", (and also 07_full_scenario2 and 08_full_scenario3) there is a scenario where a swarm forms, moves forward, changes the formation to move through the gate and push an object. Everything is automatic, you can just hit the play button and watch and change cameras while the robots are running.

## Drawing

Robots draw arrows around themselves to show debug messages. For example, in "experiment/testing/02_allocate/drone.lua or" line 56, pipuck.lua line 53, says "showParent". That means the robot would draw an arrow from itself to its parent.

There is another kind of arrows drawn by default, the code is in "experiment/api/commonAPI.lua" line 100, says "showVirtualFrame". A virtual frame keeps a logical (virtual) heading of a robot. For example a pipuck is heading west and moving forward, but in MNS logic, it considers itself heading north and moving leftward. The virtual frame shows this logical heading. All the robots show this arrow by default. You can comment out "commonAPI.lua" line 100 to disable this arrow.