#!/bin/bash

function log_message() {
	declare -g logFile
    message="$1"
    filename="${2:-$logFile}"

	completeMessage="[$(date)] : $message"
    echo "$completeMessage"
    echo "$completeMessage" >> "$filename"
}

# use echo since logFile in log_message is not available (plus we do not want to log this)
function show_syntax(){
	echo ""
	echo "Syntax is:"
	echo " convertVideos [rootFolder] [filefilter] [encoder]";
	echo "  [rootFolder] root folder from where to start (recursively) to find files (mandatory), for example:";
	echo "    /videos";
	echo "  [filefilter] file filter (mandatory), for example:";
	echo "    *.ts";
	echo "    movie*.mpeg2";
	echo "  [encoder] any supported ffmpeg codec (optionally), for example:";
	echo "    libx264 (default)";
	echo "    libx265";
	echo "    hevc_vaapi";
	echo "    hevc_qsv";
	echo "";
	echo " Supported ffmpeg encoders/codecs can be checked with:";
	echo "  ffmpeg -codecs";
	echo "";
	echo " Examples how to run this script:"
	echo "  convertVideos.sh /videos *.ts";
	echo "  convertVideos.sh /videos *.ts libx264";
	echo "  convertVideos.sh /videos *.ts libx265";
	echo "  convertVideos.sh /videos *.ts hevc_vaapi";
	echo ""
}

function delete_inputFile_and_outputFileVersions(){
	declare -g inputFile
	declare -g outputFile
	declare -g maxRetries
	declare -g versionSuffix
	
	rm "$inputFile"
	log_message "Deleted inputFile \"$inputFile\""
	
	#remove previous versions if any
	i=1
	while [ $i -le $maxRetries ]
	do
		#strip extension from $outputFile
		filename="${outputFile%.*}$versionSuffix$i.mp4"
		if [ -e "$filename" ]
		then
			rm "$filename"
			log_message "Deleted previous version: $filename"
		fi
		i=$((i+1))
	done
}