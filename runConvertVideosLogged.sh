#!/bin/bash
cd /videos
exec >> convertVideos-logfile.txt                                                                      
exec 2>&1
echo "[$(date)] : start of $0"
./convertVideos.sh /videos/ *.ts libx264
echo "[$(date)] : end of $0"
