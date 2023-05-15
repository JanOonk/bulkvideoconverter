#!/bin/bash

parse_args() {
	local -n _settingsFile=$1
	local -n _searchDirectories=$2
	local -n _fileFilters=$3
	local -n _logFile=$4
	local -n _encoder=$5
	local -n _excludedDirectories=$6
	local -n _qualityLevel=$7
	
	# Set default values
	_searchDirectories=()
	_fileFilters=()

	local args=("${@:8}")
	# echo "${args[@]}"
	# Parse last function parameter which are the command line arguments
	local i=0
	while [ $i -lt ${#args[@]} ]
	do
		key=${args[$i]}
		# echo $key
		case $key in
			-sf)
				i=$((i+1))
				_settingsFile="${args[$i]}"
				;;	
			-sd)
				i=$((i+1))
				_searchDirectories+=("${args[$i]}")
				;;
			-ff)
				i=$((i+1))
				_fileFilters+=("${args[$i]}")
				;;
			-lf)
				i=$((i+1))
				_logFile="${args[$i]}"
				;;		
			-e)
				i=$((i+1))
				_encoder="${args[$i]}"
				;;				
			-ed)
				i=$((i+1))
				_excludedDirectories="${args[$i]}"
				;;				
			-q)
				i=$((i+1))
				_qualityLevel=${args[$i]}
				;;				
			-h)
				show_syntax
				exit 1
				;;			
			*)
				echo "Invalid option: $key"
				show_syntax
				exit 1
				;;
		esac
		i=$((i+1))
	done
}

# use echo since logFile in log_message is not available (plus we do not want to log this)
function show_syntax(){
	echo ""
	echo "Convert videos v1.0 - 15 May 2023"
	echo "Syntax is:"
	echo " convertVideos.sh [option(s)]"
	echo "  where option is:"
	echo "   -h"
	echo "     this help"
	echo "   -sf [settingsFile]"
	echo "     settings file where to load all settings from"
	echo "   -sd [searchDirectory]"
	echo "     1 or more directories from where to start (recursively) to find files"
	echo "   -ff [filefilter]"
	echo "     1 or more file filters"
	echo "   -lf [logFile]"
	echo "     log file where to write all output to"
	echo "   -e [encoder]"
	echo "     any supported ffmpeg encoder, for example (and tested):"
	echo "       libx264"
	echo "       h264_vaapi (hardware accelerated)"
	echo "       h264_qsv (hardware accelerated)"
	echo "       libx265"
	echo "       hevc_vaapi (hardware accelerated)"
	echo "       hevc_qsv (hardware accelerated)"
	echo "   -ed [excludedDirectory]"
	echo "     1 or more directories to exclude when searching for files"
	echo "   -q [quality]"
	echo "     quality of encoding (value between 1-51). Lower value is better quality/lower compression, higher value is lower quality/higher compression"
	echo 
	echo "Supported ffmpeg encoders can be checked with:"
	echo "  ffmpeg -encoders"
	echo 
	echo " Examples how to run this script:"
	echo "  convertVideos.sh"
	echo "    All settings are used from \"settings.sh\""
	echo "  convertVideos.sh -q 30"
	echo "    All settings are used from \"settings.sh\" and quality value of encoding is 30"
	echo "  convertVideos.sh -sd \"/videos/\" -ff \"*.ts\""
	echo "    All settings are used from \"settings.sh\" but searchDirectory is \"/videos/\" and file filter is \"*.ts\""
	echo "  convertVideos.sh -sd \"/videos/\" -sf \"/videos2/\" -ff \"*.ts\" -ff \"*.mpeg2\""
	echo "    All settings are used from \"settings.sh\" but searchDirectories are \"/videos/\" and \"/videos2/\" and file filters are \"*.ts\" and \"*.mpeg2\""
	echo "  convertVideos.sh -sd \"/videos/\" -ff \"*.ts\" libx264"
	echo "    All settings are used from \"settings.sh\" but searchDirectory is \"/videos/\""
	echo "    File filter is \"*.ts\" with libx264 (software) encoder"
	echo "  convertVideos.sh -sf \"settings-dev.sh\" -sd \"/videos/\" -ff \"*.ts\" hevc_vaapi"
	echo "    All settings are now used from \"settings-dev.sh\" but searchDirectory is \"/videos/\""
	echo "    File filter is \"*.ts\" with h.265/hevc codec using VAAPI hardware acceleration"
	echo "  convertVideos.sh -sf \"settings-dev.sh\" -sd \"/videos/\" -ff \"*.ts\" libx264 -lf \"logfile.txt\""
	echo "    All settings are now used from \"settings-dev.sh\" but searchDirectory is \"/videos/\""
	echo "    File filter is \"*.ts\" with libx264 (software) encoder"
	echo "    Everything is logged to \"logfile.txt\""
	echo "  convertVideos.sh -sf \"settings-dev.sh\" -sd \"/videos/\" -ff \"*.ts\" libx264 -lf \"logfile.txt\" -ed \"/videos/example1/\" -ed \"/videos/example2/\""
	echo "    All settings are now used from \"settings-dev.sh\" but searchDirectory is \"/videos/\""
	echo "    File filter is \"*.ts\" with libx264 (software) encoder"
	echo "    Everything is logged to \"logfile.txt\"."
	echo "    When searching two directories are excluded: \"/videos/example1/\" and \"/videos/example2/\""
	echo ""
}
