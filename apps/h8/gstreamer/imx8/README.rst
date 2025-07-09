
iMX8 GStreamer Based Applications
=================================

.. warning::
   The Kirkstone applications portfolio is reduced on i.MX8-based devices, since the Kirkstone branch does not support OpenGL.

#. `Detection <detection/README.rst>`_ - Single-stream object detection pipeline on top of GStreamer using the Hailo-8 device.
#. `Face Recognition <face_recognition/README.rst>`_ - Face recognition pipeline on top of GStreamer using the Hailo-8 device.
#. `License Plate Recognition <license_plate_recognition/README.rst>`_ - LPR app using ``yolov5m`` vehicle detection, ``yolov8n`` license plate detection, and ``lprnet`` OCR extraction with Hailonet network-switch capability.
#. `Multi-Stream Object Detection <multistream_detection/README.rst>`_ - Multi stream object detection (up to 4 streams into one Hailo-8 chip).
#. `Pose Estimation <pose_estimation/README.rst>`_ - Human pose estimation using ``yolov8s_pose``` network.
#. `Semantic Segmentation <semantic_segmentation/README.rst>`_ - Semantic segmentation using ``resnet18_fcn8`` network on top of GStreamer using the Hailo-8 device.