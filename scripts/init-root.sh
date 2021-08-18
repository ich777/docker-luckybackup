#!/bin/bash
echo "---Initializing server, please wait...---"
export DISPLAY=:0
export XAUTHORITY=${DATA_DIR}/.Xauthority
export XDG_RUNTIME_DIR=/tmp/runtime-luckybackup


rm -rf /tmp/.X0*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
	chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null
chmod 700 ${DATA_DIR}/.ssh
chmod 600 ${DATA_DIR}/.ssh/*

vncserver -geometry 800x600 -depth 16 :0 -rfbport 9998 -noxstartup 2>/dev/null
sleep 2
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem 9999 localhost:9998

cd ${DATA_DIR}
timeout 5 /usr/bin/luckybackup

echo "-----Initialisation complete please restart the container-----"
echo "---please restart the container if it doesn't auto restart!---"
echo