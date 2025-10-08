# On your linux client pc you can display the demo video streaming with the following GStreamer command:

gst-launch-1.0 udpsrc port=5000 caps = "application/x-rtp-stream, encoding-name=H264" ! rtpstreamdepay ! rtph264depay ! decodebin ! videoconvert n-threads=8 ! videoscale n-threads=8 ! "video/x-raw,height=720, width=1280" !  autovideosink
