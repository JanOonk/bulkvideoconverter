#!/bin/bash

# Requirements/dependencies:
#  apt-get update
#  apt-get install bc
#
#  Also `stat` (standard for most Linux distro's) are used.
#
# Limitations
# -It sometimes happens that an .mp4 conversion doesn't succeed (although .ts recording might seem visually ok). 
#  Mostly because the .ts recording is (partially) corrupt which can cause the retrieved duration/length to be bogus,
#   this happens to all: MediaInfo, ffprobe, Windows, VLC
#  By implementing maxDurationDifferenceAsPercentage and maxRetries this is worked around and preventing endless retries.
#  Also by using ffmpeg instead of ffprobe gives a more reliable and robust way to retrieve the duration/length of the video files
#
# Todo:
# X trap ctrl-c (quit, terminate, kill) signals -> works if script is run directly but does not when called from other script (with piping?)
# X multipleInstancesAllowed only works on same device. Solution is to use lockfile (per host if you want to store PID's). -> 
#   But what if you do CTRL-C and lockfile is not removed?!
# X save runs stats in file and load that on start of script -> running multiple instances will give problems updating these stats

defaultSettingsFile="settings.sh"

source common-functions.sh

includeSourceFile "bootstrap-functions.sh"

#explicitly declare vars used in parsing commandline arguments
settingsFile=""
searchDirectories=()
fileFilters=()
logFile=""
encoder=""
excludedDirectories=()
quality=-1

# parse commandline arguments (last parameter) and save them in specified variable parameters
parse_args settingsFile searchDirectories fileFilters logFile encoder excludedDirectories quality "$@"
# echo "settingsFile=$settingsFile"
# echo "searchDirectories=${searchDirectories[@]}"
# echo "fileFilters=${fileFilters[@]}"
# echo "logFile=$logFile"
# echo "encoder=$encoder"
# echo "excludedDirectories=${excludedDirectories[@]}"
# echo "quality=$quality"

usingDefaultSettingsFile=$([ "$settingsFile" = "" ] && echo true || echo false)

settingsFile=$(get_non_empty_string "$settingsFile" "$defaultSettingsFile")

if [ ! -f "$settingsFile" ]; then
  echo "settingsFile file \"$settingsFile\" does NOT exist!"
  exit 1
fi

includeSourceFile "$settingsFile"

if [ ! -f "$ffmpeg" ]; then
    echo "ffmpeg was not found at \"$ffmpeg\""
    echo "check your ffmpeg settings in \"$settingsFile\""
    exit 1
fi

logFile=$(get_non_empty_string "$logFile" "$defaultLogFile")

quality=$(get_positive_value $quality $defaultQuality)
qualityLevel_software=$quality
qualityLevel_vaapi=$quality
qualityLevel_qsv=$quality

includeSourceFile "app-functions.sh"

if [ "$multipleInstancesAllowed" = false ] && check_if_running; then
	echo "$0 : Process is already running with PID $$"
	echo ""
	exit 1
fi

get_non_empty_array "searchDirectories" "defaultSearchDirectories" "searchDirectories"
get_non_empty_array "fileFilters" "defaultFileFilters" "fileFilters"
encoder=$(get_non_empty_string "$encoder" "$defaultEncoder")
get_non_empty_array "excludedDirectories" "defaultExcludedDirectories" "excludedDirectories"

# echo "settingsFile=$settingsFile"
# echo "searchDirectories=${searchDirectories[@]}"
# echo "fileFilters=${fileFilters[@]}"
# echo "fileFilters=${#fileFilters[@]}x"
# echo "logFile=$logFile"
# echo "encoder=$encoder"
# echo "excludedDirectories=${excludedDirectories[@]}"
# echo "quality=$quality"

if [ "${#searchDirectories[@]}" -eq 0 ] || [ "${#fileFilters[@]}" -eq 0 ] || [ "$encoder" = "" ]; then
	show_syntax
	exit 1
fi

log_message ""
log_message "---------------------------------------------------------------------------------------------------------"
log_message "Run starts"
log_message "Scriptname: $0"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_message "Located in: \"$script_dir\""
log_message "PID: $$"
log_message "Running on host: $(hostname)"
if [ $# -eq 0 ]; then
	log_message "No commandline arguments specified, using defaults from \"$settingsFile\""
else
	args="$@"
	log_message "Commandline arguments specified: \"$args\""
fi

if $usingDefaultSettingsFile; then
	log_message "No settingsFile file specified, using default settingsFile \"$defaultSettingsFile\""
else
	log_message "SettingsFile file specified, using settingsFile \"$settingsFile\""
fi

#map encoder to hardware
IFS="_" read -ra parts <<< "$encoder"
codec=${parts[0]}
hardware=""
if [ "${#parts[@]}" -eq 2 ]; then
	hardware="${parts[1]}"
	log_message "Encoder $encoder was specified (codec: $codec and hardware acceleration: $hardware)"
else  
	log_message "Encoder $encoder was specified (codec: $codec and hardware acceleration: none)"
fi

totalConversionTimeRuns=0
totalSucceedsRuns=0
totalRuns=0
totalTriedConvertingFilesRuns=0
totalDurationOfSuccessfullConvertedInputFilesRuns=0

inputFilesWithMaxRetries=()
load_from_file $filenameInputFilesWithMaxRetries inputFilesWithMaxRetries

exit_code=0

while [ true ]
do
	startOfRun=$(date +%s)

	readarray -t inputFiles < <(searchFiles searchDirectories[@] fileFilters[@] excludedDirectories[@])
	inputFilesLeft=${#inputFiles[@]}
	totalFilesRun=$inputFilesLeft
	echo ""
	log_message "${#searchDirectories[@]} search folder(s) will be searched"
	print_array_on_new_lines searchDirectories " "
	log_message "${#excludedDirectories[@]} folder(s) will be excluded from searching:"
	print_array_on_new_lines excludedDirectories " "
	logMessage="$totalFilesRun inputfile(s) matching ${fileFilters[@]} were found:"
	log_message "$logMessage"
	print_array_on_new_lines inputFiles " " true

	fileNr=0
	totalSucceedsRun=0
	totalAlreadyConvertedRun=0
	totalFailsRun=0
	totalFilesTooYoungRun=0
	totalDurationOfSuccessfullConvertedInputFilesRun=0
	totalConversionTimeRun=0
	
	inputFilesConvertedRun=()
	outputFilesConvertedRun=()
	filesFailedRun=()
	
	nrOfNewInputFilesWithMaxRetries=0
	nrOfInputFilesWithAlreadyMaxRetries=0
	nrOfRetriedFilesWithPreviouslyMaxRetries=0
	
	nrOfInputFilesWithMaxRetries=${#inputFilesWithMaxRetries[@]}
	# echo "nrOfInputFilesWithMaxRetries=$nrOfInputFilesWithMaxRetries"
	# echo "inputFilesWithMaxRetries="
	# print_array_on_new_lines inputFilesWithMaxRetries " "
	
	if [ $nrOfInputFilesWithMaxRetries -ge 1 ]; then
		non_existing_files=()	
		remove_non_existing_files inputFilesWithMaxRetries non_existing_files
		save_to_file inputFilesWithMaxRetries $filenameInputFilesWithMaxRetries

		log_message "$nrOfInputFilesWithMaxRetries inputfile(s) from previous run(s) had max retries:"
		log_message " ${#inputFilesWithMaxRetries[@]} existing file(s):"
		indent="  "
		print_array_on_new_lines inputFilesWithMaxRetries "$indent"
		log_message " ${#non_existing_files[@]} removed file(s):"
		print_array_on_new_lines non_existing_files "$indent"
	fi
	
	maxRunTimeReached=false
	for inputFile in "${inputFiles[@]}"; 
	do
		log_message "---------------"
		
		fileNr=$((fileNr+1))
		log_message "Next inputfile #$fileNr"
		log_message " Inputfile \"$inputFile\""

        #current folder
        # currentFolder="${inputFile%/*}"
        #remove extension and add .mp4
        outputFile="${inputFile%.*}.mp4"
        
		doConversion=true;
        
        #first check for file to be converted if it has not reached max retries else skip conversion
        found_index=$(search_string inputFilesWithMaxRetries "$inputFile")
        #strip extension from $outputFile
        maxOutputFile="${outputFile%.*}$versionSuffix$maxRetries.mp4"
        if [ -f "$maxOutputFile" ]; then
            doConversion=false
            log_message " Max. retries reached because \"$maxOutputFile\" exist... skipping file!"
            if [ $found_index -eq -1 ]; then
                log_message " Adding it to $filenameInputFilesWithMaxRetries"
                inputFilesWithMaxRetries+=("$inputFile")
                save_to_file inputFilesWithMaxRetries $filenameInputFilesWithMaxRetries
                nrOfNewInputFilesWithMaxRetries=$((nrOfNewInputFilesWithMaxRetries+1))
            else
                nrOfInputFilesWithAlreadyMaxRetries=$((nrOfInputFilesWithAlreadyMaxRetries+1))
            fi
        else
            if (( found_index >= 0 )); then
                log_message " Inputfile had previously reached $maxRetries max retries!"
                log_message " Removing it from \"$filenameInputFilesWithMaxRetries\""
                remove_string_at inputFilesWithMaxRetries $found_index
                save_to_file inputFilesWithMaxRetries $filenameInputFilesWithMaxRetries
                nrOfRetriedFilesWithPreviouslyMaxRetries=$((nrOfRetriedFilesWithPreviouslyMaxRetries + 1))
            fi
        fi

        if [ "$doConversion" = true ]; then
            log_message " Inputfile:"
            #only consider .ts files of which recording has finished (for example by HDHomeRun) (that means are old enough)
            inputfileAgeInSeconds=$(($(date +%s) - $(date +%s -r "$inputFile")))
            timeString=$(convertSecondsToTimeString "$inputfileAgeInSeconds")
            log_message "  File age is $inputfileAgeInSeconds seconds ($timeString)"

            if [ $inputfileAgeInSeconds -ge $minFileAgeInSeconds ]; then
                log_inlinemessage "  Duration is (this can take a while): "
                durationInputFile=$(determineDurationVideoInSeconds "$inputFile" "$ffmpeg")
                timeString=$(convertSecondsToTimeString "$durationInputFile")
                log_message_without_timestamp "$durationInputFile seconds ($timeString)"

                filesizeInput=$(get_filesize_in_bytes "$inputFile")
                formattedFilesize=$(format_filesize $filesizeInput)
                log_message "  Size is $formattedFilesize"

                log_message " Outputfile is \"$outputFile\""

                if [ -f "$outputFile" ]; then
                    filesizeOutput=$(get_filesize_in_bytes "$outputFile")
                    formattedFilesize=$(format_filesize $filesizeOutput)
                    log_message "  Size is $formattedFilesize"

                    #skip .mp4 files which are not old enough, in case a process is converting/writing to them
                    outputfileAgeInSeconds=$(($(date +%s) - $(date +%s -r "$outputFile")))
                    timeString=$(convertSecondsToTimeString "$outputfileAgeInSeconds")
                    log_message "  File age is $outputfileAgeInSeconds seconds ($timeString)"

                    if [ $outputfileAgeInSeconds -ge $minFileAgeInSeconds ]; then
                        percentage=$(bc <<<"scale=4; $filesizeOutput / $filesizeInput * 100")
                        log_message "  Percentage compression compared to inputfile is $percentage%"
                        
                        log_inlinemessage "  Duration is (this can take a while): "
                        durationOutputFile=$(determineDurationVideoInSeconds "$outputFile" "$ffmpeg")
                        timeString=$(convertSecondsToTimeString "$durationOutputFile")
                        log_message_without_timestamp "$durationOutputFile seconds ($timeString)"
                        difference=$(abs_diff $durationInputFile $durationOutputFile)
                        timeString=$(convertSecondsToTimeString "$difference")
                        log_message "  Difference is $difference seconds ($timeString)"
        
                        differenceAsPercentage=$(bc <<<"scale=4; $difference / $durationInputFile * 100")
                        log_message "  DifferenceAsPercentage is $differenceAsPercentage%"
                        
                        if [ $(bc <<<"$differenceAsPercentage < $maxDurationDifferenceAsPercentage") -eq 1 ]; then
                            doConversion=false;
                            totalAlreadyConvertedRun=$((totalAlreadyConvertedRun + 1))
                            log_message " A previous successfull conversion was found which matched qua duration with \"$inputFile\""
                            
                            if [ "$deleteOriginalFiles" = true ]; then
                                delete_inputFile_and_outputFileVersions
                            else
                                log_message "Skipped deletion of \"$inputFile\""
                            fi
                        else
                            log_message " Previous conversion didn't match qua duration (maybe didn't finish, corrupt, failed or file had different contents and length but with same filename)!"
                            if [ "$redoConversionWhenInputAndOutputDontMatch" = true ]; then
                                if [ "$keepPreviousConversion" = true ]; then
                                    version=1
                                    preservedOutputFile="${outputFile%.*}$versionSuffix$version.mp4"
                                    
                                    while [ -f "$preservedOutputFile" ]
                                    do
                                        version=$((version+1))
                                        preservedOutputFile="${outputFile%.*}$versionSuffix$version.mp4"
                                    done
                                    
                                    log_message " Keeping previous conversion and renaming to \"$preservedOutputFile\"!"
                                    
                                    #rename file
                                    mv "$outputFile" "$preservedOutputFile"
                                fi
                            else
                                doConversion=false;
                                log_message " NOT redoing transcoding of \"$inputFile\"!"
                            fi
                        fi
                    else
                        doConversion=false;
                        log_message " File is skipped because modified date is too young (probably in use, converting?)!"
                    fi
                else
                    log_message " Outputfile does not exist"
                fi
                
                if [ "$doConversion" = true ]; then 
                    filesizeOutput=0
                    log_message " Re-encoding file \"$inputFile\"!"
                    #codec: H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
                    #	encoder: libx264 	(~ 7x times smaller and speed=2.4x)
                    #	encoder: h264_vaapi (~ 7x times smaller and speed=2.4x)
                    #codec: H.265 / HEVC
                    #	encoder: libx265 	(~12x times smaller and speed=0.7x)
                    #	encoder: hevc_vaapi (~12x times smaller and speed=3.8x)
                    #	encoder: hevc_qsv   (~12x times smaller and speed=3.8x)
                    
                    #used commandline options ffmpeg explained:
                    # -loglevel                     = show/log only errors
                    # -i                            = use inputFile as input
                    # -y                            = overwrite previous file
                    # -c:v                          = re-encode video with encoder
                    # =pix_fmt                      = use yuv420p as pixelformat
                    # -c:a copy                     = copy original audio
                    # -acodec mp3                   = convert audio to mp3
                    # -analyzeduration 10000000     = better stream detection for slightly corrupt files (put before -i !) 
                    # -probesize 10000000           = better stream detection for slightly corrupt files (put before -i !)
                    #$($ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -i "$inputFile" -y -c:v $encoder -acodec mp3 "$outputFile" -loglevel error)
                    
                    timeBeforeConversion=$(date +%s)
                    if [ "$hardware" = "vaapi" ]; then
                        # $ffmpeg -analyzeduration 10000000 -probesize 10000000 -i "$inputFile" -y -vf 'format=nv12,hwupload' -c:v $encoder -qp $qualityLevel_vaapi -acodec mp3 "$outputFile" -loglevel $loglevel -v $loglevel -stats -init_hw_device vaapi=va:/dev/dri/renderD128
                        
                        # Construct the ffmpeg command
                        ffmpegCommand="$ffmpeg -analyzeduration 10000000 -probesize 10000000 -i \"$inputFile\" -y -vf 'format=nv12,hwupload' -c:v $encoder -qp $qualityLevel_vaapi -acodec mp3 \"$outputFile\" -loglevel $loglevel -v $loglevel -stats -init_hw_device vaapi=va:/dev/dri/renderD128"

                        # Print the command to be executed
                        echo "Executing command: $ffmpegCommand"

                        # Execute the command
                        eval "$ffmpegCommand"                        
                    else
                        #else simple cmdline when non-vaapi
                        # $ffmpeg -analyzeduration 10000000 -probesize 10000000 -i "$inputFile" -y -c:v $encoder -crf $qualityLevel_software -global_quality $qualityLevel_qsv -acodec mp3 "$outputFile" -loglevel $loglevel -v $loglevel -stats

                        # Construct the ffmpeg command
                        ffmpegCommand="$ffmpeg -analyzeduration 10000000 -probesize 10000000 -i \"$inputFile\" -y -c:v $encoder -crf $qualityLevel_software -global_quality $qualityLevel_qsv -acodec mp3 \"$outputFile\" -loglevel $loglevel -v $loglevel -stats"

                        # Print the command to be executed
                        echo "Executing command: $ffmpegCommand"

                        # Execute the command
                        eval "$ffmpegCommand"
                    fi
                    
                    conversionOk=false;
                    if [ -f "$outputFile" ]; then
                        timeAfterConversion=$(date +%s)
                        conversionTime=$((timeAfterConversion - timeBeforeConversion))

                        filesizeOutput=$(stat -c%s "$outputFile")
                        percentage=$(bc <<<"scale=4; $filesizeOutput / $filesizeInput * 100")
                        log_message "  Percentage compression after conversion: $percentage%"
                        
                        speedFactor=$(bc <<<"scale=4; $durationInputFile / $conversionTime")
                        formattedSpeedFactor=$(printf "%.2fx" $speedFactor)
                        timeString=$(convertSecondsToTimeString "$conversionTime")
                        log_message "  Time it took to convert $durationInputFile seconds of videofile: $conversionTime seconds ($timeString) ($formattedSpeedFactor)"

                        log_inlinemessage "  Duration is (this can take a while): "
                        durationOutputFile=$(determineDurationVideoInSeconds "$outputFile" "$ffmpeg")
                        timeString=$(convertSecondsToTimeString "$durationOutputFile")
                        log_message_without_timestamp "$durationOutputFile seconds ($timeString)"
                        difference=$(abs_diff $durationInputFile $durationOutputFile)
                        timeString=$(convertSecondsToTimeString "$difference")
                        log_message "  Difference is $difference seconds ($timeString)"
        
                        durationDifferenceAsPercentage=$(bc <<<"scale=4; $difference / $durationInputFile * 100")
                        log_message "  DifferenceAsPercentage is $durationDifferenceAsPercentage%"
                        
                        if [ $(bc <<<"$durationDifferenceAsPercentage < $maxDurationDifferenceAsPercentage") -eq 1 ]; then
                            conversionOk=true;
                            log_message " Conversion succesfull, inputFile can be deleted"

                            totalConversionTimeRun=$((totalConversionTimeRun + conversionTime))

                            #delete from inputFilesWithMaxRetries in case it previously had max retries
                            remove_string inputFilesWithMaxRetries $inputFile
                            inputFilesConvertedRun+=("$inputFile")
                            outputFilesConvertedRun+=("$outputFile")
                            
                            totalSucceedsRun=$((totalSucceedsRun + 1))
                            totalDurationOfSuccessfullConvertedInputFilesRun=$(bc <<<"scale=4; $totalDurationOfSuccessfullConvertedInputFilesRun + $durationInputFile")

                            if [ "$deleteOriginalFiles" = true ]; then
                                delete_inputFile_and_outputFileVersions
                            else
                                log_message " Skipped deletion of \"$inputFile\" and (if any) previous converted version(s)"
                            fi
                            
                            if [ "$removeVideoXMLFile" = true ]; then
                                xmlFile="${inputFile%.*}.xml"
                                if [ -e "$xmlFile" ]
                                then
                                    rm "$xmlFile"
                                    log_message "Deleted \"$xmlFile\""
                                fi
                            fi
                        else
                            log_message " Conversion failed because the durationDifferenceAsPercentage >= $maxDurationDifferenceAsPercentage%"
                        fi
                    else 
                        log_message " Conversion failed, outputfile \"$outputFile\" was NOT created after conversion!"
                    fi
                    
                    if [ "$conversionOk" = false ]; then 
                        totalFailsRun=$((totalFailsRun + 1))
                        filesFailedRun+=("$inputFile")
                    fi
                fi
            else
                log_message " File is skipped because modified date is too young (probably in use, recording?)!"
                
                totalFilesTooYoungRun=$((totalFilesTooYoungRun + 1))
            fi
		fi
        
		inputFilesLeft=$((inputFilesLeft - 1))
		
		#update runTime
		time=$(date +%s)
		runTime=$((time - startOfRun))
		
		#check if maxRunTime has surpassed
		if [ $maxRunTimePerRunInMinutes -ge 0 ]; then
			if [ $runTime -ge $((maxRunTimePerRunInMinutes*60)) ]; then
				maxRunTimeReached=true
				break
			fi
		fi
	done

	echo ""

	if [ $maxRunTimeReached ] && [ $inputFilesLeft -ge 1 ]; then
		log_message "This run is already taking $(bc <<<"scale=2; $runTime / 60") minutes which exceeds maxRunTimePerRunInMinutes of $maxRunTimePerRunInMinutes minutes"
		log_message "Run will be aborted with $inputFilesLeft files still left to do!"
	else
		log_message "Done, no more files!"
	fi
	
	totalTriedConvertingFilesRun=$((totalSucceedsRun + totalFailsRun))
	if [ $totalFilesRun -ge 1 ]; then
		# totalTriedConvertingFilesRun=$((totalFilesRun - totalFilesTooYoungRun - totalAlreadyConvertedRun - inputFilesLeft))
		
		formattedSpeedFactor="-"
		if [ $runTime -gt 0 ]; then
			speedFactor=$(bc <<<"scale=4; $totalDurationOfSuccessfullConvertedInputFilesRun / $runTime")
			formattedSpeedFactor=$(printf "%.2f" $speedFactor)
		fi
		
		formattedSuccessPercentage="-"
		if [ $totalTriedConvertingFilesRun -gt 0 ]; then
			successPercentage=$(bc <<<"scale=4; $totalSucceedsRun / $totalTriedConvertingFilesRun * 100")
			formattedSuccessPercentage=$(printf "%.0f" $successPercentage)
		fi

		totalFilesSkippedWithMaxRetries=$((nrOfNewInputFilesWithMaxRetries + nrOfInputFilesWithAlreadyMaxRetries))

		log_message "Stats for this run:"
		log_message " Total files $totalFilesRun"
		log_message " $inputFilesLeft files left to do in next run(s) because MaxRunTime was reached"
		log_message " $nrOfRetriedFilesWithPreviouslyMaxRetries files with previous max retries"
		log_message " $totalFilesSkippedWithMaxRetries files skipped because max retries has been reached (new: $nrOfNewInputFilesWithMaxRetries old: $nrOfInputFilesWithAlreadyMaxRetries)"
		log_message " $totalFilesTooYoungRun files skipped because modified date is too young"
		log_message " $totalAlreadyConvertedRun files already successfully converted"
		log_message " $totalFailsRun files were tried to convert but failed"
		log_message " $totalSucceedsRun successfully converted files with total duration of $totalDurationOfSuccessfullConvertedInputFilesRun seconds, took $totalConversionTimeRun seconds ($formattedSpeedFactor x) to convert"
		log_message " $totalSucceedsRun/$totalTriedConvertingFilesRun ($formattedSuccessPercentage %) files successfully converted!"
	fi
	
	totalTriedConvertingFilesRuns=$((totalTriedConvertingFilesRuns + totalTriedConvertingFilesRun))
	totalRuns=$((totalRuns + 1))
	totalSucceedsRuns=$((totalSucceedsRuns + totalSucceedsRun))
	totalDurationOfSuccessfullConvertedInputFilesRuns=$(bc <<<"scale=4; $totalDurationOfSuccessfullConvertedInputFilesRuns + $totalDurationOfSuccessfullConvertedInputFilesRun")
	totalConversionTimeRuns=$((totalConversionTimeRuns + totalConversionTimeRun))

	if [ $totalTriedConvertingFilesRuns -gt 0 ] && [ $totalConversionTimeRuns -gt 0 ]; then
		speedFactor=$(bc <<<"scale=4; $totalDurationOfSuccessfullConvertedInputFilesRuns / $totalConversionTimeRuns")
		formattedSpeedFactor=$(printf "%.2f" $speedFactor)
		successPercentage=$(bc <<<"scale=4; $totalSucceedsRuns / $totalTriedConvertingFilesRuns * 100")
		formattedSuccessPercentage=$(printf "%.0f" $successPercentage)
		totalFilesSkippedWithMaxRetries=${#inputFilesWithMaxRetries[@]}
		#filesSkippedWithMaxRetries=$(for string in "${inputFilesWithMaxRetries[@]}"; do log_message "  $string\n"; done)
		
		log_message "Stats for all $totalRuns runs:"
		if [ $totalFilesSkippedWithMaxRetries -gt 0 ]; then
			log_message "  $totalFilesSkippedWithMaxRetries files currently skipped because max retries has been reached:"
			print_array_on_new_lines inputFilesWithMaxRetries "   "
		fi
		log_message "  $totalSucceedsRuns/$totalTriedConvertingFilesRuns ($formattedSuccessPercentage %) files successfully converted!"
		log_message "  $totalSucceedsRuns successfully converted files with total duration of $totalDurationOfSuccessfullConvertedInputFilesRuns seconds took $totalConversionTimeRuns seconds ($formattedSpeedFactor x) to convert"
	fi
	
	# Convert arrays to comma-separated strings
	inputFilesConvertedRun_string=$(IFS=','; echo "${inputFilesConvertedRun[*]}")
	outputFilesConvertedRun_string=$(IFS=','; echo "${outputFilesConvertedRun[*]}")
	filesFailedRun_string=$(IFS=','; echo "${filesFailedRun[*]}")
	inputFilesWithMaxRetries_string=$(IFS=','; echo "${inputFilesWithMaxRetries[*]}")

    if [ -f "$postRunScript" ]; then
        # Call the script in a subshell and pass the array strings as arguments
        ( "$postRunScript" "$inputFilesConvertedRun_string" "$outputFilesConvertedRun_string" "$filesFailedRun_string" "$inputFilesWithMaxRetries_string" )

        # Capture the exit code of the called script
        exit_code=$?

        # Check the exit code
        if [[ $exit_code -eq 0 ]]; then
            log_message "postRun.sh script completed successfully!"
        else
            log_message "postRun.sh script returned a non-zero exit code: $exit_code"
            if [[ $stopWhenPostRunScriptFails == true ]]; then
                break;
            fi
        fi
    else
        log_message "No post run script will be called, since \"$postRunScript\" does not exist!"
    fi
    
	log_message "Waiting for next round!"

	if [ "$runOnce" = false ]; then
		newReRunAt=$rerunAt
		if [ "$rerunAtIsRelative" = true ]; then
			# Convert relative time string to seconds (using space as seperator)
			IFS=' ' read hours minutes <<< "$newReRunAt"
			time_in_seconds=$((hours * 3600 + minutes * 60))

			# Add relative time (in seconds) to current time
			current_time=$(date +%s)
			newReRunAt=$(date -d "@$((current_time + time_in_seconds))" "+%H %M")
		else
			# in the case no files were found this round wait at least one minute to prevent immediately retriggering at same time
			log_message "Waiting an extra minute to prevent immediate retriggering!"
			sleep 61
		fi

		log_message "Rerun will start at $newReRunAt, now waiting..."

		wait_till $newReRunAt
		log_message "Done waiting. Let's find new files that need converting..."
	else
		log_message "Running only once... exiting!"
		break
	fi
done
	
log_message "Ended"
exit $exit_code