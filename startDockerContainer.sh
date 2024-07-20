#!/bin/bash

# SETTINGS
# Define the Docker executable path
DOCKER_EXEC="/volume1/@appstore/ContainerManager/usr/bin/docker"
# Folder of bulk video converter
BULKVIDEOCONVERTER_FOLDER="/volume1/Apps/bulkvideoconverter/"

# Navigate to the target directory
cd "$BULKVIDEOCONVERTER_FOLDER"

# Function to check if the Docker daemon is running
wait_for_docker() {
  until sudo "$DOCKER_EXEC" info > /dev/null 2>&1; do
    echo "Waiting for Docker to start..."
    sleep 2
  done
  echo "Docker is running."
}

# Function to check if the jellyfin container is running
wait_for_container() {
  local container_name=$1
  until [ "$(sudo "$DOCKER_EXEC" inspect -f '{{.State.Running}}' $container_name)" == "true" ]; do
    echo "Waiting for container $container_name to start..."
    sleep 2
  done
  echo "Container $container_name is running."
}

# Wait for the Docker daemon to be ready
wait_for_docker

# Start the Docker container
# you can also remove `sudo` if you do not want to give too much control to container
sudo "$DOCKER_EXEC" container start jellyfin

# Wait for the jellyfin container to be running
wait_for_container jellyfin

# Execute the command inside the container
# you can also remove `sudo` if you do not want to give too much control to container
sudo "$DOCKER_EXEC" container exec jellyfin sh -c 'cd /Apps/bulkvideoconverter/ && ./convertVideos.sh' &

# use this to get a shell into the jellyfin container and to show all running tasks:
#  sudo docker exec -it jellyfin bash
#  ps -A

