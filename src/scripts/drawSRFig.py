import statistics
# scipy.mean is deprecated
#import scipy
#from scipy import stats
import math
#from brokenaxes import brokenaxes

def drawSRFig(option) :
	dataFolder = option['dataFolder']

	main_ax = None
	violin_ax = None
	violin_ax_top = None

	if 'split_right' in option and option['split_right'] == True:
		# 4 subfigures
		fig, axs = plt.subplots(2, 2, gridspec_kw={'width_ratios': [5, 1], 'height_ratios': [1, 8]})
		fig.subplots_adjust(hspace=0.05)  # adjust space between axes

		main_ax = axs[1,0]
		violin_ax = axs[1,1]
		violin_ax_top = axs[0,1]
		axs[0,0].axis('off')

		violin_ax_top_lim_from = option['violin_ax_top_lim_from']
		violin_ax_top_lim_to = option['violin_ax_top_lim_to']
		violin_ax_top.set_ylim([violin_ax_top_lim_from, violin_ax_top_lim_to])

		# draw slides between the break
		axs[0,1].spines.bottom.set_visible(False)
		axs[1,1].spines.top.set_visible(False)

		#axs[0,1].xaxis.tick_top()
		axs[0,1].tick_params(labeltop=False)  # don't put tick labels at the top
		axs[0,1].tick_params(labelbottom=False)  # don't put tick labels at the top
		axs[1,1].tick_params(labeltop=False)  # don't put tick labels at the top
		axs[1,1].tick_params(labelbottom=False)  # don't put tick labels at the top

		#ax2.xaxis.tick_bottom()
		d = .5  # proportion of vertical to horizontal extent of the slanted line
		kwargs = dict(marker=[(-1, -d), (1, d)], markersize=12,
		              linestyle="none", color='k', mec='k', mew=1, clip_on=False)
		axs[0,1].plot([0, 1, 0.5], [0, 0, 0], transform=axs[0,1].transAxes, **kwargs)
		axs[1,1].plot([0, 1, 0.5], [1, 1, 1], transform=axs[1,1].transAxes, **kwargs)
	else:
		# 2 subfigures
		fig, axs = plt.subplots(1, 2, gridspec_kw={'width_ratios': [5, 1]})
		fig.subplots_adjust(hspace=0.05)  # adjust space between axes

		main_ax = axs[0]
		violin_ax = axs[1]

		axs[1].tick_params(labeltop=False)  # don't put tick labels at the top
		axs[1].tick_params(labelbottom=False)  # don't put tick labels at the top

	main_ax_lim_from = option['main_ax_lim_from']
	main_ax_lim_to = option['main_ax_lim_to']
	main_ax.set_ylim([main_ax_lim_from, main_ax_lim_to])
	violin_ax.set_ylim([main_ax_lim_from, main_ax_lim_to])

	main_ax.set_xlabel('Time(s)')
	main_ax.set_ylabel('Error(m)')

	#-------------------------------------------------------------------------
	# read one case and shade fill each robot data
	robotsData = []
	#for subfolder in getSubfolders("@CMAKE_CURRENT_SOURCE_DIR@/../data") :
	for subFolder in getSubfolders(dataFolder) :
		#drawData(readDataFrom(subFolder + "result_data.txt"))
		#drawData(readDataFrom(subFolder + "result_lowerbound_data.txt"))
		# choose a folder
		if 'sample_run' in option and subFolder != dataFolder + "/" + option['sample_run'] + "/" :
			continue
		# draw lowerbound
		X, sparseLowerbound = sparceDataEveryXSteps(readDataFrom(subFolder + "result_lowerbound_data.txt"), 5)
		#drawDataWithXInSubplot(X, sparseLowerbound, axs[0], 'hotpink')
		drawDataInSubplot(sparseLowerbound, main_ax, 'hotpink')
		for subFile in getSubfiles(subFolder + "result_each_robot_error") :
			robotsData.append(readDataFrom(subFile))
			#drawDataInSubplot(readDataFrom(subFile), main_ax)

		if os.path.isfile(subFolder + "formationSwitch.txt") :
			switchSteps = readDataFrom(subFolder + "formationSwitch.txt")
			switchTime = []
			for data in switchSteps :
				switchTime.append(data/5)
		break

	# draw vertical line for switch
	for data in switchTime :
		main_ax.axvline(x = data, color="black", linestyle=":")

	#drawData(readDataFrom("result_data.txt"))
	boxdata, positions = transferTimeDataToBoxData(robotsData, None, 5)
	X=[]
	for i in range(0, len(positions)) :
		X.append(i)

	mean = []
	upper = []
	lower = []
	mini = []
	maxi = []
	mask_min = 0
	for stepData in boxdata :
		meanvalue = statistics.mean(stepData)
		stdev = statistics.stdev(stepData)

		# scipy.mean is deprecated
		#meanvalue = scipy.mean(stepData)
		#stdev = stats.tstd(stepData)

		minvalue = min(stepData)
		maxvalue = max(stepData)
		mean.append(meanvalue)
		count = len(stepData)
		interval95 = 1.96 * stdev / math.sqrt(count)
		#interval999 = 3.291 * stdev / math.sqrt(count)
		interval99999 = 4.417 * stdev / math.sqrt(count)

		'''
		upper.append(meanvalue + interval95)
		lower.append(meanvalue - interval95)
		mini.append(meanvalue - interval99999)
		maxi.append(meanvalue + interval99999)
		'''
		if meanvalue + interval95 >= mask_min :
			upper.append(meanvalue + interval95)
		else :
			upper.append(mask_min)

		if meanvalue - interval95 >= mask_min :
			lower.append(meanvalue - interval95)
		else :
			lower.append(mask_min)

		if meanvalue - interval99999 >= mask_min :
			mini.append(meanvalue - interval99999)
		else :
			mini.append(mask_min)

		if meanvalue + interval99999 >= mask_min :
			maxi.append(meanvalue + interval99999)
		else :
			maxi.append(mask_min)

	#drawDataWithXInSubplot(positions, mean, axs[0], 'royalblue')
	drawDataWithXInSubplot(X, mean, main_ax, 'royalblue')
	main_ax.fill_between(
	    #positions, mini, maxi, color='b', alpha=.10)
	    X, mini, maxi, color='b', alpha=.10)
	main_ax.fill_between(
	    #positions, lower, upper, color='b', alpha=.30)
	    X, lower, upper, color='b', alpha=.30)

	#-------------------------------------------------------------------------
	# read all each robot data and make it a total box plot

	boxdata = []
	for subFolder in getSubfolders(dataFolder) :
		for subFile in getSubfiles(subFolder + "result_each_robot_error") :
			boxdata = boxdata + readDataFrom(subFile)

	violin_return_1 = violin_ax.violinplot(boxdata)
	violin_returns = [violin_return_1]
	if violin_ax_top != None :
		violin_return_2 = violin_ax_top.violinplot(boxdata)
		violin_returns.append(violin_return_2)

	for violin in violin_returns :
		for line in [violin['cbars'], violin['cmins'], violin['cmaxes']] :
			line.set_linewidth(1.3)

	if violin_ax_top != None :
		maxvalue = round(max(boxdata), 1)
		violin_ax_top.yaxis.set_ticks([maxvalue])

	if 'SRFig_save' in option :
		plt.savefig(option['SRFig_save'])
	if 'SRFig_show' in option and option['SRFig_show'] == True :
		plt.show()