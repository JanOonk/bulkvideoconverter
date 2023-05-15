#!/bin/bash

function log_message() {
	declare -g logFile
    message="$1"
    filename="${2:-$logFile}"

	completeMessage="[$(date)] : $message"
    echo "$completeMessage"
    echo "$completeMessage" >> "$filename"
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