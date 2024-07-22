#!/bin/bash

# running this directly on your Synology NAS in a shell requires `sudo` to run commands below:
# ./benchmarkConvertVideosLogged.sh h264_vaapi
# ./benchmarkConvertVideosLogged.sh h264_qsv
# ./benchmarkConvertVideosLogged.sh hevc_vaapi
./benchmarkConvertVideosLogged.sh hevc_qsv
