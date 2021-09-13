#!/bin/bash

#SETTINGS
# minimum fileage in seconds for inputfiles to be considered to get converted and for outputfiles to be checked if reconverting is needed
minFileAgeInSeconds=10

# how much tolereance between inputfile and outputfile to be a match (means conversion is succesfull)
maxLengthDifferenceInSeconds=1
redoConversionWhenInputAndOutputDontMatch=true

# in some rare cases you can have an outputfile which has the same filename (without extension) as an inputfile,
# but doesn't have the same contents which is reflected in a different duration
# with this setting you can preserve these files
# the previous outputfile will have a suffix "-prev-v#" added
keepPreviousConversion=true

# after conversion delete original inputfile
deleteOriginalFiles=true

# is it allowed to have multiple instances running of this script (to be safe set to false)
multipleInstancesAllowed=false

# if false it will keep running and restart scanning automatically next day (script is never exited)
runOnce=false

# if runOnce is false then rerun next day at this time HH MM
rerunAt="03 00"

function wait_till {
	target="$1.$2"
	cur=$(date '+%H.%M')
	while test $target != $cur; do
		sleep 59
		cur=$(date '+%H.%M')
	done
}

function abs_diff {
	if [ $(bc <<<"$1 >= $2") -eq 1 ]; then
		diff="$(echo $1 - $2 | bc)"
	else
		diff="$(echo $2 - $1 | bc)"
	fi
	
	echo $diff
}

echo ""
echo "[$(date)] : Run starts"
echo "[$(date)] : scriptname: $0"
echo "[$(date)] : arguments : $1 $2 $3"

if [ "$multipleInstancesAllowed" = false ] ; then
	for pid in $(pidof -x $0); do
		if [ $pid != $$ ]; then
			echo "[$(date)] : $0 : Process is already running with PID $pid"
			echo ""
			exit 1
		fi
	done
fi

if [ "$1" = "" ] || [ "$2" = "" ]; then

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
	echo "";
	echo " Supported ffmpeg encoders/codecs can be checked with:";
	echo "  ffmpeg -codecs";
	echo "";
	echo " Examples how to run this script:"
	echo "  convertVideos.sh /videos *.ts";
	echo "  convertVideos.sh /videos *.ts libx264";
	echo "  convertVideos.sh /videos *.ts libx265";
	echo ""
	
	exit 1
else
	ROOT=$1
fi

FILEFILTER=$2

if [ "$3" = "" ]; then
	ENCODER=libx264
else
	ENCODER=$3
fi

while [ true ]
do
	readarray -d '' files < <(find "$ROOT" -name "$FILEFILTER" -print0)
	numFiles=${#files[@]}
	echo "[$(date)] : $numFiles inputfile(s) matching $FILEFILTER were found in \"$ROOT\"!"
	fileNr=0
	for inputFile in "${files[@]}"; 
	do
		echo "[$(date)] : ---------------"
		
		fileNr=$((fileNr+1))
		echo "[$(date)] : Next inputfile #$fileNr \"$inputFile\""

		#only consider .ts files which are done by HDHomeRun recorder (that means are old enough)
		inputfileAgeInSeconds=$(($(date +%s) - $(date +%s -r "$inputFile")))
		echo "[$(date)] : File age is $inputfileAgeInSeconds seconds"

		durationInputFile=$(bc <<<`ffprobe -i "$inputFile" -v quiet -print_format json -show_format | ./jq '.format.duration'`)
		echo "[$(date)] : Duration inputfile : $durationInputFile seconds"

		if [ $inputfileAgeInSeconds -ge $minFileAgeInSeconds ]; then
			#current folder
			currentFolder="${inputFile%/*}"
			#remove extension and add .mp4
			outputFile="${inputFile%.*}.mp4" 
			filesizeInput=$(stat -c%s "$inputFile")
			echo "[$(date)] : size is $filesizeInput"
			#echo "[$(date)] : \"$outputFile\"";
			doConversion=true;
			if [ -f "$outputFile" ]; then
				#echo "[$(date)] : \"$outputFile\" exists."
				
				filesizeOutput=$(stat -c%s "$outputFile")		
				echo "[$(date)] : size \"$outputFile\" is $filesizeOutput"

				#skip .mp4 files which are not old enough, in case a process is converting/writing to them
				outputfileAgeInSeconds=$(($(date +%s) - $(date +%s -r "$outputFile")))
				echo "[$(date)] : File age is $outputfileAgeInSeconds seconds"

				if [ $outputfileAgeInSeconds -ge $minFileAgeInSeconds ]; then
					percentage=$(bc <<<"scale=4; $filesizeOutput / $filesizeInput * 100")
					echo "[$(date)] : Percentage compression of already converted file: $percentage"
					durationOutputFile=$(bc <<<`ffprobe -i "$outputFile" -v quiet -print_format json -show_format | ./jq '.format.duration'`)
					echo "[$(date)] : Duration outputfile : $durationOutputFile seconds"
					difference=$(abs_diff $durationInputFile $durationOutputFile)
					echo "[$(date)] : Difference: $difference seconds"
					
					if [ $(bc <<<"$difference < $maxLengthDifferenceInSeconds") -eq 1 ]; then
						echo "[$(date)] : a previous successfull conversion was found which matched qua duration with \"$inputFile\""
						if [ "$deleteOriginalFiles" = true ]; then
							rm "$inputFile"
							echo "[$(date)] : Deleted \"$inputFile\""
						else
							echo "[$(date)] : Skipped deletion of \"$inputFile\""
						fi
						doConversion=false;
					else
						echo "[$(date)] : Previous conversion of inputfile \"$inputFile\" didn't match qua duration (maybe didn't finish, failed or file had different contents but with same filename)!"
						if [ "$redoConversionWhenInputAndOutputDontMatch" = true ]; then
							echo "[$(date)] : Redoing transcoding of \"$inputFile\"!"
							if [ "$keepPreviousConversion" = true ]; then
								version=1
								preservedOutputFile="${outputFile%.*}-prev-v$version.mp4"
								while [ -f "$preservedOutputFile" ]
								do
									version=$((version+1))
									preservedOutputFile="${outputFile%.*}-prev-v$version.mp4"
								done
								echo "[$(date)] : Keeping previous conversion and renaming to \"$preservedOutputFile\"!"
								#rename file
								mv "$outputFile" "$preservedOutputFile"
							fi
						else
							echo "[$(date)] : NOT redoing transcoding of \"$inputFile\"!"
							doConversion=false;
						fi
					fi
				else
					doConversion=false;
					echo "[$(date)] : file skipped, modified date is too young!"
				fi
			else
				echo "[$(date)] : \"$outputFile\" does not exist."
			fi
			
			if [ "$doConversion" = true ]; then 
				filesizeOutput=0
				echo "[$(date)] : Re-encoding file..."
				echo ""
				#encoder: libx264 (~ 7x times smaller and speed=2.4x) 
				#encoder: libx265 (~12x times smaller and speed=0.7x)
				
				#used commandline options ffmpeg explained:
				# -loglevel = show/log only errors
				# -i        = use inputFile as input
				# -y        = overwrite previous file
				# -c:v      = re-encode video with ENCODER
				# =pix_fmt  = use yuv420p as pixelformat
				# -c:a      = copy original audio
				ffmpeg -loglevel error -i "$inputFile" -y -c:v $ENCODER -pix_fmt yuv420p -c:a copy "$outputFile"
				filesizeOutput=$(stat -c%s "$outputFile")
				percentage=$(bc <<<"scale=4; $filesizeOutput / $filesizeInput * 100")
				echo ""
				echo "[$(date)] : Percentage compression after conversion: $percentage"

				durationOutputFile=$(bc <<<`ffprobe -i "$outputFile" -v quiet -print_format json -show_format | ./jq '.format.duration'`)
				echo "[$(date)] : Duration outputfile : $durationOutputFile seconds"
				difference=$(abs_diff $durationInputFile $durationOutputFile)
				echo "[$(date)] : Difference: $difference seconds"

				if [ -f "$outputFile" ] && [ $(bc <<<"$difference < $maxLengthDifferenceInSeconds") -eq 1 ]; then
					echo "[$(date)] : Conversion succes, inputFile can be deleted"
					if [ "$deleteOriginalFiles" = true ]; then
						rm "$inputFile"
						echo "[$(date)] : Deleted \"$inputFile\""
					else
						echo "[$(date)] : Skipped deletion of \"$inputFile\""
					fi
				else 
					echo "[$(date)] : Conversion skipped, failed or incomplete"
				fi
			fi
		else
			echo "[$(date)] : file skipped, modified date is too young!"
		fi
	done

	echo ""
	echo "[$(date)] : done, no more files!"
	echo "[$(date)] : waiting for next round!"
	
	if [ "$runOnce" = false ]; then
		echo "[$(date)] : Rerun will start next day at $rerunAt, waiting..."
		# in the case no files were found this round wait at least one minute to prevent immediately retriggering at same time
		if [ $numFiles -eq 0 ]; then
			sleep 61
		fi
		wait_till $rerunAt
	else
		echo "[$(date)] : Running only once... exiting!"
	fi
done
	
echo ""