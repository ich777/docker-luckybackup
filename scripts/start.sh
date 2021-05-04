#!/bin/bash
echo "---Checking if UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Checking if GID: ${GID} matches user---"
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Checking for optional scripts---"
if [ -f /opt/scripts/user.sh ]; then
	echo "---Found optional script, executing---"
    chmod +x /opt/scripts/user.sh
    /opt/scripts/user.sh
else
	echo "---No optional script found, continuing---"
fi

echo "---Checking configuration for noVNC---"
novnccheck

echo "---Starting...---"
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} /var/spool/cron
if [ ! -d ${DATA_DIR}/.config/crontabs ]; then
	mkdir -p ${DATA_DIR}/.config/crontabs
fi
if [ -f /var/run/crond.pid ]; then
	rm -rf /var/run/crond.pid
fi
if [ "${ROOT}" != "true" ]; then
	if [ -f ${DATA_DIR}/.cron/luckybackup ]; then
		if [ ! -d /var/spool/cron/crontab ]; then
			mkdir -p /var/spool/cron/crontab
		fi
		cp ${DATA_DIR}/.cron/luckybackup /var/spool/cron/crontabs/luckybackup
		chmod 600 /var/spool/cron/crontabs/luckybackup
		chown ${UID}:crontab /var/spool/cron/crontabs/luckybackup
	fi
else
	if [ -f ${DATA_DIR}/.cron/luckybackup ]; then
		if [ ! -d /var/spool/cron/crontab ]; then
			mkdir -p /var/spool/cron/crontab
		fi
		cp ${DATA_DIR}/.cron/luckybackup /var/spool/cron/crontabs/root
		chmod 600 /var/spool/cron/crontabs/root
		chown ${UID}:crontab /var/spool/cron/crontabs/root
	fi
fi
ln /luckybackup/.config/crontabs/luckybackup /var/spool/cron/crontabs/luckybackup 2>/dev/null
chown -R ${UID}:${GID} ${DATA_DIR}
echo "---Starting cron---"
/opt/scripts/start-cron.sh &
/opt/scripts/start-cronwatchdog.sh &

term_handler() {
	kill -SIGTERM "$killpid"
	wait "$killpid" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
if [ "${ROOT}" != "true" ]; then
	su ${USER} -c "/opt/scripts/start-server.sh" &
else
	if [ ! -d ${DATA_DIR}/.luckyBackup ]; then
		mkdir -p ${DATA_DIR}/.luckyBackup
	fi
	if [ ! -d /root/.luckyBackup ]; then
		mkdir -p /root/.luckyBackup
	else
		rm -rf /root/.luckyBackup
		mkdir -p /root/.luckyBackup
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