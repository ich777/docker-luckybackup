# luckyBackup in Docker optimized for Unraid
LuckyBackup is a very user-friendly GUI backup program. It uses rsync as a backend and transfers over only changes made rather than all data.

**Update:** The container will check on every start/restart if there is a newer version available

**Cron:** If you create a cron job please be sure to tick the "Console Mode" checkbox, otherwise the cron jobs will not work.

**Language:** If you want to change the language make sure to exit luckyBackup from within the WebGUI by clicking 'Profile -> Quit' or CTRL +X otherwise the language change isn't saved.

## Env params
| Name | Value | Example |
| --- | --- | --- |
| DATA_DIR | Folder for configfiles and the application | /luckybackup |
| ROOT | Run luckyBackup as root, this is only needed if you want to create backups from directories that require root privileges, set to 'true' to run luckyBackup as root | false |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| UMASK | Umask value for new created files | 0000 |
| DATA_PERMS | Data permissions for config folder | 770 |

## Run example
```
docker run --name luckyBackup -d \
	-p 8080:8080 \
	--env 'UID=99' \
	--env 'GID=100' \
	--env 'UMASK=0000' \
	--env 'DATA_PERMS=770' \
	--volume /mnt/cache/appdata/luckybackup:/luckybackup \
	--volume /mnt/user/:/mnt/user \
	ich777/luckybackup
```

## Set VNC Password:
 Please be sure to create the password first inside the container, to do that open up a console from the container (Unraid: In the Docker tab click on the container icon and on 'Console' then type in the following):

1) **su $USER**
2) **vncpasswd**
3) **ENTER YOUR PASSWORD TWO TIMES AND PRESS ENTER AND SAY NO WHEN IT ASKS FOR VIEW ACCESS**

Unraid: close the console, edit the template and create a variable with the `Key`: `TURBOVNC_PARAMS` and leave the `Value` empty, click `Add` and `Apply`.

All other platforms running Docker: create a environment variable `TURBOVNC_PARAMS` that is empty or simply leave it empty:
```
    --env 'TURBOVNC_PARAMS='
```

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!
 
#### Support Thread: https://forums.unraid.net/topic/83786-support-ich777-application-dockers/