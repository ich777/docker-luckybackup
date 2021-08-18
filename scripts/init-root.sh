#!/bin/bash
echo "---Initializing server, please wait...---"
#!/bin/bash
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

vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :0 -rfbport ${RFB_PORT} -noxstartup ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2

cd ${DATA_DIR}
timeout 5 /usr/bin/luckybackup

echo "-----Initialisation complete please restart the container-----"
echo "---please restart the container if it doesn't auto restart!---"
echo