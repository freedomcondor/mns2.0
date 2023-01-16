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

dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_04_switch_line/data_hw/data"
#sample_run = "test_20220628_1_success_1"
#sample_run = "test_20220628_2_success_2"
sample_run = "test_20220628_3_success_3"
#sample_run = "test_20220628_4_success_4"
#sample_run = "test_20220628_5_success_5"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'SRFig_save'             : "exp_0_hw_04_switch_line_SRFig.pdf",
	'trackLog_save'          : "exp_0_hw_04_switch_line_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.5, 3.5],

#	'split_right'            : True,
#	'violin_ax_top_lim_from' : 5,
#	'violin_ax_top_lim_to'   : 5.5,

#------------------------------------------------
	'key_frame' :  [0, 400, 1000] ,

	'key_frame_parent_index' :  [
		{}, # for key frame 0
		{
			'drone2'    :   'drone4'   ,
			'drone4'    :   'nil'      ,
			'pipuck2'   :   'drone4'   ,
			'pipuck4'   :   'drone2'   ,
			'pipuck5'   :   'drone4'   ,
			'pipuck7'   :   'drone2'   ,
			'pipuck8'   :   'drone4'   ,
			'pipuck9'   :   'drone4'   ,
		},
		{
			'drone2'    :   'drone4'   ,
			'drone4'    :   'nil'      ,
			'pipuck2'   :   'pipuck5'  ,
			'pipuck4'   :   'drone4'   ,
			'pipuck5'   :   'drone4'   ,
			'pipuck7'   :   'pipuck8'  ,
			'pipuck8'   :   'pipuck2'  ,
			'pipuck9'   :   'pipuck7'  ,
		},
		{
			'drone2'    :   'drone4'   ,
			'drone4'    :   'nil'      ,
			'pipuck2'   :   'drone4'   ,
			'pipuck4'   :   'drone4'   ,
			'pipuck5'   :   'drone4'   ,
			'pipuck7'   :   'drone2'   ,
			'pipuck8'   :   'drone2'   ,
			'pipuck9'   :   'drone4'   ,
		},
	] ,

	'x_lim'     :  [-4, 4.5]           ,
	'y_lim'     :  [-4.25, 4.25]       ,
	'z_lim'     :  [-1.0, 7.5]         ,
}

drawSRFig(option)
drawTrackLog(option)


