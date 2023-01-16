drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

drawSRFigFileName = "@CMAKE_SOURCE_DIR@/scripts/drawSRFig.py"
#execfile(drawSRFigFileName)
exec(compile(open(drawSRFigFileName, "rb").read(), drawSRFigFileName, 'exec'))

logGeneratorFileName = "@CMAKE_SOURCE_DIR@/scripts/logReader/logReplayer.py"
exec(compile(open(logGeneratorFileName, "rb").read(), logGeneratorFileName, 'exec'))

drawTrackLogFileName = "@CMAKE_SOURCE_DIR@/scripts/drawTrackLogs.py"
exec(compile(open(drawTrackLogFileName, "rb").read(), drawTrackLogFileName, 'exec'))

dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_03_obstacle_avoidance_large/data_hw/data"
#sample_run = "test_20220624_1_success_2"
sample_run = "test_20220624_2_success_3"
#sample_run = "test_20220624_3_success_4"
#sample_run = "test_20220624_4_success_5"
#sample_run = "test_20220627_1_success_6"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'SRFig_save'             : "exp_0_hw_03_obstacle_avoidance_large_SRFig.pdf",
	'trackLog_save'          : "exp_0_hw_03_obstacle_avoidance_large_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.2, 2],

	'split_right'            : True,
	'violin_ax_top_lim'      : [3.9, 4.1],
	'height_ratios'          : [1, 10],

#------------------------------------------------
	'key_frame' :  [0, 400] ,

	'key_frame_parent_index' :  [
		{}, # for key frame 0
		{
			'drone2'    :   'drone4'  ,
			'drone4'    :   'nil'     ,
			'pipuck2'   :   'drone4'  ,
			'pipuck4'   :   'drone4'  ,
			'pipuck5'   :   'drone4'  ,
			'pipuck7'   :   'drone4'  ,
			'pipuck8'   :   'drone2'  ,
			'pipuck9'   :   'drone2'  ,
		},
		{
			'drone2'    :   'drone4'  ,
			'drone4'    :   'nil'     ,
			'pipuck2'   :   'drone4'  ,
			'pipuck4'   :   'drone4'  ,
			'pipuck5'   :   'drone4'  ,
			'pipuck7'   :   'drone4'  ,
			'pipuck8'   :   'drone2'  ,
			'pipuck9'   :   'drone2'  ,
		},
	] ,

	'x_lim'     :  [-4, 5]           ,
	'y_lim'     :  [-4.5, 4.5]       ,
	'z_lim'     :  [-1.0, 8]         ,
}

drawSRFig(option)
drawTrackLog(option)
