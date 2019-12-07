#!/bin/bash

CONTENT_FILE=./movie_list.txt
key_path="/diskD/long.wang/work/key/encrypt.keyinfo"
ffmpeg_tool="/diskD/movie/ffmpeg"
ffprobe_tool="/diskD/movie/ffprobe"
find $PWD -iname "*.mkv" -or -iname "*.mp4"  -or -iname "*.avi"  \
	-or -iname "*.ts" -or -iname "*.rmvb" -or -iname "*.mpg"  \
	-or -iname "*.m4v"  \
	-or -iname "*.mov"|grep -v convert_OK > $CONTENT_FILE
icnt=0
local_path=$PWD
echo $local_path
itotalCnt=`cat $CONTENT_FILE | wc -l`
i=0
index_last=0
str=""
arr=("|" "/" "-" "\\")
video_copy=true
convert_path=$local_path/convert_OK
cpu_num=`cat /proc/cpuinfo  |grep "processor"|wc -l`
mkdir -p $convert_path

cat $CONTENT_FILE | while read line
do
	echo "current file name is :"$line
	filename=`echo $line |awk -F "/" '{print $NF}'`
	path=`dirname $line`
	folder_name=`echo $path |awk -F "/" '{print $NF}'`
	file_name=`echo ${filename%.*}`
	file_fmt=`echo ${filename##*.}`
	echo "file fmt :"$file_fmt
	echo "total cnt is: " $itotalCnt "current proessed cnt is: "$icnt
	echo "current process file is : "$filename
	echo "Absolute Path is : "$path
	echo "Folder name is : "$folder_name
	echo "file_name is : "$file_name
	
	icnt=$[$icnt+1]
	result=$(ls "$convert_path" | grep "${file_name}")
	echo "cmp is $result "	
	
	if [ -d "$convert_path/${file_name}" ]; then
    	    echo "Dont't need convert video!"
	continue
	else
	    echo "Convert video"
	fi

	cd ${path}
	if [ `$ffprobe_tool -show_streams ${filename} | grep -E "codec_name=h264|codec_name=hevc"` ]; then
    	echo "Don't need convert video!"
	video_copy=true
	else
	echo "convert video to h264"
	video_copy=false
	fi
	echo $video_copy
	
	file_mediainfo=$path/${filename}.mediainfo
	file_audioinfo=$path/${filename}.audioinfo
	file_videoinfo=$path/${filename}.videoinfo
	file_streaminfo=$path/${filename}.streaminfo
	file_ffmpeg_convert_info=$path/${filename}.convertinfo
	file_ffmpeg_remove_info=$path/${filename}.removeinfo
	file_ffmpeg_remove_cmd=$path/${filename}.removecmdinfo
	file_mediaAVinfo=$path/${filename}.AVinfo
	file_convert_cmd=$path/${filename}.ffmpegcmdinfo
        file_ffmpeg_convert2_info=$path/${filename}.bitrate.convertinfo
	
	rm special123456.mkv	
	rm $file_ffmpeg_remove_cmd $file_streaminfo $file_ffmpeg_remove_info $file_ffmpeg_convert2_info \
	    $file_mediainfo  $file_audioinfo  $file_videoinfo  $file_ffmpeg_convert_info \
	    $file_mediaAVinfo $file_convert_cmd

	$ffmpeg_tool -i ${filename} 2>$file_mediainfo
	video_index=0
	index_video_steam=0
	index_steam=0
	index_steam_type=0
	steam_str=''
	cat $file_mediainfo|grep "Stream #" >$file_streaminfo
	result=$(cat $file_streaminfo | grep -E "Video: png")
	if [[ "$result" != "" ]]; then
    	echo "need remove stream Video: png!"
		video_remove=true
	else
		echo "Do't need remove stream Video: png!"
		video_remove=false
	fi
	
	if [ "$video_remove" == "true" ];then	
		while read line
		do
			echo "current steam is:"$line
			steam_type[$index_steam]=`echo $line|awk '{print $4}'|sed 's/,//g'`
			let index_steam=$[$index_steam+1]
		done < $file_streaminfo
		for var in ${steam_type[@]} 
		do 
			echo "video type is :"$var
			if [ "$var" == "png" ]; then
				echo "ignore video png"
			else
				steam_str="  -map 0:$index_steam_type "$steam_str
				echo "steam_str is :"$steam_str
			fi
			let index_steam_type=$[$index_steam_type+1]		  
		done
		echo "$ffmpeg_tool -y -i ${filename}  $steam_str -c copy 12345abcd.$file_fmt < /dev/null 1>$file_ffmpeg_remove_info 2>$file_ffmpeg_remove_info" >$file_ffmpeg_remove_cmd
		$ffmpeg_tool -y -i ${filename}  $steam_str -c copy 12345abcd.$file_fmt < /dev/null 1>$file_ffmpeg_remove_info 2>$file_ffmpeg_remove_info
		mv ${filename} ${filename}.before
		mv "12345abcd.$file_fmt" ${filename}
		$ffmpeg_tool -i ${filename} 2>$file_mediainfo
		unset steam_type
	fi	

	cat $file_mediainfo|grep "Stream #"|grep Video >$file_videoinfo
	while read line
	do
		echo "current Video is:"$line
		video_type[$video_index]=`echo $line|awk '{print $4}'|sed 's/,//g'`
		let video_index=$[$video_index+1]
	done < $file_videoinfo
	video_str=" -pix_fmt yuv420p "
	for var in ${video_type[@]} 
	do 
		echo "video type is :"$var
		if [ "$var" == "hevc" ]|| [ "$var" == "h264" ]; then
			result=$(cat $file_streaminfo | grep -E "yuv420p10le")
			if [[ "$result" != "" ]]; then
				echo "need change yuv420p10le to yuv420p,default is h264!"
				video_str="  -c:v:"$index_video_steam"  libx264  "$video_str

			else
				echo "do not need change fmt !"
			fi
		else
			video_str="  -c:v:"$index_video_steam"  libx264  "$video_str
			echo "video_str is :"$video_str
		fi
		let index_video_steam=$[$index_video_steam+1]
	  
	done
	unset video_type

	audio_index=0
	index_audio_steam=0
	cat $file_mediainfo|grep "Stream #"|grep Audio >$file_audioinfo
	while read line
	do
		echo "current audio is:"$line
		audio_type[$audio_index]=`echo $line|awk '{print $4}'|sed 's/,//g'`
		let audio_index=$[$audio_index+1]
	done < $file_audioinfo
	audio_str=""
	audio_first_tpye=""
	for var in ${audio_type[@]} 
	do 
		echo "audio type is :"$var
		audio_first_tpye=$var
		if [ "$var" == "ac3" ]|| [ "$var" == "dts" ] || [ "$var" == "aac" ]; then
			echo "ignore ac3、dts、acc"
		else
			audio_str="  -c:a:"$index_audio_steam"  ac3  "$audio_str
			echo "audio_str is :"$audio_str
		fi
		
		let index_audio_steam=$[$index_audio_steam+1]
	  
	done

	echo "audio tpye lenght is:"${#audio_type[@]}
	if [ 1 -eq ${#audio_type[@]} ];then
		echo "only one audio steam"
		copy_audio_steam=true
	else
		copy_audio_steam=false
	fi
	
	if [ "$copy_audio_steam" == "true" ];then
		index_first_audio_index=0
		cat $file_mediainfo|grep "Stream #0:" >$file_mediaAVinfo
		while read line
		do
			echo "current audio is:"$line
			if [ "Audio" == `echo $line|awk '{print $3}'|sed 's/://g'` ]; then
				if [ $audio_first_tpye == "ac3" ]; then
					another_audio_steam_type="aac"
				elif [ $audio_first_tpye == "aac" ]; then
					another_audio_steam_type="ac3"
				else
					another_audio_steam_type="aac"
				fi
				break				
			else
				let index_first_audio_index=$[$index_first_audio_index+1]
			fi
		done < $file_mediaAVinfo

		echo "index_first_audio_index:"$index_first_audio_index	
		echo "$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i $filename -i $filename   -c copy   -map 0 \
				$video_str   -map 1:$index_first_audio_index  -c:a:1 $another_audio_steam_type -shortest -strict -2  \
				$audio_str   special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info" >$file_convert_cmd
		if [ "$file_fmt" == "mov" ];then
			echo "$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -enable_drefs 1 -use_absolute_path 1 -i ${filename} -i ${filename}  \
				-c copy   -map 0:v -map 0:a -write_tmcd 1 $video_str   -map 1:$index_first_audio_index  -c:a:1 $another_audio_steam_type -shortest -strict -2 \
				$audio_str   special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info" >$file_convert_cmd
			$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -enable_drefs 1 -use_absolute_path 1 -i ${filename} -i ${filename}   \
				-c copy   -map 0:v -map 0:a -write_tmcd 1 $video_str   -map 1:$index_first_audio_index  -c:a:1 $another_audio_steam_type -shortest -strict -2 \
			$audio_str   special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info
		else
			$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i ${filename} -i ${filename}   -c copy   -map 0 $video_str \
				-map 1:$index_first_audio_index  -c:a:1 $another_audio_steam_type -shortest -strict -2 \
				$audio_str   special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info
		fi
		else
			echo "$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i $filename   -c copy  -map 0 \
				$video_str  $audio_str  special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info" >$file_convert_cmd
		if [ "$file_fmt" == "mov" ];then
			echo "$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i $filename -enable_drefs 1 -use_absolute_path 1   -c copy  -map 0:v -map 0:a -write_tmcd 1 \
				$video_str  $audio_str  special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info" >$file_convert_cmd
            $ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i ${filename} -enable_drefs 1 -use_absolute_path 1   -c copy  -map 0:v -map 0:a -write_tmcd 1 \
				$video_str  $audio_str  special123456.mkc  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info
		else
			$ffmpeg_tool  -fflags +genpts -y  -threads $cpu_num -i ${filename}   -c copy  -map 0 \
				$video_str  $audio_str  special123456.mkv  < /dev/null 1>$file_ffmpeg_convert_info 2>$file_ffmpeg_convert_info
		fi
	fi

	unset audio_type

	$ffmpeg_tool -y -threads $cpu_num -i  special123456.mkv -max_muxing_queue_size 1024 -map 0 -c:a copy -c:s copy  \
		-b:v 5M -maxrate 10M ${file_name}_abcdef.mkv < /dev/null 1>$file_ffmpeg_convert2_info 2>$file_ffmpeg_convert2_info
	rm special123456.mkv
	
	mkdir -p $convert_path/${file_name}
	mv $file_ffmpeg_remove_cmd $file_streaminfo $file_ffmpeg_remove_info $file_ffmpeg_convert2_info \
	    $file_mediainfo  $file_audioinfo  $file_videoinfo  $file_ffmpeg_convert_info \
	    $file_mediaAVinfo $file_convert_cmd -t $convert_path/${file_name}

	mv ${file_name}_abcdef.mkv $convert_path/${file_name}/${file_name}.mkv
	cp *.qn* $convert_path/${file_name}
	cp *.srt $convert_path/${file_name}
	cp *.ass $convert_path/${file_name}
	cd ${local_path}
	let index=icnt%4
	let indexcolor=i%8
	let color=30+indexcolor
	let index_last=i
	let i=icnt*100/itotalCnt
	for ((j=0;$j<=(i-index_last);j++))
	do
		str=#$str
	done
	printf "\e[0;$color;1m[%-100s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
done
printf "\n"
