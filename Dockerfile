FROM ich777/novnc-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-luckybackup"

RUN export TZ=Europe/Rome && \
	apt-get update && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get -y install --no-install-recommends curl libqt5core5a qtscript5-dev libc6 libgcc1 libstdc++6 libqt5network5 rsync cron ssh ssh-askpass sendemail jq libnet-ssleay-perl libio-socket-ssl-perl ttf-wqy-zenhei fonts-wqy-microhei fonts-takao fonts-arphic-uming fonts-noto-cjk && \
	echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen && \ 
	echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i '/    document.title =/c\    document.title = "luckyBackup - noVNC";' /usr/share/novnc/app/ui.js && \
	wget -q -O /tmp/luckybackup.tar.gz https://github.com/ich777/luckyBackup/releases/download/0.5.0/luckyBackup-v0.5.0.tar.gz && \
	tar -C / -xf /tmp/luckybackup.tar.gz && \
	rm -rf /tmp/luckybackup.tar.gz && \
	rm /usr/share/novnc/app/images/icons/*

RUN mkdir -p /run/sshd && \
	rm -v /etc/ssh/ssh_host_* && \
	sed -i "/#Port 8022/c\Port 8022" /etc/ssh/sshd_config && \
	sed -i "/#ListenAddress 0.0.0.0/c\ListenAddress 0.0.0.0" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_rsa_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_rsa_key" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_ecdsa_key" /etc/ssh/sshd_config && \
	sed -i "/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/c\HostKey \/luckybackup\/.ssh\/ssh_host_ed25519_key" /etc/ssh/sshd_config && \
	sed -i "/HashKnownHosts yes/c\    HashKnownHosts no" /etc/ssh/ssh_config && \
	sed -i "/StrictHostKeyChecking ask/c\    StrictHostKeyChecking no" /etc/ssh/ssh_config

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
COPY /icons/* /usr/share/novnc/app/images/icons/
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