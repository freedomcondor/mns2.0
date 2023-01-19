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
	'dataFolder' : "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_1_simu_04_switch_line/data_simu/data",
	'sample_run'             : "run1",
	'SRFig_save'             : "exp_1_simu_04_switch_line_SRFig.pdf",
	'trackLog_save'          : "exp_1_simu_04_switch_line_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.5, 7.5],

	'split_right'            : True,
	'violin_ax_top_lim'      : [9.5, 10],

#------------------------------------------------
	#'key_frame' :  [0, 300, 2000] ,  # option 1
	'key_frame' :  [0, 500] ,
	'overwrite_trackFig_log_foler' : 
		"@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_1_simu_04_switch_line/data_simu/track_fig_logs"
	,

	'legend_obstacle'  : True,

	'x_lim'     :  [-12, 12]    ,
	'y_lim'     :  [-12, 12]        ,
	'z_lim'     :  [-4.0,8.0]    ,
}

drawSRFig(option)
drawTrackLog(option)
