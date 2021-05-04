#!/bin/bash
if [ "${ROOT}" != "true" ]; then
    while true
    do
    	cp -u /var/spool/cron/crontabs/luckybackup ${DATA_DIR}/.cron/luckybackup &>/dev/null
    	sleep ${CRON_WATCHDOG}
    done
else
    while true
    do
    	cp -u /var/spool/cron/crontabs/root ${DATA_DIR}/.cron/luckybackup &>/dev/null
    	sleep ${CRON_WATCHDOG}
    done
fi