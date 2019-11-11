#!/bin/bash

CONTENT_FILE=./movie_list2.txt
CONTENT_MOVIE_INFO_FILE=./movie_info.txt
file_ffmpeg_convert2_info=""
ffmpeg_tool="/diskD/movie/ffmpeg"
ffprobe_tool="/diskD/movie/ffprobe"
cpu_num=`cat /proc/cpuinfo  |grep "processor"|wc -l`
local_path=$PWD
echo $local_path
find $PWD -iname "*.mkv" |grep convert_OK |grep -v "遇见你真好"|grep -v "战犬瑞克斯原声版"\
	|grep -v "悲伤逆流成河" |grep -v "奔跑吧兄弟" |grep -v "战犬瑞克斯译制版" |grep -v "环太平洋2：雷霆再起译制版" |grep -v "环太平洋2：雷霆再起原声版"\
	> $CONTENT_FILE #-or -iname "*.mp4"  -or -iname "*.avi"  -or -iname "*.ts" -or -iname "*.rmvb" -or -iname "*.mpg"  -or -iname "*.mov" 
rm $CONTENT_MOVIE_INFO_FILE
cat $CONTENT_FILE | while read line
do
	echo "current file name is :"$line
	filename=`echo $line |awk -F "/" '{print $NF}'`
	path=`dirname $line`
	folder_name=`echo $path |awk -F "/" '{print $NF}'`
	file_name=`echo ${filename%.*}`
	file_fmt=`echo ${filename##*.}`
	file_ffmpeg_convert3_info=$path/$filename.audio.convertinfo
	echo "file fmt :"$file_fmt
	echo "total cnt is: " $itotalCnt "current proessed cnt is: "$icnt
	echo "current process file is : "$filename
	echo "Absolute Path is : "$path
	echo "Folder name is : "$folder_name
	echo "file_name is : "$file_name
	#$ffprobe_tool $line 1>>$CONTENT_MOVIE_INFO_FILE 2>>$CONTENT_MOVIE_INFO_FILE
	cd ${path}
	mv $filename ${file_name}_bak.mkv
	$ffmpeg_tool -threads $cpu_num -y -i ${file_name}_bak.mkv -map 0 -c copy -c:a:1 aac $filename < /dev/null 1>$file_ffmpeg_convert3_info 2>$file_ffmpeg_convert3_info
	
	cd ${local_path}
done