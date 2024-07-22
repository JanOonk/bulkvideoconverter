#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------

# benchmark settings
# folder that contain videos that will be converted
videosFolder="$script_dir"

# prefix of the videos filenames that will be converted for benchmarking
videoFilenames="test-SD*.ts"

# git source folder of bulkvideoconverter
bulkConvertVideosFolder="/Apps/bulkvideoconverter"
# bulkConvertVideosFolder="/volume1/Apps/bulkvideoconverter"

# points to the settings file which is used for this benchmark
settingsFile="$script_dir/settings-benchmark.sh"
postRunFile="$script_dir/postRun-benchmark.sh"

# -----------------------------------------

logfile="$videosFolder/benchmark.txt"

echo "Folder of running script: $script_dir"

if [ "$1" = "" ]; then
	echo "encoder not set (first argument)"
    cd "$script_dir"
	exit 1
else
	ENCODER=$1
fi

# Check if settingsFile exists
if [ ! -f "$settingsFile" ]; then
    echo "Settings file '$settingsFile' does not exist."
    cd "$script_dir"
    exit 1
fi

# Inside this settings file update these: 
#  runOnce=true
sed -i 's/^runOnce=.*/runOnce=true/' "$settingsFile"
sed -i "s|^postRunScript=.*|postRunScript=$postRunFile|" "$settingsFile"

# remove any previous converted output file
# videoFile=$videoFilenames-SD
# rm $videosFolder/$videoFile.mp4 2>/dev/null

# videoFile=$videoFilenames-HD
# rm $videosFolder/$videoFile.mp4 2>/dev/null

echo "[$(date)] : start of $0"

cd "$bulkConvertVideosFolder"
./convertVideos.sh -sf "$settingsFile" -sd "$videosFolder" -ff "$videoFilenames" -e $ENCODER -lf "$logfile"

# Define the output file path
outputFile="outputFilesConvertedRun.txt"

# Check if the file exists
if [ ! -f "$outputFile" ]; then
    echo "File '$outputFile' does not exist."
else
    # Read the file contents into the array
    mapfile -t outputFilesConvertedRun < "$outputFile"

    # Process each element in the array
    for filePath in "${outputFilesConvertedRun[@]}"; do
        # Extract the filename and extension
        fileName=$(basename "$filePath")
        fileExtension="${fileName##*.}"
        baseName="${fileName%.*}"
        
        # Define the new file path with the encoder suffix
        newFileName="${baseName}-${ENCODER}.${fileExtension}"
        newFilePath="${videosFolder}/${newFileName}"
        
        # Move and rename the file
        if [ -f "$filePath" ]; then
            mv "$filePath" "$newFilePath"
            echo "Moved '$filePath' to '$newFilePath'"
        else
            echo "File '$filePath' does not exist, skipping..."
        fi
    done
fi

echo "[$(date)] : end of $0"

cd "$script_dir"
