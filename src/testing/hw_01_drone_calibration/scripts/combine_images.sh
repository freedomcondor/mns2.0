working_path=$1
current=`pwd`
cd $working_path
working_path=`pwd`
mkdir -p $working_path/combined
cd $working_path/arm1
for f in *.png
do
    base=${f%_arm1.png}
    convert +append $working_path/arm1/${base}_arm1.png $working_path/arm0/${base}_arm0.png ../upper.png
    convert +append $working_path/arm2/${base}_arm2.png $working_path/arm3/${base}_arm3.png ../bottom.png
    convert -append ../upper.png ../bottom.png $working_path/combined/${base}_combined.png
    rm ../upper.png ../bottom.png
done
cd $current
