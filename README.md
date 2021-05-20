## Guidelines
1. This project requires the latest versions of argos3 (https://github.com/ilpincy/argos3) and argos3-srocs (https://github.com/allsey87/argos3-srocs) to be installed.
	"Latest version" is only relative. The current version to work with is:
	* argos3: 
		```bash
		commit f2b2d0d7b5dac6500ae34bb69d03f18ae4502257 (HEAD -> master, origin/master, origin/HEAD)
		Merge: e9d6feb 7c8a51b
		Author: Carlo Pinciroli <carlo@pinciroli.net>
		Date:   Mon May 17 11:21:26 2021 -0400

			Merge branch 'master' of https://github.com/ilpincy/argos3
		```
	* argos3-srocs:
		```bash
		commit fe6ef45b7b1844ed4bb78db0ffb3794000bb530a (HEAD -> master, origin/master, origin/HEAD)
		Author: Michael Allwright <allsey87@gmail.com>
		Date:   Wed May 19 18:50:04 2021 +0200

    		Specify resolutions using UInt32 and convert to int32_t/uint8_t at the libapriltag boundary
		```

2. After installing argos3 and argos3-srocs, you are clear to build this repository. Clone the repository and run the following commands. The default folder name is mns2.0, it should be ok to change this name :
	```bash
	cd mns2.0
	mkdir build
	cd build
	cmake ../src
	make
	argos3 -c testing/01_allocate/vns.argos
	```
	If everything is right, you should be able to see a group of drones and pipucks forming formations.
	
## Folder Explanation
0. **argos3 and cmake :** `src/cmake` contains necessary cmake files to find argos3 and argos3-srocs. `src/argos3` is a simbolic link to the parent folder, it is needed for loop function to compile. You wouldn't need to touch these usually.

1. **ARGoS loop function and user function :** They are located in `src/loop_functions` and `src/qtopengl_user_functions`. They provide a general function for most of the testing cases. For example loop function records the location of each robot. user function provides function to draw arrows.

2. **MNS core :**  The core source code of mns is located in `src/core`. Codes in these folders make the MNS algorithm come true.

3. **Testing :** src/testing is what the users play with. In testing folder, each subfolder is a scenario case to test one or several features of MNS, or an experiment in which a scenario got run for 100 times, and data collected and plotted. You can copy or create a new subfolder to create your own scenario.
	
	**IMPORTANT NOTES:** The codes inside `src/testing` are pre-executable. All the codes in `src/core` and `src/testing` are generated by cmake and make in `build/core` and `build/testing` folder.
	
	For example, if you check    
	> src/testing/00_environment_test/vns.argos.in 
	> Line 32

	you can see a `@CMAKE_CURRENT_BINARY_DIR@` in it. After cmake and make, a 
	> build/testing/00_environment_setup/vns.argos 
	
	will be generated, and this `@CMAKE_CURRENT_BINARY_DIR@` would be replaced by the absolute path of your folder. It is this file that you should run, and it doesn't matter which folder you are currently at, for everything is generated in absolute paths.
	
	This happens to most of the files, most of the files got a copy or an "improved" copy in build folder during make. So, if you want to change the code, do it in src/, and cmake and make again. Any change in build is only temporary and would be overwritten the next time you make.
	
## Scenario Explanation

I have already created several scenarios to play with. 
1. A simple one is `testing/01_allocate/` where a group of drones and pipucks form a cross shape.
2. In `testing/06_full_scenario1`, (and also 07_full_scenario2 and 08_full_scenario3) there is a scenario where a swarm forms, moves forward, changes the formation to move through the gate and push an object. Everything is automatic, you can just hit the play button and watch and change cameras while the robots are running.

## Drawing

Robots draw arrows around themselves to show debug messages. For example, in `testing/02_allocate/drone.lua` line 56, or pipuck.lua line 53, says `showParent`. That means the robot would draw an arrow from itself to its parent.

There is another kind of arrows drawn by default, the code is in `experiment/api/commonAPI.lua` line 100, says `showVirtualFrame`. A virtual frame keeps a logical (virtual) heading of a robot. For example a pipuck is heading west and moving forward, but in MNS logic, it considers itself heading north and moving leftward. The virtual frame shows this logical heading. All the robots show this arrow by default. You can comment out `commonAPI.lua` line 100 to disable this arrow.