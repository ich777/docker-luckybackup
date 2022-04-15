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
    chmod -f +x /opt/scripts/start-user.sh.sh ||:
    /opt/scripts/start-user.sh || echo "---Optional Script has thrown an Error---"
else
    echo "---No optional script found, continuing---"
fi

echo "---Checking configuration for noVNC---"
novnccheck

echo "---Taking ownership of data...---"
chown -R ${UID}:${GID} /opt/scripts
chown -R ${UID}:${GID} /var/spool/cron
if [ ! -d ${DATA_DIR}/.config/crontabs ]; then
	mkdir -p ${DATA_DIR}/.config/crontabs
fi
ln -s /luckybackup/.config/crontabs /var/spool/cron/crontabs 2>/dev/null
ln -s /luckybackup/luckybackup /usr/bin/luckybackup 2>/dev/null
chown -R ${UID}:${GID} ${DATA_DIR}
cron -- p

echo "---Starting...---"
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