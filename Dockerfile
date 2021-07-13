FROM ich777/novnc-baseimage

LABEL maintainer="admin@minenet.at"

RUN export TZ=Europe/Rome && \
	apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get -y install --no-install-recommends fonts-takao libqtcore4 libqtgui4 libc6 libgcc1 libstdc++6 libqt4-network rsync cron ssh ssh-askpass sendemail jq && \
	echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen && \ 
	echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i '/    document.title =/c\    document.title = "luckyBackup - noVNC";' /usr/share/novnc/app/ui.js && \
	wget -q -O /tmp/luckybackup.tar.gz "$(wget -qO- "https://sourceforge.net/projects/luckybackup/best_release.json" | jq -r '.platform_releases.linux.url')" && \
	tar -C / --strip-components=1 -xf /tmp/luckybackup.tar.gz && \
	rm /usr/share/novnc/app/images/icons/*

RUN mkdir -p /run/sshd && \
	rm -v /etc/ssh/ssh_host_* && \
	sed -i "/#Port 8022/c\Port 8022" /etc/ssh/sshd_config && \
	sed -i "/#ListenAddress 0.0.0.0/c\ListenAddress 0.0.0.0" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_rsa_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_rsa_key" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_ecdsa_key" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_ed25519_key" /etc/ssh/sshd_config

ENV DATA_DIR=/luckybackup
ENV CUSTOM_RES_W=1024
ENV CUSTOM_RES_H=768
ENV CUSTOM_DEPTH=16
ENV CRON_WATCHDOG=60
ENV NOVNC_PORT=8080
ENV RFB_PORT=5900
ENV TURBOVNC_PARAMS="-securitytypes none" 
ENV UMASK=0000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="luckybackup"

RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	mkdir /etc/.fluxbox && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
#COPY /icons/* /usr/share/novnc/app/images/icons/
COPY /conf/ /etc/.fluxbox/
COPY /cron /tmp/
RUN chmod -R 770 /opt/scripts/ && \
	chown -R root:$GID /usr/share && \
	chmod -R 775 /usr/share && \
	chown -R ${UID}:${GID} /mnt && \
	chmod -R 770 /mnt


EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]