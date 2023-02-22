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

dataFolder = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/data_simu_30s/data"
sample_run = "run1"

dataFolder1 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/data_simu_0.5s/data"
dataFolder2 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/data_simu_1s/data"
dataFolder3 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/data_simu_30s/data"

#dataFolder1 = "@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/data_simu_30s/data"

option = {
	'dataFolder'             : dataFolder,
	'sample_run'             : sample_run,
	'SRFig_save'             : "exp_3_simu_03_fault_tolerance_communication_SRFig.pdf",
	'trackLog_save'          : "exp_3_simu_03_fault_tolerance_communication_trackLog.pdf",
	'SRFig_show'             : True,
	'trackLog_show'          : False,

	'main_ax_lim'            : [-0.5, 7],

	'split_right'            : True,
	'violin_ax_top_lim'      : [9.8, 10.8],
	'height_ratios'          : [1, 7.5],

	'failure_place_holder'   : 0,

	'trible_right'           : True,
	'trible_right_dataFolder1':  dataFolder1,
	'trible_right_dataFolder2':  dataFolder2,
	'trible_right_dataFolder3':  dataFolder3,
}
#------------------------------------------------
'''
	#'key_frame' :  [0, 250, 950] ,
	'key_frame' :  [0, 500] ,

	'overwrite_trackFig_log_foler' : 
		"@CMAKE_SOURCE_DIR@/../../mns2.0-data/src/experiments/exp_3_simu_03_fault_tolerance_communication/track_fig_logs/logs"
	,

	'legend_obstacle'  : True,

	'x_lim'     :  [-12, 12]    ,
	'y_lim'     :  [-12, 12]        ,
	'z_lim'     :  [-4.0,8.0]    ,
}
'''

drawSRFig(option)
#drawTrackLog(option)


