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
    readonly DEFAULT_VIDEO_FORMAT="YUY2"
    readonly DEFAULT_HEF_PATH="$RESOURCES_DIR/scrfd_10g_yuy2.hef"
    readonly RECOGNITION_POST_SO="$POSTPROCESS_DIR/libface_recognition_post.so"

    # Face Alignment
    readonly FACE_ALIGN_SO="$APPS_LIBS_DIR/libvms_face_align.so"
    readonly POSTPROCESS_SO="$POSTPROCESS_DIR/libscrfd_post.so"
    readonly FACE_JSON_CONFIG_PATH="$RESOURCES_DIR/configs/scrfd.json"
    readonly FUNCTION_NAME="scrfd_10g"

    readonly RECOGNITION_HEF_PATH="$RESOURCES_DIR/arcface_mobilefacenet_yuy2.hef"
    readonly RECOGNITION_FUNCTION_NAME="arcface_nv12"

    video_format=$DEFAULT_VIDEO_FORMAT
    network=$FUNCTION_NAME
    hef_path=$DEFAULT_HEF_PATH
    video_sink_element=$([ "$XV_SUPPORTED" = "true" ] && echo "xvimagesink" || echo "ximagesink")
    additional_parameters=""
    print_gst_launch_only=false
    vdevice_key=1
    clean_local_gallery_file=false
    function_name=$FUNCTION_NAME
    local_gallery_file="$RESOURCES_DIR/gallery/face_recognition_local_gallery_yuy2.json"
}

function print_usage() {
    echo "Save face recognition local gallery - pipeline usage:"
    echo ""
    echo "Options:"
    echo "  --help                          Show this help"
    echo "  --network NETWORK               Set network to use. choose from [scrfd_10g, scrfd_2.5g (only ubuntu 22.04)], default is scrfd_10g"
    echo "  --format FORMAT                 Choose video format from [RGB, NV12], default is RGB"
    echo "  --clean                         Clean local gallery file enitrely"
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
        elif [ $1 == "--format" ]; then
            if [ $2 == "YUY2" ]; then
                video_format="YUY2"
                local_gallery_file="$RESOURCES_DIR/gallery/face_recognition_local_gallery_yuy2.json"
            elif [ $2 == "RGB" ]; then
                video_format="RGB"
            else
                echo "Received invalid format: $2. See expected arguments below:"
                print_usage
                exit 1
            fi
            shift
        elif [ $1 == "--clean" ]; then
            clean_local_gallery_file=true
            echo "Cleaning local gallery file"
        else
            echo "Received invalid argument: $1. See expected arguments below:"
            print_usage
            exit 1
        fi
        shift
    done
}

function main() {
    init_variables $@
    parse_args $@

    RECOGNITION_PIPELINE="hailocropper so-path=$CROPPER_SO function-name=face_recognition internal-offset=true name=cropper2 \
        hailoaggregator name=agg2 \
        cropper2. ! \
            queue name=bypess2_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        agg2. \
        cropper2. ! \
            queue name=pre_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailofilter so-path=$FACE_ALIGN_SO name=face_align_hailofilter use-gst-buffer=true qos=false ! \
            queue name=detector_pos_face_align_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailonet hef-path=$RECOGNITION_HEF_PATH scheduling-algorithm=1 vdevice-group-id=$vdevice_key ! \
            queue name=recognition_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
            hailofilter function-name=$RECOGNITION_FUNCTION_NAME so-path=$RECOGNITION_POST_SO name=face_recognition_hailofilter qos=false ! \
            queue name=recognition_pre_agg_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        agg2. \
        agg2. "

    FACE_DETECTION_PIPELINE="hailonet hef-path=$hef_path scheduling-algorithm=1 vdevice-group-id=$vdevice_key ! \
        queue name=detector_post_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailofilter so-path=$POSTPROCESS_SO name=face_detection_hailofilter qos=false config-path=$FACE_JSON_CONFIG_PATH function_name=$FUNCTION_NAME "

    FACE_TRACKER="hailotracker name=hailo_face_tracker class-id=-1 kalman-dist-thr=0.7 iou-thr=0.8 init-iou-thr=0.9 \
                    keep-new-frames=2 keep-tracked-frames=6 keep-lost-frames=8 keep-past-metadata=true qos=false"

    DETECTOR_PIPELINE="$FACE_DETECTION_PIPELINE ! \
            queue leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 "

    if [ "$print_gst_launch_only" = true ]; then
        exit 0
    fi

    if [ "$clean_local_gallery_file" = true ]; then
        rm -f $local_gallery_file
    fi

    skipped_names=()

    # Iterate over all png files in the directory
    for file in $RESOURCES_DIR/faces/*.png; do
        image_file=$file
        # Get image file name
        image_file_name="${image_file##*/}"
        # Remove the extension from the file name
        image_file_name="${image_file_name%.*}"
        # Set first letter to upper case
        image_file_name="${image_file_name^}"

        # Check if file $local_gallery_file already contains the name
        if grep -q $image_file_name $local_gallery_file; then
            skipped_names+=($image_file_name)
            continue
        fi

        pipeline="gst-launch-1.0 \
        multifilesrc location=$image_file loop=true num-buffers=50 ! decodebin ! \
        videoconvert n-threads=4 qos=false ! video/x-raw, format=$video_format, pixel-aspect-ratio=1/1 ! \
        queue name=pre_detector_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $DETECTOR_PIPELINE ! \
        queue name=pre_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $FACE_TRACKER ! \
        queue name=hailo_post_tracker_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        $RECOGNITION_PIPELINE ! \
        queue name=hailo_pre_gallery_q leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailogallery gallery-file-path=$local_gallery_file \
        save-local-gallery=true similarity-thr=.4 gallery-queue-size=20 class-id=-1 ! \
        queue name=pre_scale_q2 leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        hailooverlay show-confidence=false name=overlay2 qos=false ! \
        queue name=hailo_post_draw leaky=no max-size-buffers=30 max-size-bytes=0 max-size-time=0 ! \
        videoconvert n-threads=8 qos=false name=display_videoconvert ! \
        queue name=hailo_display_q_0 leaky=no max_size_buffers=300 max-size-bytes=0 max-size-time=0 ! \
        autovideosink \
        ${additional_parameters}"

        echo "Running pipeline with file: $file"
        eval "${pipeline}"

        echo "$image_file_name added to the local gallery"
        # Replace Unknown1 in $local_gallery_file to the image name
        sed -i "s/Unknown1/$image_file_name/g" $local_gallery_file
        echo ""
    done

    echo ""
    if [ ${#skipped_names[@]} -gt 0 ]; then
        echo "Names: "
        for name in "${skipped_names[@]}"; do
            echo "$name"
        done
        echo ""

        echo "Already exists in the local gallery file $local_gallery_file"
        echo "You can run the script with --clean to clean the local gallery file enitrely"
        echo "Or edit the file manually, and run again"
        exit 1
    else
        echo "All images were added to the local gallery file $local_gallery_file successfully"
    fi
}

main $@
