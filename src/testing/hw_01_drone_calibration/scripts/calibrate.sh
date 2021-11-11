#----------------------------------------------------------------------------------------------
# usage message 
usage=\
"[usage] example: bash calibrate.sh -i \"images0 images1...\" -a arm1 -t <path to opencv calibrate executable file>"
echo $usage

#----------------------------------------------------------------------------------------------
# check flags
while getopts "a:i:" arg; do
	case $arg in
		a)
			echo "arm provided: $OPTARG"
			arm=$OPTARG
			;;
		i)
			echo "input folders provided: $OPTARG"
			input_folders=$OPTARG
			;;
		t) 
			echo "opencv calibrate executable file provided $OPTARG"
			opencv_calibrate=$OPTARG
	esac
done

#----------------------------------------------------------------------------------------------
# default value
if [ -z "$input_folders" ]; then
	input_folders="images"
	echo "Input_folder not provided, use $input_folders by default"
fi
if [ -z "$arm" ]; then
	arm="arm0"
	echo "arm not provided, use $arm by default"
fi
if [ -z "$opencv_calibrate" ]; then
	opencv_calibrate="/home/harry/code/opencv/samples/cpp/tutorial_code/calib3d/camera_calibration/build/calibration"
	echo "opencv calibrate file not provided, use $opencv_calibrate by default"
fi

#----------------------------------------------------------------------------------------------
# create image name lists
name_list=""
for input_folder in $input_folders; do
	echo "traversing $input_folder"
	if [ ! -d "$input_folder/$arm" ]; then
		echo "[error] $input_folder/$arm doesn't exist!"
		exit
	fi

	# for each png file in $input_folder/$arm folder
	for file in $input_folder/$arm/*.png; do
		name_list="$name_list$file\n"
	done
done

#----------------------------------------------------------------------------------------------
# create image_list.xml
output="image_list.xml"
echo -e \
"<?xml version="1.0"?>\n\
<opencv_storage>\n\
<images>\n\
$name_list\
</images>\n\
</opencv_storage>" \
> $output

echo "$output prepared, ready to calibrate"

#----------------------------------------------------------------------------------------------
# calibrate
$opencv_calibrate calibration_input.xml