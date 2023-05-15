#!/bin/bash

function includeSourceFile(){
	if [ -r $1 ] && [ -x $1 ]; then
		source $1
	else
		echo "\"$1\" cannot be sourced. It is not a readable and executable shellscript!"
		exit 1
	fi
}

function get_non_empty_array {
    # Assign references to the input arrays
    declare -n arr1=$1
    declare -n arr2=$2
    declare -n arr3=$3

    if [ ${#arr1[@]} -eq 0 ] && [ ${#arr2[@]} -eq 0 ]; then
        # If both arrays are empty, make third array empty
        arr3=()
    elif [ ${#arr1[@]} -eq 0 ]; then
        # If first array is empty, copy second array to third array
        arr3=("${arr2[@]}")
    else
        # If second array is empty, copy first array to third array
        arr3=("${arr1[@]}")
    fi
}

function get_non_empty_string() {
	if [ "$1" = "" ] && [ "$2" = "" ]; then
		echo ""
	elif [ "$1" = "" ]; then
		echo "$2"
	else
		echo "$1"
	fi
}

function get_positive_value() {
	if [[ $1 -lt 0 && $2 -lt 0 ]]; then
		if [[ $1 -gt $2 ]]; then
			echo $1
		else
			echo $2
		fi
	elif [ $1 -lt 0 ]; then
		echo $2
	else
		echo $1
	fi
}

searchFiles() {
	local searchFolders=("${!1}")
	local fileFilters=("${!2}")
	local excludedFolders=("${!3}")
	local exclude_count=${#excludedFolders[@]}

	if [ $exclude_count -eq 0 ]; then
        find "${searchFolders[@]}" \( -name "${fileFilters[0]}" $(printf -- '-o -name "%s" ' "${fileFilters[@]:1}") \)
        return $?
    fi

    # Concat excluded servers as grep regex
    local regex="(${excludedFolders[0]}"
	for ((i=1;i<exclude_count;i++)); do
        regex="${regex}|${excludedFolders[i]}"
	done
	#append last )
    regex="${regex})"
	# echo "regex=$regex"
	
	# Search in all folders with all filters
	# echo "find ${searchFolders[@]} \( -name \"${fileFilters[0]}\" $(printf -- '-o -name \"%s\" ' "${fileFilters[@]:1}") \) -print0 | grep -zZEv \"${regex}\" | tr '\0' '\n'"
	find "${searchFolders[@]}" \( -name "${fileFilters[0]}" $(printf -- '-o -name "%s" ' "${fileFilters[@]:1}") \) -print0 | grep -zZEv "${regex}" | tr '\0' '\n'

	return $?
}

# searchFiles() {
	# local ROOT=$1
	# local FILEFILTER=$2
	# local excluded_folders=("${@:3}")
	
    # local exclude_count=${#excluded_folders[@]}
	
	# if [ $exclude_count -eq 0 ]; then
        # find $ROOT -name $FILEFILTER
        # return $?
    # fi

    ## Concat excluded servers as grep regex
    # local regex="(${excluded_folders[1]}"
	# for ((i=2;i<exclude_count;i++)); do
        # regex="${regex}|${excluded_folders[i]}"
	# done
	## append last )
    # regex="${regex})"
	
    # find "$ROOT" -name "$FILEFILTER" -print0 | grep -zZEv "${regex}" | tr '\0' '\n'
	
    # return $?
# }

# Save an array of strings to a file
function save_to_file() {
  local -n arr=$1 # reference to the array
  local filename=$2
  if [ ${#arr[@]} -ge 1 ]; then
	printf "%s\n" "${arr[@]}" > "$filename"
  else
	printf "" "${arr[@]}" > "$filename"
  fi
}

# Load an array of strings from a file
function load_from_file() {
  local filename=$1
  local -n arr=$2 # reference to the array
  if [ -f "$filename" ]; then
    readarray -t arr < "$filename"
  else
    echo "File not found: $filename"
    return 1
  fi
}

function check_if_running(){
	for pid in $(pidof -x $0); do
		if [ $pid != $$ ]; then
			return 0 # process is running
		fi
	done
	return 1 # process is not running
}

function wait_till() {
	target="$1.$2"
	cur=$(date '+%H.%M')
	while test $target != $cur; do
		sleep 59
		cur=$(date '+%H.%M')
	done
}

function abs_diff() {
	if [ $(bc <<<"$1 >= $2") -eq 1 ]; then
		diff="$(echo $1 - $2 | bc)"
	else
		diff="$(echo $2 - $1 | bc)"
	fi
	
	echo $diff
}

function get_filesize_in_bytes() {
  local file=$1
  local size=$(stat -c%s "$file")
  
  echo $size
}

function format_filesize() {
  local size=$1
  local unit="bytes"

  if [ $size -ge 1073741824 ]; then
    size=$(echo "scale=2; $size / 1073741824" | bc)
    unit="GB"
  elif [ $size -ge 1048576 ]; then
    size=$(echo "scale=2; $size / 1048576" | bc)
    unit="MB"
  elif [ $size -ge 1024 ]; then
    size=$(echo "scale=2; $size / 1024" | bc)
    unit="KB"
  fi

  echo "$size $unit"
}

function print_array_on_new_lines {
  local -n arr=$1 # assign the array by reference
  local prefix=$2
  local useLineNumbers=${3:-false} # optional, default false (=do not print line numbers)
  local lineNumberPrefix=""
  
  i=1
  for item in "${arr[@]}"
  do
    if [ $useLineNumbers = true ]; then
	  lineNumberPrefix="[$i] "
    fi
    log_message "$prefix$lineNumberPrefix$item"
	i=$((i+1))
  done
}

function remove_non_existing_files() {
  local -n arr=$1 # assign the first array by reference
  local -n arr2=$2 # assign the second array by reference
  local i
  
  for (( i=0; i<${#arr[@]}; i++ )); do
    if [[ ! -e "${arr[$i]}" ]]; then
      arr2+=("${arr[$i]}") # add non-existing file to the second array
      unset arr[$i] # remove non-existing file from the first array
    fi
  done

  # re-index the first array
  arr=("${arr[@]}")
}

# Define function to remove a string from an array
function remove_string() {
  local -n array=$1     # Pass array by reference
  local delete=$2       # Second parameter is the string to delete
  
  # Iterate over the *indices* of the array
  for i in "${!array[@]}"; do
    # Check if the value at the current index matches the delete string
    if [[ "${array[$i]}" == "$delete" ]]; then
      unset array[$i]   # Remove the element from the array
    fi
  done
}

# Define function to search for a string in an array and return the index
function search_string() {
  local -n array=$1     # Pass array by reference
  local search=$2       # Second parameter is the string to search for
  local found=-1        # Initialize found index to -1
  
  # Iterate over the indices of the array
  for i in "${!array[@]}"; do
    # Check if the value at the current index matches the search string
    if [[ "${array[$i]}" == "$search" ]]; then
      found=$i          # Set found index to the current index
      break             # Exit loop
    fi
  done
  
  # Return the index of the found string
  echo "$found"
}

# Define function to remove a string from an array at a given index
function remove_string_at() {
  local -n array=$1     # Pass array by reference
  local index=$2        # Second parameter is the index to remove
  
  if (( index >= 0 )); then
	  # Remove the element at the given index using array slicing
	  array=("${array[@]:0:$index}" "${array[@]:$((index+1))}")
  fi
}