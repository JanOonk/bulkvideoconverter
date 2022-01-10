#!/bin/bash
cd /videos
echo "[$(date)] : start of $0"
./convertVideos.sh /videos/ *.ts hevc_vaapi | tee -a convertVideos-logfile.txt 
echo "[$(date)] : end of $0"
