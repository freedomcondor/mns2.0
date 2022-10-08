for i in BB5A0070 BB5A0071 BB5A0073 BB5A0074 BB5A0075 BB5A0076 BB5A0077 BB5A0078 BB5A0079 BB5A0080 BB5A0081 BB5A0082 BB5A0083 BB5A0084 BB5A0085 BB5A0086 BB5A0087
do
	#ffmpeg -i /media/harry/1A803F64803F4613/showmanship/$i.MP4 -vcodec libx265 -crf 28 -vf scale=1920x1080 -pix_fmt yuv420p output_$i.mp4
	ffmpeg -i /media/harry/1A803F64803F4613/showmanship/$i.MOV -vcodec libx265 -crf 24 -vf scale=1920x1080 -pix_fmt yuv420p output_$i.mp4
done
