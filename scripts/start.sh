#!/bin/bash
echo "---Ensuring UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Ensuring GID: ${GID} matches user---"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Checking for optional scripts---"
cp -f /opt/custom/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:
cp -f /opt/scripts/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:

if [ -f /opt/scripts/start-user.sh ]; then
    echo "---Found optional script, executing---"
    chmod -f +x /opt/scripts/start-user.sh ||:
    /opt/scripts/start-user.sh || echo "---Optional Script has thrown an Error---"
else
    echo "---No optional script found, continuing---"
fi

echo "---Checking configuration for noVNC---"
novnccheck

echo "---Starting cron---"
if [ -f /var/run/crond.pid ]; then
	rm -rf /var/run/crond.pid
fi
export PATH=/bin:/usr/bin:${DATA_DIR}:$PATH
/usr/sbin/cron -- p

echo "---Taking ownership of data...---"
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} ${DATA_DIR}

echo "---Starting...---"
term_handler() {
	kill -SIGTERM "$killpid"
	wait "$killpid" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
if [ "${ROOT}" != "true" ]; then
	if [ -d /tmp/runtime-luckybackup ]; then
	  chown -R ${UID}:${GID} /tmp/runtime-luckybackup
	fi
	su ${USER} -c "/opt/scripts/start-server.sh" &
else
	if [ ! -d ${DATA_DIR}/.luckyBackup ]; then
		su ${USER} -c "/opt/scripts/init-root.sh"
		exit 0
	fi
	if [ ! -d /root/.luckyBackup ]; then
		mkdir -p /root/.luckyBackup
	else
		rm -rf /root/.luckyBackup
		mkdir -p /root/.luckyBackup
	fi
	if [ -d /tmp/runtime-luckybackup ]; then
	  chown -R root:root /tmp/runtime-luckybackup
	fi
	if [ -f ${DATA_DIR}/.vnc/passwd ]; then
		mkdir -p /root/.vnc 2 >/dev/null
		cp ${DATA_DIR}/.vnc/passwd /root/.vnc/passwd
	fi
	ln -s ${DATA_DIR}/.luckyBackup/* /root/.luckyBackup/
	/opt/scripts/start-server.sh &
fi
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done