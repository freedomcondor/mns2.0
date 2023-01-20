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

dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_08_split/data_hw/data"
dataFolder2 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_09_1d_switch_rescue/data_hw"
sample_run = "test_20220713_1_success_1"
#sample_run = "test_20220713_3_success_2"
#sample_run = "test_20220713_4_success_3"
#sample_run = "test_20220713_5_success_4"
#sample_run = "test_20220713_6_success_5"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'SRFig_save'             : "exp_0_hw_08_split_SRFig.pdf",
	'trackLog_save'          : "exp_0_hw_08_split_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.5, 6.5],

	#'split_right'            : True,
	#'violin_ax_top_lim'      : [2.3, 6.2],
	#'height_ratios'          : [1, 10],

	'double_right'           : True,
	'double_right_dataFolder': dataFolder2,
#------------------------------------------------
	'key_frame' :  [0] ,

	'key_frame_parent_index' :  [
		{}, # for key frame 0
		{
			'drone2'    :   'drone3'   ,
			'drone3'    :   'nil'      ,
			'pipuck1'   :   'drone3'  ,
			'pipuck2'   :   'drone2'  ,
			'pipuck3'   :   'pipuck6'  ,
			'pipuck4'   :   'drone2'  ,
			'pipuck5'   :   'pipuck6'  ,
			'pipuck6'   :   'drone3'  ,
		},
	] ,

	'x_lim'     :  [-3.5, 4.5]    ,
	'y_lim'     :  [-4, 4]    ,
	'z_lim'     :  [-1.0, 7.0]    ,
}


drawSRFig(option)
drawTrackLog(option)
