Hailo TAPPAS for i.MX - Optimized Execution of Video-Processing Pipelines
=========================================================================

.. |gstreamer| image:: https://img.shields.io/badge/gstreamer-1.16%20%7C%201.18%20%7C%201.20-blue
   :target: https://gstreamer.freedesktop.org/
   :alt: Gstreamer 1.16 | 1.18 | 1.20
   :width: 150
   :height: 20

.. |hailort| image:: https://img.shields.io/badge/HailoRT-4.19.0-green
   :target: https://github.com/hailo-ai/hailort
   :alt: HailoRT
   :height: 20


.. |license| image:: https://img.shields.io/badge/License-LGPLv2.1-green
   :target: https://github.com/hailo-ai/tappas/blob/master/LICENSE
   :alt: License: LGPL v2.1
   :height: 20

.. |check_mark| image:: ./resources/check_mark.png
  :width: 20
  :align: middle

.. image:: ./resources/github_Tappas_Mar24.jpg
  :height: 300
  :width: 600
  :align: center


.. raw:: html

   <div align="center">
      <img src="./apps/h8/gstreamer/general/cascading_networks/readme_resources/cascading_app.gif"/>
   </div>

|gstreamer| |hailort| |license|

----

Overview
--------

TAPPAS is Hailo's set of full application examples, implementing pipeline elements and
pre-trained AI tasks.

Demonstrating Hailo's system integration scenario of specific use cases on predefined systems
(software and Hardware platforms). It can be used for evaluations, reference code and demos:

* Accelerating time to market by reducing development time and deployment effort
* Simplifying integration with Hailo’s runtime SW stack
* Providing a starting point for customers to fine-tune their applications

.. image:: ./resources/HAILO_TAPPAS_SW_STACK.svg


----

Getting Started with Hailo-8
----------------------------

Prerequisites
^^^^^^^^^^^^^

* Hailo-8 device
* HailoRT PCIe driver installed
* At least 6GB's of free disk space


.. note::
    This version is compatible with HailoRT v4.20.


Installation
^^^^^^^^^^^^

.. list-table::
   :header-rows: 1

   * - Option
     - Instructions
     - Supported OS
   * - **Hailo SW Suite***
     - `SW Suite Install guide <docs/installation/sw-suite-install.rst>`_
     - Ubuntu x86 20.04, Ubuntu x86 22.04
   * - Pre-built Docker image
     - `Docker install guide <docs/installation/docker-install.rst>`_
     - Ubuntu x86 20.04, Ubuntu x86 22.04, Ubuntu aarch64 20.04 (64-bit)
   * - Manual install
     - `Manual install guide <docs/installation/manual-install.rst>`_
     - Ubuntu x86 20.04, Ubuntu x86 22.04, Ubuntu aarch64 20.04
   * - Yocto installation
     - `Read more about Yocto installation <docs/installation/yocto.rst>`_
     - Yocto supported BSP's



``* It is recommended to start your development journey by first installing the Hailo SW Suite``

Documentation
^^^^^^^^^^^^^

* `Framework architecture and elements documentation <docs/TAPPAS_architecture.rst>`_
* `Guide to writing your own C++ postprocess element <docs/write_your_own_application/write-your-own-postprocess.rst>`_
* `Guide to writing your own Python postprocess element <docs/write_your_own_application/write-your-own-python-postprocess.rst>`_
* `Debugging and profiling performance <docs/write_your_own_application/debugging.rst>`_
* `Cross compile <tools/cross_compiler/README.rst>`_ - A guide for cross-compiling

----


Example Applications Built with TAPPAS
--------------------------------------

.. note:: These example applications are part of the Hailo AI Software Suite.

  Hailo offers an additional set of
  `Application Code Examples <https://github.com/hailo-ai/Hailo-Application-Code-Examples>`_.

TAPPAS comes with a rich set of pre-configured pipelines optimized for different common hosts.


.. important:: 
    * All example applications utilize both the host (for non-neural tasks) and the Neural-Network Core
      (for neural-networks inference), therefore performance results are affected by the host.
    * General application examples do not include any architecture-specific accelerator usage,
      and therefore will provide the easiest way to run an application, but with sub-optimal performance.
    * Architecture-specific application examples (i.MX, Raspberry PI, etc.) use platform-specific
      hardware accelerators and are not compatible with different architectures.

.. note::
    All i.MX example application are validated on i.MX8 and i.MX6 platforms and are compatible with the architectures.

.. note::
    Running application examples requires a direct connection to a monitor.

Basic Single Network Pipelines
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pipelines that run a single network. The diagram below shows the pipeline data-flow.


.. image:: resources/single_net_pipeline.jpg


The following table details the currently available examples.

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: 40 12 12 12 12 12
   :align: center

   * - 
     - `General <apps/h8/gstreamer/general/README.rst>`_
     - `i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
     - `RPi4 <apps/h8/gstreamer/raspberrypi/README.rst>`_
     - `x86 Hardware Accelerated <apps/h8/gstreamer/x86_hw_accelerated/README.rst>`_
     - `Rockchip <apps/h8/gstreamer/rockchip/README.rst>`_
   * - Object Detection
     - |check_mark|
     - |check_mark|
     - |check_mark|
     - 
     - |check_mark|
   * - Depth Estimation
     - |check_mark|
     - |check_mark|
     - |check_mark|
     - 
     - 
   * - Instance segmentation
     - |check_mark|
     - 
     - 
     - 
     - 
   * - Classification with Python Postprocessing
     - |check_mark|
     - 
     - 
     - 
     - 
   * - Object Detection Multiple Devices (Century)
     - |check_mark|
     - 
     - 
     - |check_mark|
     - 
   * - Face Recognition
     - |check_mark|
     - 
     - 
     - 
     - 


Two Network Pipelines
^^^^^^^^^^^^^^^^^^^^^

Examples of basic pipelines running two networks.
The cascaded (serial) flow shows two networks running in series. This example pipeline is of the popular configuration where the first network is a detector which finds some Region-of-Interest (ROI) in the input image and the second network processes the cropped ROI (a face-detection-and-landmarking use case of this pipeline is shown at the top of this guide). The pipeline is shown in the following diagram:


.. image:: resources/cascaded_nets_pipeline.png


.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: 40 12 12 12 12 12
   :align: center

   * - 
     - `General <apps/h8/gstreamer/general/README.rst>`_
     - `i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
     - `RPi4 <apps/h8/gstreamer/raspberrypi/README.rst>`_
     - `x86 Hardware Accelerated <apps/h8/gstreamer/x86_hw_accelerated/README.rst>`_
     - `Rockchip <apps/h8/gstreamer/rockchip/README.rst>`_
   * - Cascaded - Face Detection & Landmarks
     - |check_mark|
     - 
     - |check_mark|
     - 
     - 
   * - Cascaded - Person Det & Single Person Pose Estimation
     - |check_mark|
     - |check_mark|
     - 
     - 
     - 
   * - Cascaded - Face Detection & Recognition
     - |check_mark|
     - 
     - 
     - 
     - 


Multi-Stream Pipelines
^^^^^^^^^^^^^^^^^^^^^^

.. image:: docs/resources/one_network_multi_stream.png


.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: 40 12 12 12 12 12 
   :align: center

   * - 
     - `General <apps/h8/gstreamer/general/README.rst>`_
     - `i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
     - `RPi4 <apps/h8/gstreamer/raspberrypi/README.rst>`_
     - `x86 Hardware Accelerated <apps/h8/gstreamer/x86_hw_accelerated/README.rst>`_
     - `Rockchip <apps/h8/gstreamer/rockchip/README.rst>`_
   * - Multi-stream Object Detection
     - |check_mark|
     -
     - 
     - |check_mark|
     - |check_mark|
   * - Multi-stream Multi-Device Object Detection
     - |check_mark|
     - 
     - 
     - 
     - 
     


Pipelines for High-Resolution Processing Via Tiling
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. image:: docs/resources/tiling-example.png


.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: 40 12 12 12 12 12
   :align: center

   * - 
     - `General <apps/h8/gstreamer/general/README.rst>`_
     - `i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
     - `RPi4 <apps/h8/gstreamer/raspberrypi/README.rst>`_
     - `x86 Hardware Accelerated <apps/h8/gstreamer/x86_hw_accelerated/README.rst>`_
     - `Rockchip <apps/h8/gstreamer/rockchip/README.rst>`_
   * - HD Object Detection
     - |check_mark|
     - 
     - 
     - 
     - |check_mark|


Example Use Case Pipelines
^^^^^^^^^^^^^^^^^^^^^^^^^^

Our LPR reference application demonstrates the use of 3 networks, with a database.
The pipeline demonstrates inference based decision making (Vehicle detection) for secondary inference tasks (License plate data extraction). This allows multiple networks to cooperate in the pipeline for reactive behavior.


.. image:: resources/lpr_pipeline.png

Our Multi-Person Multi-Camera Tracking reference application demonstrates person tracking across multiple streams using RE-ID tracking.
The pipeline demonstrates another method for inference based decision making that also connects between different video streams.


.. image:: resources/re_id_pipeline.png

.. list-table::
   :header-rows: 1
   :stub-columns: 1
   :widths: 40 12 12 12 12 12
   :align: center

   * - 
     - `General <apps/h8/gstreamer/general/README.rst>`_
     - `i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
     - `RPi4 <apps/h8/gstreamer/raspberrypi/README.rst>`_
     - `x86 Hardware Accelerated <apps/h8/gstreamer/x86_hw_accelerated/README.rst>`_
     - `Rockchip <apps/h8/gstreamer/rockchip/README.rst>`_
   * - LPR
     - |check_mark|
     - |check_mark|
     - 
     - 
     - |check_mark|
   * - RE-ID
     - |check_mark|
     - 
     - 
     - 
     - 


----

Support
-------

If you need support, please post your question on our `Hailo community Forum <https://community.hailo.ai/>`_ for assistance.

Contact information is available at `hailo.ai <https://hailo.ai/contact-us/>`_.

----

Changelog
----------

**v3.XX.X (June 2025)**

* Insert change here