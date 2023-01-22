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
	'dataFolder' : "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_2_simu_scalability/data_simu_scale_4/data",
	'sample_run'             : "run1",
	'SRFig_save'             : "exp_2_simu_scalability_scale4_SRFig.pdf",
	'trackLog_save'          : "exp_2_simu_scalability_scale4_trackLog.pdf",
	'SRFig_show'             : False,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.5, 13],

	'split_right'            : True,
	'violin_ax_top_lim'      : [17.5, 19.5],

#------------------------------------------------
	#'key_frame' :  [0, 300, 2000] ,  # option 1
	'key_frame' :  [0, 1200] ,
	'overwrite_trackFig_log_foler' : 
		"@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_2_simu_scalability/track_fig_logs_scale_4"
	,

	'figsize'          : [10, 10],
	'legend_obstacle'  : True,

	'x_lim'     :  [-15,   20]   ,
	'y_lim'     :  [-17.5, 17.5] ,
	'z_lim'     :  [-10.0, 25.0] ,
}

drawSRFig(option)
drawTrackLog(option)
