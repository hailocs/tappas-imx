#!/bin/bash

CLIENT_IP=$1
CAMERA_DEVICE=$2

APPS_DIR="/home/root/apps/"


# Check that parameter is provided
if [ -z "$CLIENT_IP" ]; then
    echo "Error: Missing client IP parameter"
    exit 1
fi

if [ -z "$CAMERA_DEVICE" ]; then
    echo "Error: Missing camera device parameter"
    exit 1
fi

# Kill any existing gst-launch processes
while pgrep -x "gst-launch-1.0" > /dev/null; do
    echo "Stopping old gst-launch processes..."
    pkill -9 gst-launch-1.0
    sleep 1
done

#
# RUN TAPPAS
#

cd $APPS_DIR

cd semantic_segmentation

./semantic_segmentation.sh -i $CAMERA_DEVICE --udpsink $1
