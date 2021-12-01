#----------------------------------------------------------------------------------------------
# usage message 
usage=\
"[usage] example: bash copy_images_from_drone.sh -i 192.168.1.103:/media/usb/ -a arm0(default all) -s images(folder name) -t temp(folder name)"
echo $usage

temp_folder="temp"

#----------------------------------------------------------------------------------------------
# check flags
while getopts "i:a:s:h" arg; do
	case $arg in
		i)
			echo "ip provided: $OPTARG"
			drone_ip=$OPTARG
			;;
		a)
			echo "arm provided: $OPTARG"
			arm=$OPTARG
			;;
		s)
			echo "save folder provided: $OPTARG"
			save_folder=$OPTARG
			;;
		h)
			exit
	esac
done

#----------------------------------------------------------------------------------------------
# default value
if [ -z "$drone_ip" ]; then
	drone_ip="192.168.1.103:/media/usb/"
	echo "ip not provided, use $drone_ip by default"
fi
if [ -z "$arm" ]; then
	arm="all"
	echo "arm not provided, copy all arms images by default"
fi
if [ -z "$save_folder" ]; then
	save_folder="images"
	echo "save folder not provided, use $save_folder by default"
fi
if [ -z "$temp_folder" ]; then
	temp_folder="images"
	echo "temp folder not provided, use $temp_folder by default"
fi

#----------------------------------------------------------------------------------------------
# create temp folder
if [ -d "$temp_folder" ]; then
	echo "[Warning] $temp_folder folder exist! Overwrite by default"
	rm -r $temp_folder
fi
mkdir $temp_folder

#----------------------------------------------------------------------------------------------
# copy pnms from the drone
echo "Copying pnms from the drone"
pnm_name="*.pnm"
if [ "$arm" != "all" ]; then
	pnm_name="*$arm.pnm"
fi
scp root@$drone_ip$pnm_name $temp_folder

# check temp_folder empty
if [ "`ls -A $temp_folder`" = "" ]; then
	echo "[Error] Nothing copied, maybe check ip address or confirm that there are images on the drone?"
	rm -r $temp_folder
	exit
fi

echo "Converting pnms to pngs"
for f in $temp_folder/*.pnm
do
	base=${f%.*}
	if [ -s ${base}.pnm ]; then
		pnmtopng ${base}.pnm > ${base}.png
	else
		echo "${base}.pnm is empty"
	fi
done
rm $temp_folder/*.pnm

#----------------------------------------------------------------------------------------------
# sort images
#  create save folder
if [ -d "$save_folder" ]; then
	echo "[Warning] $save_folder folder exist! Overwrite by default"
	rm -r $save_folder
fi
mkdir $save_folder
if [ "$arm" != "all" ]; then
	mv $temp_folder $save_folder/$arm
else
	for armi in arm0 arm1 arm2 arm3; do
		mkdir $save_folder/$armi
		mv $temp_folder/*$armi.png $save_folder/$armi
	done
	rm -r $temp_folder
fi
	