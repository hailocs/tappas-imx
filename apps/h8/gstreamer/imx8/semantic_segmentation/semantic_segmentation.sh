#!/bin/bash
set -e

CURRENT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

CAMERA_RES="1280x720"
# CAMERA_FPS="30" # not needed

APP_TITLE="semantic_segmentation"

##################### DO NOT MODIFY BELOW THIS LINE ##########################


##############################################################################
#                                  TOOLS                                     #
##############################################################################

#
# init main variables for system platform identification
#
function init_variables() {

    # host platform specification
    host_cpu_type=$(cat /sys/devices/soc0/soc_id 2>/dev/null) || \
      host_cpu_type=$(uname -n 2>/dev/null)
    host_hw_type=$(uname -i)
    host_os_type=$(uname -o)
    hailo_device=$(lspci | grep "Hailo")
    
    # input specification
    input_source="none"
    input_type="none"

    # input camera 
    camera_format="none"
    camera_resolution="none"
    camera_fps="none"

    # input file
    file_format="none"

    # extra sw tools
    sw_v4l2_ctl=`which v4l2-ctl`


    #
    # filter CPU types
    #
    if [[ $host_cpu_type =~ "i.MX8" ]] || [[ $host_cpu_type =~ "imx8" ]]; then
        host_cpu_type="imx8"
    else
        host_cpu_type="generic"
    fi

    #
    # filter OS types
    #
    if [[ $host_os_type =~ "Linux" ]]; then
        host_os_type="linux"
    elif [[ $host_os_type =~ "linux" ]]; then
        host_os_type="linux"
    else
        host_os_type="none"
    fi

    #
    # filter HAILO device
    #
    if [[ $hailo_device =~ "Hailo-8" ]]; then
        hailo_device="hailo8"
    else
        hailo_device="none"
    fi
}

#
# qualify camera capabilities
#
function find_camera_format(){
    DEVICE=$1
    RES=$2
    REQ_FPS=$3  # Optional

    REQ_WIDTH=${RES%x*}
    REQ_HEIGHT=${RES#*x}

    FORMATS_OUTPUT=$(v4l2-ctl --device="$DEVICE" --list-formats-ext)

    # Format priority: lower index = higher priority
    format_priority=(MJPG H264 YUYV NV12 NV16)

    formats=()
    fps_list=()

    current_format=""
    current_width=""
    current_height=""

    match_found=0
    match_format=""

    stepwise_found=0
    best_stepwise_format=""
    best_stepwise_width=0
    best_stepwise_height=0
    best_stepwise_priority=9999

    while IFS= read -r line; do
      # Match format line like: [0]: 'YUYV'
      if [[ $line =~ \[[0-9]+\]:\ \'([A-Z0-9_]+)\' ]]; then
        current_format="${BASH_REMATCH[1]}"
        continue
      fi

      # Match Discrete size
      if [[ $line =~ Size:\ Discrete\ ([0-9]+)x([0-9]+) ]]; then
        current_width="${BASH_REMATCH[1]}"
        current_height="${BASH_REMATCH[2]}"
        continue
      fi

      # Match Interval: Discrete x.xxxs (FPS)
      if [[ $line =~ Interval:\ Discrete\ ([0-9]+\.[0-9]+)s ]]; then
        interval="${BASH_REMATCH[1]}"
        fps=$(printf "%.0f" "$(echo "scale=2; 1 / $interval" | bc -l)")

        if [[ "$current_width" == "$REQ_WIDTH" && "$current_height" == "$REQ_HEIGHT" ]]; then
          if [[ -n "$REQ_FPS" ]]; then
            if [[ "$fps" -eq "$REQ_FPS" ]]; then
              echo "Format: $current_format - ${REQ_WIDTH}x${REQ_HEIGHT} supported at ${REQ_FPS} FPS"
              match_found=1
              match_format=$current_format
            fi
          else
            found=0
            for i in "${!formats[@]}"; do
              if [[ "${formats[$i]}" == "$current_format" ]]; then
                if [[ "$fps" -gt "${fps_list[$i]}" ]]; then
                  fps_list[$i]=$fps
                fi
                found=1
                break
              fi
            done
            if [[ "$found" -eq 0 ]]; then
              formats+=("$current_format")
              fps_list+=("$fps")
            fi
          fi
        fi
      fi

      # Match Stepwise line
      if [[ $line =~ Size:\ Stepwise\ ([0-9]+)x([0-9]+)\ -\ ([0-9]+)x([0-9]+) ]]; then
        min_w="${BASH_REMATCH[1]}"
        min_h="${BASH_REMATCH[2]}"
        max_w="${BASH_REMATCH[3]}"
        max_h="${BASH_REMATCH[4]}"

        # Check if requested resolution is within the range
        if [[ "$REQ_WIDTH" -ge "$min_w" && "$REQ_WIDTH" -le "$max_w" && "$REQ_HEIGHT" -ge "$min_h" && "$REQ_HEIGHT" -le "$max_h" ]]; then
          # Pick this format only if it's higher priority than what we've already seen
          for i in "${!format_priority[@]}"; do
            if [[ "${format_priority[$i]}" == "$current_format" ]]; then
              if [[ "$i" -lt "$best_stepwise_priority" ]]; then
                best_stepwise_format="$current_format"
                best_stepwise_width="$REQ_WIDTH"
                best_stepwise_height="$REQ_HEIGHT"
                best_stepwise_priority="$i"
                stepwise_found=1
              fi
              break
            fi
          done
        fi
      fi

    done <<< "$FORMATS_OUTPUT"

    # Output results
    if [[ -n "$REQ_FPS" ]]; then
      if [[ "$match_found" -eq 0 ]]; then
        echo "camera_input: No formats found matching ${REQ_WIDTH}x${REQ_HEIGHT} at ${REQ_FPS} FPS. exit."
      else
        camera_format=$match_format
      fi
    else
      if [[ "${#formats[@]}" -gt 0 ]]; then
        for i in "${!formats[@]}"; do
          echo "Format: ${formats[$i]} - ${REQ_WIDTH}x${REQ_HEIGHT} supported, max FPS: ${fps_list[$i]}"

            if [[ ${formats[$i]} =~ "MJPG" ]]; then
                # best is MJPEG over YUYV
                camera_format="MJPG"
                camera_resolution="${REQ_WIDTH}x${REQ_HEIGHT}"
                camera_fps=${fps_list[$i]}
            else
                # best is higher fps
                if [[ $tmp_fps < ${fps_list[$i]} ]]; then

                    tmp_fps=${fps_list[$i]}

                    camera_format=${formats[$i]} 
                    camera_resolution="${REQ_WIDTH}x${REQ_HEIGHT}"
                    camera_fps=${fps_list[$i]}
                fi
            fi
        done
      elif [[ "$stepwise_found" -eq 1 ]]; then
        echo "Stepwise match: Format: $best_stepwise_format - ${best_stepwise_width}x${best_stepwise_height} (stepwise)"
        camera_format=$best_stepwise_format 
        camera_resolution="${best_stepwise_width}x${best_stepwise_height}"
      else
        echo "camera_input: No matching resolution found, ${REQ_WIDTH}x${REQ_HEIGHT}. exit. "
        exit 1
      fi
    fi

}


#
# script sanity checks
#
function sanity_check(){
    #
    # check supported platforms
    #
    if [[ $host_cpu_type =~ "none" ]]; then
        echo "unsupported host_cpu_type: $host_cpu_type"
    fi

    if [[ $host_os_type =~ "none" ]]; then
        echo "unsupported host_os_type: $host_os_type"
    fi

    if [[ $hailo_device =~ "none" ]]; then
        echo "unsupported hailo_device: $hailo_device"
    fi

    #
    # check extra tools
    #
    if ! [[ $sw_v4l2_ctl =~ "v4l2-ctl" ]]; then
        echo "missing tool: v4l2-ctl"
        exit 0
    fi

    #
    # check input type
    #
    if ! [[ $input_source =~ "none" ]]; then
        if [[ $input_source =~ "/dev/video" ]]; then
            input_type="camera"
        else    
            input_type="file"
        fi    
    fi

    if [[ $input_source =~ "none" ]]; then
        echo "missing input, use option \"-i\""
        exit 0
    fi

    #
    # check for input file presence
    #
    if [[ $input_source =~ "file" ]]; then
        if [[ ! -f $input_source ]]; then
            echo "cannot find file: $input_source"
            exit 0
        fi

        # override camera format so we use only one param
        camera_format="file"
    fi

    #
    # check for camera input format
    #
    if [[ $input_type =~ "camera" ]]; then

        find_camera_format $input_source $CAMERA_RES

        if [[ $camera_format =~ "none" ]]; then
            echo "cannot find camera format ($CAMERA_RES) for device: $input_source. exit."
            exit 1
        fi

    fi
}


##############################################################################
#                                  MAIN                                      #
##############################################################################


function print_usage() {
    echo "Object Detection pipeline usage:"
    echo ""
    echo "Options:"
    echo "  --help              Show this help"
    echo "  -i INPUT --input INPUT          Set the video source (default $input_source)"
    echo "  --show-fps          Print fps"
    echo "  --print-gst-launch  Print the ready gst-launch command without running it"
    exit 0
}

function parse_args() {
    while test $# -gt 0; do
        if [ "$1" = "--help" ] || [ "$1" == "-h" ]; then
            print_usage
            exit 0
        elif [ "$1" = "--print-gst-launch" ]; then
            print_gst_launch_only=true
        elif [ "$1" = "--show-fps" ]; then
            additional_parameters="-v | grep hailo_display"
        elif [ "$1" = "--input" ] || [ "$1" = "-i" ]; then
            input_source="$2"
            shift
        else
            echo "Received invalid argument: $1. See expected arguments below:"
            print_usage
            exit 1
        fi

        shift
    done
}


init_variables $@

parse_args $@

sanity_check $@

script_launcher="./platforms/$APP_TITLE-$host_os_type-$host_hw_type-$host_cpu_type-$hailo_device.sh"

if ! [[ -f $script_launcher ]]; then
    echo "platform script unsupported ($script_launcher). exit."
    exit 1
fi

# add extra parameters for camera format

if [[ $input_type =~ "file" ]]; then
    set -- "$@" "--format" "file"
else
    set -- "$@" "--format" $camera_format "--fps" $camera_fps
fi

$script_launcher $@