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

dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_01_formation_1_2d_10p/data_hw/data"
dataFolder2 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_10_formation_1_2d_6p_group_start/data_hw/data"
#sample_run = "test_20220621_6_success_1"
#sample_run = "test_20220621_7_success_2"
#sample_run = "test_20220621_8_success_3"
sample_run = "test_20220621_9_success_4"
#sample_run = "test_20220621_10_success_5"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'SRFig_save'             : "exp_0_hw_01_formation_1_2d_10p_SRFig.pdf",
	'trackLog_save'          : "exp_0_hw_01_formation_1_2d_10p_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.2, 2],

	'split_right'            : True,
	#'violin_ax_top_lim'      : [5.75, 6],
	'violin_ax_top_lim'      : [2.3, 6.2],
	#'height_ratios'          : [1, 10],

	'double_right'           : True,
	'double_right_dataFolder': dataFolder2,
#------------------------------------------------
	'key_frame' :  [0] ,

	'key_frame_parent_index' :  [
		{}, # for key frame 0
		{
			'drone2'    :   'drone4'   ,
			'drone4'    :   'nil'      ,
			'pipuck1'   :   'drone4'  ,
			'pipuck2'   :   'drone2'  ,
			'pipuck4'   :   'drone2'  ,
			'pipuck5'   :   'drone2'  ,
			'pipuck6'   :   'drone4'  ,
			'pipuck7'   :   'drone4'   ,
			'pipuck8'   :   'drone4'   ,
			'pipuck9'   :   'drone4'  ,
			'pipuck10'  :   'drone2'  ,
			'pipuck11'  :   'drone2'  ,
		},
	] ,

	'x_lim'     :  [-1.5, 3.5]    ,
	'y_lim'     :  [-2.5, 2.5]    ,
	'z_lim'     :  [-1.0, 3.0]    ,
}

drawSRFig(option)
drawTrackLog(option)
