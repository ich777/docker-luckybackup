#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=${DATA_DIR}/.Xauthority
export XDG_RUNTIME_DIR=/tmp/runtime-luckybackup

echo "---Preparing Server---"
if [ ! -d ${DATA_DIR}/.ssh ]; then
    mkdir -p ${DATA_DIR}/.ssh
fi
if [ ! -f ${DATA_DIR}/.ssh/ssh_host_rsa_key ]; then
    echo "---No ssh_host_rsa_key found, generating!---"
    ssh-keygen -f ${DATA_DIR}/.ssh/ssh_host_rsa_key -t rsa -b 4096 -N ""
else
    echo "---ssh_host_rsa_key keys found!---"
fi
if [ ! -f ${DATA_DIR}/.ssh/ssh_host_ecdsa_key ]; then
    echo "---No ssh_host_ecdsa_key found, generating!---"
    ssh-keygen -f ${DATA_DIR}/.ssh/ssh_host_ecdsa_key -t ecdsa -b 521 -N ""
else
    echo "---ssh_host_ecdsa_key found!---"
fi
if [ ! -f ${DATA_DIR}/.ssh/ssh_host_ed25519_key ]; then
    echo "---No ssh_host_ed25519_key found, generating!---"
    ssh-keygen -f ${DATA_DIR}/.ssh/ssh_host_ed25519_key -t ed25519 -N ""
else
    echo "---ssh_host_ed25519_key found!---"
fi
echo "---Starting ssh daemon---"
/usr/sbin/sshd
sleep 2

echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W} ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H} ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
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
if [ ! -d ${DATA_DIR}/.cron ]; then
	mkdir -p ${DATA_DIR}/.cron
fi
if [ ! "$(crontab -l 2>/dev/null)" ]; then
  if [ ! -f ${DATA_DIR}/.luckyBackup/schedule/luckyCron.txt ]; then
    crontab /tmp/cron
  else
    crontab ${DATA_DIR}/.luckyBackup/schedule/luckyCron.txt
  fi
fi

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :0 -rfbport ${RFB_PORT} -noxstartup ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2
echo "---Starting ssh daemon---"
/usr/sbin/sshd
sleep 2

echo "---Starting luckyBackup---"
cd ${DATA_DIR}
/usr/bin/luckybackup