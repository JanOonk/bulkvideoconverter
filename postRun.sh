#!/bin/bash

source common-functions.sh

# Convert the comma-separated strings arguments back to arrays
IFS=',' read -ra filesConvertedRun <<< "$1"
IFS=',' read -ra outputFilesConvertedRun <<< "$2"
IFS=',' read -ra filesFailedRun <<< "$3"
IFS=',' read -ra inputFilesWithMaxRetries <<< "$4"

# Replace code below with your own post processing logic
echo "filesConvertedRun elements:"
for element in "${filesConvertedRun[@]}"; do
    echo "$element"
done

echo "outputFilesConvertedRun elements:"
for element in "${outputFilesConvertedRun[@]}"; do
    echo "$element"
done

echo "filesFailedRun elements:"
for element in "${filesFailedRun[@]}"; do
    echo "$element"
done

echo "inputFilesWithMaxRetries elements:"
for element in "${inputFilesWithMaxRetries[@]}"; do
    echo "$element"
done

# Exit with a success status
exit 0