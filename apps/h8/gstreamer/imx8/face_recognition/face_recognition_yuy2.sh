#!/bin/bash
set -e

CURRENT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

function init_variables() {
    print_help_if_needed $@
    script_dir=$(dirname $(realpath "$0"))

    readonly RESOURCES_DIR="${CURRENT_DIR}/resources"
    readonly POSTPROCESS_DIR="/usr/lib/hailo-post-processes"
    readonly APPS_LIBS_DIR="/home/root/apps/libs/vms/"
    readonly CROPPER_SO="$POSTPROCESS_DIR/cropping_algorithms/libvms_croppers.so"
    
    # Face Alignment
    readonly FACE_ALIGN_SO="$APPS_LIBS_DIR/libvms_face_align.so"
    
    # Face Recognition
    readonly RECOGNITION_POST_SO="$POSTPROCESS_DIR/libface_recognition_post.so"
    readonly RECOGNITION_HEF_PATH="$RESOURCES_DIR/arcface_mobilefacenet.hef"

    # Face Detection and Landmarking
    readonly DEFAULT_HEF_PATH="$RESOURCES_DIR/scrfd_10g_yuy2.hef"
    readonly POSTPROCESS_SO="$POSTPROCESS_DIR/libscrfd_post.so"
    readonly FACE_JSON_CONFIG_PATH="$RESOURCES_DIR/configs/scrfd.json"
    readonly FUNCTION_NAME="scrfd_10g"

    detection_network="scrfd_10g"

    detection_hef=$DEFAULT_HEF_PATH
    detection_post=$FUNCTION_NAME
    recognition_hef=$RECOGNITION_HEF_PATH
    recognition_post="arcface_nv12"

    video_format="YUY2"

    input_source="/dev/video2"
    video_sink_element=autovideosink
    additional_parameters=""
    print_gst_launch_only=false
    vdevice_key=1
    local_gallery_file="$RESOURCES_DIR/gallery/face_recognition_local_gallery_yuy2.json"

}

function print_usage() {
    echo "Face recognition - pipeline usage:"
    echo ""
    echo "Options:"
    echo "  --help                          Show this help"
    echo "  --show-fps                      Printing fps"
    echo "  --print-gst-launch              Print the ready gst-launch command without running it"
    exit 0
}

function print_help_if_needed() {
    while test $# -gt 0; do
        if [ "$1" = "--help" ] || [ "$1" == "-h" ]; then
            print_usage
        fi
        shift
    done
}

function parse_args() {
    while test $# -gt 0; do
        if [ "$1" = "--help" ] || [ "$1" == "-h" ]; then
            print_usage
            exit 0
        elif [ "$1" = "--print-gst-launch" ]; then
            print_gst_launch_only=true
        elif [ "$1" = "--show-fps" ]; then
            echo "Printing fps"
            additional_parameters="-v 2>&1 | grep hailo_display"
        else
            echo "Received invalid argument: $1. See expected arguments below:"
            print_usage
            exit 1
        fi
        shift
    done
}

function set_networks() {
    # Face Recognition
    recognition_hef="$RESOURCES_DIR/arcface_mobilefacenet_yuy2.hef"
    
    # Face Detection and Landmarking
    hef_path="$RESOURCES_DIR/scrfd_10g_yuy2.hef"
    recognition_post="arcface_nv12"
}

function main() {
    init_variables $@
    parse_args $@
    set_networks $@

    # If the video provided is from a camera
    source_element="v4l2src device=$input_source name=src_0 ! video/x-raw,format=YUY2,width=1280,height=720,framerate=30/1 "


    RECOGNITION_PIPELINE="hailocropper so-path=$CROPPER_SO function-name=face_recognition internal-offset=true name=cropper2 \
        hailoaggregator name=agg2 \
        cropper2. ! \
            queue name=bypess2_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        agg2. \
        cropper2. ! \
            queue name=pre_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailofilter so-path=$FACE_ALIGN_SO name=face_align_hailofilter use-gst-buffer=true qos=false ! \
            queue name=detector_pos_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailonet hef-path=$recognition_hef scheduling-algorithm=1 vdevice-group-id=$vdevice_key ! \
            queue name=recognition_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailofilter function-name=$recognition_post so-path=$RECOGNITION_POST_SO name=face_recognition_hailofilter qos=false ! \
            queue name=recognition_pre_agg_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        agg2. \
        agg2. "

    FACE_DETECTION_PIPELINE="hailonet hef-path=$hef_path scheduling-algorithm=1 vdevice-group-id=$vdevice_key ! \
        queue name=detector_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailofilter so-path=$POSTPROCESS_SO name=face_detection_hailofilter qos=false config-path=$FACE_JSON_CONFIG_PATH function_name=$detection_post"

    FACE_TRACKER="hailotracker name=hailo_face_tracker class-id=-1 kalman-dist-thr=0.7 iou-thr=0.8 init-iou-thr=0.9 \
                    keep-new-frames=2 keep-tracked-frames=6 keep-lost-frames=8 keep-past-metadata=true qos=false"

    DETECTOR_PIPELINE="$FACE_DETECTION_PIPELINE ! \
            queue leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 "

    pipeline="gst-launch-1.0 \
        $source_element ! \
        queue name=hailo_pre_convert_0 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        videoconvert n-threads=4 qos=false ! \
        queue name=pre_detector_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $DETECTOR_PIPELINE ! \
        queue name=pre_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $FACE_TRACKER ! \
        queue name=hailo_post_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $RECOGNITION_PIPELINE ! \
        queue name=hailo_pre_gallery_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailogallery gallery-file-path=$local_gallery_file \
        load-local-gallery=true similarity-thr=.4 gallery-queue-size=20 class-id=-1 ! \
        queue name=hailo_pre_draw2 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailooverlay name=hailo_overlay qos=false show-confidence=false local-gallery=true line-thickness=5 font-thickness=2 landmark-point-radius=8 ! \
        queue name=hailo_post_draw leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        videoconvert n-threads=4 qos=false name=display_videoconvert qos=false ! \
        queue name=hailo_display_q_0 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        fpsdisplaysink video-sink=$video_sink_element name=hailo_display sync=false text-overlay=false \
        ${additional_parameters}"

    echo ${pipeline}
    if [ "$print_gst_launch_only" = true ]; then
        exit 0
    fi

    echo "Running Pipeline..."
    eval "${pipeline}"

}

main $@
