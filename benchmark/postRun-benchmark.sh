#!/bin/bash

source common-functions.sh

# Convert the comma-separated strings arguments back to arrays
IFS=',' read -ra outputFilesConvertedRun <<< "$2"

# Define the output file path
outputFile="outputFilesConvertedRun.txt"

# Replace code below with your own post-processing logic
echo "outputFilesConvertedRun files:"
for element in "${outputFilesConvertedRun[@]}"; do
    echo "$element" | tee "$outputFile"
done

# Exit with a success status
exit 0
