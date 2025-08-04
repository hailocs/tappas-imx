
Pose Estimation Pipeline
========================

Overview
--------

``pose_estimation.sh`` demonstrates human pose estimation on the camera stream (/dev/video2).
 This is done by running a ``single-stream pose estimation pipeline`` on top of GStreamer using the Hailo-8 device.

Options
-------

.. code-block:: sh

   ./pose_estimation.sh [--input FILL-ME]


* 
  ``--input`` is an optional flag, for the input camera source (default is /dev/video2).

* 
  ``--show-fps``  is an optional flag that enables printing FPS on screen.

* ``--network``   Set network to use. choose from [centerpose, centerpose_416], default is centerpose
* ``--print-gst-launch`` is a flag that prints the ready gst-launch command without running it"

Run
---

.. code-block:: sh

   cd /home/root/apps/pose_estimation
   ./pose_estimation.sh


Model
-----


* ``yolov8s_pose``: https://github.com/hailo-ai/hailo_model_zoo/blob/master/hailo_model_zoo/cfg/networks/yolov8s_pose.yaml

Method of Operation
-------------------

This app is based on our `single network pipeline template <../../../../../docs/pipelines/single_network.rst>`_

