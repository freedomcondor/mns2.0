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

option = {
	'dataFolder' : "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_0_hw_05_gate_switch/data_hw/data",
	'sample_run'             : "test_20220630_12_success_3",
	'SRFig_save'             : "exp_0_hw_05_gate_switch_SRFig.pdf",
	'trackLog_save'          : "exp_0_hw_05_gate_switch_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.3, 4.0],

	'split_right'            : True,
	'violin_ax_top_lim'      : [5, 5.5],

#------------------------------------------------
	'key_frame' :  [0, 300, 1200] ,
	'key_frame_parent_index' :  [
		{}, # for key frame 0
		{
			'drone2'    :   'nil'      ,
			'drone3'    :   'drone2'   ,
			'pipuck2'   :   'drone2'   ,
			'pipuck4'   :   'drone3'   ,
			'pipuck5'   :   'drone2'   ,
			'pipuck7'   :   'drone2'   ,
			'pipuck8'   :   'drone3'   ,
			'pipuck9'   :   'drone2'   ,
		},
		{
			'drone2'    :   'drone3'   ,
			'drone3'    :   'nil'      ,
			'pipuck2'   :   'drone3'   ,
			'pipuck4'   :   'drone3'   ,
			'pipuck5'   :   'drone2'   ,
			'pipuck7'   :   'drone3'   ,
			'pipuck8'   :   'drone3'   ,
			'pipuck9'   :   'drone2'   ,
		},
		{
			'drone2'    :   'drone3'   ,
			'drone3'    :   'nil'      ,
			'pipuck2'   :   'drone3'   ,
			'pipuck4'   :   'drone2'   ,
			'pipuck5'   :   'drone2'   ,
			'pipuck7'   :   'drone3'   ,
			'pipuck8'   :   'drone3'   ,
			'pipuck9'   :   'drone2'   ,
		},
	] ,

	'x_lim'     :  [-3.5, 4.5]    ,
	'y_lim'     :  [-4, 4]        ,
	'z_lim'     :  [-1.0, 7.0]    ,
}

drawSRFig(option)
drawTrackLog(option)
