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

echo "---Starting...---"
chown -R ${UID}:${GID} /opt/scripts
chown -R ${UID}:${GID} /var/spool/cron
if [ ! -d ${DATA_DIR}/.config/crontabs ]; then
	mkdir -p ${DATA_DIR}/.config/crontabs
fi
ln -s /luckybackup/.config/crontabs /var/spool/cron/crontabs 2>/dev/null
ln -s /luckybackup/luckybackup /usr/bin/luckybackup 2>/dev/null
chown -R ${UID}:${GID} ${DATA_DIR}
cron -- p

term_handler() {
	kill -SIGTERM "$killpid"
	wait "$killpid" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
su ${USER} -c "/opt/scripts/start-server.sh" &
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done