until cron -- p ; do
	echo "cron crashed with exit code $?.  Respawning.." >&2
    if [ -f /var/run/crond.pid ]; then
        rm -rf /var/run/crond.pid
    fi
	sleep 1
done