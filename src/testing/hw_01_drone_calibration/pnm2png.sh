mkdir $1
scp root@192.168.1.105:~/*.pnm $1
for f in $1/*.pnm
do
	base=${f%.*}
	pnmtopng ${base}.pnm > ${base}.png
done
rm $1/*.pnm
