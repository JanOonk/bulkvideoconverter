#!/bin/bash

parse_args() {
	local -n _settingsFile=$1
	local -n _searchDirectories=$2
	local -n _fileFilters=$3
	local -n _logFile=$4
	local -n _encoder=$5
	local -n _excludeDirectories=$6
	
	# Set default values
	_searchDirectories=()
	_fileFilters=()

	local args=("${@:7}")
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
				_excludeDirectories="${args[$i]}"
				;;			
			*)
				echo "Invalid option: $key"
				exit 1
				;;
		esac
		i=$((i+1))
	done
}
