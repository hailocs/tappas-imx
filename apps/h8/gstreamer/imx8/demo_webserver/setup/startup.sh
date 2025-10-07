sleep 3

cd /opt/imx8-isp/bin
./run.sh -lm -c dual_imx219_1080p60 &

sleep 3

cd /root/apps/demo_webserver
python3 ./webserver.py
