Demo Webserver
===============

Overview
--------

This is a simple webserver to allow switching demos from remote.
It currently supports the following demos:

* Detection
* Face recognition
* Pose estimation
* Semantic segmentation



Webserver usage
---------------

1) On your imx8/astrial/arducam camera install the required FLASK library and startup scripts.
   use the setup.sh script (run only once) available under the ``demo_webserver/setup`` folder.

2) Reboot the board.

3) Assuming that your hostname is ``astrial-2g-imx8mp`` you can connect with a browser to
   your camera using the link:

   http://astrial-2g-imx8mp.local

   if you change the hostname (/etc/hostname) you will need to use the proper hostname.

   Alternatively, you can use the device's IP address.

4) From the webpage select the required demo and press "switch".

5) On your linux PC as a streaming client use the ``client_webserver_streaming.sh`` to launch the gstreamer display of the selected demo (the server address must be specified).
   This script offers also polling capability to verify which demo is currently running on the webserver.
   Alternatively, you can use the ``client_rtp_streaming.sh`` script available in the apps section to display the demo (without polling capability).
