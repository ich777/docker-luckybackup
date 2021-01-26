#!/bin/bash
export DISPLAY=:0
LAT_V="$(wget -qO- https://github.com/ich777/versions/raw/master/luckyBackup | grep FORK | cut -d '=' -f2)"
CUR_V="$(${DATA_DIR}/luckybackup --version 2> /dev/null | grep "version:" | rev | cut -d ' ' -f1 | rev)"
if [ -z $LAT_V ]; then
	if [ -z $CUR_V ]; then
		echo "---Can't get latest version of luckyBackup, putting container into sleep mode!---"
		sleep infinity
	else
		echo "---Can't get latest version of luckyBackup, falling back to v$CUR_V---"
	fi
fi

echo "---Version Check---"
if [ -z "$CUR_V" ]; then
	echo "---luckyBackup not found, downloading and installing v$LAT_V...---"
	cd ${DATA_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz "https://github.com/ich777/luckyBackup/releases/download/$LAT_V/luckyBackup-v${LAT_V}.tar.gz" ; then
		echo "---Successfully downloaded luckyBackup v$LAT_V---"
	else
		echo "---Something went wrong, can't download luckyBackup v$LAT_V, putting container into sleep mode!---"
		sleep infinity
	fi
	tar -C / --overwrite -xf ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz 2> /dev/null
	rm ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz
elif [ "$CUR_V" != "$LAT_V" ]; then
	echo "---Version missmatch, installed v$CUR_V, downloading and installing latest v$LAT_V...---"
	cd ${DATA_DIR}
	rm -R ${DATA_DIR}/luckybackup*
	if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz "https://github.com/ich777/luckyBackup/releases/download/$LAT_V/luckyBackup-v${LAT_V}.tar.gz" ; then
		echo "---Successfully downloaded luckyBackup v$LAT_V---"
	else
		echo "---Something went wrong, can't download luckyBackup v$LAT_V, putting container into sleep mode!---"
		sleep infinity
	fi
	tar -C / --overwrite -xf ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz 2> /dev/null
	rm ${DATA_DIR}/luckyBackup-v$LAT_V.tar.gz
elif [ "$CUR_V" == "$LAT_V" ]; then
	echo "---luckyBackup v$CUR_V up-to-date---"
fi

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
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
find /tmp -name ".X0*" -exec rm -f {} \; > /dev/null 2>&1
screen -wipe 2&>/dev/null
chmod -R ${DATA_PERM} ${DATA_DIR}
chmod 700 ${DATA_DIR}/.ssh
chmod 600 ${DATA_DIR}/.ssh/*

echo "---Starting Xvfb server---"
screen -S Xvfb -L -Logfile ${DATA_DIR}/XvfbLog.0 -d -m /opt/scripts/start-Xvfb.sh
sleep 2
echo "---Starting x11vnc server---"
screen -S x11vnc -L -Logfile ${DATA_DIR}/x11vncLog.0 -d -m /opt/scripts/start-x11.sh
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
${DATA_DIR}/luckybackup