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

TAPPAS-IMX is Hailo's set of full application examples, implementing pipeline elements and
pre-trained AI tasks. This repository is a derivative of the TAPPAS repository and includes applications that run specifically on i.MX8 platforms.

Demonstrating Hailo's system integration scenario of specific use cases on predefined systems
(software and Hardware platforms). It can be used for evaluations, reference code and demos:

* Accelerating time to market by reducing development time and deployment effort
* Simplifying integration with Hailo’s runtime SW stack
* Providing a starting point for customers to fine-tune their applications

.. image:: ./resources/HAILO_TAPPAS_SW_STACK.svg


----

Getting Started with Hailo-8 on i.MX platforms
----------------------------------------------

Prerequisites
^^^^^^^^^^^^^

* Hailo-8 device connected to your i.MX8 platform.
* HailoRT PCIe driver installed in the system
* At least 6GB's of free disk space


.. note::
    This version is compatible with HailoRT v4.21.


Installation
^^^^^^^^^^^^

.. list-table::
   :header-rows: 1

   * - Yocto installation
     - `Read more about Yocto installation <docs/installation/yocto.rst>`_
     - Yocto supported BSP's



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
    * Architecture-specific application examples use platform-specific
      hardware accelerators and are not compatible with different architectures.

.. note::
    All i.MX example application are validated on i.MX8 platforms and are compatible with this architecture.

.. note::
    Running application examples requires a direct connection to a monitor.

Basic Single Network Pipelines
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pipelines that run a single network. The diagram below shows the pipeline data-flow.


.. image:: resources/single_net_pipeline.jpg


The following table details the currently available examples.


`i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
 - Object Detection
 - Depth Estimation
 - Face Recognition


Two Network Pipelines
^^^^^^^^^^^^^^^^^^^^^

Examples of basic pipelines running two networks.
The cascaded (serial) flow shows two networks running in series. This example pipeline is of the popular configuration where the first network is a detector which finds some Region-of-Interest (ROI) in the input image and the second network processes the cropped ROI (a face-detection-and-landmarking use case of this pipeline is shown at the top of this guide). The pipeline is shown in the following diagram:


.. image:: resources/cascaded_nets_pipeline.png


`i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
 - Face Detection & Recognition


Multi-Stream Pipelines
^^^^^^^^^^^^^^^^^^^^^^

.. image:: docs/resources/one_network_multi_stream.png


`i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
 - Multi-stream Object Detection
     


Pipelines for High-Resolution Processing Via Tiling
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. image:: docs/resources/tiling-example.png


`i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
 - HD Object Detection


Example Use Case Pipelines
^^^^^^^^^^^^^^^^^^^^^^^^^^

Our LPR reference application demonstrates the use of 3 networks, with a database.
The pipeline demonstrates inference based decision making (Vehicle detection) for secondary inference tasks (License plate data extraction). This allows multiple networks to cooperate in the pipeline for reactive behavior.


.. image:: resources/lpr_pipeline.png

Our Multi-Person Multi-Camera Tracking reference application demonstrates person tracking across multiple streams using RE-ID tracking.
The pipeline demonstrates another method for inference based decision making that also connects between different video streams.


.. image:: resources/re_id_pipeline.png

`i.MX8 <apps/h8/gstreamer/imx8/README.rst>`_
 - LPR


----

Support
-------

If you need support, please post your question on our `Hailo community Forum <https://community.hailo.ai/>`_ for assistance.

Contact information is available at `hailo.ai <https://hailo.ai/contact-us/>`_.

----

Changelog
----------

**v3.32.0 (June 2025)**

* First release.
* Compatibility with HailoRT v4.21.
* Added more demo applications for i.MX8 platforms.
